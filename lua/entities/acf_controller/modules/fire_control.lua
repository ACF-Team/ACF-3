local TimerSimple = timer.Simple

local RecacheBindOutput = ENT.RecacheBindOutput
local GetKeyState = ENT.GetKeyState

local NUM_WEAPONS = 3 -- Number of Gun1/Gun2/Gun3 slots

local function Init(Entity)
	Entity.Turrets          = {}    -- Turrets, both horizontal and vertical
	Entity.Guns             = {}    -- All guns
	Entity.Racks            = {}    -- All racks
	Entity.GuidanceComputer = nil   -- The guidance computer, if any
	Entity.TurretComputer   = nil   -- The turret computer, if any
	Entity.FireGroups       = {}    -- [1]/[2]/[3]: guns/racks sharing Gun1's/Gun2's/Gun3's ShortName
	Entity.WeaponGroups     = {}    -- ShortName -> Set of every linked gun/rack of that type
	Entity.GunsSmoke        = {}    -- Smoke and flare launchers
	Entity.TurretLocked     = false -- Whether the turret is locked or not
	Entity.Smoke            = nil   -- Reference smoke launcher, for HUD purposes
	Entity.Drop             = 0
	Entity.TravelTime       = 0
	Entity.LaseDist         = 0
	Entity.LasePitch        = 0

	for i = 1, NUM_WEAPONS do Entity.FireGroups[i] = {} end
end

