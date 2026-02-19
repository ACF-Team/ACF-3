--[[
This defines the major serverside logic for the controller entity.

Supported Drivetrains:
- Must have a single "main" gearbox that does the heavy lifting, e.g. a CVT transax.


]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Client modules
AddCSLuaFile("modules_cl/overlay.lua")
AddCSLuaFile("modules_cl/camera.lua")
AddCSLuaFile("modules_cl/hud.lua")

AddCSLuaFile("modules_sh/helpers_sh.lua")

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

local Clock = Utilities.Clock
local Defaults = include("modules/defaults.lua")
include("modules_sh/helpers_sh.lua")

local RecacheBindState = ENT.RecacheBindState
local RecacheBindOutput = ENT.RecacheBindOutput

include("modules/drivetrain.lua")
include("modules/ammo.lua")
include("modules/camera.lua")
include("modules/hud.lua")
include("modules/fire_control.lua")
include("modules/overlay.lua")

do
	local Inputs = {
		"Filter (Filters out entities from the camera trace) [ARRAY]",
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
		-- Reset computer lase
		if Controller.Driver:KeyDown( IN_DUCK ) then
			Controller.Additive = vector_origin
			Controller.LaseDist = 0
			Controller.LasePitch = 0
			Controller.Drop = 0
			Controller.TravelTime = 0
			return
		end

		-- Otherwise log metrics on lase, and use these later
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
			if Value == nil or not istable(Value) then return end
			Controller.UsesWireFilter = true
			Controller.Filter = Value
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

		-- Handle camera entity selection
		local Parent1 = IsValid(self:GetCam1Parent()) and self:GetCam1Parent():EntIndex() or 0
		local Parent2 = IsValid(self:GetCam2Parent()) and self:GetCam2Parent():EntIndex() or 0
		local Parent3 = IsValid(self:GetCam3Parent()) and self:GetCam3Parent():EntIndex() or 0
		duplicator.StoreEntityModifier(self, "CamParents", {Parent1, Parent2, Parent3})

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

		-- Handle camera parent entities
		if EntMods.CamParents then
			self:SetCam1Parent(CreatedEntities[EntMods.CamParents[1]])
			self:SetCam2Parent(CreatedEntities[EntMods.CamParents[2]])
			self:SetCam3Parent(CreatedEntities[EntMods.CamParents[3]])
			EntMods.CamParents = nil
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