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
util.AddNetworkString("ACF_Controller_Radar")	-- Relay radar data

local Clock = Utilities.Clock
local Defaults = include("modules/defaults.lua")
include("modules_sh/helpers_sh.lua")

local ControllerLinkRegistry = {}
function ACF.RegisterControllerLink(Class, Config)
	ControllerLinkRegistry[Class] = Config
end

local ModuleInits = {}
local function RegisterServerModule(InitFn)
	if InitFn then ModuleInits[#ModuleInits + 1] = InitFn end
end

RegisterServerModule(include("modules/seat.lua"))
RegisterServerModule(include("modules/drivetrain.lua"))
RegisterServerModule(include("modules/fire_control.lua"))
RegisterServerModule(include("modules/camera.lua"))
RegisterServerModule(include("modules/ammo.lua"))
RegisterServerModule(include("modules/receivers.lua"))
RegisterServerModule(include("modules/radar.lua"))
RegisterServerModule(include("modules/hud.lua"))
RegisterServerModule(include("modules/overlay.lua"))

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
		"CamParent (The entity the camera is parented to) [ENTITY]",
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
		if not Player:CheckLimit("_acf_controller") then return false end

		local CanSpawn	= HookRun("ACF_PreSpawnEntity", "acf_controller", Player, Data)
		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_controller")
		if not IsValid(Entity) then return end

		Entity:SetPlayer(Player)
		Entity:SetAngles(Ang)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Player:AddCleanup("acf_controller", Entity)
		Player:AddCount("_acf_controller", Entity)

		Entity.Name = "ACF AIO Controller"
		Entity.ShortName = "ACF AIO Controller"
		Entity.EntType = "ACF AIO Controller"

		Entity.Driver    = nil
		Entity.Active    = false
		Entity.KeyStates = {}

		for _, Init in ipairs(ModuleInits) do Init(Entity) end

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

	function ENT:ACF_PostMenuSpawn()
		ACF.DropToFloor(self)
		self:SetAngles(self:GetAngles() + Angle(0, -90, 0))
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

		if iters % SelfTbl.RadarUpdateRate == 0 then self:ProcessRadars(SelfTbl) end

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
		for _, Data in pairs(ControllerLinkRegistry) do
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

		for _, Data in pairs(ControllerLinkRegistry) do
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

		for _, Data in pairs(ControllerLinkRegistry) do
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