-- Turret related
do
	-- Groups are keyed by weapon name, never by raw caliber alone,
	-- since a gun and a rack's missile can share the same caliber number but aren't the same weapon
	local function AnalyzeWeapon(self, Weapon)
		local Key = Weapon.Name
		local Set = self.WeaponGroups[Key] or {}
		self.WeaponGroups[Key] = Set
		Set[Weapon] = true

		-- The user's LockWeaponSlots checkbox decides auto-detection, instead of us guessing
		-- intent from whether Gun1/2/3 happen to be set (e.g. from a dupe restore)
		if not self:GetLockWeaponSlots() then
			local Reps = {}
			for _, Group in pairs(self.WeaponGroups) do Reps[#Reps + 1] = next(Group) end
			-- Equal calibers across types are expected, so break ties by key to keep slots stable
			-- A rack's Caliber can still be nil if it hasn't been given ammo yet
			table.sort(Reps, function(A, B)
				local CaliberA, CaliberB = A.Caliber or 0, B.Caliber or 0
				if CaliberA == CaliberB then return A.Name < B.Name end
				return CaliberA > CaliberB
			end)

			for i = 1, NUM_WEAPONS do self["SetGun" .. i](self, Reps[i] or NULL) end
		end

		-- Either way, each slot's group is everything sharing that slot's weapon identity
		for i = 1, NUM_WEAPONS do
			local Gun = self["GetGun" .. i](self)
			self.FireGroups[i] = IsValid(Gun) and self.WeaponGroups[Gun.Name] or {}
		end
	end

	function ENT:AnalyzeGuns(Gun)
		self.Guns[Gun] = true

		if Gun.Weapon == "ACF.Guns.SmokeLauncher" then
			self.GunsSmoke[Gun] = true
			if not IsValid(self.Smoke) then self.Smoke = Gun end
			local Fuse = self:GetSmokeFuse() or 0
			if Fuse > 0 then Gun:TriggerInput("Fuze", Fuse) end
			return
		end

		AnalyzeWeapon(self, Gun)
	end

	function ENT:AnalyzeRacks(Rack)
		self.Racks[Rack] = true

		AnalyzeWeapon(self, Rack)
	end

	-- Fire guns
	-- TODO:  Add fire sequencing
	local function HandleFire(Fire, Guns, OverrideDelay)
		local Gun = next(Guns)
		if not Gun then return end

		local Delay = OverrideDelay or Gun.ReloadTime or 0
		local Count = table.Count(Guns)
		local Counter = 0
		for Gun in pairs(Guns) do
			local CurrentGun = Gun
			if CurrentGun.Firing == Fire then continue end -- Don't make a timer if nothing changed
			CurrentGun.Firing = Fire
			local TrueDelay = Counter * Delay / Count -- It's called good luck
			TimerSimple(TrueDelay, function()
				if IsValid(CurrentGun) and Fire then
					local GunCanFire = CurrentGun.CanFire and CurrentGun:CanFire()
					local RackCanFire = CurrentGun.CanShoot and CurrentGun:CanShoot()
					if (GunCanFire or RackCanFire) then CurrentGun:Shoot() end
				end
			end)
			Counter = Counter + 1
		end
	end

	function ENT:ProcessGuns(SelfTbl)
		if SelfTbl:GetDisableFiring() then return end

		local Fires = {GetKeyState(SelfTbl, IN_ATTACK), GetKeyState(SelfTbl, IN_ATTACK2), GetKeyState(SelfTbl, IN_WALK)}

		for i = 1, NUM_WEAPONS do
			HandleFire(Fires[i], SelfTbl.FireGroups[i], i == NUM_WEAPONS and SelfTbl:GetFireDelay() or nil)
		end

		HandleFire(GetKeyState(SelfTbl, IN_SPEED), SelfTbl.GunsSmoke)
	end

	function ENT:ToggleTurretLocks(SelfTbl, Key, Down)
		if Key == IN_RELOAD and Down then
			local Turrets = SelfTbl.Turrets
			SelfTbl.TurretLocked = not SelfTbl.TurretLocked
			RecacheBindOutput(self, SelfTbl, "IsTurretLocked", SelfTbl.TurretLocked and 1 or 0)
			for Turret, _ in pairs(Turrets) do
				if IsValid(Turret) then Turret:TriggerInput("Active", not SelfTbl.TurretLocked) end
			end
		end
	end

	-- Aim turrets
	function ENT:ProcessTurrets(SelfTbl, HitPos)
		local Turrets = SelfTbl.Turrets
		if not IsValid(SelfTbl.Baseplate) then return end -- Needed for velocity
		if SelfTbl.TurretLocked then return end
		if self:GetDisableAIOCam() then return end -- I guess bro

		local Primary = self:GetGun1()
		local BreechReference = IsValid(Primary) and Primary.BreechReference
		local ReloadAngle = self:GetReloadAngle()
		local ReloadAngleHorizontal = self:GetReloadAngleHorizontal()
		-- Mag-fed guns chamber a fresh round between shots too, only level for the actual magazine reload
		local ShouldLevel = ReloadAngle ~= 0 and IsValid(Primary) and Primary.State ~= "Loaded" and (not Primary.MagSize or Primary.MagazineReloading)

		-- Liddul... if you can hear me...
		local TurretComputer = self.TurretComputer
		local SuperElevation = nil
		if TurretComputer  then
			if TurretComputer.Computer == "DIR-BalComp" then SuperElevation = TurretComputer.Outputs.Elevation.Value
			elseif TurretComputer.Computer == "IND-BalComp" then SuperElevation = TurretComputer.Outputs.Angle[1] end
		end

		if SuperElevation ~= nil and SuperElevation ~= SelfTbl.LastSuperElevation then
			local TrueSuperElevation = SuperElevation - (SelfTbl.LasePitch or 0) -- Compute pitch offset to account for drop
			SelfTbl.Drop = (SelfTbl.LaseDist or 0) * math.tan(math.rad(-TrueSuperElevation)) -- Compute vector offset to account for drop
			SelfTbl.TravelTime = SelfTbl.LaseDist ~= 0 and TurretComputer.Outputs["Flight Time"].Value or 0
		end
		local AntiDrop = Vector(0, 0, SelfTbl.Drop or 0)
		local AntiDrift = -self.Baseplate:GetVelocity() * (SelfTbl.TravelTime or 0)

		for Turret, _ in pairs(Turrets) do
			if IsValid(Turret) then
				if Turret == BreechReference and ShouldLevel then Turret:InputDirection(ReloadAngle)
				elseif BreechReference and Turret == BreechReference:GetParent() and ShouldLevel and ReloadAngleHorizontal ~= 0 then Turret:InputDirection(ReloadAngleHorizontal)
				else Turret:InputDirection(HitPos + AntiDrop + AntiDrift) end

				if Turret == SelfTbl.RadarVertical and SelfTbl.SelectedTargetID then Turret:InputDirection(SelfTbl.SelectedTargetPos) end
			end
		end
	end

	-- Guidance related
	do
		function ENT:ProcessGuidance(SelfTbl)
			local GuideComp = SelfTbl.GuidanceComputer
			if not IsValid(GuideComp) then return end

			-- We just want to know if there are any in air we should be lasing for...
			local FoundInAir = false

			for Gun in pairs(SelfTbl.Guns) do
				if FoundInAir then break end
				if Gun.Outputs["In Air"].Value > 0 then FoundInAir = true end
			end

			for Rack in pairs(SelfTbl.Racks) do
				if FoundInAir then break end
				if Rack.Outputs["In Air"].Value > 0 then FoundInAir = true end
			end

			GuideComp:TriggerInput("Lase", FoundInAir and 1 or 0)
			GuideComp:TriggerInput("HitPos", SelfTbl.HitPos)
		end
	end
end

ACF.RegisterControllerLink("acf_turret", {
	Field = "Turrets",
	Single = false,
})

ACF.RegisterControllerLink("acf_gun", {
	Field = "Guns",
	Single = false,
	OnLinked = function(Controller, Target)
		Controller:AnalyzeGuns(Target)
	end,
})

ACF.RegisterControllerLink("acf_turret_computer", {
	Field = "TurretComputer",
	Single = true,
})

ACF.RegisterControllerLink("acf_computer", {
	Field = "GuidanceComputer",
	Single = true,
	PreLink = function(_, Target)
		if Target.Computer ~= "CPR-LSR" and Target.Computer ~= "CPR-OPT" then return false, "Only laser/optical guidance computers are supported." end
		return true
	end,
})

ACF.RegisterControllerLink("acf_rack", {
	Field = "Racks",
	Single = false,
	OnLinked = function(Controller, Target)
		Controller:AnalyzeRacks(Target)
	end,
})

return Init