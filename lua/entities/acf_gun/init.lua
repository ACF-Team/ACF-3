--[[
This is the main server side file for the gun entity.

Crew relevant functions:
- ENT:UpdateLoadMod(LastTime) -- Updates the load modifier for the gun
- ENT:UpdateAccuracyMod(LastTime) -- Updates the accuracy modifier for the gun
- ENT:FindNextCrate(Current, Check, ...) -- Finds the next crate that can be used for the gun
]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars -----------------------------------

local ACF         = ACF
local Contraption = ACF.Contraption
local Classes     = ACF.Classes
local AmmoTypes   = Classes.AmmoTypes
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock
local Sounds      = Utilities.Sounds
local TimerCreate = timer.Create
local TraceLine = util.TraceLine
local EMPTY       = { Type = "Empty", PropMass = 0, ProjMass = 0, Tracer = 0 }

-- Helper functions
local function UpdateTotalAmmo(Entity)
	local Total = 0

	for Crate in pairs(Entity.Crates) do
		if Crate:CanConsume() then
			Total = Total + Crate.Ammo
		end
	end

	Entity.TotalAmmo = Total

	WireLib.TriggerOutput(Entity, "Total Ammo", Total)
end

-- TODO: Maybe move this logic to crates?
local function CheckValid(v, Gun)
	return IsValid(v) and v.Weapons[Gun]
end

local function CheckConsumable(v, Gun)
	return CheckValid(v, Gun) and v:CanConsume()
end

local function CheckRestockable(v, Gun)
	return CheckValid(v, Gun) and v:CanRestock()
end

local function CheckUnloadable(v, Gun)
	return CheckValid(v, Gun) and v:CanRestock() and ACF.BulletEquality(v.BulletData, Gun.BulletData)
end

do -- Random timer crew stuff
	local Red = Color(255, 0, 0)
	local Green = Color(0, 255, 0)

	local TraceConfig = {start = Vector(), endpos = Vector(), filter = nil}

	-- Calculates the reload efficiency between a Crew, one of it's guns and an ammo crate
	local function GetReloadEff(Crew, Gun, Ammo)
		local BreechPos = Gun:LocalToWorld(Gun.BreechPos)
		local CrewPos = Crew:LocalToWorld(Crew.CrewModel.ScanOffsetL)
		local AmmoPos = Ammo:GetPos()
		local D1 = CrewPos:Distance(BreechPos)
		local D2 = CrewPos:Distance(AmmoPos)

		TraceConfig.start = CrewPos
		TraceConfig.endpos = BreechPos
		TraceConfig.filter = function(x) return not (x == Gun or x.noradius or x == Crew or x:GetOwner() ~= Gun:GetOwner() or x:IsPlayer()) end
		local tr = TraceLine(TraceConfig)

		debugoverlay.Line(CrewPos, tr.HitPos, 1, Green, true)
		debugoverlay.Line(tr.HitPos, BreechPos, 1, Red, true)

		Crew.OverlayErrors.LOSCheck = tr.Hit and "Crew cannot see the breech\nOf: " .. (tostring(Gun) or "<INVALID ENTITY???>") .. "\nBlocked by " .. (tostring(tr.Entity) or "<INVALID ENTITY???>") or nil
		Crew:UpdateOverlay()
		if tr.Hit then return 0.000001 end -- Wanna avoid division by zero...

		return Crew.TotalEff * ACF.Normalize(D1 + D2, ACF.LoaderWorstDist, ACF.LoaderBestDist)
	end

	function ENT:UpdateLoadMod()
		self.CrewsByType = self.CrewsByType or {}
		local Sum1 = ACF.WeightedLinkSum(self.CrewsByType.Loader or {}, GetReloadEff, self, self.CurrentCrate or self)
		local Sum2 = ACF.WeightedLinkSum(self.CrewsByType.Commander or {}, GetReloadEff, self, self.CurrentCrate or self)
		local Sum3 = ACF.WeightedLinkSum(self.CrewsByType.Pilot or {}, GetReloadEff, self, self.CurrentCrate or self)
		self.LoadCrewMod = math.Clamp(Sum1 + Sum2 + Sum3, ACF.CrewFallbackCoef, ACF.LoaderMaxBonus)

		-- Check space behind breech
		if self.BulletData and self.ClassData.BreechConfigs then

			-- Check assuming 2 piece for now.
			local ShellLength = ((self.BulletData.PropLength or 0) + (self.BulletData.ProjLength or 0)) / ACF.InchToCm / 2
			local p1 = self.BreechPos
			local p2 = p1 - Vector(ShellLength, 0, 0)
			local wp1, wp2 = self:LocalToWorld(p1), self:LocalToWorld(p2)

			TraceConfig.start = wp1
			TraceConfig.endpos = wp2
			TraceConfig.filter = function(x) return not (x == self or x.noradius or x:GetOwner() ~= self:GetOwner() or x:IsPlayer()) end
			local tr = TraceLine(TraceConfig)

			debugoverlay.Line(wp1, tr.HitPos, 1, Green, true)
			debugoverlay.Line(tr.HitPos, wp2, 1, Red, true)

			-- Additional Randomized check just in case
			local tr2
			if not tr.Hit then
				local rb = Vector(0, self.BreechWidth or 0, self.BreechHeight or 0) / 2 * VectorRand()
				local rp1 = p1 + rb
				local rp2 = p2 + rb
				local wrp1, wrp2 = self:LocalToWorld(rp1), self:LocalToWorld(rp2)

				TraceConfig.start = wrp1
				TraceConfig.endpos = wrp2
				local tr2 = TraceLine(TraceConfig)

				debugoverlay.Line(wrp1, tr2.HitPos, 1, Green, true)
				debugoverlay.Line(tr2.HitPos, wrp2, 1, Red, true)
			end

			local IsBlocked = (tr.Hit or (tr2 and tr2.Hit))
			self.OverlayErrors.BreechCheck = IsBlocked and "Not enough space behind breech!\nHover with ACF menu tool" or nil
			self:UpdateOverlay()
			if IsBlocked then return 0.000001 end
		end

		return self.LoadCrewMod
	end

	--- Finds the turret ring or baseplate from a gun
	function ENT:FindPropagator()
		local Temp = self:GetParent()
		if IsValid(Temp) and Temp:GetClass() == "acf_turret" and Temp.Turret == "Turret-V" then Temp = Temp:GetParent() end
		if IsValid(Temp) and Temp:GetClass() == "acf_turret" and Temp.Turret == "Turret-H" then return Temp end
		if IsValid(Temp) and Temp:GetClass() == "acf_baseplate" then return Temp end
		return nil
	end

	function ENT:UpdateAccuracyMod(Config)
		local Propagator = self:FindPropagator(Config)
		local Val = Propagator and Propagator.AccuracyCrewMod or 0

		self.AccuracyCrewMod = math.Clamp(Val, ACF.CrewFallbackCoef, 1)
		return self.AccuracyCrewMod
	end
end

do -- Spawn and Update functions --------------------------------
	local WireIO    = Utilities.WireIO
	local Entities  = Classes.Entities
	local Weapons   = Classes.Weapons

	local Inputs = {
		"Fire (Attempts to fire the weapon.)",
		"Unload (Forces the weapon to empty itself)",
		"Reload (Forces the weapon to reload itself.)"
	}
	local Outputs = {
		"Ready (Returns 1 if the weapon can be fired.)",
		"Status (Returns the current state of the weapon.) [STRING]",
		"Ammo Type (Returns the name of the currently loaded ammo type.) [STRING]",
		"Shots Left (Returns the amount of rounds left in the breech or magazine.)",
		"Total Ammo (Returns the amount of rounds available for this weapon.)",
		"Rate of Fire (Returns the amount of rounds per minute the weapon can fire.)",
		"Reload Time (Returns the amount of time in seconds it'll take to reload the weapon.)",
		"Mag Reload Time (Returns the amount of time in seconds it'll take to reload the magazine.)",
		"Projectile Mass (Returns the mass in grams of the currently loaded projectile.)",
		"Muzzle Velocity (Returns the speed in m/s of the currently loaded projectile.)",
		"Entity (The weapon itself.) [ENTITY]",
	}

	local function VerifyData(Data)
		if not isstring(Data.Weapon) then
			Data.Weapon = Data.Id
		end

		local Class = Classes.GetGroup(Weapons, Data.Weapon)

		if not Class then
			Class = Weapons.Get("C")

			Data.Destiny = "Weapons"
			Data.Weapon  = "C"
			Data.Caliber = 50
		elseif Weapons.IsAlias(Data.Weapon) then
			Data.Weapon = Class.ID
		end

		-- Verifying and clamping caliber value
		if Class.IsScalable then
			local Weapon = Weapons.GetItem(Class.ID, Data.Weapon)

			if Weapon then
				Data.Weapon  = Class.ID
				Data.Caliber = Weapon.Caliber
			end

			local Bounds  = Class.Caliber
			local Caliber = ACF.CheckNumber(Data.Caliber, Bounds.Base)

			Data.Caliber = math.Clamp(Caliber, Bounds.Min, Bounds.Max)
		end

		-- For breech locations
		if not Data.BreechIndex then
			Data.BreechIndex = 1
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			hook.Run("ACF_OnVerifyData", "acf_gun", Data, Class)
		end
	end

	-- self.ParentState is one of three values:
	-- 0:  Unparented
	-- -1: Invalid parent chain
	-- 1:  Valid parent chain

	function ENT:DetermineParentState()
		local EntTable = self:GetTable()
		if EntTable.ParentStateValid then return end

		if not IsValid(self:GetParent()) then
			self.ParentState = 0
		elseif not ACF.CheckParentChain(self, {acf_turret = true, acf_turret_rotator = true}, "acf_baseplate") then
			self.ParentState = -1
		else
			self.ParentState = 1
		end
	end

	hook.Add("cfw.family.added", "ACF_Gun_FamilyChecks", function(Family, Ent)
		if not IsValid(Ent) then return end -- CFW issue?

		if Ent:GetClass() == "acf_gun" then
			if Family.Guns then
				Family.Guns[Ent] = true
			else
				Family.Guns = {[Ent] = true}
			end

			Family.HasGuns = true
		end

		if Family.HasGuns then
			for Gun in pairs(Family.Guns) do
				if IsValid(Gun) then Gun:DetermineParentState() end
			end
		end
	end)

	hook.Add("cfw.family.subbed", "ACF_Gun_FamilyChecks", function(Family, Ent)
		if not IsValid(Ent) then return end -- CFW issue?

		if Ent:GetClass() == "acf_gun" then
			if Family.Guns then
				Family.Guns[Ent] = nil
			end

			Family.HasGuns = next(Family.Guns) and true or nil
			Ent:DetermineParentState()
		end

		if Family.HasGuns then
			for Gun in pairs(Family.Guns) do
				if IsValid(Gun) then Gun:DetermineParentState() end
			end
		end
	end)

	local function GetSound(Caliber, Class, Weapon)
		local Result = Weapon and Weapon.Sound or Class.Sound
		local ClassSounds = Class.Sounds

		if ClassSounds then
			local Lowest = math.huge

			for Current, Sound in pairs(ClassSounds) do
				if Caliber <= Current and Current <= Lowest then
					Lowest = Current
					Result = Sound
				end
			end
		end

		return Result
	end

	local function GetMass(Caliber, Class, Weapon)
		if Weapon then return Weapon.Mass end

		local Factor = Caliber / Class.Caliber.Base

		return math.Round(Class.Mass * Factor ^ 3) -- 3d space so scaling has a cubing effect
	end

	local function UpdateWeapon(Entity, Data, Class, Weapon)
		local Model   = Weapon and Weapon.Model or Class.Model
		local Caliber = Weapon and Weapon.Caliber or Data.Caliber
		local Scale   = Weapon and 1 or (Caliber / Class.Caliber.Base * (Class.ScaleFactor or 1)) -- Set scale to 1 if Weapon exists (non scaled lmao), or relative caliber otherwise
		local Cyclic  = ACF.GetWeaponValue("Cyclic", Caliber, Class, Weapon)
		local MagSize = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon) or 1

		Entity.ACF.Model = Model

		Entity:SetScaledModel(Model)
		Entity:SetScale(Scale)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name         = Weapon and Weapon.Name or (Caliber .. "mm " .. Class.Name)
		Entity.ShortName    = Weapon and Weapon.ID or (Caliber .. "mm" .. Class.ID)
		Entity.EntType      = Class.Name
		Entity.ClassData    = Class
		Entity.Class        = Class.ID -- Needed for custom killicons
		Entity.WeaponData	= Data.WeaponData
		Entity.Caliber      = Caliber
		Entity.MagReload    = ACF.GetWeaponValue("MagReload", Caliber, Class, Weapon)
		Entity.MagSize      = math.floor(MagSize)
		Entity.BaseCyclic   = Cyclic and Cyclic
		Entity.Cyclic       = Entity.BaseCyclic
		Entity.ReloadTime   = Entity.Cyclic and 60 / Entity.Cyclic or 1
		Entity.Spread       = Class.Spread
		Entity.DefaultSound = GetSound(Caliber, Class)
		Entity.SoundPath    = Entity.SoundPath or Entity.DefaultSound
		Entity.SoundPitch   = Entity.SoundPitch or 1
		Entity.SoundVolume  = Entity.SoundVolume or 1
		Entity.HitBoxes     = ACF.GetHitboxes(Model, Scale)
		Entity.Long         = Class.LongBarrel
		Entity.NormalMuzzle = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("muzzle")).Pos)
		Entity.Muzzle       = Entity.NormalMuzzle

		-- Breech information
		Entity.BreechIndex  = Data.BreechIndex or 1
		local BreechConfigs = Entity.ClassData.BreechConfigs
		if BreechConfigs then
			-- If a custom breech config is specified, use it
			local BreechScale = (Caliber / 10) / BreechConfigs.MeasuredCaliber
			local BreechConfig = BreechConfigs.Locations[Entity.BreechIndex] or {}
			Entity.BreechPos = BreechConfig.LPos * BreechScale
			Entity.BreechAng = BreechConfig.LAng
			Entity.BreechWidth = BreechConfig.Width * BreechScale
			Entity.BreechHeight = BreechConfig.Height * BreechScale
		else
			-- If no custom breech config is specified, use the rear of the model
			Entity.BreechPos = Vector(Entity:OBBMins().x, 0, 0)
			Entity.BreechAng = Angle(0, 0, 0)
			Entity.BreechWidth = 0
			Entity.BreechHeight = 0
		end

		Entity.OverlayErrors = {}

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Weapon)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Weapon)

		-- Set NWvars
		Entity:SetNWString("WireName", "ACF " .. Entity.Name)
		Entity:SetNWString("Sound", Entity.SoundPath)
		Entity:SetNWFloat("SoundPitch", Entity.SoundPitch)
		Entity:SetNWFloat("SoundVolume", Entity.SoundVolume)
		Entity:SetNWString("ACF_Class", Entity.Class)

		-- Adjustable barrel length
		if Entity.Long then
			local Attachment = Entity:GetAttachment(Entity:LookupAttachment(Entity.Long.NewPos))

			Entity.LongMuzzle = Attachment and Entity:WorldToLocal(Attachment.Pos)
		end

		Entity:CanProperty(nil, "bodygroups")

		if Entity.Cyclic then -- Automatics don't change their rate of fire
			WireLib.TriggerOutput(Entity, "Reload Time", 60 / Entity.Cyclic)
			WireLib.TriggerOutput(Entity, "Rate of Fire", Entity.Cyclic)
			WireLib.TriggerOutput(Entity, "Mag Reload Time", Entity.MagReload)
		end

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj

		if IsValid(PhysObj) then
			local Mass = GetMass(Caliber, Class, Weapon)

			Contraption.SetMass(Entity, Mass)
		end
	end

	hook.Add("ACF_OnSetupInputs", "ACF Weapon Fuze", function(Entity, List)
		if Entity:GetClass() ~= "acf_gun" then return end
		if Entity.Caliber <= ACF.MinFuzeCaliber then return end

		List[#List + 1] = "Fuze (Sets the delay in seconds in which explosive rounds will detonate after leaving the weapon.)"
	end)

	hook.Add("ACF_OnSetupInputs", "ACF Cyclic ROF", function(Entity, List)
		if Entity:GetClass() ~= "acf_gun" then return end
		if not Entity.BaseCyclic then return end

		List[#List + 1] = "Rate of Fire (Sets the rate of fire of the weapon in rounds per minute)"
	end)

	-------------------------------------------------------------------------------

	function ACF.MakeWeapon(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Weapons, Data.Weapon)
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end -- Check gun spawn limits

		local Weapon   = Weapons.GetItem(Class.ID, Data.Weapon)
		local CanSpawn = hook.Run("ACF_PreSpawnEntity", "acf_gun", Player, Data, Class, Weapon)

		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_gun")

		if not IsValid(Entity) then return end

		Player:AddCleanup(Class.Cleanup, Entity)
		Player:AddCount(Limit, Entity)

		Entity.ACF			= {}

		Contraption.SetModel(Entity, Weapon and Weapon.Model or Class.Model)

		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.BarrelFilter = { Entity }
		Entity.State        = "Empty"
		Entity.Crates       = {}
		Entity.CurrentShot  = 0
		Entity.TotalAmmo    = 0
		Entity.BulletData   = EMPTY
		Entity.TurretLink	= false
		Entity.HasInitialLoaded = false
		Entity.DataStore    = Entities.GetArguments("acf_gun")
		Entity.ParentState = 0

		duplicator.ClearEntityModifier(Entity, "mass")

		UpdateWeapon(Entity, Data, Class, Weapon)

		WireLib.TriggerOutput(Entity, "Status", "Empty")
		WireLib.TriggerOutput(Entity, "Ammo Type", "Empty")
		WireLib.TriggerOutput(Entity, "Projectile Mass", 1000)
		WireLib.TriggerOutput(Entity, "Muzzle Velocity", 1000)

		if Class.OnSpawn then
			Class.OnSpawn(Entity, Data, Class, Weapon)
		end

		ACF.AugmentedTimer(function(Config) Entity:UpdateLoadMod(Config) end, function() return IsValid(Entity) end, nil, {MinTime = 0.5, MaxTime = 1})
		ACF.AugmentedTimer(function(Config) Entity:UpdateAccuracyMod(Config) end, function() return IsValid(Entity) end, nil, {MinTime = 0.5, MaxTime = 1})

		hook.Run("ACF_OnSpawnEntity", "acf_gun", Entity, Data, Class, Weapon)

		TimerCreate("ACF Ammo Left " .. Entity:EntIndex(), 1, 0, function()
			if not IsValid(Entity) then return end

			UpdateTotalAmmo(Entity)
		end)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_gun", ACF.MakeWeapon, "Weapon", "Caliber", "BreechIndex")

	ACF.RegisterLinkSource("acf_gun", "Crates")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		if self.Firing then return false, "Stop firing before updating the weapon!" end

		VerifyData(Data)

		local Class    = Classes.GetGroup(Weapons, Data.Weapon)
		local Weapon   = Weapons.GetItem(Class.ID, Data.Weapon)
		local OldClass = self.ClassData

		local CanUpdate, Reason = hook.Run("ACF_PreUpdateEntity", "acf_gun", self, Data, Class, Weapon)

		if CanUpdate == false then return CanUpdate, Reason end

		if self.State ~= "Empty" then
			self:Unload()
		end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		hook.Run("ACF_OnEntityLast", "acf_gun", self, OldClass)

		ACF.SaveEntity(self)

		UpdateWeapon(self, Data, Class, Weapon)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Weapon)
		end

		hook.Run("ACF_OnUpdateEntity", "acf_gun", self, Data, Class, Weapon)

		if next(self.Crates) then
			for Crate in pairs(self.Crates) do
				self:Unlink(Crate)
			end
		end

		if self.Crews and next(self.Crews) then
			for Crew in pairs(self.Crews) do
				self:Unlink(Crew)
			end
		end

		return true, "Weapon updated successfully!"
	end
end ---------------------------------------------

do -- Metamethods --------------------------------
	local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
	local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"

	-- Used to determine if a crate should be unlinked or not
	local function CheckCrate(Gun, Crate, GunPos)
		local CrateUnlinked = false

		if Crate:GetPos():DistToSqr(GunPos) > MaxDistance then
			local Sound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(Crate, Sound, 70, 100, 1)
			Sounds.SendSound(Gun, Sound, 70, 100, 1)

			CrateUnlinked = Gun:Unlink(Crate)
		end

		return CrateUnlinked
	end

	do -- Inputs/Outputs/Linking ----------------
		WireLib.AddOutputAlias("AmmoCount", "Total Ammo")
		WireLib.AddOutputAlias("Muzzle Weight", "Projectile Mass")

		ACF.RegisterClassLink("acf_gun", "acf_ammo", function(This, Crate)
			if This.Crates[Crate] then return false, "This weapon is already linked to this crate." end
			if Crate.Weapons[This] then return false, "This weapon is already linked to this crate." end
			if Crate.IsRefill then return false, "Refill crates cannot be linked to weapons." end
			if This.Weapon ~= Crate.Weapon then return false, "Wrong ammo type for this weapon." end
			if This.Caliber ~= Crate.Caliber then return false, "Wrong ammo type for this weapon." end
			if Crate:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This crate is too far away from this weapon." end

			local Blacklist = Crate.RoundData.Blacklist

			if Blacklist[This.Class] then
				return false, "The ammo type in this crate cannot be used for this weapon."
			end

			This.Crates[Crate]  = true
			Crate.Weapons[This] = true

			This:UpdateOverlay(true)
			Crate:UpdateOverlay(true)

			local function AttemptReload(This, Target, Instant)
				if IsValid(This) and IsValid(Target) and Target:CanConsume() then
					This:Load(Instant)
				end
			end

			if This.State == "Empty" and Crate.AmmoStage == 1 then -- When linked to an empty weapon, attempt to load it
				if This.HasInitialLoaded then
					timer.Simple(1, function()
						AttemptReload(This, Crate)
					end)
				else
					This.HasInitialLoaded = true
					timer.Simple(ACF.InitReloadDelay, function()
						AttemptReload(This, Crate, true)
					end)
				end
				This:SetState("Loading")
			end

			return true, "Weapon linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_gun", "acf_ammo", function(This, Crate)
			if This.Crates[Crate] or Crate.Weapons[This] then
				This.Crates[Crate]  = nil
				Crate.Weapons[This] = nil

				-- Since we removed the references, this should ignore the removed crate.
				if This.CurrentCrate == Crate then
					This.CurrentCrate = This:FindNextCrate(nil, CheckConsumable, This)
					if IsValid(This.CurrentCrate) then This:SetNW2Int("CurCrate", This.CurrentCrate:EntIndex()) end
				end

				This:UpdateOverlay(true)
				Crate:UpdateOverlay(true)

				return true, "Weapon unlinked successfully."
			end

			return false, "This weapon is not linked to this crate."
		end)

		ACF.RegisterClassLink("acf_gun", "acf_turret", function(This, Turret)
			This.TurretLink = true
			This.Turret	= Turret

			return true, "Weapon linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_gun", "acf_turret", function(This, _)
			This.TurretLink	= false
			This.Turret	= nil

			return true, "Weapon unlinked successfully."
		end)

		ACF.AddInputAction("acf_gun", "Fire", function(Entity, Value)
			local Bool = tobool(Value)

			Entity.Firing = Bool

			if Bool and Entity:CanFire() then
				Entity:Shoot()
			end
		end)

		ACF.AddInputAction("acf_gun", "Unload", function(Entity, Value)
			if tobool(Value) and Entity.State == "Loaded" then
				Entity:Unload()
			end
		end)

		ACF.AddInputAction("acf_gun", "Reload", function(Entity, Value)
			if tobool(Value) then
				if Entity.State == "Loaded" then
					Entity:Unload(true) -- Unload, then reload
				elseif Entity.State == "Empty" then
					Entity:Load()
				end
			end
		end)

		ACF.AddInputAction("acf_gun", "Fuze", function(Entity, Value)
			Entity.SetFuze = tobool(Value) and math.abs(Value)
		end)

		ACF.AddInputAction("acf_gun", "Rate of Fire", function(Entity, Value)
			if not Entity.BaseCyclic then return end

			Entity.Cyclic     = math.Clamp(Value, 30, Entity.BaseCyclic)
			Entity.ReloadTime = 60 / Entity.Cyclic
		end)
	end -----------------------------------------

	do -- Shooting ------------------------------
		local Effects   = Utilities.Effects
		local TraceRes  = {} -- Output for traces
		local TraceData = { start = true, endpos = true, filter = true, mask = MASK_SOLID, output = TraceRes }

		function ENT:BarrelCheck()
			local owner  = self:GetPlayer()
			local filter = self.BarrelFilter

			TraceData.start	 = self:GetPos()
			TraceData.endpos = self:LocalToWorld(self.Muzzle)
			TraceData.filter = filter

			ACF.trace(TraceData)

			while TraceRes.HitNonWorld do
				local Entity = TraceRes.Entity

				if Entity.IsACFEntity and not (Entity.IsACFArmor or Entity.IsACFTurret) then break end
				if Entity:CPPIGetOwner() ~= owner then break end

				filter[#filter + 1] = Entity

				ACF.trace(TraceData)
			end

			return TraceRes.HitPos
		end

		function ENT:CanFire()
			if not ACF.GunsCanFire then return false end -- Disabled by the server
			if not self.Firing then return false end -- Nobody is holding the trigger
			if self.Disabled then return false end -- Disabled

			if self.State ~= "Loaded" then -- Weapon is not loaded
				if self.State == "Empty" and not self.Retry then
					if not self:Load() then
						Sounds.SendSound(self, "weapons/pistol/pistol_empty.wav", 70, 100, 1) -- Click!
					end

					self.Retry = true

					timer.Simple(1, function() -- Try again after a second
						if IsValid(self) then
							self.Retry = nil

							if self:CanFire() then
								self:Shoot()
							end
						end
					end)
				end

				return false
			end

			if self.ParentState ~= 1 and ACF.LegalChecks and not ACF.AllowArbitraryParents then
				-- This NEEDS a better message, I can't find a good way to explain it right now
				ACF.DisableEntity(self, "Invalid Parent Chain", "Guns can only be parented to turret entities and must have a baseplate root ancestor.", 5)
				return false
			end

			if self.TurretLink and IsValid(self.Turret) then -- Special link to a turret, will block the gun from firing if the gun is not aligned with the turret's target angle
				local Turret = self.Turret
				if not Turret.Active then return false end

				if self:GetForward():Dot(Turret.SlewFuncs.GetWorldTarget(Turret):Forward()) < 0.9961 then return false end
			end

			local CanFire = hook.Run("ACF_PreFireWeapon", self)

			return CanFire
		end

		function ENT:GetSpread()
			local SpreadScale = ACF.SpreadScale
			local IaccMult    = math.Clamp(((1 - SpreadScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, 1, SpreadScale)

			return self.Spread * ACF.GunInaccuracyScale * IaccMult / (self.AccuracyCrewMod or 1)
		end

		function ENT:Shoot()
			local Cone = math.tan(math.rad(self:GetSpread()))
			local randUnitSquare = (self:GetUp() * (2 * math.random() - 1) + self:GetRight() * (2 * math.random() - 1))
			local Spread = randUnitSquare:GetNormalized() * Cone * (math.random() ^ (1 / ACF.GunInaccuracyBias))
			local Dir = (self:GetForward() + Spread):GetNormalized()
			local Velocity = self:GetAncestor():GetVelocity()
			local BulletData = self.BulletData
			local AmmoType = AmmoTypes.Get(BulletData.Type)

			if BulletData.CanFuze and self.SetFuze then
				local Variance = math.Rand(-0.015, 0.015) * math.max(0, 203 - self.Caliber) * 0.01

				self.Fuze = math.max(self.SetFuze, 0.02) + Variance -- If possible, we're gonna update the fuze time
			else
				self.Fuze = nil
			end

			self.CurrentUser = self:GetUser(self.Inputs.Fire.Src) -- Must be updated on every shot

			BulletData.Owner  = self.CurrentUser
			BulletData.Gun	   = self -- because other guns share this table
			BulletData.Pos    = self:BarrelCheck()
			BulletData.Flight = Dir * BulletData.MuzzleVel * ACF.MeterToInch + Velocity
			BulletData.Fuze   = self.Fuze -- Must be set when firing as the table is shared
			BulletData.Filter = self.BarrelFilter

			AmmoType:Create(self, BulletData) -- Spawn projectile

			self:MuzzleEffect()
			self:Recoil()

			local Energy = ACF.Kinetic(BulletData.MuzzleVel * ACF.MeterToInch, BulletData.ProjMass).Kinetic

			if Energy > 50 then -- Why yes, this is completely arbitrary! 20mm AC AP puts out about 115, 40mm GL HE puts out about 20
				ACF.Overpressure(self:LocalToWorld(self.Muzzle) - self:GetForward() * 5, Energy, BulletData.Owner, self, self:GetForward(), 30)
			end

			if self.MagSize then -- Mag-fed/Automatically loaded
				self.CurrentShot = self.CurrentShot - 1

				if self.CurrentShot > 0 then -- Not empty
					self:Chamber()
				else -- Reload the magazine
					self:Load()
				end
			else -- Single-shot/Manually loaded
				self.CurrentShot = 0 -- We only have one shot, so shooting means we're at 0
				self:Chamber()
			end
		end

		function ENT:MuzzleEffect()
			if not ACF.GunsCanSmoke then return end

			local EffectTable = {
				Entity    = self,
				Scale     = self.BulletData.PropMass,
				Magnitude = self.ReloadTime,
			}

			Effects.CreateEffect("ACF_Muzzle_Flash", EffectTable, true, true)
		end

		function ENT:ReloadEffect(Time)
			local EffectTable = {
				Entity = self,
				Scale = 0,
				Magnitude = Time,
			}

			Effects.CreateEffect("ACF_Muzzle_Flash", EffectTable, true, true)
		end

		function ENT:Recoil()
			if not ACF.RecoilPush then return end

			local MassCenter = self:LocalToWorld(self:GetPhysicsObject():GetMassCenter())
			local BulletData = self.BulletData
			local Energy = BulletData.ProjMass * BulletData.MuzzleVel * ACF.MeterToInch + BulletData.PropMass * 3000 * ACF.MeterToInch

			ACF.KEShove(self, MassCenter, -self:GetForward(), Energy)
		end
	end -----------------------------------------

	do -- Loading -------------------------------
		--- Finds the next crate
		--- @param Current any Optionally specified current crate to check against (optimization measure)
		--- @param Check any Function used to check if a crate meets our criteria
		--- @param ... unknown Varargs passed to the check function after the crew entity
		--- @return any # The next crate that matches the check function or nil if none are found
		function ENT:FindNextCrate(Current, Check, ...)
			if not next(self.Crates) then return end

			-- If the current crate is still satisfactory, why bother searching?
			if Current and Check(Current, ...) then return Current end

			-- Search crates by their stage level
			local Crate = ACF.FindCrateByStage(self:GetContraption(), ACF.AmmoStageMin, Check, ...)

			-- This is not performant... but people may be unhappy if I don't do this
			if not Crate then
				for k in pairs(self.Crates) do
					if Check(k, ...) then
						Crate = k
						break
					end
				end
			end

			return Crate
		end

		function ENT:Unload(Reload)
			if self.Disabled then return end
			if self.State == "Unloading" then return end -- Don't unload while unloading
			if self.BulletData == EMPTY then return end -- If it's empty, we're already unloading, or something went wrong
			self.FreeCrate = self:FindNextCrate(self.FreeCrate, CheckUnloadable, self)
			if IsValid(self.FreeCrate) then self.FreeCrate:Consume(-1) end -- Put a shell back in the crate, if possible

			local IdealTime, Manual = ACF.CalcReloadTimeMag(self.Caliber, self.ClassData, self.WeaponData, self.BulletData, self)
			local Time = Manual and IdealTime / self.LoadCrewMod or IdealTime

			self:ReloadEffect(Reload and Time * 2 or Time)
			self:SetState("Unloading")
			Sounds.SendSound(self, "weapons/357/357_reload4.wav", 70, 100, 1)
			self.CurrentShot = 0
			self.BulletData  = EMPTY

			WireLib.TriggerOutput(self, "Ammo Type", "Empty")
			WireLib.TriggerOutput(self, "Shots Left", 0)

			ACF.ProgressTimer(
				self,
				function()
					return self:UpdateLoadMod()
				end,
				function()
					if IsValid(self) then
						if Reload then
							self:Load()
						else
							self:SetState("Empty")
						end
					end
				end,
				{MinTime = 1.0,	MaxTime = 3.0, Progress = 0, Goal = IdealTime}
			)
		end

		function ENT:Chamber(Instant)
			if self.Disabled then return end
			if self.State == "Unloading" then return end -- Don't chamber while unloading

			local Crate = self:FindNextCrate(self.CurrentCrate, CheckConsumable, self)

			if IsValid(Crate) and not CheckCrate(self, Crate, self:GetPos()) then -- Have a crate, start loading
				self:SetState("Loading") -- Set our state to loading
				Crate:Consume() -- Take one round of ammo out of the current crate (Must be called *after* setting the state to loading)

				self.CurrentCrate = Crate
				self:SetNW2Int("CurCrate", self.CurrentCrate:EntIndex())

				local BulletData = Crate.BulletData
				local IdealTime, Manual = ACF.CalcReloadTime(self.Caliber, self.ClassData, self.WeaponData, BulletData, self)
				local Time = Manual and IdealTime / self.LoadCrewMod or IdealTime

				self.ReloadTime   = Time
				self.BulletData   = BulletData
				self.NextFire 	  = Clock.CurTime + Time

				WireLib.TriggerOutput(self, "Ammo Type", BulletData.Type)
				WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

				self:SetNW2Int("Length", self.BulletData.PropLength + self.BulletData.ProjLength)
				self:SetNW2Float("Caliber", self.BulletData.Caliber)
				self:SetNW2Int("BreechIndex", self.BreechIndex or 1)

				local ReloadLoop = function()
					local eff = Manual and self:UpdateLoadMod() or 1
					if Manual then -- Automatics don't change their rate of fire
						WireLib.TriggerOutput(self, "Reload Time", IdealTime / eff)
						WireLib.TriggerOutput(self, "Rate of Fire", 60 / (IdealTime / eff))
						self.ReloadTime = IdealTime / eff
					end
					return eff
				end

				local ReloadFinish = function()
					if IsValid(self) and self.BulletData then
						if self.State == "Unloading" then return end -- Don't chamber while unloading
						if self.CurrentShot == 0 then
							self.CurrentShot = math.min(self.MagSize or 1, self.TotalAmmo)
						end

						self.NextFire = nil

						WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)
						WireLib.TriggerOutput(self, "Projectile Mass", math.Round((self.BulletData.ProjMass or 0) * 1000, 2))
						WireLib.TriggerOutput(self, "Muzzle Velocity", math.Round((self.BulletData.MuzzleVel or 0) * ACF.Scale, 2))

						self:SetState("Loaded")

						if self:CanFire() then self:Shoot() end
					end
				end

				if Instant then
					ReloadLoop()
					ReloadFinish()
					return true
				end

				ACF.ProgressTimer(
					self, ReloadLoop, ReloadFinish, {MinTime = 1.0,	MaxTime = 3.0, Progress = 0, Goal = IdealTime}
				)
			else -- No available crate to pull ammo from, out of ammo!
				self:SetState("Empty")

				self.CurrentShot = 0
				self.BulletData  = EMPTY

				WireLib.TriggerOutput(self, "Ammo Type", "Empty")
				WireLib.TriggerOutput(self, "Shots Left", 0)
			end
		end

		function ENT:Load(Instant)
			if self.Disabled then return false end

			local Crate = self:FindNextCrate(self.CurrentCrate, CheckConsumable, self)

			if not IsValid(Crate) or CheckCrate(self, Crate, self:GetPos()) then -- Can't load without having ammo being provided
				self:SetState("Empty")

				self.CurrentShot = 0
				self.BulletData  = EMPTY

				WireLib.TriggerOutput(self, "Ammo Type", "Empty")
				WireLib.TriggerOutput(self, "Shots Left", 0)

				return false
			end

			self.BulletData = Crate.BulletData

			self.CurrentCrate = Crate
			self:SetNW2Int("Length", self.BulletData.PropLength + self.BulletData.ProjLength)
			self:SetNW2Int("Caliber", self.BulletData.Caliber)
			self:SetNW2Int("BreechIndex", self.BreechIndex or 1)

			self:SetState("Loading")

			if self.MagReload then -- Mag-fed/Automatically loaded
				-- Dynamically adjust magazine size for beltfeds to fit the crate's capacity
				if Crate.IsBelted then
					self.MagSize = Crate.Ammo
				end

				Sounds.SendSound(self, "weapons/357/357_reload4.wav", 70, 100, 1)

				WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

				local IdealTime, Manual = ACF.CalcReloadTimeMag(self.Caliber, self.ClassData, self.WeaponData, self.BulletData)
				local Time = Manual and IdealTime / self.LoadCrewMod or IdealTime

				self.NextFire = Clock.CurTime + Time

				local ReloadLoop = function()
					local eff = self:UpdateLoadMod()
					if Manual then WireLib.TriggerOutput(self, "Mag Reload Time", IdealTime / eff) end
					self.MagReload = IdealTime / eff
					return eff
				end

				local ReloadFinish = function()
					if IsValid(self) then self:Chamber() end
				end

				if Instant then
					ReloadLoop()
					ReloadFinish()
					return true
				end

				ACF.ProgressTimer(
					self, ReloadLoop, ReloadFinish, {MinTime = 1.0,	MaxTime = 3.0, Progress = 0, Goal = IdealTime}
				)
			else -- Single-shot/Manually loaded
				self:Chamber(Instant)
			end

			return true
		end
	end -----------------------------------------

	do -- Duplicator Support --------------------
		function ENT:PreEntityCopy()
			if next(self.Crates) then
				local Entities = {}

				for Crate in pairs(self.Crates) do
					Entities[#Entities + 1] = Crate:EntIndex()
				end

				duplicator.StoreEntityModifier(self, "ACFCrates", Entities)
			end

			if IsValid(self.Turret) then
				duplicator.StoreEntityModifier(self, "ACFTurret", {self.Turret:EntIndex()})
			end

			-- Wire dupe info
			self.BaseClass.PreEntityCopy(self)
		end

		function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
			local EntMods = Ent.EntityMods

			-- Backwards compatibility
			if EntMods.ACFAmmoLink then
				local Entities = EntMods.ACFAmmoLink.entities

				for _, EntID in ipairs(Entities) do
					self:Link(CreatedEntities[EntID])
				end

				EntMods.ACFAmmoLink = nil
			end

			if EntMods.ACFCrates then
				for _, EntID in pairs(EntMods.ACFCrates) do
					self:Link(CreatedEntities[EntID])
				end

				EntMods.ACFCrates = nil
			end

			if EntMods.ACFTurret and next(EntMods.ACFTurret) then
				self:Link(CreatedEntities[EntMods.ACFTurret[1]])
			end

			self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		end
	end -----------------------------------------

	do -- Overlay -------------------------------
		local Text = "%s\n\nRate of Fire: %s rpm\nShots Left: %s\nAmmo Available: %s\nLoading Location: %s"

		function ENT:UpdateOverlayText()
			local AmmoType  = self.BulletData.Type .. (self.BulletData.Tracer ~= 0 and "-T" or "")
			local Firerate  = math.floor(60 / self.ReloadTime)
			local CrateAmmo = 0
			local Status

			if not next(self.Crates) then
				Status = "Not linked to an ammo crate!"
			else
				Status = self.State == "Loaded" and "Loaded with " .. AmmoType or self.State
			end

			local ErrorCount = table.Count(self.OverlayErrors)
			if ErrorCount > 0 then
				Status = Status .. " (" .. ErrorCount .. " errors)"
			end

			-- Compile error messages
			for _, Error in pairs(self.OverlayErrors) do
				Status = Status .. "\n\n" .. Error
			end

			for Crate in pairs(self.Crates) do -- Tally up the amount of ammo being provided by active crates
				if Crate:CanConsume() then
					CrateAmmo = CrateAmmo + Crate.Ammo
				end
			end

			local BreechIndex = self.BreechIndex or 1
			local BreechName = self.ClassData.BreechConfigs and self.ClassData.BreechConfigs.Locations[BreechIndex].Name or "N/A"
			return Text:format(Status, Firerate, self.CurrentShot, CrateAmmo, BreechName)
		end
	end -----------------------------------------

	do	-- Other networking
		util.AddNetworkString("ACF.RequestGunInfo")
		net.Receive("ACF.RequestGunInfo", function(_, Ply)
			local Gun = net.ReadEntity()
			if not IsValid(Gun) then return end

			local AmmoCrates = {}

			if next(Gun.Crates) then
				for Crate in pairs(Gun.Crates) do
					AmmoCrates[#AmmoCrates + 1] = Crate:EntIndex()
				end
			end

			net.Start("ACF.RequestGunInfo")
				net.WriteEntity(Gun)
				net.WriteString(util.TableToJSON(AmmoCrates))
			net.Send(Ply)
		end)
	end

	do -- Misc ----------------------------------
		function ENT:ACF_Activate(Recalc)
			local PhysObj = self.ACF.PhysObj
			local Area    = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
			local Armour  = self.Caliber * ACF.ArmorMod
			local Health  = Area / ACF.Threshold
			local Percent = 1

			if Recalc and self.ACF.Health and self.ACF.MaxHealth then
				Percent = self.ACF.Health / self.ACF.MaxHealth
			end

			self.ACF.Area      = Area
			self.ACF.Health    = Health * Percent
			self.ACF.MaxHealth = Health
			self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
			self.ACF.MaxArmour = Armour
			self.ACF.Type      = "Prop"
		end

		function ENT:SetState(State)
			self.State = State

			self:UpdateOverlay()

			WireLib.TriggerOutput(self, "Status", State)
			WireLib.TriggerOutput(self, "Ready", State == "Loaded" and 1 or 0)

			UpdateTotalAmmo(self)
		end

		function ENT:Think()
			local Crates = self.Crates

			if next(Crates) then
				local Pos = self:GetPos()

				for Crate in pairs(Crates) do
					CheckCrate(self, Crate, Pos)
				end
			end

			-- for each crate in the first stage, if it's restockable, restock it
			self.FirstStage = ACF.FindFirstStage(self:GetContraption())
			for v, _ in pairs(self.FirstStage) do
				if CheckRestockable(v, self) then
					v:Restock()
				end
			end

			self:NextThink(Clock.CurTime + 0.5 + math.random())

			return true
		end

		function ENT:Enable()
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Firing   = false -- Stop firing

			self:Unload() -- Unload the gun for being a big baddie
			self:UpdateOverlay()
		end

		function ENT:CanProperty(_, Property)
			if self.Long and Property == "bodygroups" then
				timer.Simple(0, function()
					if not IsValid(self) then return end

					local Long = self.Long
					local IsLong = self:GetBodygroup(Long.Index) == Long.Submodel

					self.Muzzle = IsLong and self.LongMuzzle or self.NormalMuzzle
				end)
			end

			return true
		end

		function ENT:OnRemove()
			local Class = self.ClassData

			if Class.OnLast then
				Class.OnLast(self, Class)
			end

			hook.Run("ACF_OnEntityLast", "acf_gun", self, Class)

			for Crate in pairs(self.Crates) do
				self:Unlink(Crate)
			end

			if self.Crews and next(self.Crews) then
				for Crew in pairs(self.Crews) do
					if IsValid(Crew) then self:Unlink(Crew) end
				end
			end

			timer.Remove("ACF Ammo Left " .. self:EntIndex())

			WireLib.Remove(self)
		end
	end -----------------------------------------
end
