-- Turret related
do
	function ENT:AnalyzeGuns(Gun)
		-- Sorts guns into primary, secondary and smoke launchers
		-- O(n)... heartwarming
		if Gun.Weapon == "SL" then self.GunsSmoke[Gun] = true
		elseif Gun.Caliber < self.LargestCaliber then self.GunsSecondary[Gun] = true
		elseif Gun.Caliber == self.LargestCaliber then self.GunsPrimary[Gun] = true
		elseif Gun.Caliber > self.LargestCaliber then
			for Gun in pairs(self.GunsPrimary) do
				self.GunsSecondary[Gun], self.GunsPrimary[Gun] = true, nil
			end
			self.GunsPrimary[Gun] = true
			self.LargestCaliber = Gun.Caliber
		end
	end

	function ENT:AnalyzeRacks(Rack)
		self.Racks[Rack] = true
		self.Tertiary = Rack
	end

	-- Fire guns
	-- TODO:  Add fire sequencing
	local FiringStates = {}
	local function HandleFire(Fire, Guns)
		for Gun in pairs(Guns) do
			if IsValid(Gun) then
				if not FiringStates[Gun] and Fire then
					Gun.Firing = true
					local GunCanFire = Gun.CanFire and Gun:CanFire()
					local RackCanFire = Gun.CanShoot and Gun:CanShoot()
					if (GunCanFire or RackCanFire) then Gun:Shoot() end
				else
					Gun.Firing = false
				end
			end
		end
	end

	function ENT:ProcessGuns(SelfTbl)
		if SelfTbl:GetDisableFiring() then return end

		local Fire1, Fire2, Fire3, Fire4 = GetKeyState(SelfTbl, IN_ATTACK), GetKeyState(SelfTbl, IN_ATTACK2), GetKeyState(SelfTbl, IN_WALK), GetKeyState(SelfTbl, IN_SPEED)

		HandleFire(Fire1, SelfTbl.GunsPrimary)
		HandleFire(Fire2, SelfTbl.GunsSecondary)
		HandleFire(Fire3, SelfTbl.Racks)
		HandleFire(Fire4, SelfTbl.GunsSmoke)
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

		if SelfTbl.TurretLocked then return end

		local Primary = self.Primary
		local BreechReference = IsValid(Primary) and Primary.BreechReference
		local ReloadAngle = self:GetReloadAngle()
		local ShouldLevel = ReloadAngle ~= 0 and IsValid(Primary) and Primary.State ~= "Loaded"
		local ShouldElevate = IsValid(self.TurretComputer)

		-- Liddul... if you can hear me...
		local TurretComputer = self.TurretComputer
		local SuperElevation
		if TurretComputer  then
			if TurretComputer.Computer == "DIR-BalComp" then SuperElevation = TurretComputer.Outputs.Elevation.Value
			elseif TurretComputer.Computer == "IND-BalComp" then SuperElevation = TurretComputer.Outputs.Angle[1]
			end
		end

		if SuperElevation ~= nil and SuperElevation ~= SelfTbl.LastSuperElevation then
			local TrueSuperElevation = SuperElevation - (SelfTbl.LasePitch or 0) -- Compute pitch offset to account for drop
			local CounterDrop = (SelfTbl.LaseDist or 0) * math.tan(math.rad(-TrueSuperElevation)) -- Compute vector offset to account for drop
			SelfTbl.Additive = Vector(0, 0, CounterDrop)
		end
		SelfTbl.LastSuperElevation = SuperElevation

		SelfTbl.Additive = SelfTbl.Additive or vector_origin

		for Turret, _ in pairs(Turrets) do
			if IsValid(Turret) then
				if Turret == BreechReference and ShouldLevel then
					Turret:InputDirection(ReloadAngle)
				elseif Turret == BreechReference and ShouldElevate then
					Turret:InputDirection(HitPos + self.Additive)
				else
					Turret:InputDirection(HitPos + self.Additive)
				end
			end
		end
	end

	-- Guidance related
	do
		function ENT:ProcessGuidance(SelfTbl)
			local GuideComp = SelfTbl.GuidanceComputer
			if not IsValid(GuideComp) then return end

			-- We just want to know if there are any in air we should be lasing for...
			local InAir = 0
			if SelfTbl.Primary then InAir = InAir + (SelfTbl.Primary.Outputs["In Air"].Value or 0) end
			if SelfTbl.Tertiary then InAir = InAir + (SelfTbl.Tertiary.Outputs["In Air"].Value or 0) end
			GuideComp:TriggerInput("Lase", InAir > 0 and 1 or 0)
			GuideComp:TriggerInput("HitPos", SelfTbl.HitPos)
		end
	end
end