--[[
This file contains most of the crew type/model agnostic logic for crew members.
Crew type specific logic is possible via functions like OnLink, OnUnLink, UpdateLowFreq, etc specified externally.

Note about spatial scanning:
Spatial scans are conducted using hull traces from the crew's torso outwards to the corners, edge midpoints and face midpoints (27 total) of a box.
The average of all the lengths is used as an approximation of how much of the box's space the crew occupies, and represents how much space they have vs how much they need.
For optimizaion reasons, a set number of lengths are rescanned every so often and using the older scans, the average is updated.
More accurate but intensive methods exist; we found this to be the most efficient.

Files with crew logic:
lua/acf/entities/crew_types/crew_types.lua		(Defines crew type specific properties and logic)
lua/acf/entities/crew_types/crew_models.lua		(Defines crew model specific properties and logic)
lua/acf/entities/acf_crew/init.lua				(SV crew code)
lua/acf/entities/acf_crew/cl_init.lua			(CL crew code)
lua/acf/entities/acf_crew/shared.lua			(SH crew code)
lua/entities/acf_gun/init.lua					(Gunner/loader/commander interaction with guns)
lua/entities/acf_ammo/init.lua					(Loader interaction with ammo for restocking)
lua/entities/acf_engine/init.lua				(Driver interaction with engines)

Note on common contraption checks:
When checks that verify two entities are a part of the same contraption have a vacuous case.
If both entities don't have a contraption (aren't linked) then the check passes. 
This is for normal building QOL and since CFW doesn't have a notion of when a contraption is "finished" being built.
]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--
local ACF = ACF
local HookRun     = hook.Run
local HookRemove     = hook.Remove
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock
local WireIO      = Utilities.WireIO

local Contraption = ACF.Contraption
local hook	   = hook
local Classes	= ACF.Classes
local CrewTypes = Classes.CrewTypes
local CrewModels = Classes.CrewModels
local Entities   = Classes.Entities
local CheckLegal = ACF.CheckLegal
local TraceHull = util.TraceHull
local TimerSimple	= timer.Simple

--- Helper function that generates scanning information for the crew member
local function GenerateScanSetup()
	local directions = {}
	local lengths = {}
	for i = -1, 1 do
		for j = -1, 1 do
			for k = -1, 1 do
				table.insert(directions, Vector(i, j, k))
				table.insert(lengths, 0)
			end
		end
	end
	return directions, lengths, #directions
end

--- Helper function that runs a hull trace between two points
local function traceVisHullCube(pos1, pos2, boxsize, filter)
	local res = TraceHull({
		start = pos1,
		endpos = pos2,
		filter = filter,
		mins = -boxsize / 2,
		maxs = boxsize / 2
	})

	local length = pos1:Distance(pos2)
	local truelength = res.Fraction * length
	return res.Fraction, length, truelength, res.HitPos
end

--- Helper function that Scans the space around the crew member by updating 
local function iterScan(crew, reps)
	local localoffset = crew.CrewModel.ScanOffsetL
	local center = crew:LocalToWorld(localoffset)
	local count = crew.ScanCount

	local Box = crew.ScanBoxBase + crew.ScanBox
	local Hull = crew.ScanHull

	-- Filter out players and other people's props
	local filter = function(x) return not (x == crew or x:GetOwner() ~= crew:GetOwner() or x:IsPlayer()) end

	-- Update reps hull traces
	for i = 1, reps do
		-- Perform hull trace from scan center to corner of box
		local index = crew.ScanIndex
		local disp = crew.ScanDisplacements[index]
		local p1 = center
		local corner = Vector(disp.x * Box.x / 2, disp.y * Box.y / 2, disp.z * Box.z / 2)
		local p2 = crew:LocalToWorld(localoffset + corner)

		local frac, _, _, hitpos = traceVisHullCube(p1, p2, Hull, filter)
		crew.ScanLengths[index] = frac

		debugoverlay.Line(p1, hitpos, 1, Color(255, 0, 0))
		debugoverlay.Line(hitpos, p2, 1, Color(0, 255, 0))
		debugoverlay.Box( hitpos, -Hull/2, Hull/2, 10, Color(0,255,255,100) )

		-- Save the index for the next iteration. Loop around if needed.
		index = index  + 1
		if index > count then index = 1 end
		crew.ScanIndex = index
	end
	debugoverlay.BoxAngles( crew:LocalToWorld(localoffset), -Box/2, Box/2, crew:GetAngles(), 1, Color(0,0,255,100) )

	-- Update using new and saved scan lengths
	local sum = 0
	for i = 1, count do sum = sum + crew.ScanLengths[i] end
	return sum / count
