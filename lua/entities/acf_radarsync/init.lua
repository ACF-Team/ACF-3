AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local Classes     = ACF.Classes
local Contraption = ACF.Contraption
local Damage      = ACF.Damage
local Sounds      = ACF.Utilities.Sounds
local RadarHelpers = ACF.RadarHelpers
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local hook        = hook

-- Tracks every currently-spawned Synchronizer so the shared ACF_OnTick hook below can advance each one's
-- rate-group counters; mirrors the ACF.ActiveRadars pattern used for standalone radars
local ActiveSyncs = {}

-- Uses the same stable per-target integer ID scheme as acf_radar (own pool, not shared), so IDs stay
-- consistent for a target across scans within this synchronizer
local Indexes = {}
local Unused  = {}
local IndexCount = 0

local function GetEntityIndex(Entity)
	if Indexes[Entity] then return Indexes[Entity] end

	if next(Unused) then
		local Index = next(Unused)

		Indexes[Entity] = Index
		Unused[Index] = nil
	else
		IndexCount = IndexCount + 1

		Indexes[Entity] = IndexCount
	end

	local EntID = Indexes[Entity]

	Entity:CallOnRemove("RadarSync Index", function()
		Indexes[Entity] = nil
		Unused[EntID] = true
	end)

	return EntID
end

local function ClearTargets(Entity)
	local TargetInfo = Entity.TargetInfo
	local Targets = Entity.Targets

	for Target in pairs(Targets) do
		Targets[Target] = nil
	end

	for _, List in pairs(TargetInfo) do
		for Index in ipairs(List) do
			List[Index] = nil
		end
	end
end

-- Picks, among the radars that matched a candidate within one rate-group batch, the healthiest
-- one to attribute the candidate's detection roll/spread/LOS origin to
local function GetBestMatchingRadar(MatchedRadars)
	local Best, BestDamage

	for _, Radar in ipairs(MatchedRadars) do
		local RadarDamage = Radar.Damage or 0

		if not Best or RadarDamage < BestDamage then
			Best = Radar
			BestDamage = RadarDamage
		end
	end

	return Best
end

-- Rewrites this Synchronizer's combined Targets/TargetInfo from the current BatchResults snapshot and
-- re-fires wire outputs. Safe to call with an empty BatchResults (e.g. all radars unlinked). Clk only
-- bumps when the calling batch itself confirmed a detection this cycle
local function RefreshOutputs(Entity, BatchDetected)
	local TargetInfo = Entity.TargetInfo
	local Targets = Entity.Targets

	ClearTargets(Entity)

	local IDs = TargetInfo.ID
	local Own = TargetInfo.Owner
	local Position = TargetInfo.Position
	local Velocity = TargetInfo.Velocity
	local Distance = TargetInfo.Distance
	local Size = TargetInfo.Size
	local Type = TargetInfo.Type
	local Sensor = TargetInfo.Sensor
	local Closest = math.huge
	local Count = 0

	for Ent, Data in pairs(Entity.BatchResults) do
		local Index = GetEntityIndex(Ent)

		Count = Count + 1

		Targets[Ent] = {
			Index    = Index,
			Owner    = Data.Owner,
			Position = Data.Position,
			Velocity = Data.Velocity,
			Distance = Data.Distance,
			Spread   = Data.Spread,
			Type     = Data.Type,
			Sensor   = Data.FromRadar,
		}

		IDs[Count] = Index
		Own[Count] = Data.Owner
		Position[Count] = Data.Position
		Velocity[Count] = Data.Velocity
		Distance[Count] = Data.Distance
		Size[Count] = Data.Size
		Type[Count] = Data.Type
		Sensor[Count] = Data.FromRadar

		if Data.Distance < Closest then
			Closest = Data.Distance
		end
	end

	Closest = Closest < math.huge and Closest or 0

	WireLib.TriggerOutput(Entity, "ClosestDistance", Closest)
	WireLib.TriggerOutput(Entity, "IDs", IDs)
	WireLib.TriggerOutput(Entity, "Owner", Own)
	WireLib.TriggerOutput(Entity, "Position", Position)
	WireLib.TriggerOutput(Entity, "Velocity", Velocity)
	WireLib.TriggerOutput(Entity, "Distance", Distance)
	WireLib.TriggerOutput(Entity, "Detected", Count)
	WireLib.TriggerOutput(Entity, "Size", Size)
	WireLib.TriggerOutput(Entity, "Type", Type)
	WireLib.TriggerOutput(Entity, "Sensor", Sensor)

	local LinkedCount = 0
	for Radar in pairs(Entity.Radars) do
		if IsValid(Radar) then LinkedCount = LinkedCount + 1 end
	end
	WireLib.TriggerOutput(Entity, "Linked Radars", LinkedCount)

	-- Only bump Clk when this specific batch confirmed a detection
	if BatchDetected then
		WireLib.TriggerOutput(Entity, "Clk", engine.TickCount())
	end

	if Count ~= Entity.TargetCount then
		if Count > Entity.TargetCount then
			Sounds.SendSound(Entity, Entity.SoundPath, 70, 100, 1)
		end

		Entity.TargetCount = Count

		Entity:UpdateOverlay()
	end

	-- Guidance packages read a rack-linked radar's own .Targets/.TargetCount directly; mirror this
	-- Synchronizer's combined results back onto every currently-linked radar so a rack linked to any one
	-- of them transparently sees the aggregated picture with no guidance-side changes needed
	for Radar in pairs(Entity.Radars) do
		if not IsValid(Radar) then continue end

		Radar.Targets = Targets
		Radar.TargetCount = Count
	end
