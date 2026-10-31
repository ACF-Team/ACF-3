AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local Classes     = ACF.Classes
local Contraption = ACF.Contraption
local Damage      = ACF.Damage
local RadarHelpers = ACF.RadarHelpers
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local hook        = hook


-- Tracks every currently-spawned Synchronizer so the shared ACF_OnTick hook below can advance each one's
-- rate-group counters; mirrors the ACF.ActiveRadars pattern used for standalone radars
local ActiveSyncs = {}

-- Publishes the combined BatchResults, safe to call with none. Clk only bumps when the calling batch
-- itself confirmed a detection this cycle
local function RefreshOutputs(Entity, BatchDetected)
	local LinkedCount = 0
	for Linked in pairs(Entity.Sensors) do
		if IsValid(Linked) then LinkedCount = LinkedCount + 1 end
	end
	WireLib.TriggerOutput(Entity, "Linked Sensors", LinkedCount)

	RadarHelpers.PublishTargets(Entity, Entity.BatchResults, BatchDetected)
end

-- Runs one rate-group batch and replaces the results that group owns, without touching results still
-- being reported by other rate-groups
local function RunBatch(Entity, GroupSensors)
	local BatchResults = Entity.BatchResults
	local Detections   = RadarHelpers.DetectTargets(Entity, GroupSensors)

	for Ent, Data in pairs(BatchResults) do
		if GroupSensors[Data.Sensor] and not Detections[Ent] then
			BatchResults[Ent] = nil
		end
	end

	for Ent, Data in pairs(Detections) do
		BatchResults[Ent] = Data
	end

	RefreshOutputs(Entity, next(Detections) ~= nil)
end

-- Regroups this Synchronizer's linked sensors by their exact ThinkTicks, so sensors are never sped up or
-- slowed down by another linked sensor's scan rate. Each distinct tick interval gets its own counter,
-- advanced by the shared ACF_OnTick hook below
local function RebuildRateGroups(Entity)
	local Groups = {}

	for Sensor in pairs(Entity.Sensors) do
		if not IsValid(Sensor) or not Sensor.Scanning then continue end

		local Ticks = Sensor.ThinkTicks
		Groups[Ticks] = Groups[Ticks] or { Sensors = {}, Counter = 0, ThinkTicks = Ticks }
		Groups[Ticks].Sensors[Sensor] = true
	end

	Entity.RateGroups = Groups

	-- Prune results attributed to a sensor that's no longer linked/active in any current group
	for Ent, Data in pairs(Entity.BatchResults) do
		local Group = Data.Sensor and Groups[Data.Sensor.ThinkTicks]
		local StillGrouped = Group and Group.Sensors[Data.Sensor]

		if not StillGrouped then
			Entity.BatchResults[Ent] = nil
		end
	end

	if not next(Groups) then
		-- No active linked sensors left
		RefreshOutputs(Entity, false)

		return
	end

	-- Run each group once immediately so it doesn't wait a full cycle for its first result
	for _, Group in pairs(Groups) do
		RunBatch(Entity, Group.Sensors)
	end
end

