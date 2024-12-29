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

CreateConVar(
	"sbox_max_acf_crew",
	8,
	FCVAR_ARCHIVE + FCVAR_NOTIFY,
	"Maximum amount of " .. "ACF crew members" .. " a player can create."
)

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

local function iterScan(ent, reps)
	local localoffset = ent.CrewModel.OffsetL
	local center = ent:LocalToWorld(localoffset)
	local count = ent.ScanCount

	local Length = 1 * 39.3701
	local Caliber = 0.125 * 39.3701
	local LoadBox = (ent:OBBMaxs() - ent:OBBMins()) + Vector(Length/2,Length/2,Caliber)

	-- Iterate reps times and iterate over time
	for i = 1, reps do
		local index = ent.ScanIndex
		local disp = ent.ScanDisplacements[index]
		local p1 = center

		local corner = Vector(disp.x * LoadBox.x/2, disp.y * LoadBox.y/2, disp.z * LoadBox.z/2)
		local p2 = ent:LocalToWorld(localoffset + corner)
		local frac, _, _, hitpos = traceVisHullCube(p1, p2, Vector(Caliber, Caliber, Caliber), ent)
		debugoverlay.Line(p1, hitpos, 1, Color(255, 0, 0))
		debugoverlay.Line(hitpos, p2, 1, Color(0, 255, 0))
		ent.ScanLengths[index] = frac

		index = index  + 1
		if index > count then index = 1 end
		ent.ScanIndex = index
	end
	debugoverlay.BoxAngles( ent:LocalToWorld(localoffset), -LoadBox/2, LoadBox/2, ent:GetAngles(), 1, Color(0,0,255,100) )

	-- Update based on old values
	local sum = 0
	for i = 1, count do
		sum = sum + ent.ScanLengths[i]
	end
	return sum / count
end

do -- Random timer stuff
	function ENT:UpdateLowFreq(LastTime)
		local DeltaTime = Clock.CurTime - LastTime

		-- Update health ergonomics
		self.HealthEff = math.Round(self.ACF.Health / self.ACF.MaxHealth, 2)
		WireLib.TriggerOutput(self, "HealthEff", self.HealthEff * 100)

		-- Update oxygen levels
		local MouthPos = self:LocalToWorld(self:OBBCenter()) -- Probably well underwater at this point
		if ( bit.band( util.PointContents( MouthPos ), CONTENTS_WATER ) == CONTENTS_WATER ) then
			self.Oxygen = self.Oxygen - DeltaTime * ACF.CrewOxygenLossRate
		else
			self.Oxygen = self.Oxygen + DeltaTime * ACF.CrewOxygenGainRate
		end
		self.Oxygen = math.Clamp(self.Oxygen, 0, ACF.CrewOxygen)
		if self.Oxygen <= 0 and self.ACF.Health > 0 then
			self:KillCrew( "player/pl_drown1.wav")
		end
		WireLib.TriggerOutput(self, "Oxygen", self.Oxygen)

		-- Update crew focus
		if self.CrewType.UpdateFocus then
			self.CrewType.UpdateFocus(self)
		end
	end

	function ENT:UpdateMedFreq(LastTime)
		-- Update space ergonomics if needed
		if self.CrewType.ShouldScan then
			self.SpaceEff = math.Round(iterScan(self, self.CrewType.ScanStep or 1), 2)
			WireLib.TriggerOutput(self, "SpaceEff", self.SpaceEff * 100)
		end
	end

	function ENT:UpdateHighFreq(LastTime)
		local DeltaTime = Clock.CurTime - LastTime

		-- Check world lean angle and update ergonomics
		local LeanDot = Vector(0, 0, 1):Dot(self:GetUp())
		self.LeanAngle = math.Round(math.deg(math.acos(LeanDot)), 2)
		self.LeanEff = math.Round(1 - ACF.Normalize(self.LeanAngle, 0, 90))
		WireLib.TriggerOutput(self, "LeanEff", self.LeanEff * 100)

		if DeltaTime > 0 and self.IsAlive then
			-- Check G forces
			-- print("DFA", DeltaTime)
			self.Pos = self.Pos or self:GetPos()
			self.Vel = self.Vel or self:GetVel()
			-- print(self.Pos, self.Vel)

			-- print("---")

			local pos = self:GetPos()
			local vel = (pos - self.Pos) / DeltaTime
			local accel = (vel - self.Vel) / DeltaTime

			self.Pos = pos
			self.Vel = vel
			self.Accel = accel
			-- print(self.Pos, self.Vel)
			-- print(self.Accel, accel:Length())
			-- print("End")

			if self.CrewType.GLimitEff then
				-- Update move ergonomics
				local GLimitEffSU = self.CrewType.GLimitEff * 39.37 * 9.8 -- Convert Gs to in/s^2		
				self.MoveEff = math.Round(math.Clamp(1 - math.abs(accel:Length() / GLimitEffSU), 0, 1), 2)
				WireLib.TriggerOutput(self, "MoveEff", self.MoveEff * 100)
			end

			local GLimitSU = self.CrewType.GLimit * 39.37 * 9.8 -- Convert Gs to in/s^2
			if accel:Length() > GLimitSU then
				self:KillCrew("player/pl_fallpain3.wav")
			end
		end

		-- Update total ergonomics
		self.TotalEff = math.Clamp(self.ModelEff * self.LeanEff * self.SpaceEff * self.MoveEff * self.HealthEff, 0, 1)
		WireLib.TriggerOutput(self, "TotalEff", self.TotalEff * 100)
	end
