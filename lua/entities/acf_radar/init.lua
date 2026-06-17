AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF
local Classes		= ACF.Classes
local Contraption	= ACF.Contraption

ACF.RegisterClassLink("acf_radar", "acf_rack", function(Radar, Target)
	if Radar.Weapons[Target] then return false, "This rack is already linked to this radar!" end
	if Target.Radar == Radar then return false, "This rack is already linked to this radar!" end

	Radar.Weapons[Target] = true
	Target.Radar = Radar

	Radar:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Rack linked successfully!"
end)

ACF.RegisterClassUnlink("acf_radar", "acf_rack", function(Radar, Target)
	if Radar.Weapons[Target] or Target.Radar == Radar then
		Radar.Weapons[Target] = nil
		Target.Radar = nil

		Radar:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Rack unlinked successfully!"
	end

	return false, "This rack is not linked to this radar."
end)

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Radars	  = ACF.ActiveRadars
local Damage      = ACF.Damage
local Sounds      = ACF.Utilities.Sounds
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local TraceData	  = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY, filter = {} }
local Indexes	  = {}
local Unused	  = {}
local IndexCount  = 0
local Trace       = ACF.trace
local TimerExists = timer.Exists
local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local hook        = hook

-- TODO: Optimize this so the entries are only cleared when the target is no longer detected by the radar
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

local function ResetOutputs(Entity)
	if Entity.TargetCount == 0 then return end

	local TargetInfo = Entity.TargetInfo

	ClearTargets(Entity)

	Entity.TargetCount = 0

	WireLib.TriggerOutput(Entity, "Detected", 0)
	WireLib.TriggerOutput(Entity, "ClosestDistance", 0)
	WireLib.TriggerOutput(Entity, "IDs", TargetInfo.ID)
	WireLib.TriggerOutput(Entity, "Owner", TargetInfo.Owner)
	WireLib.TriggerOutput(Entity, "Position", TargetInfo.Position)
	WireLib.TriggerOutput(Entity, "Velocity", TargetInfo.Velocity)
	WireLib.TriggerOutput(Entity, "Distance", TargetInfo.Distance)
	WireLib.TriggerOutput(Entity, "Size", TargetInfo.Size)
end

local function SetSequence(Entity, Active)
	local SequenceName = Active and "active" or "idle"
	local Sequence = Entity:LookupSequence(SequenceName)

	Entity:ResetSequence(Sequence or 0)

	Entity.AutomaticFrameAdvance = Active
end

local function CheckLOS(Start, End)
	TraceData.start = Start
	TraceData.endpos = End

	return not Trace(TraceData).Hit
end

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

	Entity:CallOnRemove("Radar Index", function()
		Indexes[Entity] = nil
		Unused[EntID] = true
	end)

	return EntID
end

local function GetEntityOwner(Owner, Entity)
	-- If radar info is restricted and the radar owner doesn't have permissions on this entity then return Unknown
	if ACF.RestrictRadarInfo and (not IsValid(Owner) or not Entity:CPPICanTool(Owner)) then
		return "Unknown"
	end

	local EntOwner = Entity:CPPIGetOwner()

	if not IsValid(EntOwner) then
		EntOwner = EntOwner == game.GetWorld() and "World" or "Unknown"
	else
		EntOwner = EntOwner:GetName()
	end

	return EntOwner
end