-- Advances every currently-spawned Synchronizer's rate-group counters each server tick, running a group's
-- batch every N ticks (N = that group's shared ThinkTicks), same scan rate as standalone sensors
hook.Add("ACF_OnTick", "ACF SensorSync Scan", function()
	for Entity in pairs(ActiveSyncs) do
		if not IsValid(Entity) then continue end

		for _, Group in pairs(Entity.RateGroups) do
			Group.Counter = Group.Counter + 1

			if Group.Counter >= Group.ThinkTicks then
				Group.Counter = 0

				RunBatch(Entity, Group.Sensors)
			end
		end
	end
end)

-- Watched by the link system, which unlinks and warns the owner once out of range
local function CheckLinkDistance(Sync, Sensor)
	if Sync:GetPos():DistToSqr(Sensor:GetPos()) <= MaxDistance then return true end

	return false, "The synchronizer is too far from this sensor."
end

--===============================================================================================--

-- When linked, a sensor stops running its own scan and outputs, and instead becomes a passive
-- reference point for the Synchronizer's aggregated scan
for SensorClass in pairs(ENT.ACF_SensorClasses) do
	ACF.RegisterClassLinkCheck("acf_sensorsync", SensorClass, CheckLinkDistance)

	ACF.RegisterClassLink("acf_sensorsync", SensorClass, function(Sync, Sensor)
		if IsValid(Sensor.SyncSource) then return false, "This sensor is already linked to a synchronizer!" end

		Sync.Sensors[Sensor] = true
		Sensor.SyncSource = Sync

		ACF.Hints.Set(Sync, "sensorsync_no_sensors", false)

		Sensor:StopIndependentScanning()
		Sync:RefreshRateGroups()

		Sync:UpdateOverlay()
		Sensor:UpdateOverlay()

		return true, "Sensor linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_sensorsync", SensorClass, function(Sync, Sensor)
		if not Sync.Sensors[Sensor] and Sensor.SyncSource ~= Sync then
			return false, "This sensor is not linked to this synchronizer."
		end

		Sync.Sensors[Sensor] = nil
		Sensor.SyncSource = nil

		ACF.Hints.Set(Sync, "sensorsync_no_sensors", not next(Sync.Sensors))

		Sensor:ResumeIndependentScanning()

		if IsValid(Sync) then Sync:RefreshRateGroups() end

		Sync:UpdateOverlay()
		Sensor:UpdateOverlay()

		return true, "Sensor unlinked successfully!"
	end)
end

ACF.RegisterLinkSource("acf_sensorsync", "Sensors")

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local SyncClass = "ACF.Components.SensorSync"

do -- Spawning
	function ENT:ACF_PreSpawn()
		self.ACF = {}

		local Class = Classes.GetTypeByName(SyncClass)

		Contraption.SetModel(self, Class.Model)
	end

	function ENT:ACF_OnSpawn()
		self.RateGroups   = {}
		self.BatchResults = {}
		self.TargetCount  = 0
		self.Targets      = {}
		self.TargetInfo   = {
			ID = {},
			Owner = {},
			Position = {},
			Velocity = {},
			Distance = {},
			Size = {},
			Type = {},
			Sensor = {}
		}

		ActiveSyncs[self] = true
	end

	function ENT:ACF_PostSpawn()
		ACF.Hints.Set(self, "sensorsync_no_sensors", not next(self.Sensors))
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		local Class = Classes.GetTypeByName(SyncClass)

		Contraption.SetModel(self, Class.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self.Name      = Class.Name
		self.ShortName = Class.ID
		self.EntType   = Class.Name
		self.ClassType = Class.ID
		self.ClassData = Class
		self.SoundPath = Class.Sound or ACF.DefaultRadarSound
		self.Origin    = Vector()
		self.Sensors   = self:ACF_GetUserVar("Sensors") -- Auto-registered linked field, so dupes save and restore links

		self:SetNWString("WireName", "ACF " .. self.Name)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		Contraption.SetMass(self, Class.Mass)
	end
end

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	return Damage.doPropDamage(self, DmgResult, DmgInfo)
end

function ENT:GetCost()
	return ACF.SensorSyncCost
end

function ENT:Enable() end
function ENT:Disable() end

function ENT:ACF_UpdateOverlayState(State)
	local LinkedCount = 0
	for Sensor in pairs(self.Sensors) do
		if IsValid(Sensor) then LinkedCount = LinkedCount + 1 end
	end

	if self.TargetCount > 0 then
		State:AddSuccess(self.TargetCount .. " target(s) detected")
	else
		State:AddSuccess("Active")
	end

	State:AddKeyValue("Linked sensors", LinkedCount)
end

-- Called by a linked sensor whenever its own ThinkTicks or Scanning state changes so this Synchronizer's
-- rate groups stay in sync
function ENT:RefreshRateGroups()
	RebuildRateGroups(self)
end

function ENT:OnRemove()
	for Sensor in pairs(self.Sensors) do
		self:Unlink(Sensor)
	end

	ActiveSyncs[self] = nil

	WireLib.Remove(self)
end