end

do
	util.AddNetworkString("ACF_Crew_Links")

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
		-- Default crew is a sitting commander
		if Data.CrewTypeID == nil then Data.CrewTypeID = "Commander" end
		if Data.CrewModelID == nil then Data.CrewModelID = "Sitting" end
		if Data.ReplaceOthers == nil then Data.ReplaceOthers = true end
		if Data.ReplaceSelf == nil then Data.ReplaceSelf = true end
	end

	local function UpdateCrew(Entity, Data, CrewModel, CrewType)
		Entity.ACF = Entity.ACF or {}
		Entity.ACF.Model = CrewModel.Model

		Entity:SetModel(CrewModel.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Loads Entity.CrewTypeID from Data
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.CrewModel = CrewModel
		Entity.CrewType = CrewType
		Entity.CrewTypeID = Data.CrewTypeID
		Entity.CrewModelID = Data.CrewModelID

		Entity.ReplaceOthers = Data.ReplaceOthers
		Entity.ReplaceSelf = Data.ReplaceSelf

		if Entity.CrewType.ShouldScan then
			Entity.ScanDisplacements, Entity.ScanLengths, Entity.ScanCount = GenerateScanSetup()
			Entity.ScanIndex = 1
			Entity.SpaceEff = iterScan(Entity, Entity.ScanCount)
		end

		Entity.ModelEff = CrewModel.BaseErgoScores[Data.CrewTypeID] or 1
		WireLib.TriggerOutput(Entity, "ModelEff", Entity.ModelEff * 100)

		Entity:SetNWString("WireName", "ACF Crew Member") -- Set overlay wire entity name

		Entity.ACF.Model = CrewModel.Model

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj
		if IsValid(PhysObj) then
			Contraption.SetMass(Entity, CrewType.Mass)
		end

		Entity:UpdateOverlay(true)
	end

	function MakeCrew(Player, Pos, Angle, Data)
		VerifyData(Data)

		local CrewModel = CrewModels.Get(Data.CrewModelID)
		local CrewType = CrewTypes.Get(Data.CrewTypeID)

		local Limit = "_acf_crew" -- TODO: unhardcode this later
		if not Player:CheckLimit(Limit) then return false end

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

		Entity.Name = "Crew Member"
		Entity.ShortName = "Crew Member"
		Entity.EntType = "Crew Member"

		Entity.Owner = Player
		Entity.DataStore = Entities.GetArguments("acf_crew")

		Entity.Targets = {} -- Targets linked to this crew (LUT)

		Entity.LeanAngle = 0

		-- Various efficiency modifiers
		Entity.ModelEff = 1
		Entity.LeanEff = 1
		Entity.SpaceEff = 1
		Entity.MoveEff = 1
		Entity.HealthEff = 1
		Entity.TotalEff = 1

		Entity.Oxygen = ACF.CrewOxygen -- Time in seconds of breath left before drowning

		-- DFA like move efficiency
		Entity.Pos = Pos
		Entity.Vel = Vector(0, 0, 0)
		Entity.Accel = Vector(0, 0, 0)

		Entity.IsAlive = true

		Entity.LastThink = Clock.CurTime

		UpdateCrew(Entity, Data, CrewModel, CrewType)

		ACF.RandomizedDependentTimer(function(LastTime) Entity:UpdateLowFreq(LastTime) end, function() return IsValid(Entity) end, 1, 2, 3)
		ACF.RandomizedDependentTimer(function(LastTime) Entity:UpdateMedFreq(LastTime) end, function() return IsValid(Entity) end, 0.5, 1, 3)
		ACF.RandomizedDependentTimer(function(LastTime) Entity:UpdateHighFreq(LastTime) end, function() return IsValid(Entity) end, 0.05, 0.5, 3)

		hook.Run("ACF_OnEntitySpawn", "acf_crew", Entity, Data, CrewModel, CrewType)

		WireIO.SetupOutputs(Entity, Outputs, Data)

		WireLib.TriggerOutput(Entity, "Entity", Entity)

		Entity:UpdateOverlay(true)

		CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_crew", MakeCrew, "CrewTypeID", "CrewModelID", "ReplaceOthers", "ReplaceSelf")

	-- TODO: Determine sources
	ACF.RegisterLinkSource("acf_gun", "Crew")
	ACF.RegisterLinkSource("acf_engine", "Crew")

	function ENT:Update(Data)
		VerifyData(Data)

		local CrewModel = CrewModels.Get(Data.CrewModelID)
		local CrewType = CrewTypes.Get(Data.CrewTypeID)

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_crew", self, Data, CrewModel, CrewType)
		if CanUpdate == false then return CanUpdate, Reason end

		HookRun("ACF_OnEntityLast", "acf_crew", self)

		ACF.SaveEntity(self)

		UpdateCrew(self, Data, CrewModel, CrewType)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnEntityUpdate", "acf_crew", self, Data, CrewModel, CrewType)

		return true, "Crew updated successfully!"
	end

	function ENT:UpdateOverlayText()
		str = string.format("Role: %s\nHealth: %s HP\nLean Angle: %s Deg\nSpace: %s %%\nMove: %s %%\nEfficiency: %s %%", self.CrewType.ID, self.HealthEff * 100, self.LeanAngle, (self.SpaceEff or 1) * 100, (self.MoveEff or 1) * 100, (self.TotalEff or 1) * 100)
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
		local Targets = self.Targets
		if next(Targets) then
			local Pos = self:GetPos()
			for Link in pairs(Targets) do
				if not IsValid(Link) then self:Unlink(Link) continue end			-- If the link is invalid, remove it and skip it

				local OutOfRange = Pos:DistToSqr(Link:GetPos()) > MaxDistance		-- Check distance limit and common ancestry

				-- #TODO: Address once done development
				-- local DiffAncestors = self:GetAncestor() ~= Link:GetAncestor()
				if OutOfRange or DiffAncestors then
					local Sound = UnlinkSound:format(math.random(1, 3))
					Link:EmitSound(Sound, 70, 100, ACF.Volume)
					self:EmitSound(Sound, 70, 100, ACF.Volume)
					self:Unlink(Link)
					Link:Unlink(self)
				end
			end
		end

		self.LastThink = Clock.CurTime

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

	-- Handles crew death
	-- sound is the sound to play when the crew dies
	function ENT:KillCrew(sound)
		EmitSound( sound, self:GetPos())
		self:SetMaterial( "models/flesh" )
		self:SetColor( Color(255, 255, 255, 255) )

		self.IsAlive = false
		self.ACF.Health = 0
		self.ACF.HealthEff = 0

		self:UpdateOverlay()
	end

	-- Handles swapping crew during replacement. Assumes self has died.
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
		self.IsAlive = self.ACF.Health > 0

		self:UpdateOverlay()
		Other:UpdateOverlay()
	end

	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		local Health = self.ACF.Health
		local HitRes = DmgResult:Compute()

		HitRes.Kill = false

		-- Prevent entity from being destroyed (clamp health)
		local NewHealth = math.max(0, Health - HitRes.Damage)

		self.ACF.Health = NewHealth
		self.ACF.Armour = self.ACF.MaxArmour * (NewHealth / self.ACF.MaxHealth)

		-- If we reach 0, replace the crew with the next one
		if NewHealth == 0 and self.IsAlive then
			-- TODO: Remove hardcode
			self:KillCrew("player/pl_pain7.wav")
			if not self.ToBeReplaced and self.ReplaceSelf then
				self.ToBeReplaced = true

				local start = false
				for _, CrewType in ipairs(ACF.CrewPriorities) do						-- For each crew type in the replacement hierarchy
					local OtherCrews = self:GetContraption().crewsByType[CrewType] or {}

					-- Ignore all classes before our own
					if CrewType == self.CrewTypeID then start = true end
					if not start then continue end

					for Other, _ in pairs(OtherCrews) do									-- For each crew of that type
						local NotMe = Other ~= self and IsValid(Other) 						-- Valid crew that isn't us
						local NotBusy = not Other.ToReplace									-- Other isn't replacing someone else
						local Alive = Other.ACF.Health and Other.ACF.Health > 0				-- Other is alive
						local Replaceable = Other.ReplaceOthers								-- Other can be replaced
						if NotMe and NotBusy and Alive and Replaceable then
							Other.ToReplace = true -- Other will replace us

							local ReplacementDist = self:GetPos():Distance(Other:GetPos())
							local ReplacementTime = ACF.CrewRepTimeBase + ACF.CrewRepDistToTime * ReplacementDist
							TimerSimple(ReplacementTime, function()
								-- Swap the crews visually and health wise
								Other.ToReplace = false
								self.ToBeReplaced = false

								self:SwapCrew(Other)
							end)
							return HitRes -- Early return to break out of nested loop
						end
					end
				end
			end
		end

		return HitRes
	end

	function ENT:ACF_OnRepaired(OldArmor, OldHealth, Armor, Health) -- Normally has OldArmor, OldHealth, Armor, and Health passed
		-- Dead crew should not be revivable
		if OldArmor == 0 then self.ACF.Armour = 0 end
		if OldHealth == 0 then self.ACF.Health = 0 end

		self.ACF.Armour = self.ACF.MaxArmour * (self.ACF.Health / self.ACF.MaxHealth)
		self:UpdateOverlay()
	end
end

-- CFW Integration
do
	-- Maintain a record in the contraption of its current crew
	hook.Add("cfw.contraption.entityAdded", "crewaddindex", function(contraption, ent)
		if ent:GetClass() == "acf_crew" then
			-- LUT of crews
			contraption.crews = contraption.crews or {}
			contraption.crews[ent] = true

			-- LUT of crews by type
			contraption.crewsByType = contraption.crewsByType or {}
			contraption.crewsByType[ent.CrewTypeID] = contraption.crewsByType[ent.CrewTypeID] or {}
			contraption.crewsByType[ent.CrewTypeID][ent] = true
		end
	end)

	hook.Add("cfw.contraption.entityRemoved", "crewremoveindex", function(contraption, ent)
		if ent:GetClass() == "acf_crew" then
			contraption.crews = contraption.crews or {}
			contraption.crews[ent] = nil

			contraption.crewsByType = contraption.crewsByType or {}
			contraption.crewsByType[ent.CrewTypeID] = contraption.crewsByType[ent.CrewTypeID] or {}
			contraption.crewsByType[ent.CrewTypeID][ent] = nil
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
	local function CanLinkCrew(Target, Crew)
		if not Target.Crews then Target.Crews = {} end -- Safely make sure the link target has a crew list
		if Target.Crews[Crew] then return false, "This entity is already linked to this crewmate!" end
		if Crew.Targets[Target] then return false, "This entity is already linked to this crewmate!" end
		if not Crew.CrewType.Whitelist[Target:GetClass()] then return false, "This entity cannot be linked with this occupation" end
		return true, "Crew linked."
	end

	local function LinkCrew(Target, Crew)
		if not CanLinkCrew(Target, Crew) then return end

		Crew.Targets[Target] = true
		Crew.TargetsByType = Crew.TargetsByType or {}
		Crew.TargetsByType[Target:GetClass()] = Crew.TargetsByType[Target:GetClass()] or {}
		Crew.TargetsByType[Target:GetClass()][Target] = true

		Target.Crews[Crew] = true
		Target.CrewsByType = Target.CrewsByType or {}
		Target.CrewsByType[Crew.CrewTypeID] = Target.CrewsByType[Crew.CrewTypeID] or {}
		Target.CrewsByType[Crew.CrewTypeID][Crew] = true

		BroadcastEntity("ACF_Crew_Links", Crew, Target, true)

		if Target.UpdateOverlay then Target:UpdateOverlay() end
		Crew:UpdateOverlay()
	end

	local function UnlinkCrew(Target, Crew)
		Crew.Targets[Target] = nil
		Crew.TargetsByType = Crew.TargetsByType or {}
		Crew.TargetsByType[Target:GetClass()] = Crew.TargetsByType[Target:GetClass()] or {}
		Crew.TargetsByType[Target:GetClass()][Target] = nil

		Target.Crews[Crew] = nil
		Target.CrewsByType = Target.CrewsByType or {}
		Target.CrewsByType[Crew.CrewTypeID] = Target.CrewsByType[Crew.CrewTypeID] or {}
		Target.CrewsByType[Crew.CrewTypeID][Crew] = nil

		BroadcastEntity("ACF_Crew_Links", Crew, Target, false)

		if Target.UpdateOverlay then Target:UpdateOverlay() end
		Crew:UpdateOverlay()
	end

	for k,v in ipairs({"acf_gun", "acf_engine", "acf_turret"}) do
		ACF.RegisterClassLink(v, "acf_crew", function(Target, Crew, FromChip)
			local Result, Message = CanLinkCrew(Target, Crew)
			if Result then
				if FromChip then TimerSimple(10, function() LinkCrew(Target, Crew) end)
				else LinkCrew(Target, Crew) end
			end
			return Result, Message
		end)

		ACF.RegisterClassUnlink(v, "acf_crew", function(Target, Crew, FromChip)
			if not Target.Crews[Crew] or not Crew.Targets[Target] then return false, "This acf entity is not linked to this crewmate."	end

			UnlinkCrew(Target, Crew)

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

		if EntMods.CrewTargets then
			for _, EntID in pairs(EntMods.CrewTargets) do
				self:Link(CreatedEntities[EntID])
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

		HookRemove("AdvDupe_FinishPasting", "crewdupefinished" .. self:EntIndex())

		-- Unlink target entities
		for v,_ in pairs(self.Targets) do
			if IsValid(v) then self:Unlink(v) end
		end

		WireLib.Remove(self)
	end
end