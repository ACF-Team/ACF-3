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
AddCSLuaFile("modules/defaults.lua") -- Read by the ponder proxy of the settings menu

AddCSLuaFile("modules_sh/helpers_sh.lua")
AddCSLuaFile("modules_sh/binds_sh.lua")

-- Localizations
local ACF = ACF
local Utilities   = ACF.Utilities
local Contraption = ACF.Contraption
local MaxDistance  = ACF.LinkDistance * ACF.LinkDistance

util.AddNetworkString("ACF_Controller_Links")	-- Relay links to client
util.AddNetworkString("ACF_Controller_Active")	-- Relay active state to client
util.AddNetworkString("ACF_Controller_CamInfo")	-- Relay entities and camera modes
util.AddNetworkString("ACF_Controller_CamData")	-- Relay camera updates
util.AddNetworkString("ACF_Controller_Zoom")	-- Relay camera zooms
util.AddNetworkString("ACF_Controller_Ammo")	-- Relay ammo counts
util.AddNetworkString("ACF_Controller_Receivers")	-- Relay LWS/RWS data
util.AddNetworkString("ACF_Controller_Radar")	-- Relay radar data
util.AddNetworkString("ACF_Controller_Button")	-- Forward button presses and releases to the client, PlayerButtonDown/Up don't fire client side in singleplayer
util.AddNetworkString("ACF_Controller_Action")	-- Receive rebound keyboard actions from the client

local Clock = Utilities.Clock
local Defaults = include("modules/defaults.lua")
include("modules_sh/helpers_sh.lua")
include("modules_sh/binds_sh.lua") -- Reads the helpers above, and must precede the modules that register bind handlers

local ControllerLinkRegistry = {}
function ACF.RegisterControllerLink(Class, Config)
	ControllerLinkRegistry[Class] = Config
end

-- https://wiki.facepunch.com/gmod/Enums/IN
local KEY_WIRE_BINDINGS = {
	{ IN_FORWARD,   "W" },
	{ IN_MOVELEFT,  "A" },
	{ IN_BACK,      "S" },
	{ IN_MOVERIGHT, "D" },
	{ IN_ATTACK,    "Mouse1" },
	{ IN_ATTACK2,   "Mouse2" },
	{ IN_RELOAD,    "R" },
	{ IN_JUMP,      "Space" },
	{ IN_SPEED,     "Shift" },
	{ IN_ZOOM,      "Zoom" },
	{ IN_WALK,      "Alt" },
	{ IN_DUCK,      "Duck" },
}
ACF.ControllerKeyBindings = KEY_WIRE_BINDINGS

local Inputs = {
	"Filter (Filters out entities from the camera trace) [ARRAY]",
	"FLIR (Enables/disables FLIR while in the baseplate seat)",
	"ParkingBrake (Enables brakes and disables mobility when 1, releases brakes and re-enables mobility when 0)"
}

local ADDITIONAL_OUTPUTS = {
	"HitPos (The position the driver is looking at) [VECTOR]",
	"CamAng (The direction of the camera.) [ANGLE]",
	"CamIndex (The currently active camera index)",
	"IsTurretLocked (Whether the turret is locked or not.)",
	"Active",
	"Speed (Determined by selected unit)",
	"Driver (The player driving the vehicle.) [ENTITY]",
	"CamParent (The entity the camera is parented to) [ENTITY]",
	"Entity (The controller entity itself) [ENTITY]",
}