local function ScanForEntities(Entity)
	ClearTargets(Entity)

	if not Entity.GetDetected then return end

	local Detected = Entity:GetDetected()

	local Origin = Entity:LocalToWorld(Entity.Origin)
	local TargetInfo = Entity.TargetInfo
	local Targets = Entity.Targets
	local Closest = math.huge
	local Count = 0

	local IDs = TargetInfo.ID
	local Own = TargetInfo.Owner
	local Position = TargetInfo.Position
	local Velocity = TargetInfo.Velocity
	local Distance = TargetInfo.Distance
	local Size = TargetInfo.Size

	local EntDamage = Entity.Damage
	local Spread = ACF.MaxDamageInaccuracy * EntDamage

	for Ent in pairs(Detected) do
		local EntPos = Ent.ACF_Position or Ent:GetPos()

		if CheckLOS(Origin, EntPos) and (math.Rand(0, 1) >= (EntDamage / 10)) then
			local EntSpread = VectorRand(-Spread, Spread)
			local EntVel = Ent.ACF_Velocity or Ent:GetVelocity()
			local Owner = GetEntityOwner(Entity.Owner, Ent)
			local Index = GetEntityIndex(Ent)

			EntPos = EntPos + EntSpread
			EntVel = EntVel + EntSpread
			Count = Count + 1

			local EntDist = Origin:Distance(EntPos)

			local EntSize = 0
			if Ent.IsACFMissile then
				EntSize = (Ent.Caliber or 0) / ACF.InchToMm
			elseif Ent:CFW_GetContraption() then
				local Mins, Maxs, _ = Ent:CFW_GetContraption():GetAABB()
				EntSize = (Maxs - Mins):Length()
			end
			EntSize = math.Round(EntSize) -- Round to nearest inch

			Targets[Ent] = {
				Index = Index,
				Owner = Owner,
				Position = EntPos,
				Velocity = EntVel,
				Distance = EntDist,
				Spread   = EntSpread,
			}

			IDs[Count] = Index
			Own[Count] = Owner
			Position[Count] = EntPos
			Velocity[Count] = EntVel
			Distance[Count] = EntDist
			Size[Count] = EntSize

			if EntDist < Closest then
				Closest = EntDist
			end
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

	if Count ~= Entity.TargetCount then
		if Count > Entity.TargetCount then
			Sounds.SendSound(Entity, Entity.SoundPath, 70, 100, 1)
		end

		Entity.TargetCount = Count

		Entity:UpdateOverlay()
	end
end

local function SetScanning(Entity, Active)
	Entity.Scanning = Active

	Entity:UpdateOverlay()

	ResetOutputs(Entity)
	SetSequence(Entity, Active)

	Radars[Entity] = Active or nil

	WireLib.TriggerOutput(Entity, "Scanning", Active and 1 or 0)

	if Active then
		TimerCreate("ACF Radar Scan " .. Entity:EntIndex(), Entity.ThinkDelay, 0, function()
			if IsValid(Entity) and Entity.Scanning then
				return ScanForEntities(Entity)
			end

			TimerRemove("ACF Radar Scan " .. Entity:EntIndex())
		end)
	end
end

local function SetActive(Entity, Active)
	if Entity.Active == Active then return end

	Entity.Active = Active

	Entity:UpdateOverlay()

	if TimerExists("ACF Radar Switch " .. Entity:EntIndex()) then
		TimerRemove("ACF Radar Switch " .. Entity:EntIndex())
	end

	if not Active then return SetScanning(Entity, Active) end

	TimerCreate("ACF Radar Switch " .. Entity:EntIndex(), Entity.SwitchDelay, 1, function()
		if IsValid(Entity) then
			return SetScanning(Entity, Active)
		end
	end)
end

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

ACF.AddInputAction("acf_radar", "Active", function(Entity, Value)
	SetActive(Entity, tobool(Value))
end)

-- Radars must be turned off before they can be reconfigured.
hook.Add("ACF_PreUpdateEntity", "ACF Radar Update Guard", function(Class, Entity)
	if Class ~= "acf_radar" then return end
	if Entity.Active then return false, "Turn off the radar before updating it!" end
end)

ACF.RegisterLinkSource("acf_radar", "Weapons")

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local DefaultType = "ACF.Sensors.Radar.Targeting.SmallDirectional"

