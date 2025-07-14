--[[
This defines the major serverside logic for the controller entity.

Supported Drivetrains:
- Must have a single "main" gearbox that does the heavy lifting, e.g. a CVT transax.


]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Localizations
local ACF = ACF
local HookRun     = hook.Run
local Utilities   = ACF.Utilities
local WireIO      = Utilities.WireIO
local Contraption = ACF.Contraption
local hook	   = hook
local Classes	= ACF.Classes
local Entities   = Classes.Entities
local CheckLegal = ACF.CheckLegal
local MaxDistance  = ACF.LinkDistance * ACF.LinkDistance

local TraceLine = util.TraceLine

util.AddNetworkString("ACF_Controller_Links")	-- Relay links to client
util.AddNetworkString("ACF_Controller_Active")	-- Relay active state to client
util.AddNetworkString("ACF_Controller_CamInfo")	-- Relay entities and camera modes
util.AddNetworkString("ACF_Controller_CamData")	-- Relay camera updates

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

-- Reverse lookup
local WIRE_OUTPUT_TO_IN_ENUM = {}
for IN, Output in pairs(IN_ENUM_TO_WIRE_OUTPUT) do WIRE_OUTPUT_TO_IN_ENUM[Output] = IN end

local Defaults = {
	ZoomSpeed = 10,
	ZoomMin = 5,
	ZoomMax = 90,
	SlewMin = 0.15,
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

	ThrottleIdle = 0,
	SpeedUnit = 0,
	FuelUnit = 0,

	BrakeEngagement = 0,
	BrakeStrength = 100,

	ShiftTime = 100,
	ShiftMinRPM = 0,
	ShiftMaxRPM = 0
}

local Clock = Utilities.Clock
local DriverKeyDown = FindMetaTable("Player").KeyDown

--- Sets a wire output if the cached value has changed
local function RecacheBindOutput(Entity, SelfTbl, Output, Value)
	if SelfTbl.Outputs[Output].Value == Value then return end
	WireLib.TriggerOutput(Entity, Output, Value)
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

		Entity:UpdateOverlay(true)
	end

	function ACF.MakeController(Player, Pos, Ang, Data)
		VerifyData(Data)

		-- Creating the entity
		local CanSpawn	= HookRun("ACF_PreEntitySpawn", "acf_controller", Player, Data)
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

		Entity.LeftGearboxes = {}			-- Gearboxes connected to the left drive wheel
		Entity.RightGearboxes = {}			-- Gearboxes connected to the right drive wheel
		Entity.LeftWheels = {}				-- Wheels connected to the left drive wheel
		Entity.RightWheels = {}				-- Wheels connected to the right drive wheel

		Entity.GearboxLeft = nil			-- A Gearbox connected to the left drive wheel
		Entity.GearboxRight = nil			-- A Gearbox connected to the right drive wheel
		Entity.GearboxLeftDir = nil			-- Direction of that left gearbox's output
		Entity.GearboxRightDir = nil		-- Direction of that right gearbox's output

		Entity.ControllerWelds = {}			-- Keep track of the welds we created

		-- State and meta variables
		Entity.TurretLocked = false			-- Whether the turret is locked or not
		Entity.LargestCaliber = 0			-- Largest caliber gun of the vehicle
		Entity.FuelCapacity = 0				-- Total fuel capacity of the vehicle
		Entity.Active = false				-- Whether the controller is active or not

		Entity.CamMode = 0					-- Camera mode (from client)
		Entity.CamAng = Angle(0, 0, 0)		-- Camera angle (from client)
		Entity.CamOffset = Vector() 		-- Camera offset (from client)
		Entity.CamOrbit = 0					-- Camera orbit (from client)

		Entity.Speed = 0

		Entity.Primary = nil
		Entity.Secondary = nil
		Entity.Tertiary = nil

		Entity.GearboxEndCount = 1			-- Number of endpoint gearboxes

		Entity.Owner = Player -- MUST be stored on ent for PP
		Entity.DataStore = Entities.GetArguments("acf_controller")

		UpdateController(Entity, Data)

		-- Finish setting up the entity
		hook.Run("ACF_OnSpawnEntity", "acf_controller", Entity, Data)

		WireIO.SetupInputs(Entity, Inputs, Data)
		WireIO.SetupOutputs(Entity, Outputs, Data)

		WireLib.TriggerOutput(Entity, "Entity", Entity)

		Entity:UpdateOverlay(true)

		CheckLegal(Entity)

		if Data.AIODefaults then Entity:RestoreNetworkVars(Data.AIODefaults) end

		return Entity
	end

	-- Bare minimum arguments to reconstruct an armor controller
	Entities.Register("acf_controller", ACF.MakeController)

	function ENT:Update(Data)
		-- Called when updating the entity
		VerifyData(Data)

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_controller", self, Data)
		if CanUpdate == false then return CanUpdate, Reason end

		HookRun("ACF_OnEntityLast", "acf_controller", self)

		ACF.SaveEntity(self)

		UpdateController(self, Data)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnEntityUpdate", "acf_controller", self, Data)

		self:UpdateOverlay(true)

		return true, "Armor Controller updated successfully!"
	end

	local GearboxEndMap = {
		[1] = "One Final, Dual Clutch",
		[2] = "Two Final, Dual Clutch"
	}
	function ENT:UpdateOverlayText()
		local str = string.format("All In One Controller\nPredicted Drivetrain: %s", GearboxEndMap[self.GearboxEndCount] or "All Wheel Drive")
		return str
	end
end

-- Camera related
do
	net.Receive("ACF_Controller_CamInfo", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local CamMode = net.ReadUInt(2)
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity:CPPIGetOwner() ~= ply then return end
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
		if Entity:CPPIGetOwner() ~= ply then return end
		if Entity:GetDisableAIOCam() then return end
		Entity.CamAng = CamAng
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

		RecacheBindNW(self, SelfTbl, "AHS_Speed", math.Round(SelfTbl.Speed or 0), self.SetNWInt)
		if IsValid(SelfTbl.Gearbox) then RecacheBindNW(self, SelfTbl, "AHS_Gear", SelfTbl.Gearbox.Gear, self.SetNWInt) end

		local FuelLevel = 0
		local Conv = self:GetFuelUnit() == 0 and 1 or 0.264172 -- Liters / Gallons
		for Fuel in pairs(SelfTbl.Fuels) do
			if IsValid(Fuel) then FuelLevel = FuelLevel + Fuel.Fuel end
		end
		RecacheBindNW(self, SelfTbl, "AHS_Fuel", math.Round(FuelLevel * Conv), self.SetNWInt)
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
					if Gun.CanFire and Gun:CanFire() then Gun:Shoot() end
				else
					Gun.Firing = false
				end
			end
		end
	end

	function ENT:ProcessGuns(SelfTbl, Driver)
		if SelfTbl:GetDisableFiring() then return end

		local Fire1, Fire2, Fire3, Fire4 = DriverKeyDown(Driver, IN_ATTACK), DriverKeyDown(Driver, IN_ATTACK2), DriverKeyDown(Driver, IN_WALK), DriverKeyDown(Driver, IN_SPEED)

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
	function ENT:ProcessTurrets(SelfTbl, _, HitPos)
		local Turrets = SelfTbl.Turrets

		if SelfTbl.TurretLocked then return end

		for Turret, _ in pairs(Turrets) do
			if IsValid(Turret) then Turret:InputDirection(HitPos) end
		end
	end
end

-- Drivetrain related
do
	local CLUTCH_FLOW = 0
	local CLUTCH_BLOCK = 1

	--- Finds the components of the drive train
	--- Input is the "main" gearbox of the drivetrain
	--- returns multiple arrays, one for Wheels, engines, fuels, wheel gearboxes and intermediate gearboxes
	--- This should be enough for general use, obviously it can't cover every edge case.
	local function DiscoverDriveTrain(Target)
		local Queued  = { [Target] = true }
		local Checked = {}
		local Current, Class, Sources

		local Wheels, Engines, Fuels, Ends, Intermediates = {}, {}, {}, {}, {}

		while next(Queued) do
			Current = next(Queued)
			Class   = Current:GetClass()
			Sources = ACF.GetAllLinkSources(Class)

			Queued[Current] = nil
			Checked[Current] = true

			if Class == "acf_engine" then
				Engines[Current] = true
			elseif Class == "acf_gearbox" then
				if Sources.Wheels and next(Sources.Wheels(Current)) then Ends[Current] = true else Intermediates[Current] = true end
			elseif Class == "acf_fueltank" then
				Fuels[Current] = true
			elseif Class == "prop_physics" then
				Wheels[Current] = true
			end

			for _, Action in pairs(Sources) do
				for Entity in pairs(Action(Current)) do
					if not (Checked[Entity] or Queued[Entity]) then
						Queued[Entity] = true
					end
				end
			end
		end
		return Wheels, Engines, Fuels, Ends, Intermediates
	end

	--- Finds the "side" of the gearbox that the wheel is connected to. This corresponds to the wire inputs.
	local function GetLROutput(Gearbox, Wheel)
		local lp = Gearbox:GetAttachment(Gearbox:LookupAttachment("driveshaftL")).Pos
		local rp = Gearbox:GetAttachment(Gearbox:LookupAttachment("driveshaftR")).Pos
		local d1 = Wheel:GetPos():Distance(lp or Vector())
		local d2 = Wheel:GetPos():Distance(rp or Vector())
		if d1 < d2 then return "Left" else return "Right" end
	end

	--- Sets the brakes of the left/right transfers
	local function SetBrakes(SelfTbl, L, R)
		SelfTbl.GearboxLeft:TriggerInput(SelfTbl.GearboxLeftDir .. " Brake", L)
		SelfTbl.GearboxRight:TriggerInput(SelfTbl.GearboxRightDir .. " Brake", R)
	end

	--- Sets the clutches of the left/right transfers
	local function SetClutches(SelfTbl, L, R)
		SelfTbl.GearboxLeft:TriggerInput(SelfTbl.GearboxLeftDir .. " Clutch", L)
		SelfTbl.GearboxRight:TriggerInput(SelfTbl.GearboxRightDir .. " Clutch", R)
	end

	--- Sets the gears of the left/right transfers
	local function SetTransfers(SelfTbl, L, R)
		SelfTbl.GearboxLeft:TriggerInput("Gear", L)
		SelfTbl.GearboxRight:TriggerInput("Gear", R)
	end

	--- Creates/Removes weld constraints from the Left/Right Wheels to baseplate or between them.
	local function SetLatches(SelfTbl, Engage)
		for Wheel in pairs(SelfTbl.Wheels) do
			local AlreadyHasWeld = SelfTbl.ControllerWelds[Wheel]
			if Engage and not AlreadyHasWeld then
				SelfTbl.ControllerWelds[Wheel] = constraint.Weld(SelfTbl.Baseplate, Wheel, 0, 0, 0, true, true)
			elseif not Engage and AlreadyHasWeld then
				SelfTbl.ControllerWelds[Wheel]:Remove()
				SelfTbl.ControllerWelds[Wheel] = nil
			end
		end
	end

	--- All wheel variant
	local function SetAllBrakes(SelfTbl, Strength)
		for Gearbox in pairs(SelfTbl.GearboxEnds) do
			if IsValid(Gearbox) then Gearbox:TriggerInput("Brake", Strength) end
		end
	end

	--- All wheel variant
	local function SetAllClutches(SelfTbl, Strength)
		for Gearbox in pairs(SelfTbl.GearboxEnds) do
			if IsValid(Gearbox) then Gearbox:TriggerInput("Clutch", Strength) end
		end
	end

	--- All wheel variant
	local function SetAllTransfers(SelfTbl, Gear)
		for Gearbox in pairs(SelfTbl.GearboxEnds) do
			if IsValid(Gearbox) then Gearbox:TriggerInput("Gear", Gear) end
		end
	end

	--- Intentionally Supported drivetrains:
	--- Single Transaxial gearbox with dual clutch -> basic ww2 style
	--- Single Transaxial gearbox with transfers -> basic neutral steer style
	--- Main gearbox with transfers to wheels -> basic wheeled
	function ENT:AnalyzeDrivetrain(MainGearbox)
		-- Need a list of all linked wheels
		if not IsValid(MainGearbox) then return end

		-- Recalculate the drive train components
		self.Wheels, self.Engines, self.Fuels, self.GearboxEnds, self.GearboxIntermediates = DiscoverDriveTrain(MainGearbox)

		self.GearboxEndCount = table.Count(self.GearboxEnds)
		-- PrintTable({Wheels = self.Wheels, Engines = self.Engines, Fuels = self.Fuels, GearboxEnds = self.GearboxEnds, GearboxIntermediates = self.GearboxIntermediates})

		-- Process gears
		local ForwardGearCount = 0
		for _, v in ipairs(MainGearbox.Gears) do
			if v > 0 then ForwardGearCount = ForwardGearCount + 1 else break end
		end
		self.ForwardGearCount, self.TotalGearCount = ForwardGearCount, #MainGearbox.Gears

		self.FuelCapacity = 0
		for Fuel in pairs(self.Fuels) do self.FuelCapacity = self.FuelCapacity + Fuel.Capacity end

		-- Determine the Left/Right wheels assuming the vehicle is built north
		local LeftWheels, RightWheels = {}, {}
		local avg, count = 0, 0
		for Wheel in pairs(self.Wheels) do
			avg = avg + Wheel:GetPos().x
			count = count + 1
		end
		avg = avg / count
		for Wheel in pairs(self.Wheels) do
			if Wheel:GetPos().x < avg then LeftWheels[Wheel] = true else RightWheels[Wheel] = true end
		end
		self.LeftWheels, self.RightWheels = LeftWheels, RightWheels

		-- Determine the Left/Right gearboxes from the Left/Right wheels
		-- Hypothetically there's a drivetrain with more than one gearbox per side but that's out of scope for newcomers.
		local GetWheels = ACF.GetAllLinkSources("acf_gearbox").Wheels
		local LeftGearboxes, RightGearboxes = {}, {} -- LUTs from gearbox to output direction
		for Gearbox in pairs(self.GearboxEnds) do
			for Wheel in pairs(GetWheels(Gearbox)) do
				if LeftWheels[Wheel] then LeftGearboxes[Gearbox] = GetLROutput(Gearbox, Wheel) end
				if RightWheels[Wheel] then RightGearboxes[Gearbox] = GetLROutput(Gearbox, Wheel) end
			end
		end
		self.LeftGearboxes, self.RightGearboxes = LeftGearboxes, RightGearboxes

		self.GearboxLeft, self.GearboxLeftDir = next(LeftGearboxes)
		self.GearboxRight, self.GearboxRightDir = next(RightGearboxes)
	end

	--- Handles driving, gearing, clutches, latches and brakes
	function ENT:ProcessDrivetrain(SelfTbl, Driver)
		-- Log speed even if drivetrain is invalid
		-- TODO: should this be map or player scale?
		local Unit = self:GetSpeedUnit()
		local Conv = Unit == 0 and 0.09144 or 0.05681 -- Converts u/s to km/h or mph (Assumes 1u = 1in)
		local Speed = self.Baseplate:GetVelocity():Length() * Conv
		SelfTbl.Speed = Speed
		RecacheBindOutput(self, SelfTbl, "Speed", Speed)

		if not IsValid(SelfTbl.Gearbox) then return end

		local W, A, S, D = DriverKeyDown(Driver, IN_FORWARD), DriverKeyDown(Driver, IN_MOVELEFT), DriverKeyDown(Driver, IN_BACK), DriverKeyDown(Driver, IN_MOVERIGHT)
		local IsBraking = DriverKeyDown(Driver, IN_JUMP)

		if self:GetFlipAD() then A, D = D, A end

		local IsLateral = W or S						-- Forward/backward movement
		local IsTurning = A or D						-- Left/right movement
		local IsMoving = IsLateral or (not self:GetThrottleIgnoresAD() and IsTurning) -- Moving in any direction

		-- Only two transfer setups can reasonably be expected to neutral steer
		local IsNeutral = not IsLateral and IsTurning
		local CanNeutral = SelfTbl.GearboxEndCount == 2
		local ShouldAWD = SelfTbl.GearboxEndCount > 2

		-- Throttle the engines
		local Engines = SelfTbl.Engines
		for Engine in pairs(Engines) do Engine:TriggerInput("Throttle", IsMoving and 100 or self:GetThrottleIdle() or 0) end

		local BrakeStrength = self:GetBrakeStrength()


		if not ShouldAWD then
			-- Tank steering
			if IsBraking or (self:GetBrakeEngagement() == 1 and not IsMoving) then -- Braking
				SetBrakes(SelfTbl, BrakeStrength, BrakeStrength) SetClutches(SelfTbl, CLUTCH_BLOCK, CLUTCH_BLOCK) SetLatches(SelfTbl, true)
				return
			end

			SetLatches(SelfTbl, false)
			if IsNeutral and CanNeutral then -- Neutral steering, gears follow A/D
				SetBrakes(SelfTbl, 0, 0) SetClutches(SelfTbl, CLUTCH_FLOW, CLUTCH_FLOW)
				SetTransfers(SelfTbl, A and 2 or 1, D and 2 or 1)
			else -- Normal driving, gears follow W/S
				local TransferGear = (W and 1) or (S and 2) or (A and 1) or (D and 1) or 0
				if CanNeutral then SetTransfers(SelfTbl, TransferGear, TransferGear) end

				if A and not D then -- Turn left
					SetBrakes(SelfTbl, BrakeStrength, 0) SetClutches(SelfTbl, CLUTCH_BLOCK, CLUTCH_FLOW)
				elseif D and not A then -- Turn right
					SetBrakes(SelfTbl, 0, BrakeStrength) SetClutches(SelfTbl, CLUTCH_FLOW, CLUTCH_BLOCK)
				else -- No turn
					SetBrakes(SelfTbl, 0, 0) SetClutches(SelfTbl, CLUTCH_FLOW, CLUTCH_FLOW)
				end
			end
		else
			-- Car steering
			if IsBraking or (self:GetBrakeEngagement() == 1 and not IsMoving) then -- Braking
				SetAllBrakes(SelfTbl, BrakeStrength) SetAllClutches(SelfTbl, CLUTCH_BLOCK) SetLatches(SelfTbl, true)
				return
			end

			SetLatches(SelfTbl, false)
			local TransferGear = (W and 1) or (S and 2) or (A and 1) or (D and 1) or 0
			SetAllTransfers(SelfTbl, TransferGear)
		end
	end

	--- Handles gear shifting
	function ENT:ProcessDrivetrainLowFreq(SelfTbl)
		local Gearbox = SelfTbl.Gearbox
		if not IsValid(Gearbox) then return end

		local W, S = DriverKeyDown(self.Driver, IN_FORWARD), DriverKeyDown(self.Driver, IN_BACK)

		local Gear = Gearbox.Gear
		local RPM, Count = 0, 0
		for Engine in pairs(SelfTbl.Engines) do
			if IsValid(Engine) then
				RPM = RPM + Engine.FlyRPM
				Count = Count + 1
			end
		end
		if Count > 0 then RPM = RPM / Count end

		local MinRPM, MaxRPM = self:GetShiftMinRPM(), self:GetShiftMaxRPM()
		if MinRPM == MaxRPM then return end -- Probably not set by the user
		if RPM > MinRPM then Gear = Gear + 1
		elseif RPM < MaxRPM then Gear = Gear - 1 end

		local Lower = (W and 1) or (S and SelfTbl.ForwardGearCount + 1) or 0
		local Upper = (W and SelfTbl.ForwardGearCount) or (S and SelfTbl.TotalGearCount) or 0
		Gear = math.Clamp(Gear, Lower, Upper)
		if Gear ~= SelfTbl.Gearbox.Gear then
			SelfTbl.Gearbox:TriggerInput("Gear", Gear)
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
	RecacheBindOutput(Controller, Controller, "Driver", Ply)
	RecacheBindOutput(Controller, Controller, "Active", Active and 1 or 0)

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
	if Output ~= nil then
		RecacheBindOutput(Controller, Controller, Output, Down and 1 or 0)
	end

	Controller:ToggleTurretLocks(Controller:GetTable(), Key, Down)
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
	acf_baseplate = {
		Field = "Baseplate",
		Single = true,
		OnLinked = function(Controller, Target)
			if IsValid(Target.Pod) then Controller:Link(Target.Pod) end
		end,
		OnUnlinked = function(Controller, Target)
			if IsValid(Target.Pod) then Controller:Unlink(Target.Pod) end
		end
	},
	acf_crew = {
		Field = "Crew",
		Single = true,
		OnLinked = function(Controller, Target)
			if IsValid(Target.Pod) then Controller:Link(Target.Pod) end
		end,
		OnUnlinked = function(Controller, Target)
			if IsValid(Target.Pod) then Controller:Unlink(Target.Pod) end
		end
	},
	acf_rack = {
		Field = "Racks",
		Single = false,
		OnLinked = function(Controller, Target)
			Controller:AnalyzeRacks(Target)
		end
	},
}

-- Register links to the controller with various classes
for Class, Data in pairs(LinkConfigs) do
	local Field = Data.Field
	local Single = Data.Single
	local OnLinked = Data.OnLinked
	local OnUnlinked = Data.OnUnlinked

	-- Register the link/unlink functions for each class
	ACF.RegisterClassLink("acf_controller", Class, function(Controller, Target)
		if (Single and Controller[Field]) or (not Single and Controller[Field][Target]) then return false, "Controllers can only link to one of this entity type" end
		if Controller:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "The controller is too far from this entity." end

		if Single then Controller[Field] = Target
		else Controller[Field][Target] = true end

		-- Alot of things initialize in the first tick, so wait for them to be available
		timer.Simple(0, function()
			if OnLinked then OnLinked(Controller, Target) end
		end)

		BroadcastEntity("ACF_Controller_Links", Controller, Target, true)
		Controller:UpdateOverlay()
		return true, "Controller linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_controller", Class, function(Controller, Target)
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
	local iters = 0
	function ENT:Think()
		local SelfTbl = self:GetTable()
		local Driver = SelfTbl.Driver
		if not IsValid(Driver) then return end

		if not self.Active then return end

		-- Process cameras
		local _, _, HitPos = self:ProcessCameras(SelfTbl)

		-- Aim turrets
		if iters % 4 == 0 then self:ProcessTurrets(SelfTbl, Driver, HitPos) end

		-- Fire guns
		if iters % 4 == 0 then self:ProcessGuns(SelfTbl, Driver) end

		-- Process gearboxes
		if iters % 4 == 0 then self:ProcessDrivetrain(SelfTbl, Driver) end

		local Interval = math.Round(self:GetShiftTime() * 66 / 1000)
		if iters % Interval == 0 then self:ProcessDrivetrainLowFreq(SelfTbl) end

		-- Process HUDs
		if iters % 7 == 0 then self:ProcessHUDs(SelfTbl) end

		iters = iters + 1
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