local Outputs = {}
for _, Binding in ipairs(KEY_WIRE_BINDINGS) do
	Outputs[#Outputs + 1] = Binding[2]
end
table.Add(Outputs, ADDITIONAL_OUTPUTS)

ENT.ACF_StaticWireInputs  = Inputs
ENT.ACF_StaticWireOutputs = Outputs

local ModuleInits = {}
local function RegisterServerModule(InitFn)
	if InitFn then ModuleInits[#ModuleInits + 1] = InitFn end
end

RegisterServerModule(include("modules/seat.lua"))
RegisterServerModule(include("modules/camera.lua"))
RegisterServerModule(include("modules/fire_control.lua"))
RegisterServerModule(include("modules/drivetrain.lua"))
RegisterServerModule(include("modules/ammo.lua"))
RegisterServerModule(include("modules/receivers.lua"))
RegisterServerModule(include("modules/radar.lua"))
RegisterServerModule(include("modules/hud.lua"))
RegisterServerModule(include("modules/overlay.lua"))

do
	-- Menu spawn requests the default network-var config; stash it for PostUpdate to apply.
	function ENT.ACF_OnVerifyClientData(ClientData)
		if ClientData.AIOUseDefaults then
			ClientData.AIODefaults = Defaults
		end
	end

	function ENT.ACF_CheckSpawnLimit(Player)
		return Player:CheckLimit("_acf_controller")
	end

	function ENT:ACF_PreSpawn(Player)
		self.ACF          = {}
		self.Driver       = nil
		self.Active       = false
		self.KeyStates    = {}
		self.ActionStates = {}
		self.ActionLatches = {}
		self.ActionMask   = 0

		self.ACF.Model = "models/hunter/plates/plate025x025.mdl"
		self:SetModel("models/hunter/plates/plate025x025.mdl")
		self:SetPlayer(Player)

		for _, Init in ipairs(ModuleInits) do Init(self) end
	end

	function ENT:ACF_PostUpdateEntityData(ClientData)
		self.ACF = self.ACF or {}
		self.ACF.Model = "models/hunter/plates/plate025x025.mdl"
		self:SetModel("models/hunter/plates/plate025x025.mdl")

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:ACF_SetEntityName("ACF All In One Controller")

		ACF.Activate(self, true)

		local PhysObj = self.ACF.PhysObj
		if IsValid(PhysObj) then Contraption.SetMass(self, 1) end

		if ClientData and ClientData.AIODefaults then self:RestoreNetworkVars(ClientData.AIODefaults) end
	end

	function ENT:ACF_PostSpawn()
		ACF.AugmentedTimer(function(_) self:UpdateParentHint() self:RefreshDrivetrain() self:UpdateDrivetrainHints() self:UpdateOverlay() end, function() return IsValid(self) end, nil, {MinTime = 1, MaxTime = 1})
	end

	function ENT:ACF_PostMenuSpawn()
		ACF.DropToFloor(self)
		self:SetAngles(self:GetAngles() + Angle(0, -90, 0))
	end

	function ENT:FLIR_OnEnter(Player)
		if not IsValid(Player) then return end
		if self.UseWireFLIR then
			FLIR.start(Player)
		end
	end

	function ENT:FLIR_OnChange(Value)
		local Player = self.Driver
		if not IsValid(Player) then return end

		FLIR.enable(Player, Value)
	end

	function ENT:FLIR_OnExit(Player)
		if not IsValid(Player) then return end
		if self.UseWireFLIR then
			FLIR.stop(Player)
		end
	end

	-- Handle Inputs
	do
		ACF.AddInputAction("acf_controller", "Filter", function(Controller, Value)
			if Value == nil or not istable(Value) then Controller.UsesWireFilter = false return end
			Controller.UsesWireFilter = true
			Controller.Filter = Value
		end)

		ACF.AddInputAction("acf_controller", "FLIR", function(Controller, Value)
			if Value == nil or not isnumber(Value) then return end
			Controller.UseWireFLIR = Value ~= 0
			Controller:FLIR_OnChange(Value ~= 0)
		end)

		ACF.AddInputAction("acf_controller", "ParkingBrake", function(Controller, Value)
			if Value == nil or not isnumber(Value) then return end
			Controller:SetWireParkingBrake(Controller:GetTable(), Value ~= 0)
		end)
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

-- Register links to the controller with various classes
for Class, Data in pairs(ControllerLinkRegistry) do
	local Field = Data.Field
	local Single = Data.Single
	local PreLink = Data.PreLink
	local OnLinked = Data.OnLinked
	local OnUnlinked = Data.OnUnlinked

	-- Register the link/unlink functions for each class
	ACF.RegisterClassLink("acf_controller", Class, function(Controller, Target)
		if Controller:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "The controller is too far from this entity." end
		local Linked = Controller:ACF_GetUserVar(Field)

		if Single and IsValid(Linked) then return false, "This controller is already linked to another entity of this type." end
		if not Single and Linked[Target] then return false, "This controller is already linked to this entity." end

		if Single then Controller:ACF_SetUserVar(Field, Target)
		else Linked[Target] = true end

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
		local Linked = Controller:ACF_GetUserVar(Field)

		if Single and Linked ~= Target then return false, "This controller is not linked to this entity." end
		if not Single and not Linked[Target] then return false, "This controller is not linked to this entity." end

		if Single then Controller:ACF_SetUserVar(Field, nil)
		else Linked[Target] = nil end

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

		if iters % 4 == 0 then self:RegroupWeapons() end

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

		if iters % SelfTbl.RadarUpdateRate == 0 then self:ProcessRadars(SelfTbl) end
		self:ProcessRadarSlaving(SelfTbl)

		SelfTbl.iters = iters + 1
		self:UpdateOverlay()
		self:NextThink(Clock.CurTime)
		return true
	end

end

-- Adv Dupe 2 Related
do
	local EntityVars = {"Gun1", "Gun2", "Gun3", "Cam1Parent", "Cam2Parent", "Cam3Parent"}

	function ENT:PreEntityCopy()
		local UserData = self.ACF_UserData
		if not UserData then return end

		for _, Name in ipairs(EntityVars) do
			local Target = self["Get" .. Name](self)

			UserData[Name] = IsValid(Target) and Target:EntIndex() or -1
		end
	end

	function ENT:PostEntityPaste(_, Ent)
		local UserData = ACF.DupeTable(Ent.ACF_UserData)

		for _, Name in ipairs(EntityVars) do
			if UserData[Name] ~= nil then self["Set" .. Name](self, self:ACF_GetUserVar(Name)) end
		end
	end
end