end

-- Runs one rate-group batch: gathers all its radars' geometry into one ACF.GetEntitiesInShapes /
-- Countermeasures.GetMissilesInShapes call (single pass over the tracked pools instead of one pass per
-- radar), resolves overlaps to the healthiest matching radar, then refreshes this Synchronizer's combined
-- Targets/TargetInfo from the union of all rate-groups' most recent results and re-fires wire outputs.
-- Radars are split into separate contraption/missile shape lists per their own DetectContraptions/
-- DetectMissiles settings, so a radar that can't see missiles never contributes to missile detection here
-- (and likewise for a radar that can't see contraptions); mirrors the per-radar gating in radar.lua
local function RunBatch(Entity, GroupRadars)
	local Countermeasures = ACF.Countermeasures
	local ContraptionShapes = {}
	local MissileShapes = {}

	for Radar in pairs(GroupRadars) do
		if not IsValid(Radar) or Radar.ACF.Health <= 0 then continue end

		local Origin = Radar:LocalToWorld(Radar.Origin)
		local Shape

		if Radar.ConeDegs then
			Shape = { Radar = Radar, Position = Origin, Direction = Radar:GetForward(), Degrees = Radar.ConeDegs }
		else
			Shape = { Radar = Radar, Position = Origin, Radius = Radar.Range }
		end

		if Radar.DetectContraptions then ContraptionShapes[#ContraptionShapes + 1] = Shape end
		if Radar.DetectMissiles then MissileShapes[#MissileShapes + 1] = Shape end
	end

	if #ContraptionShapes == 0 and #MissileShapes == 0 then return RefreshOutputs(Entity, false) end

	local Matches = #ContraptionShapes > 0 and ACF.GetEntitiesInShapes(ContraptionShapes) or {}

	if #MissileShapes > 0 then
		for Ent, MatchedRadars in pairs(Countermeasures.GetMissilesInShapes(MissileShapes)) do
			local List = Matches[Ent]

			if not List then
				Matches[Ent] = MatchedRadars
			else
				for _, Radar in ipairs(MatchedRadars) do
					List[#List + 1] = Radar
				end
			end
		end
	end

	local Confirmed = {}

	for Ent, MatchedRadars in pairs(Matches) do
		local Radar = GetBestMatchingRadar(MatchedRadars)
		if not Radar then continue end

		local Origin = Radar:LocalToWorld(Radar.Origin)
		local EntPos = Ent.ACF_Position or Ent:GetPos()

		if not RadarHelpers.CheckLOS(Origin, EntPos) then continue end

		local EntDamage = Radar.Damage or 0
		if math.Rand(0, 1) < (EntDamage / 10) then continue end

		local EntDist = Origin:Distance(EntPos)
		local EntSize, EntType = RadarHelpers.GetEntSizeAndType(Ent)

		if EntSize < RadarHelpers.GetMinDetectableSize(Radar, EntDist) then continue end

		local Spread = ACF.MaxDamageInaccuracy * EntDamage
		local EntSpread = VectorRand(-Spread, Spread)
		local EntVel = Ent.ACF_Velocity or Ent:GetVelocity()

		Confirmed[Ent] = true

		Entity.BatchResults[Ent] = {
			Owner    = RadarHelpers.GetEntityOwner(Entity.Owner, Ent),
			Position = EntPos + EntSpread,
			Velocity = EntVel + EntSpread,
			Distance = EntDist,
			Size     = EntSize,
			Type     = EntType,
			Spread   = EntSpread,
			FromRadar = Radar,
		}
	end

	-- Drop stale results this rate-group no longer confirms (failed LOS/damage-roll/min-size this cycle,
	-- or moved out of every linked radar's zone), without touching results still being reported by other
	-- rate-groups
	for Ent, Data in pairs(Entity.BatchResults) do
		if GroupRadars[Data.FromRadar] and not Confirmed[Ent] then
			Entity.BatchResults[Ent] = nil
		end
	end

	RefreshOutputs(Entity, next(Confirmed) ~= nil)
end

-- Regroups this Synchronizer's linked radars by their exact ThinkTicks, so radars are never sped up or
-- slowed down by another linked radar's scan rate. Each distinct tick interval gets its own counter, 
-- advanced by the shared ACF_OnTick hook below
local function RebuildRateGroups(Entity)
	local Groups = {}

	for Radar in pairs(Entity.Radars) do
		if not IsValid(Radar) or not Radar.Active then continue end

		local Ticks = Radar.ThinkTicks
		Groups[Ticks] = Groups[Ticks] or { Radars = {}, Counter = 0, ThinkTicks = Ticks }
		Groups[Ticks].Radars[Radar] = true
	end

	Entity.RateGroups = Groups

	-- Prune results attributed to a radar that's no longer linked/active in any current group
	for Ent, Data in pairs(Entity.BatchResults) do
		local Group = Data.FromRadar and Groups[Data.FromRadar.ThinkTicks]
		local StillGrouped = Group and Group.Radars[Data.FromRadar]

		if not StillGrouped then
			Entity.BatchResults[Ent] = nil
		end
	end

	if not next(Groups) then
		-- No active linked radars left
		RefreshOutputs(Entity, false)

		return
	end

	-- Run each group once immediately so it doesn't wait a full cycle for its first result
	for _, Group in pairs(Groups) do
		RunBatch(Entity, Group.Radars)
	end
end

-- Advances every currently-spawned Synchronizer's rate-group counters each server tick, running a group's
-- batch every N ticks (N = that group's shared ThinkTicks), same scan rate as standalone radars
hook.Add("ACF_OnTick", "ACF RadarSync Scan", function()
	for Entity in pairs(ActiveSyncs) do
		if not IsValid(Entity) then continue end

		for _, Group in pairs(Entity.RateGroups) do
			Group.Counter = Group.Counter + 1

			if Group.Counter >= Group.ThinkTicks then
				Group.Counter = 0

				RunBatch(Entity, Group.Radars)
			end
		end
	end
end)

local function CheckDistantLinks(Entity, Source)
	local Position = Entity:GetPos()

	for Link in pairs(Entity[Source]) do
		if Position:DistToSqr(Link:GetPos()) > MaxDistance then
			local Sound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(Entity, Sound, 70, 100, 1)
			Sounds.SendSound(Link, Sound, 70, 100, 1)

			Entity:Unlink(Link)
		end
	end
end

--===============================================================================================--

ACF.RegisterLinkSource("acf_radarsync", "Radars")

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local SyncClass = "ACF.Components.RadarSync"

do -- Spawning
	function ENT:ACF_PreSpawn()
		self.ACF = {}

		local Class = Classes.GetTypeByName(SyncClass)

		Contraption.SetModel(self, Class.Model)
	end

	function ENT:ACF_OnSpawn()
		self.Radars       = {}
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

		TimerCreate("ACF RadarSync Clock " .. self:EntIndex(), 3, 0, function()
			if not IsValid(self) then return end

			CheckDistantLinks(self, "Radars")
		end)
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
	return ACF.RadarSyncCost
end

function ENT:Enable() end
function ENT:Disable() end

function ENT:ACF_UpdateOverlayState(State)
	local LinkedCount = 0
	for Radar in pairs(self.Radars) do
		if IsValid(Radar) then LinkedCount = LinkedCount + 1 end
	end

	if self.TargetCount > 0 then
		State:AddSuccess(self.TargetCount .. " target(s) detected")
	elseif LinkedCount == 0 then
		State:AddWarning("No radars linked")
	else
		State:AddSuccess("Active")
	end

	State:AddKeyValue("Linked radars", LinkedCount)
end

-- Called by a linked radar whenever its own ThinkTicks changes (spawn, update, or when a radar with a
-- different rate joins/leaves) so this Synchronizer's rate groups stay in sync
function ENT:RefreshRateGroups()
	RebuildRateGroups(self)
end

function ENT:OnRemove()
	for Radar in pairs(self.Radars) do
		self:Unlink(Radar)
	end

	ActiveSyncs[self] = nil

	TimerRemove("ACF RadarSync Clock " .. self:EntIndex())

	WireLib.Remove(self)
end