end

--- Check other crews of the same type and enforce convar limits
local function EnforceLimits(crew)
	local CrewType = crew.CrewType
	local CrewTypeID = crew.CrewTypeID

	local Contraption = crew:GetContraption() or {}
	local CrewsByType = Contraption.CrewsByType or {}

	local Limit = CrewType.LimitConVar
	if Limit then
		local Count = table.Count(CrewsByType[CrewTypeID] or {})
		if Count > Limit.Amount then
			ACF.SendNotify(crew.Owner, false, "You have reached the " .. CrewType.Name .. "limit for this contraption.")
			crew:Remove()
		end
	end

	if CrewType.EnforceLimits then CrewType.EnforceLimits(crew) end
end

do -- Random timer stuff
	function ENT:UpdateUltraLowFreq(cfg)
		if self.CrewType.UpdateUltraLowFreq then self.CrewType.UpdateUltraLowFreq(self, cfg) end
	end

	function ENT:UpdateLowFreq(cfg)
		local DeltaTime = cfg.DeltaTime

		-- Update health ergonomics
		self.HealthEff = self.ACF.Health / self.ACF.MaxHealth
		WireLib.TriggerOutput(self, "HealthEff", self.HealthEff * 100)

		-- Update oxygen levels and apply drowning if necessary
		local MouthPos = self:LocalToWorld(self.CrewModel.MouthOffsetL) -- Probably well underwater at this point
		if ( bit.band( util.PointContents( MouthPos ), CONTENTS_WATER ) == CONTENTS_WATER ) then
			self.Oxygen = self.Oxygen - DeltaTime * ACF.CrewOxygenLossRate
		else
			self.Oxygen = self.Oxygen + DeltaTime * ACF.CrewOxygenGainRate
		end
		self.Oxygen = math.Clamp(self.Oxygen, 0, ACF.CrewOxygen)
		if self.Oxygen <= 0 and self.IsAlive then
			self:KillCrew( "player/pl_drown1.wav")
		end
		WireLib.TriggerOutput(self, "Oxygen", self.Oxygen)

		-- Update crew focus
		self.CrewType.UpdateFocus(self)

		if self.CrewType.UpdateLowFreq then self.CrewType.UpdateLowFreq(self, cfg) end
	end

	function ENT:UpdateMedFreq(cfg)
		-- If specified, affect crew ergonomics based on space 
		local SpaceInfo = self.CrewType.SpaceInfo
		if SpaceInfo and self.ShouldScan then
			if not self.ScanIndex then
				-- If we haven't ran an initial scan, setup relevant information
				self.ScanBoxBase = self:OBBMaxs() - self:OBBMins()
				self.ScanBox = Vector()
				self.ScanHull = Vector(6, 6, 6)
				self.ScanDisplacements, self.ScanLengths, self.ScanCount = GenerateScanSetup()
				self.ScanIndex = 1
				self.SpaceEff = iterScan(self, self.ScanCount)
			else
				-- Routine scan run in a loop
				self.SpaceEff = iterScan(self, SpaceInfo.ScanStep)
			end
			WireLib.TriggerOutput(self, "SpaceEff", self.SpaceEff * 100)
		end

		if self.CrewType.UpdateMedFreq then self.CrewType.UpdateMedFreq(self, cfg) end
	end

	function ENT:UpdateHighFreq(cfg)
		local DeltaTime = cfg.DeltaTime

		-- If specified, affect crew ergonomics based on lean angle
		local LeanInfo = self.CrewType.LeanInfo
		if LeanInfo then
			local LeanDot = Vector(0, 0, 1):Dot(self:GetUp())
			local Angle = math.deg(math.acos(LeanDot))
			self.LeanEff = 1 - ACF.Normalize(Angle, LeanInfo.Min, LeanInfo.Max)
			WireLib.TriggerOutput(self, "LeanEff", self.LeanEff * 100)
		end

		-- Avoid G force calculation on crew during building...
		if DeltaTime > 0 and self:GetContraption() ~= nil then
			-- Calculate current G force on crew
			self.Pos = self.Pos or self:GetPos()
			self.Vel = self.Vel or self:GetVelocity()

			local pos = self:GetPos()
			local vel = (pos - self.Pos) / DeltaTime
			local accel = (vel - self.Vel) / DeltaTime

			self.Pos = pos
			self.Vel = vel
			self.Accel = accel

			local GForce = accel:Length() / 600

			-- If specified, affect crew ergonomics based on G forces
			local Effs = self.CrewType.GForceInfo.Efficiencies
			if Effs then
				self.MoveEff = 1 - ACF.Normalize(GForce, Effs.Min, Effs.Max)
				WireLib.TriggerOutput(self, "MoveEff", self.MoveEff * 100)
			end

			-- If specified, apply damage to crew based on G forces
			local Damages = self.CrewType.GForceInfo.Damages
			if Damages and GForce > Damages.Min and self.IsAlive then
				local Damage = ACF.Normalize(GForce, Damages.Min, Damages.Max) * 100
				self:DamageCrew(Damage, "player/pl_fallpain3.wav")
			end
		end

		-- TODO: Clean this shit up man
		local Contraption = self:GetContraption() or {}
		local CrewsByType = Contraption.CrewsByType or {}
		local Commanders = CrewsByType["Commander"] or {}
		local Commander = next(Commanders)

		self.CrewType.UpdateEfficiency(self, Commander)
		WireLib.TriggerOutput(self, "TotalEff", self.TotalEff * 100)

		if self.CrewType.UpdateHighFreq then self.CrewType.UpdateHighFreq(self, cfg) end
	end
