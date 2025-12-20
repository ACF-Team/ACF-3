--[[
This defines the major serverside logic for the controller entity.

Supported Drivetrains:
- Must have a single "main" gearbox that does the heavy lifting, e.g. a CVT transax.


]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

include("modules/drivetrain.lua")

-- Localizations
local ACF = ACF
local HookRun     = hook.Run
local Utilities   = ACF.Utilities
local WireIO      = Utilities.WireIO
local Contraption = ACF.Contraption
local hook	   = hook
local Classes	= ACF.Classes
local Entities   = Classes.Entities
local MaxDistance  = ACF.LinkDistance * ACF.LinkDistance

local TraceLine = util.TraceLine

util.AddNetworkString("ACF_Controller_Links")	-- Relay links to client
util.AddNetworkString("ACF_Controller_Active")	-- Relay active state to client
util.AddNetworkString("ACF_Controller_CamInfo")	-- Relay entities and camera modes
util.AddNetworkString("ACF_Controller_CamData")	-- Relay camera updates
util.AddNetworkString("ACF_Controller_Zoom")	-- Relay camera zooms
util.AddNetworkString("ACF_Controller_Ammo")	-- Relay ammo counts
util.AddNetworkString("ACF_Controller_Receivers")	-- Relay LWS/RWS data

-- https://wiki.facepunch.com/gmod/Enums/IN
local IN_ENUM_TO_WIRE_OUTPUT = {
	[IN_FORWARD] = "W",
	[IN_MOVELEFT] = "A",
	[IN_BACK] = "S",
	[IN_MOVERIGHT] = "D",
	[IN_ATTACK] = "Mouse1",
	[IN_ATTACK2] = "Mouse2",

	[IN_RELOAD] = "R",
	[IN_JUMP] = "Space",
	[IN_SPEED] = "Shift",
	[IN_ZOOM] = "Zoom",
	[IN_WALK] = "Alt",
	[IN_DUCK] = "Duck",
}

-- Values default to zero anyways so only specify nonzero here
local Defaults = {
	ZoomSpeed = 10,
	ZoomMin = 5,
	ZoomMax = 90,
	SlewMin = 1,
	SlewMax = 1,

	CamCount = 2,
	Cam1Offset = Vector(0, 0, 150),
	Cam1Orbit = 300,
	Cam2Offset = Vector(0, 0, 150),
	Cam2Orbit = 0,
	Cam3Offset = Vector(0, 0, 0),
	Cam3Orbit = 0,

	HUDType = 1,
	HUDScale = 1,
	HUDColor = Vector(1, 0.5, 0),

	BrakeStrength = 300,
	SpeedTop = 60,

	ShiftTime = 100,
}

local Clock = Utilities.Clock

--- Sets a wire output if the cached value has changed
local function RecacheBindOutput(Entity, SelfTbl, Output, Value)
	if SelfTbl.Outputs[Output].Value == Value then return end
	WireLib.TriggerOutput(Entity, Output, Value)
end

local function RecacheBindState(SelfTbl, Key, Value)
	if SelfTbl.KeyStates[Key] == Value then return end
	SelfTbl.KeyStates[Key] = Value
end

local function GetKeyState(SelfTbl, Key)
	return SelfTbl.KeyStates[Key] or false
end

--- Sets a networked variable if the cached value has changed
local function RecacheBindNW(Entity, SelfTbl, Key, Value, SetNWFunc)
	SelfTbl.CacheNW = SelfTbl.CacheNW or {}
	if SelfTbl.CacheNW[Key] == Value then return end
	SelfTbl.CacheNW[Key] = Value
	SetNWFunc(Entity, Key, Value)
end

do
	local Inputs = {
		"Filter (Filters out entities from the camera trace) [ENTITY]",
	}

	local Outputs = {
		"W", "A", "S", "D", "Mouse1", "Mouse2",
		"R", "Space", "Shift", "Zoom", "Alt", "Duck",
		"HitPos (The position the driver is looking at) [VECTOR]",
		"CamAng (The direction of the camera.) [ANGLE]",
		"IsTurretLocked (Whether the turret is locked or not.)",
		"Active",
		"Speed (Determined by selected unit)",
		"Driver (The player driving the vehicle.) [ENTITY]",
		"Entity (The controller entity itself) [ENTITY]",
	}

	local function VerifyData(Data)
		if Data.AIOUseDefaults then
			Data.AIODefaults = Defaults
		end
	end

	local function UpdateController(Entity, Data)
		-- Update model info and physics
		-- TODO: May need to change this depending on the dproperty stuff
		Entity.ACF = Entity.ACF or {}
		Entity.ACF.Model = "models/hunter/plates/plate025x025.mdl"
		Entity:SetModel("models/hunter/plates/plate025x025.mdl")

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		for _, V in ipairs(Entity.DataStore) do Entity[V] = Data[V] end

		Entity:SetNWString("WireName", "ACF All In One Controller") -- Set overlay wire entity name

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj
		if IsValid(PhysObj) then Contraption.SetMass(Entity, 1) end
	end

	function ACF.MakeController(Player, Pos, Ang, Data)
		VerifyData(Data)

		-- Creating the entity
		local CanSpawn	= HookRun("ACF_PreSpawnEntity", "acf_controller", Player, Data)
		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_controller")
		if not IsValid(Entity) then return end

		Entity:SetPlayer(Player)
		Entity:SetAngles(Ang)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.Name = "ACF AIO Controller"
		Entity.ShortName = "ACF AIO Controller"
		Entity.EntType = "ACF AIO Controller"

		-- Determined from links
		Entity.Seat = nil					-- The single seat
		Entity.Gearbox = nil				-- Main gearbox of the vehicle
		Entity.Turrets = {}					-- Turrets, both horizontal and vertical
		Entity.Guns = {}					-- All guns
		Entity.Racks = {}					-- All racks
		Entity.Baseplate = nil				-- The baseplate of the vehicle
		Entity.SteerPlates = {}				-- Steering plates, if any
		Entity.GuidanceComputer = nil		-- The guidance computer, if any
		Entity.TurretComputer = nil			-- The turret computer, if any
		Entity.Receivers = {}				-- LWR/RWRs

		-- Determined automatically
		Entity.Driver = nil					-- The player driving the vehicle
		Entity.GunsPrimary = {}				-- Primary guns (Main gun, cannon, etc)
		Entity.GunsSecondary = {}			-- Secondary guns (Machine guns, etc)
		Entity.GunsSmoke = {}				-- Smoke and flare launchers
		Entity.GearboxEnds = {}				-- Gearboxes connected to a wheel
		Entity.GearboxIntermediates = {}	-- Or otherwise
		Entity.Wheels = {}					-- Wheels
		Entity.Engines = {}					-- Engines
		Entity.Fuels = {}					-- Fuel tanks
		Entity.SteerPlatesSorted = {}		-- Steer plates sorted by their position
		Entity.SteerPhysicsObjects = {}		-- Steering physics objects

		Entity.LeftGearboxes = {}			-- Gearboxes connected to the left drive wheel
		Entity.RightGearboxes = {}			-- Gearboxes connected to the right drive wheel
		Entity.LeftWheels = {}				-- Wheels connected to the left drive wheel
		Entity.RightWheels = {}				-- Wheels connected to the right drive wheel

		Entity.GearboxLeft = nil			-- A Gearbox connected to the left drive wheel
		Entity.GearboxRight = nil			-- A Gearbox connected to the right drive wheel
		Entity.GearboxLeftDir = nil			-- Direction of that left gearbox's output
		Entity.GearboxRightDir = nil		-- Direction of that right gearbox's output

		Entity.ControllerWelds = {}			-- Keep track of the welds we created

		Entity.PrimaryAmmoCountsByType = {}

		-- State and meta variables
		Entity.TurretLocked = false			-- Whether the turret is locked or not
		Entity.LargestCaliber = 0			-- Largest caliber gun of the vehicle
		Entity.FuelCapacity = 0				-- Total fuel capacity of the vehicle
		Entity.Active = false				-- Whether the controller is active or not

		Entity.CamMode = 0					-- Camera mode (from client)
		Entity.CamAng = Angle(0, 0, 0)		-- Camera angle (from client)
		Entity.CamOffset = Vector() 		-- Camera offset (from client)
		Entity.CamOrbit = 0					-- Camera orbit (from client)

		Entity.KeyStates = {} 				-- Key states for the driver

		Entity.SteerAngles = {} 			-- Steering angles for the wheels

		Entity.ReceiverDirections = {}			-- LWS/RWS receiver angles
		Entity.ReceiverDetecteds = {}			-- LWS/RWS receiver detected states

		Entity.Speed = 0

		Entity.Primary = nil
		Entity.Secondary = nil
		Entity.Tertiary = nil
		Entity.Smoke = nil

		Entity.GearboxEndCount = 1			-- Number of endpoint gearboxes

		Entity.DataStore = Entities.GetArguments("acf_controller")

		UpdateController(Entity, Data)

		-- Finish setting up the entity
		HookRun("ACF_OnSpawnEntity", "acf_controller", Entity, Data)

		WireIO.SetupInputs(Entity, Inputs, Data)
		WireIO.SetupOutputs(Entity, Outputs, Data)

		if Data.AIODefaults then Entity:RestoreNetworkVars(Data.AIODefaults) end

		ACF.AugmentedTimer(function(_) Entity:UpdateOverlay() end, function() return IsValid(Entity) end, nil, {MinTime = 1, MaxTime = 1})

		return Entity
	end

	-- Bare minimum arguments to reconstruct an all-in-one controller
	Entities.Register("acf_controller", ACF.MakeController)

	function ENT:Update(Data)
		-- Called when updating the entity
		VerifyData(Data)

		local CanUpdate, Reason = HookRun("ACF_PreUpdateEntity", "acf_controller", self, Data)
		if CanUpdate == false then return CanUpdate, Reason end

		HookRun("ACF_OnEntityLast", "acf_controller", self)

		ACF.SaveEntity(self)

		UpdateController(self, Data)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnUpdateEntity", "acf_controller", self, Data)

		return true, "All-In-One Controller updated successfully!"
	end

	local GearboxEndMap = {
		[1] = "One Final, Dual Clutch",
		[2] = "Two Final, Dual Clutch"
	}

	function ENT:ACF_UpdateOverlayState(State)
		State:AddKeyValue("Predicted Drivetrain", GearboxEndMap[self.GearboxEndCount] or "All Wheel Drive")

		local Contraption = self:GetContraption()
		if Contraption == nil or Contraption.ACF_Baseplate ~= self.Baseplate then
			State:AddWarning("Must be parented to baseplate or its contraption")
		end
	end
end

-- Camera related
do
	net.Receive("ACF_Controller_CamInfo", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local CamMode = net.ReadUInt(2)
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end
		if Entity:GetDisableAIOCam() then return end
		Entity.CamMode = math.Clamp(CamMode, 1, Entity:GetCamCount())
		Entity.CamOffset = Entity["GetCam" .. CamMode .. "Offset"]()
		Entity.CamOrbit = Entity["GetCam" .. CamMode .. "Orbit"]()
	end)

	net.Receive("ACF_Controller_CamData", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local CamAng = net.ReadAngle()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end
		if Entity:GetDisableAIOCam() then return end
		Entity.CamAng = CamAng
	end)

	net.Receive("ACF_Controller_Zoom", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local FOV = net.ReadFloat()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end
		if Entity:GetDisableAIOCam() then return end
		Entity.FOV = FOV
		ply:SetFOV(FOV, 0, nil)
	end)

	local CamTraceConfig = {}
	function ENT:ProcessCameras(SelfTbl)
		if self:GetDisableAIOCam() then return end
		local CamAng = SelfTbl.CamAng or angle_zero
		RecacheBindOutput(self, SelfTbl, "CamAng", CamAng)

		local CamDir = CamAng:Forward()
		local CamOffset = SelfTbl.CamOffset or vector_origin
		local CamPos = self:LocalToWorld(CamOffset)

		-- debugoverlay.Line(CamPos, CamPos + CamDir * 100, 0.1, Color(255, 0, 0), true)

		CamTraceConfig.start = CamPos
		CamTraceConfig.endpos = CamPos + CamDir * 99999
		CamTraceConfig.filter = SelfTbl.Filter or {self}
		local Tr = TraceLine(CamTraceConfig)

		local HitPos = Tr.HitPos or vector_origin
		self.HitPos = HitPos
		RecacheBindOutput(self, SelfTbl, "HitPos", HitPos)

		return CamPos, CamAng, HitPos
	end
end

-- Cam related
do
	function ENT:AnalyzeCams()
		if self.UsesWireFilter then return end -- So we don't override the wire based filter

		-- Just get it from the contraption lol...
		local Filter = {self} -- Atleast filter the controller itself
		local Contraption = self:GetContraption()
		if Contraption ~= nil then
			-- And the contraption too if it's valid
			local LUT = Contraption.ents
			Filter = {}
			for v, _ in pairs(LUT) do
				if IsValid(v) then Filter[#Filter + 1] = v end
			end
		end
		self.Filter = Filter
	end
end

-- Hud related
do
	local BallCompStatusToCode = {
		-- Busy
		["Calculating..."] = 1,
		["Processing..."] = 1,
		["Tracking"] = 1,
		["Adjusting..."] = 1,
		-- Success
		["Ready"] = 2,
		["Super elevation calculated!"] = 2,
		["Firing solution found!"] = 2,
		-- Error
		["Target unable to be reached!"] = 3,
		["Gun unlinked!"] = 3,
		["Took too long!"] = 3,
		["Disabled"] = 3,
	}

	function ENT:ProcessHUDs(SelfTbl)
		-- Network various statistics
		if IsValid(SelfTbl.Primary) then
			RecacheBindNW(self, SelfTbl, "AHS_Primary_SL", SelfTbl.Primary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_AT", SelfTbl.Primary.BulletData.Type or 0, self.SetNWString)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_NF", SelfTbl.Primary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_RD", SelfTbl.Primary.State == "Loaded" or false, self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Primary", SelfTbl.Primary, self.SetNWEntity)
		else
			SelfTbl.Primary = next(self.GunsPrimary)
		end

		if IsValid(SelfTbl.Secondary) then
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_SL", SelfTbl.Secondary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_AT", SelfTbl.Secondary.BulletData.Type or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_NF", SelfTbl.Secondary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_RD", SelfTbl.Secondary.State == "Loaded" or false, self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary", SelfTbl.Secondary, self.SetNWEntity)
		else
			SelfTbl.Secondary = next(self.GunsSecondary)
		end

		if IsValid(SelfTbl.Tertiary) then
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_SL", SelfTbl.Tertiary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_AT", SelfTbl.Tertiary.BulletData.Type or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_NF", SelfTbl.Tertiary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_RD", SelfTbl.Tertiary.State == "Loaded" or false, self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary", SelfTbl.Tertiary, self.SetNWEntity)
		else
			SelfTbl.Tertiary = next(self.Racks)
		end

		if IsValid(SelfTbl.Smoke) then
			RecacheBindNW(self, SelfTbl, "AHS_Smoke_SL", SelfTbl.Smoke.TotalAmmo or 0, self.SetNWInt)
		else
			SelfTbl.Smoke = next(self.GunsSmoke)
		end

		if IsValid(SelfTbl.TurretComputer) then
			local Status = SelfTbl.TurretComputer.Status
			local Code = BallCompStatusToCode[Status] or 0
			RecacheBindNW(self, SelfTbl, "AHS_TurretComp_Status", Code, self.SetNWInt)
		end

		RecacheBindNW(self, SelfTbl, "AHS_Speed", math.Round(SelfTbl.Speed or 0), self.SetNWInt)
		if IsValid(SelfTbl.Gearbox) then RecacheBindNW(self, SelfTbl, "AHS_Gear", SelfTbl.Gearbox.Gear, self.SetNWInt) end

		local FuelLevel = 0
		local Conv = self:GetFuelUnit() == 0 and 1 or 0.264172 -- Liters / Gallons
		for Fuel in pairs(SelfTbl.Fuels) do
			if IsValid(Fuel) then FuelLevel = FuelLevel + Fuel.Amount end
		end
		RecacheBindNW(self, SelfTbl, "AHS_Fuel", math.Round(FuelLevel * Conv), self.SetNWInt)
		RecacheBindNW(self, SelfTbl, "AHS_FuelCap", math.Round(SelfTbl.FuelCapacity * Conv), self.SetNWInt) -- Should only run once effectively

		local AliveCrew = 0
		local TotalCrew = 0
		local Contraption = self:GetContraption()
		local Crew = Contraption and Contraption.Crews or {}
		for CrewMember, _ in pairs(Crew) do
			if CrewMember.IsAlive then AliveCrew = AliveCrew + 1 end
			TotalCrew = TotalCrew + 1
		end
		RecacheBindNW(self, SelfTbl, "AHS_Crew", AliveCrew, self.SetNWInt)
		RecacheBindNW(self, SelfTbl, "AHS_CrewCap", TotalCrew, self.SetNWInt) -- Should only run once effectively
	end
end

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

-- Receiver related
do
	function ENT:ProcessReceivers(SelfTbl)
		for Receiver, _ in pairs(SelfTbl.Receivers) do
			local Detected = Receiver.Outputs.Detected.Value
			local Direction = Receiver.Outputs.Direction.Value
			if IsValid(Receiver) and (SelfTbl.ReceiverDetecteds[Receiver] ~= Detected or SelfTbl.ReceiverDirections[Receiver] ~= Direction) then
				SelfTbl.ReceiverDirections[Receiver] = Direction
				SelfTbl.ReceiverDetecteds[Receiver] = Detected
				if Detected == 0 then return end
				net.Start("ACF_Controller_Receivers")
				net.WriteEntity(self)
				net.WriteEntity(Receiver)
				net.WriteVector(Direction)
				net.Send(self.Driver)
			end
		end
	end
end

-- Ammo related
do
	net.Receive("ACF_Controller_Ammo", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local SelectAmmoType = net.ReadString()
		local ForceReload = net.ReadBool()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end

		local PrimaryGun = Entity.Primary
		if not IsValid(PrimaryGun) then return end
		for Crate, _ in pairs(PrimaryGun.Crates) do
			if IsValid(Crate) then
				local AmmoType = Crate.RoundData.ID
				Crate:TriggerInput("Load", AmmoType == SelectAmmoType and 1 or 0)
			end
		end
		if ForceReload then PrimaryGun:TriggerInput("Reload", 1) end
	end)

	function ENT:ProcessAmmo(SelfTbl)
		local Contraption = self:GetContraption()
		if Contraption == nil then return end

		-- Determine current counts
		local PrimaryGun = SelfTbl.Primary
		if not IsValid(PrimaryGun) then return end

		local PrimaryAmmoCountsByType = {}
		for Crate, _ in pairs(PrimaryGun.Crates) do
			if IsValid(Crate) then
				local AmmoType = Crate.RoundData.ID
				PrimaryAmmoCountsByType[AmmoType] = (PrimaryAmmoCountsByType[AmmoType] or 0) + (Crate.Amount or 0)
			end
		end

		for AmmoType, Count in pairs(PrimaryAmmoCountsByType) do
			if SelfTbl.PrimaryAmmoCountsByType[AmmoType] ~= Count then
				SelfTbl.PrimaryAmmoCountsByType[AmmoType] = Count
				net.Start("ACF_Controller_Ammo")
				net.WriteEntity(self)
				net.WriteString(AmmoType)
				net.WriteInt(Count, 16)
				net.Send(self.Driver)
			end
		end
	end
end

-- Link and unlink functions
-- I hate this so much :(
local function BroadcastEntity(Name, Entity, Entity2, State)
	net.Start(Name)
	net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
	net.WriteUInt(Entity2:EntIndex(), MAX_EDICT_BITS)
	net.WriteBool(State)
	net.Broadcast()
end

-- Handle a player entering or exiting the vehicle
local function OnActiveChanged(Controller, Ply, Active)
	local SelfTbl = Controller:GetTable()

	-- Reset all key states and outputs when getting in or out of the vehicle
	Controller.KeyStates = {}
	for Key, Output in pairs(IN_ENUM_TO_WIRE_OUTPUT) do
		RecacheBindOutput(Controller, SelfTbl, Output, 0)
		RecacheBindState(SelfTbl, Key, false)
	end

	RecacheBindOutput(Controller, SelfTbl, "Driver", Ply)
	RecacheBindOutput(Controller, SelfTbl, "Active", Active and 1 or 0)

	Controller.FOV = Controller.FOV or 90
	Ply:SetFOV(Active and Controller.FOV or 0, 0, nil)

	Controller.Active = Active
	Controller.Driver = Active and Ply or NULL
	if Active then Controller:AnalyzeCams() end -- Recalculate filter for the cameras

	for Turret in pairs(Controller.Turrets) do
		if IsValid(Turret) then Turret:TriggerInput("Active", Active) end
	end

	for Engine in pairs(Controller.Engines) do
		if IsValid(Engine) then Engine:TriggerInput("Active", Active) end
	end

	if IsValid(Controller.Gearbox) then Controller.Gearbox:TriggerInput("Gear", Active and 1 or 0) end

	for Gearbox in pairs(Controller.GearboxEnds) do
		if IsValid(Gearbox) then Gearbox:TriggerInput("Gear", Active and 1 or 0) end
	end

	for Gearbox in pairs(Controller.GearboxIntermediates) do
		if IsValid(Gearbox) then Gearbox:TriggerInput("Gear", Active and 1 or 0) end
	end

	-- Let the player know the controller is active or not
	net.Start("ACF_Controller_Active")
	net.WriteUInt(Controller:EntIndex(), MAX_EDICT_BITS)
	net.WriteBool(Active)
	net.Send(Ply)

	-- Network the camera filter to the player
	net.Start("ACF_Controller_CamInfo")
	net.WriteTable(Controller.Filter or {})
	net.Send(Ply)
end

local function OnKeyChanged(Controller, Key, Down)
	local Output = IN_ENUM_TO_WIRE_OUTPUT[Key]
	local SelfTbl = Controller:GetTable()
	if Output ~= nil then
		RecacheBindOutput(Controller, SelfTbl, Output, Down and 1 or 0)
		RecacheBindState(SelfTbl, Key, Down)
	end

	Controller:ToggleTurretLocks(SelfTbl, Key, Down)
end

local function OnButtonChanged(Controller, Button, Down)
	if not IsFirstTimePredicted() then return end
	if Button == MOUSE_MIDDLE and Down and IsValid(Controller.TurretComputer) then
		Controller.TurretComputer.Inputs.Position.Value = Controller.HitPos
		Controller.TurretComputer:TriggerInput("Calculate Superelevation", 1)

		local Diff = (Controller.Primary:GetPos() - Controller.HitPos)
		Controller.LasePitch = math.deg(math.asin(Diff.z / Diff:Length()))
		Controller.LaseDist = Diff:Length()
	end
end

local function OnLinkedSeat(Controller, Target)
	hook.Add("PlayerEnteredVehicle", "ACFControllerSeatEnter" .. Controller:EntIndex(), function(Ply, Veh)
		if Veh == Target then OnActiveChanged(Controller, Ply, true) end
	end)

	hook.Add("PlayerLeaveVehicle", "ACFControllerSeatExit" .. Controller:EntIndex(), function(Ply, Veh)
		if Veh == Target then OnActiveChanged(Controller, Ply, false) end
	end)

	hook.Add("KeyPress", "ACFControllerSeatKeyPress" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnKeyChanged(Controller, Key, true)
	end)

	hook.Add("KeyRelease", "ACFControllerSeatKeyRelease" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnKeyChanged(Controller, Key, false)
	end)

	hook.Add("PlayerButtonDown", "ACFControllerSeatButtonDown" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnButtonChanged(Controller, Key, true)
	end)

	hook.Add("PlayerButtonUp", "ACFControllerSeatButtonUp" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnButtonChanged(Controller, Key, false)
	end)

	-- Remove the hooks when the controller is removed
	Controller:CallOnRemove("ACFRemoveController", function(Ent)
		hook.Remove("PlayerEnteredVehicle", "ACFControllerSeatEnter" .. Ent:EntIndex())
		hook.Remove("PlayerLeaveVehicle", "ACFControllerSeatExit" .. Ent:EntIndex())
		hook.Remove("KeyPress", "ACFControllerSeatKeyPress" .. Ent:EntIndex())
		hook.Remove("KeyRelease", "ACFControllerSeatKeyRelease" .. Ent:EntIndex())
	end)
end

local function OnUnlinkedSeat(Controller)
	-- Remove the hooks when the seat is unlinked
	hook.Remove("PlayerEnteredVehicle", "ACFControllerSeatEnter" .. Controller:EntIndex())
	hook.Remove("PlayerLeaveVehicle", "ACFControllerSeatExit" .. Controller:EntIndex())
	hook.Remove("KeyPress", "ACFControllerSeatKeyPress" .. Controller:EntIndex())
	hook.Remove("KeyRelease", "ACFControllerSeatKeyRelease" .. Controller:EntIndex())
end

-- Using this to auto generate the link/unlink functions
local LinkConfigs = {
	prop_vehicle_prisoner_pod = {
		Field = "Seat",
		Single = true,
		OnLinked = function(Controller, Target)
			OnLinkedSeat(Controller, Target)
		end,
		OnUnlinked = function(Controller, _)
			OnUnlinkedSeat(Controller)
		end,
	},
	acf_gearbox = {
		Field = "Gearbox",
		Single = true,
		OnLinked = function(Controller, Target)
			Controller:AnalyzeDrivetrain(Target)
		end
	},
	acf_turret = {
		Field = "Turrets",
		Single = false
	},
	acf_gun = {
		Field = "Guns",
		Single = false,
		OnLinked = function(Controller, Target)
			Controller:AnalyzeGuns(Target)
		end
	},
	acf_turret_computer = {
		Field = "TurretComputer",
		Single = true
	},
	acf_computer = {
		Field = "GuidanceComputer",
		Single = true,
		PreLink = function(_, Target)
			if Target.Computer ~= "CPR-LSR" and Target.Computer ~= "CPR-OPT" then return false, "Only laser/optical guidance computers are supported." end
			return true
		end
	},
	acf_receiver = {
		Field = "Receivers",
		Single = false
	},
	acf_baseplate = {
		Field = "Baseplate",
		Single = true,
		OnLinked = function(Controller, Target)
			if IsValid(Target.Pod) and not Controller.Seat then Controller:Link(Target.Pod) end
		end,
		OnUnlinked = function(Controller, Target)
			if IsValid(Target.Pod) and not Controller.Seat then Controller:Unlink(Target.Pod) end
		end
	},
	acf_rack = {
		Field = "Racks",
		Single = false,
		OnLinked = function(Controller, Target)
			Controller:AnalyzeRacks(Target)
		end
	},
	prop_physics = {
		Field = "SteerPlates",
		Single = false,
		OnLinked = function(Controller, Target)
			Controller:AnalyzeSteerPlates(Target)
		end
	}
}

-- Register links to the controller with various classes
for Class, Data in pairs(LinkConfigs) do
	local Field = Data.Field
	local Single = Data.Single
	local PreLink = Data.PreLink
	local OnLinked = Data.OnLinked
	local OnUnlinked = Data.OnUnlinked

	-- Register the link/unlink functions for each class
	ACF.RegisterClassLink("acf_controller", Class, function(Controller, Target)
		if Controller:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "The controller is too far from this entity." end
		if Single and IsValid(Controller[Field]) then return false, "This controller is already linked to another entity of this type." end
		if not Single and Controller[Field][Target] then return false, "This controller is already linked to this entity." end

		if Single then Controller[Field] = Target
		else Controller[Field][Target] = true end

		if PreLink then
			local PreLinkResult, PreLinkMsg = PreLink(Controller, Target)
			if not PreLinkResult then return false, PreLinkMsg end
		end

		-- Alot of things initialize in the first tick, so wait for them to be available
		timer.Simple(0, function()
			if OnLinked then OnLinked(Controller, Target) end
		end)

		BroadcastEntity("ACF_Controller_Links", Controller, Target, true)
		Controller:UpdateOverlay()
		return true, "Controller linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_controller", Class, function(Controller, Target)
		if Single and Controller[Field] ~= Target then return false, "This controller is not linked to this entity." end
		if not Single and not Controller[Field][Target] then return false, "This controller is not linked to this entity." end

		if Single then Controller[Field] = nil
		else Controller[Field][Target] = nil end

		if OnUnlinked then OnUnlinked(Controller, Target) end

		BroadcastEntity("ACF_Controller_Links", Controller, Target, false)

		Controller:UpdateOverlay()
		return true, "Controller unlinked successfully!"
	end)
end

-- Entity methods
do
	-- Main logic loop
	function ENT:Think()
		local SelfTbl = self:GetTable()
		local Driver = SelfTbl.Driver
		if not IsValid(Driver) then return end

		if not self.Active then return end

		SelfTbl.iters = SelfTbl.iters or 0
		local iters = SelfTbl.iters

		-- Process cameras
		local _, _, HitPos = self:ProcessCameras(SelfTbl)

		-- Aim turrets
		if iters % 4 == 0 then self:ProcessTurrets(SelfTbl, HitPos) end

		-- Fire guns
		if iters % 4 == 0 then self:ProcessGuns(SelfTbl) end

		if iters % 1 == 0 then self:ProcessGuidance(SelfTbl) end

		-- Process ammo counts
		if iters % 66 == 0 then self:ProcessAmmo(SelfTbl) end

		-- Process receivers
		if iters % 10 == 0 then self:ProcessReceivers(SelfTbl) end

		-- Process gearboxes
		if iters % 4 == 0 then self:ProcessDrivetrain(SelfTbl) end

		local Interval = math.Round(self:GetShiftTime() * 66 / 1000)
		if iters % Interval == 0 then self:ProcessDrivetrainLowFreq(SelfTbl) end

		-- Process HUDs
		if iters % 7 == 0 then self:ProcessHUDs(SelfTbl) end

		SelfTbl.iters = iters + 1
		self:UpdateOverlay()
		self:NextThink(Clock.CurTime)
		return true
	end

	-- Handle Inputs
	do
		ACF.AddInputAction("acf_controller", "Filter", function(Controller, Value)
			local Filter = ToTable(Value)
			if not IsValid(Filter) then return end
			Controller.UsesWireFilter = true
			Controller.Filter = Filter
		end)
	end
end

-- Adv Dupe 2 Related
do
	-- Hopefully we can improve this when the codebase is refactored.
	function ENT:PreEntityCopy()
		for _, Data in pairs(LinkConfigs) do
			local Field = Data.Field
			if Data.Single then
				if IsValid(self[Field]) then
					duplicator.StoreEntityModifier(self, Field, {self[Field]:EntIndex()})
				end
			else
				if next(self[Field]) then
					local Entities = {}
					for Ent in pairs(self[Field]) do Entities[#Entities + 1] = Ent:EntIndex() end
					duplicator.StoreEntityModifier(self, Field, Entities)
				end
			end
		end

		-- Wire dupe info
		self.BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		local EntMods = Ent.EntityMods

		for _, Data in pairs(LinkConfigs) do
			local Field = Data.Field
			if EntMods[Field] then
				if Data.Single then
					local Target = CreatedEntities[EntMods[Field][1]]
					if IsValid(Target) then self:Link(Target) end
				else
					for _, EntID in pairs(EntMods[Field]) do self:Link(CreatedEntities[EntID]) end
				end
				EntMods[Field] = nil
			end
		end

		--Wire dupe info
		self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
	end

	function ENT:OnRemove()
		HookRun("ACF_OnEntityLast", "acf_controller", self)

		for _, Data in pairs(LinkConfigs) do
			local Field = Data.Field
			if Data.Single then
				if IsValid(self[Field]) then self:Unlink(self[Field]) end
			else
				for Ent in pairs(self[Field]) do self:Unlink(Ent) end
			end
		end

		WireLib.Remove(self)
	end
end