do -- Spawning
	function ENT:ACF_PreSpawn(_, _, _, Data)
		self.ACF = {}

		local Sensor = Data and Data.Sensor
		local Class  = Classes.GetTypeByName(Sensor and Sensor.Type or DefaultType) or Classes.GetTypeByName(DefaultType)

		Contraption.SetModel(self, Class.Model)
	end

	function ENT:ACF_OnSpawn()
		self.Active      = false
		self.Scanning    = false
		self.TargetCount = 0
		self.Damage      = 0
		self.Weapons     = {}
		self.Targets     = {}
		self.TargetInfo  = {
			ID = {},
			Owner = {},
			Position = {},
			Velocity = {},
			Distance = {},
			Size = {}
		}

		TimerCreate("ACF Radar Clock " .. self:EntIndex(), 3, 0, function()
			if not IsValid(self) then return end

			CheckDistantLinks(self, "Weapons")
		end)
	end

	function ENT:ACF_PostSpawn()
		WireLib.TriggerOutput(self, "Entity", self)

		-- Radars should be active by default
		self:TriggerInput("Active", 1)
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		local Sensor = self:ACF_GetUserVar("Sensor")
		local Class  = Sensor:GetType()
		local Group  = Classes.GetBaseClass(Class)
		local Tick   = engine.TickInterval()
		local Delay  = Sensor.ThinkDelay

		Contraption.SetModel(self, Sensor.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		local OriginAttach = self:LookupAttachment(Sensor.Origin)
		local AttachData   = self:GetAttachment(OriginAttach)

		self.Name         = Sensor.Name
		self.ShortName    = Sensor.ID
		self.EntType      = Group.Name
		self.ClassType    = Group.ID
		self.SoundPath    = Sensor.Sound or ACF.DefaultRadarSound
		self.DefaultSound = self.SoundPath
		self.ConeDegs     = Sensor.ViewCone
		self.Range        = Sensor.Range
		self.SwitchDelay  = Sensor.SwitchDelay
		self.ThinkDelay   = math.Round(Delay / Tick) * Tick -- Uses a timer, so has to be tied to CurTime/tickrate
		self.GetDetected  = Sensor.Detect
		self.Origin       = AttachData and self:WorldToLocal(AttachData.Pos) or Vector()

		self:SetNWString("WireName", "ACF " .. self.Name)

		WireLib.TriggerOutput(self, "Think Delay", self.ThinkDelay)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		Contraption.SetMass(self, Sensor.Mass)
	end
end

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	self.Damage = (1 - math.Round(self.ACF.Health / self.ACF.MaxHealth, 2))

	return HitRes
end

function ENT:ACF_OnRepaired() -- OldArmor, OldHealth, Armor, Health
	self.Damage = (1 - math.Round(self.ACF.Health / self.ACF.MaxHealth, 2))
end

function ENT:GetCost()
	local selftbl	= self:GetTable()

	local Scalar = 1
	local Cost = 0

	if selftbl.ClassType == "AM-Radar" then Scalar = 0.5 end

	if selftbl.Range then	--
		Cost = 10 * (selftbl.Range / 4096)
	else -- ConeDegs
		Cost = selftbl.ConeDegs
	end

	return Cost * Scalar
end

function ENT:Enable()
	if not ACF.CheckLegal(self) then return end

	if self.Inputs.Active.Path then
		self:TriggerInput("Active", self.Inputs.Active.Value)
	end

	self:UpdateOverlay()
end

function ENT:Disable()
	self:TriggerInput("Active", 0)
end

function ENT:ACF_UpdateOverlayState(State)
	if self.TargetCount > 0 then
		State:AddSuccess(self.TargetCount .. " target(s) detected")
	elseif not self.Active then
		State:AddWarning("Idle")
	else
		if self.Scanning then
			State:AddSuccess("Active")
		else
			State:AddWarning("Activating")
		end
	end

	State:AddKeyValue("Detection range", self.Range and math.Round(self.Range / ACF.MeterToInch, 2) .. " meters" or "Infinite")
	State:AddNumber("Scanning angle", self.ConeDegs and math.Round(self.ConeDegs, 2) or 360)
end

function ENT:OnRemove()
	for Weapon in pairs(self.Weapons or {}) do
		self:Unlink(Weapon)
	end

	if Radars[self] then
		Radars[self] = nil
	end

	timer.Remove("ACF Radar Clock " .. self:EntIndex())
end

do	-- Overlay/networking
	util.AddNetworkString("ACF.RequestRadarInfo")
	net.Receive("ACF.RequestRadarInfo", function(_, Ply)
		local Radar = net.ReadEntity()
		if not IsValid(Radar) then return end

		local RadarInfo	= {}
		RadarInfo.Spherical = (Radar.ConeDegs == nil) and true or false
		RadarInfo.Cone	= Radar.ConeDegs and math.Round(Radar.ConeDegs, 2) or 0
		RadarInfo.Range	= Radar.Range and math.Round(Radar.Range, 2) or 0
		RadarInfo.Origin	= Radar.Origin

		net.Start("ACF.RequestRadarInfo")
			net.WriteEntity(Radar)
			net.WriteString(util.TableToJSON(RadarInfo))
		net.Send(Ply)
	end)
end