end

do
	util.AddNetworkString("ACF_Crew_Links")
	util.AddNetworkString("ACF_Crew_Space")

	local Outputs = {
		"ModelEff",
		"LeanEff",
		"SpaceEff",
		"HealthEff",
		"MoveEff",
		"TotalEff",
		"Oxygen (Seconds of breath left before drowning)",
		"Entity (The crew entity itself) [ENTITY]",
	}

	local function VerifyData(Data)
		-- Default crew is a sitting commander that can replace others and be replaced
		if Data.CrewTypeID == nil then Data.CrewTypeID = "Commander" end
		if Data.CrewModelID == nil then Data.CrewModelID = "Sitting" end
		if Data.ReplaceOthers == nil then Data.ReplaceOthers = true end
		if Data.ReplaceSelf == nil then Data.ReplaceSelf = true end
	end

	local function UpdateCrew(Entity, Data, CrewModel, CrewType)
		-- Update model info and physics
		Entity.ACF = Entity.ACF or {}
		Entity.ACF.Model = CrewModel.Model

		Entity:SetModel(CrewModel.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Loads crew arguments ("CrewTypeID", "CrewModelID", "ReplaceOthers", "ReplaceSelf") into the entity from data
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		-- Update entity data
		Entity.CrewModel = CrewModel
		Entity.CrewType = CrewType
		Entity.CrewTypeID = Data.CrewTypeID
		Entity.CrewModelID = Data.CrewModelID
		Entity.ReplaceOthers = Data.ReplaceOthers
		Entity.ReplaceSelf = Data.ReplaceSelf

		Entity.ModelEff = CrewModel.BaseErgoScores[Data.CrewTypeID] or 1

		Entity:SetNWString("WireName", "ACF Crew Member") -- Set overlay wire entity name

		Entity.ACF.Model = CrewModel.Model

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj
		if IsValid(PhysObj) then
			Contraption.SetMass(Entity, CrewType.Mass)
		end

		Entity:UpdateOverlay(true)

		if Entity.CrewType.OnUpdate then Entity.CrewType.OnUpdate(Entity) end
	end

	function MakeCrew(Player, Pos, Angle, Data)
		VerifyData(Data)

		local CrewModel = CrewModels.Get(Data.CrewModelID)
		local CrewType = CrewTypes.Get(Data.CrewTypeID)

		-- Enforcing limits
		local Limit = "_acf_crew"
		if not Player:CheckLimit(Limit) then return false end

		-- Creating the entity
		local CanSpawn	= HookRun("ACF_PreEntitySpawn", "acf_crew", Player, Data, CrewModel, CrewType)
		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_crew")

		if not IsValid(Entity) then return end

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Player:AddCleanup("acf_crew", Entity)
		Player:AddCount(Limit, Entity)
		if CrewType.LimitConVar then Player:AddCount(CrewType.LimitConVar.Name, Entity) end

		Entity.Name = "Crew Member"
		Entity.ShortName = "Crew Member"
		Entity.EntType = "Crew Member"

		Entity.Owner = Player -- MUST be stored on ent for PP
		Entity.DataStore = Entities.GetArguments("acf_crew")

		-- Storing links
		Entity.Targets = {} -- Targets linked to this crew (LUT)
		Entity.TargetsByType = {} -- Targets linked to this crew by type (LUT)

		-- Various efficiency modifiers
		Entity.ModelEff = 1
		Entity.LeanEff = 1
		Entity.SpaceEff = 1
		Entity.MoveEff = 1
		Entity.HealthEff = 1
		Entity.TotalEff = 1
		Entity.Focus = 1

		-- Various state variables
		Entity.ShouldScan = false
		Entity.Oxygen = ACF.CrewOxygen -- Time in seconds of breath left before drowning
		Entity.IsAlive = true

		UpdateCrew(Entity, Data, CrewModel, CrewType)

		-- Run randomized timers
		-- TODO: Fix args
		ACF.AugmentedTimer(function(cfg) Entity:UpdateUltraLowFreq(cfg) end, function() return IsValid(Entity) end, nil, {MinTime = 3, MaxTime = 5, Delay = 0.1})
		ACF.AugmentedTimer(function(cfg) Entity:UpdateLowFreq(cfg) end, function() return IsValid(Entity) end, nil, {MinTime = 1, MaxTime = 2, Delay = 0.1})
		ACF.AugmentedTimer(function(cfg) Entity:UpdateMedFreq(cfg) end, function() return IsValid(Entity) end, nil, {MinTime = 0.5, MaxTime = 1, Delay = 0.1})
		ACF.AugmentedTimer(function(cfg) Entity:UpdateHighFreq(cfg) end, function() return IsValid(Entity) end, nil, {MinTime = 0.1, MaxTime = 0.5, Delay = 0.1})

		-- Finish setting up the entity
		hook.Run("ACF_OnEntitySpawn", "acf_crew", Entity, Data, CrewModel, CrewType)

		WireIO.SetupOutputs(Entity, Outputs, Data)

		WireLib.TriggerOutput(Entity, "ModelEff", Entity.ModelEff * 100)
		WireLib.TriggerOutput(Entity, "Entity", Entity)

		Entity:UpdateOverlay(true)

		CheckLegal(Entity)

		if Entity.CrewType.OnSpawn then Entity.CrewType.OnSpawn(Entity) end

		return Entity
	end

	-- Bare minimum arguments to reconstruct a crew
	Entities.Register("acf_crew", MakeCrew, "CrewTypeID", "CrewModelID", "ReplaceOthers", "ReplaceSelf")

	-- Necessary for e2/sf link related functionality
	ACF.RegisterLinkSource("acf_gun", "Crew")
	ACF.RegisterLinkSource("acf_engine", "Crew")

	function ENT:Update(Data)
		-- Called when updating the entity
		VerifyData(Data)

		local CrewModel = CrewModels.Get(Data.CrewModelID)
		local CrewType = CrewTypes.Get(Data.CrewTypeID)

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_crew", self, Data, CrewModel, CrewType)
		if CanUpdate == false then return CanUpdate, Reason end

		HookRun("ACF_OnEntityLast", "acf_crew", self)

		-- Unlink crews if their type changes
		if self.CrewTypeID ~= Data.CrewTypeID then
			ACF.SendNotify(self.Owner, false, "Crew updated with different occupation. All links removed, please relink.")
			if next(self.Targets) then
				for Target in pairs(self.Targets) do
					self:Unlink(Target)
				end
			end
		end

		ACF.SaveEntity(self)

		UpdateCrew(self, Data, CrewModel, CrewType)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnEntityUpdate", "acf_crew", self, Data, CrewModel, CrewType)

		self:UpdateOverlay(true)

		return true, "Crew updated successfully!"
	end

	function ENT:UpdateOverlayText()
		str = string.format("Role: %s\nHealth: %s HP\nLean: %s %%\nSpace: %s %%\nMove: %s %%\nEfficiency: %s %%",
			self.CrewTypeID,
			math.Round(self.HealthEff * 100, 2),
			math.Round(self.LeanEff * 100, 2),
			math.Round(self.SpaceEff * 100, 2),
			math.Round(self.MoveEff * 100, 2),
			math.Round(self.TotalEff * 100, 2)
		)
		return str
	end
end

-- Entity methods
do
	-- Think logic (mostly checks and stuff that updates frequently)
	local MaxDistance = ACF.LinkDistance ^ 2
	local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"

	function ENT:Think()
		-- Check links on this entity
		local Targets = self.Targets or {}
		if next(Targets) then
			local Pos = self:GetPos()
			for Link in pairs(Targets) do
				if not IsValid(Link) then self:Unlink(Link) continue end				-- If the link is invalid, remove it and skip it

				local OutOfRange = Pos:DistToSqr(Link:GetPos()) > MaxDistance			-- Check distance limit
				local DiffAncestors = self:GetContraption() ~= Link:GetContraption()	-- Check same contraption
				if OutOfRange or DiffAncestors then
					local Sound = UnlinkSound:format(math.random(1, 3))
					Link:EmitSound(Sound, 70, 100, ACF.Volume)
					self:EmitSound(Sound, 70, 100, ACF.Volume)
					self:Unlink(Link)
					Link:Unlink(self)
					ACF.SendNotify(self.Owner, false, "Crew unlinked. Make sure they're part of the same contraption as and close enough to their target.")
				end
			end
		end

		EnforceLimits(self)

		self:UpdateOverlay()
		self:NextThink(Clock.CurTime + math.Rand(1, 2))
		return true
	end

	function ENT:ACF_Activate(Recalc)
		local PhysObj = self.ACF.PhysObj
		local Mass    = PhysObj:GetMass()
		local Area    = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
		local Armour  = ACF.CrewArmor -- Human body isn't that thick but we have to put something here
		local Health  = ACF.CrewHealth
		local Percent = 1

		if Recalc and self.ACF.Health and self.ACF.MaxHealth then
			Percent = self.ACF.Health / self.ACF.MaxHealth
		end

		self.ACF.Area      = Area
		self.ACF.Health    = Health * Percent
		self.ACF.MaxHealth = Health
		self.ACF.Armour    = Armour * Percent
		self.ACF.MaxArmour = Armour
		self.ACF.Type      = "Prop"
	end

	--- Attempts to replace self with another crew member
	function ENT:ReplaceCrew()
		if self:GetContraption() == nil then return end 				-- No contraption to replace crew in
		if self:GetContraption().CrewsByType == nil then return end 	-- No crew to replace with
		if not self.ToBeReplaced and self.ReplaceSelf then
			self.ToBeReplaced = true									-- Mark self for replacement

			local start = false
			local CrewsByType = self:GetContraption().CrewsByType
			for _, CrewType in ipairs(ACF.CrewPriorities) do							-- Priority wise search over crew types
				local OtherCrews = CrewsByType[CrewType] or {}

				-- Ignore all crew types before our own on the hierarchy (only search for)
				if CrewType == self.CrewTypeID then start = true end
				if not start then continue end

				for Other, _ in pairs(OtherCrews) do									-- For each crew of that type
					local NotMe = Other ~= self and IsValid(Other) 						-- Valid crew that isn't us
					local NotBusy = not Other.ToReplace									-- Other isn't replacing someone else
					local Alive = Other.ACF.Health and Other.ACF.Health > 0				-- Other is alive
					local Replaceable = Other.ReplaceOthers								-- Other can be replaced
					if NotMe and NotBusy and Alive and Replaceable then
						Other.ToReplace = true 											-- Other is now replacing someone (us)

						-- Calculate replacement time
						local ReplacementDist = self:GetPos():Distance(Other:GetPos())
						local ReplacementTime = ACF.CrewRepTimeBase + ACF.CrewRepDistToTime * ReplacementDist
						TimerSimple(ReplacementTime, function()
							Other.ToReplace = false
							self.ToBeReplaced = false

							self:SwapCrew(Other)
						end)
						return
					end
				end
			end
		end
	end

	-- Handles swapping crew during replacement. Assumes KillCrew has ran before.
	function ENT:SwapCrew(Other)
		local mat1, mat2 = self:GetMaterial(), Other:GetMaterial()
		local col1, col2 = self:GetColor(), Other:GetColor()
		self:SetMaterial(mat2)
		self:SetColor(col2)
		Other:SetMaterial(mat1)
		Other:SetColor(col1)

		self.ACF.Health, Other.ACF.Health = Other.ACF.Health, self.ACF.Health
		self.ACF.Armour = self.ACF.MaxArmour * (self.ACF.Health / self.ACF.MaxHealth)
		Other.ACF.Armour = Other.ACF.MaxArmour * (Other.ACF.Health / Other.ACF.MaxHealth)
		self.IsAlive, Other.IsAlive = Other.IsAlive, self.IsAlive

		self:UpdateOverlay()
		Other:UpdateOverlay()
	end

	-- Somewhat internal function to handle crew damage
	function ENT:DamageCrew(Damage, sound)
		-- Avoid negative health to avoid weird damage interactions
		local NewHealth = math.max(0, self.ACF.Health - Damage)

		self.ACF.Health = NewHealth
		self.ACF.Armour = self.ACF.MaxArmour * (NewHealth / self.ACF.MaxHealth)

		if NewHealth == 0 and self.IsAlive then
			self:KillCrew(sound)
		end
	end

	-- sound is the sound to play when the crew dies
	function ENT:KillCrew(sound)
		EmitSound( sound, self:GetPos())
		self:SetMaterial( "models/flesh" )
		self:SetColor( Color(255, 255, 255, 255) )

		self.IsAlive = false
		self.ACF.Health = 0

		self:UpdateOverlay()
		self:ReplaceCrew()

		-- TODO: CLEAN THIS UP
		-- Check how many crew remain and kill the owner if there are none left
		local Contraption = self:GetContraption() or {}
		local Crews = Contraption.Crews or {}
		local Alive = 0
		for crew, _ in pairs(Crews) do
			if crew.IsAlive then Alive = Alive + 1 end
		end

		-- Crew death at 1 left
		if Alive <= 0 then
			local Contraption = self:GetContraption() or {}
			local Base = Contraption.Base or {}
			local Seat = Base.Seat or {}
			if IsValid(Seat) then 
				Seat:GetDriver():Kill()

				-- hook.Add("CanPlayerEnterVehicle", "LockOut" .. Base:EntIndex(), function(ply, veh, role)
				-- 	if veh == Base.Seat then return false end
				-- end)
			end
		end
	end

	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		local HitRes = DmgResult:Compute()

		HitRes.Kill = false	-- Crew entities should never be removed

		self:DamageCrew(HitRes.Damage, "npc/zombie/zombie_voice_idle6.wav")

		return HitRes
	end

	function ENT:ACF_OnRepaired(OldArmor, OldHealth, Armor, Health)
		-- Dead crew should not be revivable
		if OldArmor == 0 then self.ACF.Armor = 0 end
		if OldHealth == 0 then self.ACF.Health = 0 end

		if self.ACF.Health == self.ACF.MaxHealth then EmitSound("items/medshot4.wav", self:GetPos()) end
		self.ACF.Armour = self.ACF.MaxArmour * (self.ACF.Health / self.ACF.MaxHealth)
		self:UpdateOverlay()
	end
end

-- CFW Integration
do
	-- Maintain a record in the contraption of its current crew
	hook.Add("cfw.contraption.entityAdded", "crewaddindex", function(contraption, ent)
		if ent:GetClass() == "acf_crew" then
			contraption.Crews = contraption.Crews or {}
			contraption.Crews[ent] = true

			contraption.CrewsByType = contraption.CrewsByType or {}
			contraption.CrewsByType[ent.CrewTypeID] = contraption.CrewsByType[ent.CrewTypeID] or {}
			contraption.CrewsByType[ent.CrewTypeID][ent] = true
		end
	end)

	hook.Add("cfw.contraption.entityRemoved", "crewremoveindex", function(contraption, ent)
		if ent:GetClass() == "acf_crew" then
			contraption.Crews = contraption.Crews or {}
			contraption.Crews[ent] = nil

			contraption.CrewsByType = contraption.CrewsByType or {}
			contraption.CrewsByType[ent.CrewTypeID] = contraption.CrewsByType[ent.CrewTypeID] or {}
			contraption.CrewsByType[ent.CrewTypeID][ent] = nil
		end
	end)
end

-- Linkage Related
do
	--- Sends a "link" between two entities to the client
	local function BroadcastEntity(name, entity, entity2, state)
		net.Start(name)
		net.WriteUInt(entity:EntIndex(), 16)
		net.WriteUInt(entity2:EntIndex(), 16)
		net.WriteBool(state)
		net.Broadcast()
	end

	--- Register basic linkages from crew to non crew entities
	local function CanLinkCrew(Crew, Target)
		if not Target.Crews then Target.Crews = {} end -- Safely make sure the link target has a crew list
		if Target.Crews[Crew] then return false, "This entity is already linked to this crewmate!" end
		if Crew.Targets[Target] then return false, "This entity is already linked to this crewmate!" end
		if Target:GetContraption() ~= Crew:GetContraption() then return false, "This entity is not part of the same contraption as this crewmate!" end
		if not Crew.CrewType.LinkHandlers[Target:GetClass()] then return false, "This entity cannot be linked with this occupation" end

		local Handlers = Crew.CrewType.LinkHandlers[Target:GetClass()]
		if Handlers.CanLink then return Handlers.CanLink(Crew, Target) end
		return true, "Crew linked."
	end

	local function LinkCrew(Crew, Target)
		local TargetClass = Target:GetClass()
		if not CanLinkCrew(Crew, Target) then return end

		-- Update crew and target's records of each other
		Crew.Targets[Target] = true
		Crew.TargetsByType = Crew.TargetsByType or {}
		Crew.TargetsByType[TargetClass] = Crew.TargetsByType[TargetClass] or {}
		Crew.TargetsByType[TargetClass][Target] = true

		Target.Crews[Crew] = true
		Target.CrewsByType = Target.CrewsByType or {}
		Target.CrewsByType[Crew.CrewTypeID] = Target.CrewsByType[Crew.CrewTypeID] or {}
		Target.CrewsByType[Crew.CrewTypeID][Crew] = true

		local Handlers = Crew.CrewType.LinkHandlers[TargetClass]
		if Handlers.OnLink then Handlers.OnLink(Crew, Target, TargetClass) end

		BroadcastEntity("ACF_Crew_Links", Crew, Target, true)

		if Target.UpdateOverlay then Target:UpdateOverlay() end
		Crew:UpdateOverlay()
	end

	local function UnlinkCrew(Crew, Target)
		local TargetClass = Target:GetClass()
		-- Update crew and target's records of each other
		Crew.Targets[Target] = nil
		Crew.TargetsByType = Crew.TargetsByType or {}
		Crew.TargetsByType[TargetClass] = Crew.TargetsByType[TargetClass] or {}
		Crew.TargetsByType[TargetClass][Target] = nil

		Target.Crews[Crew] = nil
		Target.CrewsByType = Target.CrewsByType or {}
		Target.CrewsByType[Crew.CrewTypeID] = Target.CrewsByType[Crew.CrewTypeID] or {}
		Target.CrewsByType[Crew.CrewTypeID][Crew] = nil

		local Handlers = Crew.CrewType.LinkHandlers[TargetClass]
		if Handlers.OnUnLink then Handlers.OnUnLink(Crew, Target, TargetClass) end

		BroadcastEntity("ACF_Crew_Links", Crew, Target, false)

		if Target.UpdateOverlay then Target:UpdateOverlay() end
		Crew:UpdateOverlay()
	end

	-- Compactly define links between crew and other entities
	local lt = {} -- Merge all crew whitelists
	for ct, _ in pairs(CrewTypes.GetEntries()) do
		for et, _ in pairs(CrewTypes.Get(ct).LinkHandlers or {}) do
			lt[et] = true
		end
	end

	for v, _ in pairs(lt) do
		ACF.RegisterClassLink(v, "acf_crew", function(Target, Crew, FromChip)
			local Result, Message = CanLinkCrew(Crew, Target)
			if Result then
				if FromChip then TimerSimple(10, function() LinkCrew(Crew, Target) end)
				else LinkCrew(Crew, Target) end
			end
			return Result, Message
		end)

		ACF.RegisterClassUnlink(v, "acf_crew", function(Target, Crew, FromChip)
			if not Target.Crews[Crew] or not Crew.Targets[Target] then return false, "This acf entity is not linked to this crewmate."	end

			UnlinkCrew(Crew, Target)

			return true, "Crewmate unlinked successfully!"
		end)
	end
end

-- Adv Dupe 2 Related
do
	function ENT:PreEntityCopy()
		if next(self.Targets) then
			local Entities = {}
			for Ent in pairs(self.Targets) do
				Entities[#Entities + 1] = Ent:EntIndex()
			end
			duplicator.StoreEntityModifier(self, "CrewTargets", Entities)
		end

		-- Wire dupe info
		self.BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		local EntMods = Ent.EntityMods

		-- Restore previous links
		if EntMods.CrewTargets then
			for _, EntID in pairs(EntMods.CrewTargets) do
				-- ACF turrets i kneel
				timer.Simple(1, function()
					self:Link(CreatedEntities[EntID])
				end)
			end
			EntMods.CrewTargets = nil
		end

		--Wire dupe info
		self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
	end

	function ENT:OnRemove()
		local CrewModel = self.CrewModel
		local CrewType = self.CrewType

		HookRun("ACF_OnEntityLast", "acf_crew", self, CrewModel, CrewType)

		-- Unlink target entities
		for v,_ in pairs(self.Targets) do
			if IsValid(v) then self:Unlink(v) end
		end

		WireLib.Remove(self)
	end
end