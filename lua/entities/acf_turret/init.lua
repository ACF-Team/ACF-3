AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF

local Contraption	= ACF.Contraption
local Classes		= ACF.Classes
local Utilities		= ACF.Utilities
local Sounds		= Utilities.Sounds
local Clock			= Utilities.Clock
local TimerSimple	= timer.Simple

local math_Round    = math.Round
local math_Clamp    = math.Clamp
local math_min      = math.min
local math_max      = math.max
local math_abs      = math.abs

local ENTITY        = FindMetaTable("Entity")
local PHYSOBJ       = FindMetaTable("PhysObj")
local VECTOR        = FindMetaTable("Vector")

local MaxLinkDistance = ACF.LinkDistance ^ 2
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"

do -- Random timer crew stuff
	local function ReturnCrewTotalEff(Crew) return ENTITY.GetTable(Crew).TotalEff end
	function ENT:UpdateAccuracyMod()
		local SelfTbl = ENTITY.GetTable(self)

		SelfTbl.CrewsByType = SelfTbl.CrewsByType or {}
		local Sum1, Count1 = ACF.WeightedLinkSum(SelfTbl.CrewsByType.Gunner or {}, ReturnCrewTotalEff)
		local Sum2, Count2 = ACF.WeightedLinkSum(SelfTbl.CrewsByType.Commander or {}, ReturnCrewTotalEff)
		local Sum3, Count3 = ACF.WeightedLinkSum(SelfTbl.CrewsByType.Pilot or {}, ReturnCrewTotalEff)
		local Sum, Count = Sum1 + Sum2 + Sum3, Count1 + Count2 + Count3
		local Val = (Count > 0) and (Sum / Count) or 0
		SelfTbl.AccuracyCrewMod = math_Clamp(Val, ACF.CrewFallbackCoef, 1)
		return SelfTbl.AccuracyCrewMod
	end
end

-- Some locals for entity functions that are stored as locals to avoid expensive
-- __index operations in think hooks. They are still available for convenience.
local ENT_CheckCoM
local ENT_GetTotalMass
local ENT_GetTurretMassCenter
local ENT_UpdateTurretSlew

do	-- Spawn and Update funcs
	CFW.addParentDetour("acf_turret", "Rotator")

	local DefaultType = "ACF.Turrets.Drive.Horizontal"

	-- Appends the selected drive's item-specific wire input (Bearing/Elevation).
	-- Re-run from ACF_PostUpdateEntityData once the item is known, since the
	-- generated wire setup runs before deserialization.
	function ENT:ACF_SetupWireIO(Inputs, _)
		local Turret = self:ACF_GetUserVar("Turret")
		if Turret and Turret.SetupInputs then Turret.SetupInputs(self, Inputs) end
	end

	-- Clamp the ring size to the selected drive's bounds (replaces legacy VerifyData).
	function ENT.ACF_OnVerifyClientData(ClientData)
		local Sel    = ClientData.Turret
		local Class  = (Sel and Classes.GetTypeByName(Sel.Type)) or Classes.GetTypeByName(DefaultType)
		local Bounds = Class.Size

		if Bounds then
			ClientData.RingSize = math_Clamp(ACF.CheckNumber(ClientData.RingSize, Bounds.Base), Bounds.Min, Bounds.Max)
		end
	end

	------------------

	local function GetMass(Turret, Size)
		return math_Round(math_max(Turret.Mass * (Size / Turret.Size.Base), 5) ^ 1.5, 1)
	end

	function ENT:ACF_PreSpawn(_, _, _, Data)
		self.ACF = {}

		local Sel   = Data and Data.Turret
		local Class = Classes.GetTypeByName(Sel and Sel.Type or DefaultType) or Classes.GetTypeByName(DefaultType)
		local Model = Class.Model
		local Size  = Data and tonumber(Data.RingSize)

		if Size and (Size < 12) and (Class.ID == "Turret-H") then
			Model = Class.ModelSmall
		end

		self:SetScaledModel(Model)
	end

	function ENT:ACF_OnSpawn()
		local Rotator = ents.Create("acf_turret_rotator") -- Integral to the turret working, if this does not spawn then stop everything
		if not IsValid(Rotator) then
			self:Remove()
			error(tostring(self) .. " did not have a valid rotator spawn with it, cancelling operation")
			return
		end

		self.MassCheckDelay = 0
		self.CoMCheckDelay  = 0
		self.ScaledArmor    = 0
		self.HandGear       = Classes.GetTypeByName("ACF.Turrets.Drive").HandGear
		self.Disconnect     = false

		self:SetNWEntity("ACF.Rotator", Rotator)

		Rotator:SetModel("models/hunter/plates/plate.mdl")
		Rotator:SetPos(self:GetPos())
		Rotator:SetAngles(self:GetAngles())
		Rotator:SetParent(self)
		Rotator:Spawn()
		Rotator:PhysicsInit(SOLID_VPHYSICS)
		Rotator:SetRenderMode(RENDERMODE_NONE)
		Rotator:SetNotSolid(true)
		Rotator:DrawShadow(false)

		self.Rotator   = Rotator
		Rotator.Turret = self
		Rotator.Owner  = self

		ACF.AugmentedTimer(function(cfg) self:UpdateAccuracyMod(cfg) end, function() return IsValid(self) end, nil, {MinTime = 0.5, MaxTime = 1})
	end

	function ENT:ACF_PostUpdateEntityData()
		local Turret   = self:ACF_GetUserVar("Turret")
		local Class    = Turret:GetType()
		local Group    = Classes.GetBaseClass(Class)
		local TurretID = Turret.ID
		local Size     = self:ACF_GetUserVar("RingSize")
		local Model    = Turret.Model

		if Group.WillUseSmallModel(Size) and (TurretID == "Turret-H") then
			Model = Turret.ModelSmall
		end

		self:SetScaledModel(Model)

		local RingHeight = Group.GetRingHeight({Type = TurretID, Ratio = Turret.Size.Ratio}, Size)

		if TurretID == "Turret-H" then
			self:SetSize(Vector(Size, Size, RingHeight))
		else
			self:SetScale(Size / 20)
		end

		self.ACF.Model   = Model
		self.Name        = math_Round(Size, 2) .. "\" " .. Turret.Name
		self.ShortName   = math_Round(Size, 2) .. "\" " .. Turret.ID
		self.EntType     = Group.Name
		self.Class       = Group.ID
		self.ClassData   = Group
		self.Turret      = TurretID
		self.ID          = Turret.ID

		local SizePerc = (Size - Turret.Size.Min) / (Turret.Size.Max - Turret.Size.Min)
		local MaxMass  = ((Turret.MassLimit.Min * (1 - SizePerc)) + (Turret.MassLimit.Max * SizePerc)) ^ 2
		self.MaxMass   = MaxMass

		self.TurretData = {
			Teeth       = Group.GetTeethCount(Turret, Size),
			RingSize    = Size,
			RingHeight  = RingHeight,
			TotalMass   = 0,
			LocalCoM    = Vector(),
			Tilt        = 1,
			TurretClass = TurretID,
			MaxMass     = MaxMass
		}

		-- Type-specific functions that differ between horizontal and vertical turret components
		self.SlewFuncs = Turret.SlewFuncs

		self.DesiredAngle = self.DesiredAngle or Angle(0, 0, 0)
		self.CurrentAngle = self.CurrentAngle or 0

		-- This is TRUE whenever the last used angle input is Elevation/Bearing
		-- Otherwise this is FALSE and will attempt to rotate to the Angle input
		self.Manual        = true
		self.UseVector     = false
		self.DesiredVector = Vector()
		self.DesiredDeg    = 0

		-- Any turrets that happen to get parented to this one, either directly or indirectly
		-- Mass calculation will stop at this, and instead read whatever that turret has calculated
		self.SubTurrets = {}

		-- Anything else deemed dynamic when it comes to mass (e.g. ammo, racks, fuel (for whatever reason))
		self.DynamicEntities = {}

		-- Three different mass types to track, all checked differently
		--[[
			Static is updated only when parenting is updated, or a mass change function is called, and after a delay (not indefinite)
			Dynamic is from any entities deemed able to change mass at will (ammo, racks, fuel)
			SubTurret is from any turret components parented to this one, and will simply used whatever was calculated already
		]]
		self.StaticMass    = 0
		self.StaticCoM     = Vector()
		self.DynamicMass   = 0
		self.DynamicCoM    = Vector()
		self.SubTurretMass = 0
		self.SubTurretCoM  = Vector()

		self.Active           = false
		self.SlewRate         = 0 -- Rotation rate
		self.Stabilized       = false
		self.StabilizeAmount  = 0
		self.LastRotatorAngle = self.Rotator:GetAngles()

		self.MaxSlewRate = 0
		self.SlewAccel   = 0

		if TurretID == "Turret-H" then
			local MinDeg = self:ACF_GetUserVar("MinDeg")
			local MaxDeg = self:ACF_GetUserVar("MaxDeg")
			self.MinDeg = MinDeg
			self.MaxDeg = MaxDeg
			self.HasArc = not ((MinDeg == -180) and (MaxDeg == 180))
		else
			self.MinDeg = math_max(self:ACF_GetUserVar("MinDeg"), -85)
			self.MaxDeg = math_min(self:ACF_GetUserVar("MaxDeg"), 85)
			self.HasArc = true
		end

		self.MotorMaxSpeed  = 1
		self.MotorGearRatio = 1
		self.EffortScale    = 1
		self.Complexity     = 1

		local MaxSpeed    = self:ACF_GetUserVar("MaxSpeed") or 0
		self.SpeedLimited = MaxSpeed > 0
		self.MaxSpeed     = MaxSpeed

		if self.SoundPlaying == true then
			Sounds.SendAdjustableSound(self, true)
		end
		self.SoundPlaying = false
		self.SoundPath    = self.HandGear.Sound

		self.ScaledArmor  = (Turret.Armor.Min * (1 - SizePerc)) + (Turret.Armor.Max * SizePerc)

		-- Rebuild wire IO now that the drive type (and its Bearing/Elevation input) is known.
		self:ACF_SetupWireFunctions()

		self:SetNWString("WireName", "ACF " .. self.Name)
		self:SetNWString("Class", self.Class)

		WireLib.TriggerOutput(self, "Mass", 0)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		local Health    = self.ACF.Health
		local MaxHealth = self.ACF.MaxHealth
		self.DamageScale = (Health and MaxHealth) and math_max((Health / (MaxHealth * 0.75)) - 0.25 / 0.75, 0) or 1

		Contraption.SetMass(self, GetMass(Turret, Size))

		self:UpdateTurretMass()
	end

	------------------

	util.AddNetworkString("ACF_RequestTurretInfo")
	util.AddNetworkString("ACF_InvalidateTurretInfo")

	function ENT:InvalidateClientInfo()
		net.Start("ACF_InvalidateTurretInfo")
			net.WriteEntity(self)
		net.Broadcast()
	end

	net.Receive("ACF_RequestTurretInfo", function(_, Player)
		local Entity = net.ReadEntity()

		if IsValid(Entity) then
			local CoM = Entity.TurretData.LocalCoM
			local Data = {
				LocalCoM	= Vector(math_Round(CoM.x, 1), math_Round(CoM.y, 1), math_Round(CoM.z, 1)),
				Mass		= math_Round(Entity.TurretData.TotalMass, 1),
				MinDeg		= Entity.MinDeg,
				MaxDeg		= Entity.MaxDeg,
				CoMDist		= math_Round(CoM:Length2D(), 2),
				Type		= Entity.Turret
			}

			net.Start("ACF_RequestTurretInfo")
				net.WriteEntity(Entity)
				net.WriteEntity(Entity.Rotator)
				net.WriteVector(Data.LocalCoM)
				net.WriteFloat(Data.Mass)
				net.WriteFloat(Data.MinDeg)
				net.WriteFloat(Data.MaxDeg)
				net.WriteFloat(Data.CoMDist)
				net.WriteString(Data.Type)
			net.Send(Player)
		end
	end)

	------------------

	-- A turret's drive type (horizontal/vertical) is structural; it can only be changed
	-- by respawning, not by updating an existing turret.
	hook.Add("ACF_PreUpdateEntity", "ACF Turret Type Guard", function(Class, Entity, ClientData)
		if Class ~= "acf_turret" then return end
		if not Entity.Turret then return end -- Fresh spawn, nothing to compare against yet

		local Sel     = ClientData and ClientData.Turret
		local NewType = Sel and Classes.GetTypeByName(Sel.Type)
		local NewID   = NewType and NewType.ID

		if NewID and (Entity.Turret ~= NewID) then
			return false, "Turret type is mismatched!\n(" .. Entity.Turret .. " > " .. NewID .. ")"
		end
	end)

	function ENT:OnRemove()
		local SelfTbl = ENTITY.GetTable(self)

		if IsValid(SelfTbl.Rotator) then
			SelfTbl.Rotator:Remove()
		end

		if SelfTbl.Crews and next(SelfTbl.Crews) then
			for Crew in pairs(SelfTbl.Crews) do
				if IsValid(Crew) then self:Unlink(Crew) end
			end
		end
	end

	------------------

	-- Entity types that can have a different mass from time to time
	-- Need to hook into SetMass specifically for these so it can do a simple update for the turret
	local DynamicMassTypes = {
		acf_ammo		= true,
		acf_rack		= true,
		acf_fueltank	= true
	}

	local function GetFilteredChildren(Entity, Pass, FilterClass) -- Specialized for this use case, this will stop at any subturrets found, but still include them
		local List = Pass or {}

		if Entity.Rotator then Entity = Entity.Rotator end

		for _, V in pairs(Entity:GetChildren()) do
			if not IsValid(V) or List[V] then continue end

			local Parent = V:GetParent()
			if Parent == NULL then continue end -- somehow this shit is still a problem

			List[V] = V

			if V:GetClass() == FilterClass then continue end

			GetFilteredChildren(V, List, FilterClass)
		end

		return List
	end

	local function Proxy_ACF_OnParent(self, _, _)
		local SelfTbl = ENTITY.GetTable(self)
		if (not IsValid(SelfTbl.ACF_TurretAncestor)) or (not Contraption.HasAncestor(self, SelfTbl.ACF_TurretAncestor)) then self.CFW_OnParented = nil SelfTbl.ACF_TurretAncestor = nil return end

		SelfTbl.ACF_TurretAncestor:UpdateTurretMass(false)
	end

	local function Proxy_ACF_OnMassChange(self)
		local SelfTbl = ENTITY.GetTable(self)
		if (not IsValid(SelfTbl.ACF_TurretAncestor)) or (not Contraption.HasAncestor(self, SelfTbl.ACF_TurretAncestor)) then self.ACF_OnMassChange = nil SelfTbl.ACF_TurretAncestor = nil return end

		SelfTbl.ACF_TurretAncestor:UpdateTurretMass(false)
	end

	local function ParentLink(Turret, Entity, Connect)
		if Connect then
			Entity.CFW_OnParented		= Proxy_ACF_OnParent
			Entity.ACF_OnMassChange		= Proxy_ACF_OnMassChange
			Entity.ACF_TurretAncestor	= Turret
		else
			Entity.CFW_OnParented		= nil
			Entity.ACF_OnMassChange		= nil
			Entity.ACF_TurretAncestor	= nil
		end

		if IsValid(Turret) then
			Turret:InvalidateClientInfo()
		end
	end

	local function BuildWatchlist(Entity) -- Potentially hot and heavy, should only be triggered after a (maximum) delay to catch large changes and not every single new entity
		if not IsValid(Entity) then return end

		local PhysObj = Entity.ACF.PhysObj
		if not IsValid(PhysObj) then return end

		local Mass = 0
		local CoM = Vector()
		local AddCoM = {}

		Entity.DynamicEntities	= {}
		Entity.SubTurrets		= {}

		local ChildList = GetFilteredChildren(Entity, {}, "acf_turret")

		for k in pairs(ChildList) do
			local Class = k:GetClass()

			k.ACF_TurretAncestor = nil
			if Class == "acf_turret" then
				Entity.SubTurrets[k] = true

				k.ACF_TurretAncestor = Entity
			elseif DynamicMassTypes[Class] then
				Entity.DynamicEntities[k] = true

				ParentLink(Entity, k, true)
			else
				if not ACF.Check(k) then continue end
				ParentLink(Entity, k, true)

				if Class == "acf_turret_motor" then k:ValidatePlacement() end

				local PO = k:GetPhysicsObject()
				if not IsValid(PO) then continue end

				Mass = Mass + PO:GetMass()
				AddCoM[k] = PO
			end
		end

		Entity.StaticMass = Mass

		local Rotator = Entity.Rotator
		for Ent, PhysObj in pairs(AddCoM) do
			local Shift = Rotator:WorldToLocal(Ent:LocalToWorld(PhysObj:GetMassCenter())) * (PhysObj:GetMass() / Mass)
			CoM = CoM + Shift
		end

		Entity.StaticCoM = CoM
	end

	local function GetDynamicMass(Entity) -- Returns mass center (local to rotator) and amount from all "dynamic" entities, should be triggered after a resettable delay (only delayable by so long) in order to reduce spammed calls
		if not IsValid(Entity) then return end

		if next(Entity.DynamicEntities) == nil then return Vector(), 0 end -- Early stop if empty

		local Mass = 0
		local CoM = Vector()
		local AddCoM = {}

		for k in pairs(Entity.DynamicEntities) do
			if not IsValid(k) then continue end
			local PO = k:GetPhysicsObject()
			if not IsValid(PO) then continue end

			Mass = Mass + PO:GetMass()
			AddCoM[k] = PO
		end

		Entity.DynamicMass = Mass

		local Rotator = Entity.Rotator
		for Ent, PhysObj in pairs(AddCoM) do
			local Shift = Rotator:WorldToLocal(Ent:LocalToWorld(PhysObj:GetMassCenter())) * (PhysObj:GetMass() / Mass)
			CoM = CoM + Shift
		end

		Entity.DynamicCoM = CoM

		return CoM, Mass
	end

	local function GetSubTurretMass(Entity) -- Returns mass center (local to rotator) and amount from all subturrets
		if not IsValid(Entity) then return end

		Entity.Complexity = 1

		if next(Entity.SubTurrets) == nil then return Vector(), 0 end

		local Mass = 0
		local CoM = Vector()
		local AddCoM = {}

		for k in pairs(Entity.SubTurrets) do
			if not IsValid(k) then continue end

			if (k.Turret == Entity.Turret) and (k.TurretData.RingSize > (Entity.TurretData.RingSize * 0.5)) then
				Entity.Complexity = Entity.Complexity * math_Clamp(((Entity.TurretData.RingSize * 0.5) / k.TurretData.RingSize) ^ 2, 0, 1)
			end

			Mass = Mass + k:GetTotalMass() + k.ACF.Mass
			AddCoM[k] = true
		end

		Entity.SubTurretMass = Mass

		local Rotator = Entity.Rotator
		for Turret in pairs(AddCoM) do
			local Shift = Rotator:WorldToLocal(Turret.Rotator:LocalToWorld(Turret:GetTurretMassCenter())) * (Turret.TurretData.TotalMass / Mass)
			CoM = CoM + Shift
		end

		Entity.SubTurretCoM = CoM

		return CoM, Mass
	end

	function ENT:UpdateSound()
		local SelfTbl = ENTITY.GetTable(self)

		local Motor       = SelfTbl.Motor
		local SoundPath   = SelfTbl.HandGear.Sound
		local SoundPitch  = 70
		local SoundVolume = 0.1

		if IsValid(Motor) then
			SoundPath  = Motor.SoundPath
			SoundPitch = Motor.SoundPitch and math_Clamp(Motor.SoundPitch * 100, 0, 255) or SoundPitch
			SoundVolume = Motor.SoundVolume or SoundVolume
		end

		SelfTbl.SoundPath   = SoundPath
		SelfTbl.SoundPitch  = SoundPitch
		SelfTbl.SoundVolume = SoundVolume
	end

	function ENT_UpdateTurretSlew(self, SelfTbl)
		SelfTbl		        = SelfTbl or ENTITY.GetTable(self)

		local SlewInput 	= SelfTbl.HandGear
		local Stabilized	= false
		local StabilizeAmount	= 0
		local MotorDistance = IsValid(SelfTbl.Motor) and (SelfTbl.Motor.CompSize * 7.5) or 0
		local MaxDistance 	= (((SelfTbl.TurretData.RingSize / 2) * 1.2) + 12 + MotorDistance) ^ 2

		if IsValid(SelfTbl.Motor) and SelfTbl.Motor:GetPos():DistToSqr(self:GetPos()) > MaxDistance then
			local USound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(self, USound, 70, 100, 1)
			Sounds.SendSound(SelfTbl.Motor, USound, 70, 100, 1)
			self:Unlink(SelfTbl.Motor)

			-- No sense checking for this separately since it can't function without the motor anyway
			-- Using separate link distance as gyros can be parented to other things
			if IsValid(SelfTbl.Gyro) and ENTITY.GetPos(SelfTbl.Gyro):DistToSqr(ENTITY.GetPos(self)) > MaxLinkDistance then
				Sounds.SendSound(self, USound, 70, 100, 1)
				Sounds.SendSound(SelfTbl.Gyro, USound, 70, 100, 1)
				self:Unlink(SelfTbl.Gyro)
			end
		end

		if IsValid(SelfTbl.Motor) and SelfTbl.Motor:IsActive() then
			SlewInput	= SelfTbl.Motor:GetInfo()
			Stabilized	= IsValid(SelfTbl.Gyro) and SelfTbl.Gyro:IsActive()
			if Stabilized then StabilizeAmount = SelfTbl.Gyro:GetInfo() end
		end

		-- Scale for being off-axis, further affects friction
		local Tilt = 1
		if SelfTbl.Turret == "Turret-V" then
			Tilt = math_max(1 - ENTITY.GetRight(self):Dot(vector_up), 0)
		else
			Tilt = math_max(ENTITY.GetUp(self):Dot(vector_up), 0)
		end

		SelfTbl.TurretData.Tilt = Tilt

		local SlewData		= SelfTbl.ClassData.CalcSpeed(SelfTbl.TurretData, SlewInput)

		-- Allowing vertical turret drives to have a small amount of stabilization, but only if they aren't powered and the mass is well balanced
		-- Think about certain turrets in WW2 where the gun was vertically aimed by the gunner with his shoulder
		-- Only going to allow at most 25% so it's always better to motorize the drive and link a gyro to it
		-- Also limited to 125mm distance from center of drive, where it will be strongest at the center
		if (SelfTbl.ID == "Turret-V") and ((SelfTbl.TurretData.LocalCoM:Length2DSqr() * ACF.InchToMm) < (125 ^ 2)) and not IsValid(SelfTbl.Motor) then
			Stabilized = true
			StabilizeAmount = (1 - ((SelfTbl.TurretData.LocalCoM:Length2DSqr() * ACF.InchToMm) / (125 ^ 2))) * 0.25
		end

		SelfTbl.MotorMaxSpeed		= SlewData.MotorMaxSpeed or 1 -- Both this and MotorGearRatio are used for sound calculations
		SelfTbl.MotorGearRatio		= SlewData.MotorGearRatio or 1

		self:UpdateSound()

		SelfTbl.MaxSlewRate		= SlewData.MaxSlewRate * SelfTbl.Complexity
		if SelfTbl.SpeedLimited then SelfTbl.MaxSlewRate = math_min(SelfTbl.MaxSlewRate, SelfTbl.MaxSpeed) end
		SelfTbl.SlewAccel			= SlewData.SlewAccel * SelfTbl.Complexity
		SelfTbl.EffortScale		= SlewData.EffortScale or 1 -- Sound scaling
		SelfTbl.Stabilized			= Stabilized
		SelfTbl.StabilizeAmount	= StabilizeAmount
	end
	ENT.UpdateTurretSlew = ENT_UpdateTurretSlew

	function ENT_GetTotalMass(self, SelfTbl) -- Sum of all of the mass mounted on the turret, plus the turret component itself
		if not IsValid(self) then return 0 end

		SelfTbl = SelfTbl or ENTITY.GetTable(self)

		local PhysObj = ENTITY.GetPhysicsObject(self)
		if not IsValid(PhysObj) then return 0 end

		SelfTbl.TurretData.TotalMass = SelfTbl.StaticMass + SelfTbl.DynamicMass + SelfTbl.SubTurretMass

		WireLib.TriggerOutput(self, "Mass", SelfTbl.TurretData.TotalMass)

		return SelfTbl.TurretData.TotalMass
	end
	ENT.GetTotalMass = ENT_GetTotalMass

	function ENT_GetTurretMassCenter(self, SelfTbl) -- Returns a local vector of the center of all of the mass on the turret component, from the rotator
		SelfTbl = SelfTbl or ENTITY.GetTable(self)

		local PhysObj = ENTITY.GetPhysicsObject(self)
		if not IsValid(PhysObj) then return Vector() end

		local MassTotal = ENT_GetTotalMass(self, SelfTbl) + SelfTbl.ACF.Mass

		SelfTbl.TurretData.LocalCoM = (PhysObj:GetMassCenter() * (SelfTbl.ACF.Mass / MassTotal)) + (SelfTbl.StaticCoM * (SelfTbl.StaticMass / MassTotal)) + (SelfTbl.DynamicCoM * (SelfTbl.DynamicMass / MassTotal)) + (SelfTbl.SubTurretCoM * (SelfTbl.SubTurretMass / MassTotal))

		self:UpdateOverlay()
		return SelfTbl.TurretData.LocalCoM
	end
	ENT.GetTurretMassCenter = ENT_GetTurretMassCenter

	function ENT_CheckCoM(self, Force, SelfTbl)
		SelfTbl	= SelfTbl or ENTITY.GetTable(self)

		if (Force == false) and (Clock.CurTime < SelfTbl.CoMCheckDelay) then return end
		SelfTbl.CoMCheckDelay = Clock.CurTime + 2 + math.Rand(1, 2)

		GetDynamicMass(self)
		GetSubTurretMass(self)

		if SelfTbl.ACF_TurretAncestor then
			SelfTbl.Complexity = (SelfTbl.Complexity or 1) * (SelfTbl.ACF_TurretAncestor.Complexity or 1)
		end

		ENT_GetTotalMass(self, SelfTbl)
		ENT_GetTurretMassCenter(self, SelfTbl)

		ENT_UpdateTurretSlew(self, SelfTbl)
		self:UpdateOverlay()
	end
	ENT.CheckCoM = ENT_CheckCoM

	function ENT:UpdateTurretMass(Force) -- Will call the other parts above, this should be triggered after a parent (safe to call multiple times e.g. on dupe paste, as it has an internal delay to prevent spamming)
		local SelfTbl = ENTITY.GetTable(self)
		if (Force == false) and (Clock.CurTime < SelfTbl.MassCheckDelay) then return end

		SelfTbl.MassCheckDelay = Clock.CurTime + 2 + math.Rand(1, 2)

		TimerSimple(Force and 0 or 3, function()
			if not IsValid(self) then return end
			SelfTbl = ENTITY.GetTable(self)

			if IsValid(SelfTbl.ACF_TurretAncestor) then
				SelfTbl.ACF_TurretAncestor:UpdateTurretMass(true)
			end

			BuildWatchlist(self)
			ENT_CheckCoM(self, Force, SelfTbl)

			self:UpdateOverlay()
		end)
	end
end

do -- Overlay
	function ENT:ACF_UpdateOverlayState(State)
		local SelfTbl	= ENTITY.GetTable(self)
		local SlewMax	= math_Round(SelfTbl.MaxSlewRate * SelfTbl.DamageScale, 2)
		local SlewAccel	= math_Round(SelfTbl.SlewAccel * SelfTbl.DamageScale, 4)
		local TotalMass	= math_Round(SelfTbl.TurretData.TotalMass, 1)
		local MaxMass	= math_Round(SelfTbl.MaxMass, 1)

		State:AddNumber("Max Rotation", SlewMax, " deg/s")
		State:AddNumber("Accel", SlewAccel, " deg/s^2")
		State:AddNumber("Teeth", SelfTbl.TurretData.Teeth, " t")
		State:AddProgressBar("Current Mass", TotalMass, MaxMass, " kg")

		if SelfTbl.HasArc then
			State:AddKeyValue("Arc", SelfTbl.MinDeg .. "/" .. SelfTbl.MaxDeg)
		end

		if IsValid(SelfTbl.Motor) then
			State:AddKeyValue("Motor", tostring(SelfTbl.Motor))
		end

		if IsValid(SelfTbl.Gyro) then
			State:AddKeyValue("Gyro", tostring(SelfTbl.Gyro))
		end

		if SelfTbl.Stabilized and IsValid(SelfTbl.Gyro) and IsValid(SelfTbl.Motor) then
			State:AddLabel("Motor stabilized at " .. math_Round(SelfTbl.StabilizeAmount * 100, 1) .. "%")
		elseif SelfTbl.Stabilized then
			State:AddLabel("Naturally stabilized at " .. math_Round(SelfTbl.StabilizeAmount * 100, 1) .. "%")
		end
	end
end

do -- Metamethods
	do	-- Links
		ACF.RegisterLinkSource("acf_turret", "Motors")
		ACF.RegisterLinkSource("acf_turret", "Gyros")

		-- Motor links

		ACF.RegisterClassLink("acf_turret", "acf_turret_motor", function(This, Motor)
			if IsValid(This.Motor) then return false, "This turret already has a motor linked!" end
			if IsValid(Motor.Turret) and (Motor.Turret ~= This) then return false, "This motor is already linked to different turret!" end
			if IsValid(Motor.Turret) and (Motor.Turret == This) then return false, "This motor is already linked to this turret!" end
			if This:GetPos():DistToSqr(Motor:GetPos()) > ((((This.TurretData.RingSize / 2) * 1.2) + 12 + Motor.CompSize * 7.5) ^ 2) then return false, "This motor is too far from the turret!" end

			This.Motor		= Motor
			Motor.Turret	= This

			Motor:ValidatePlacement()
			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Motor:UpdateOverlay(true)

			return true, "Motor linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_turret", "acf_turret_motor", function(This, Motor)
			if not IsValid(This.Motor) then return false, "This turret doesn't have a motor linked!" end
			if not IsValid(Motor.Turret) then return false, "This motor isn't linked to a turret!" end
			if This.Motor ~= Motor then return false, "This turret isn't linked to this motor!" end

			This.Motor		= nil
			Motor.Turret	= nil

			Motor:ValidatePlacement()
			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Motor:UpdateOverlay(true)

			return true, "Motor unlinked successfully."
		end)

		-- Gyro links

		ACF.RegisterClassLink("acf_turret", "acf_turret_gyro", function(This, Gyro)
			if IsValid(This.Gyro) then return false, "This turret already has a gyro linked!" end
			if Gyro.IsDual then
				if IsValid(Gyro[This.ID]) then return false, "This gyro is already linked to this type of turret!" end
				if This:GetPos():DistToSqr(Gyro:GetPos()) > MaxLinkDistance then return false, "This gyro is too far from the turret!" end

				Gyro[This.ID]	= This
			else
				if IsValid(Gyro.Turret) and (Gyro.Turret ~= This) then return false, "This gyro is already linked to a turret!" end
				if This:GetPos():DistToSqr(Gyro:GetPos()) > MaxLinkDistance then return false, "This gyro is too far from the turret!" end

				Gyro.Turret		= This
			end

			This.Gyro	= Gyro

			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Gyro:UpdateOverlay(true)

			return true, "Gyro linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_turret", "acf_turret_gyro", function(This, Gyro)
			if not IsValid(This.Gyro) then return false, "This turret doesn't have a gyro linked!" end

			if Gyro.IsDual then
				if not IsValid(Gyro[This.ID]) then return false, "This gyro isn't linked to this type of turret!" end
				if This ~= Gyro[This.ID] then return false, "This turret isn't linked to this gyro!" end

				Gyro[This.ID]	= nil
			else
				if not IsValid(Gyro.Turret) then return false, "This gyro isn't linked to a turret!" end
				if This.Gyro ~= Gyro then return false, "This turret isn't linked to this gyro!" end

				Gyro.Turret		= nil
			end

			This.Gyro	= nil

			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Gyro:UpdateOverlay(true)

			return true, "Gyro unlinked successfully."
		end)
	end

	do	-- Dupe Support
		function ENT:PreEntityCopy()
			local SelfTbl = ENTITY.GetTable(self)

			if IsValid(SelfTbl.Motor) then
				duplicator.StoreEntityModifier(self, "ACFMotor", {SelfTbl.Motor:EntIndex()})
			end

			-- Gyros!
			if IsValid(SelfTbl.Gyro) then
				duplicator.StoreEntityModifier(self, "ACFGyro", {SelfTbl.Gyro:EntIndex()})
			end

			-- Wire dupe info
			self.BaseClass.PreEntityCopy(self)
		end

		function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
			local EntMods = Ent.EntityMods

			if EntMods.ACFMotor then
				self:Link(CreatedEntities[EntMods.ACFMotor[1]])

				EntMods.ACFMotor = nil
			end

			if EntMods.ACFGyro then
				self:Link(CreatedEntities[EntMods.ACFGyro[1]])

				EntMods.ACFGyro = nil
			end

			self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		end
	end

	do	-- Think
		-- This is written this way for performance reasons in the think hook
		local function SetSoundState(self, State, SelfTbl)
			SelfTbl = SelfTbl or ENTITY.GetTable(self)

			if State ~= SelfTbl.SoundPlaying then
				if State == true then
					Sounds.CreateAdjustableSound(self, SelfTbl.SoundPath, 100, 0)
					SelfTbl.CurrentSound = SelfTbl.SoundPath
				else
					Sounds.SendAdjustableSound(self, true)
				end
			end

			SelfTbl.SoundPlaying = State
		end
		ENT.SetSoundState = SetSoundState

		function ENT:InputDirection(Direction)
			local SelfTbl = ENTITY.GetTable(self)
			if SelfTbl.Disabled then return end

			SelfTbl.Manual		= true
			SelfTbl.UseVector	= false

			if isnumber(Direction) then
				SelfTbl.DesiredDeg = math.NormalizeAngle(Direction)
				return
			end

			SelfTbl.Manual		= false

			if isangle(Direction) then
				Direction:Normalize()
				SelfTbl.DesiredAngle = Direction

				return
			end
			if isvector(Direction) then
				SelfTbl.UseVector = true
				SelfTbl.DesiredVector = Direction

				return
			end
		end

		function ENT:Think() -- The meat and POE-TAE-TOES of the turret working
			local SelfTbl = ENTITY.GetTable(self)

			if SelfTbl.Disabled then
				SetSoundState(self, false, SelfTbl)
				ENTITY.NextThink(self, Clock.CurTime + 0.1)

				return true
			end

			ENT_CheckCoM(self, false, SelfTbl)
			local Tick		= Clock.DeltaTime
			local Rotator	= SelfTbl.Rotator
			if not IsValid(Rotator) then ENTITY.Remove(self) return end

			local Scale		    = SelfTbl.DamageScale * Tick

			local SlewMax		= SelfTbl.MaxSlewRate * Scale
			local SlewAccel		= SelfTbl.SlewAccel * Scale
			local MaxImpulse	= math_min(SlewMax, SlewAccel)

			local AngleChange	= SelfTbl.CurrentAngle

			-- Something or another has caused the turret to be unable to rotate, so don't waste the extra processing time
			if MaxImpulse == 0 then
				SelfTbl.LastRotatorAngle = ENTITY.GetAngles(Rotator)

				if SelfTbl.SoundPlaying == true then
					SetSoundState(self, false, SelfTbl)
				end

				ENTITY.NextThink(self, Clock.CurTime + 0.1)
				return true
			end

			if SelfTbl.UseVector and SelfTbl.Manual == false then
				local DesiredAngle = (SelfTbl.DesiredVector - ENTITY.GetPos(Rotator))
				VECTOR.Normalize(DesiredAngle)
				SelfTbl.DesiredAngle = VECTOR.Angle(DesiredAngle)
			end

			local StabAmt	= math_Clamp(SelfTbl.SlewFuncs.GetStab(self), -SlewMax, SlewMax)
			local StabSign	= -StabAmt < 0 and -1 or 1

			local TargetBearing	= math_Round(SelfTbl.SlewFuncs.GetTargetBearing(self, StabAmt), 8)

			local Sign			= TargetBearing < 0 and -1 or 1
			local Dist			= math_abs(TargetBearing)
			local FinalAccel	= math_Clamp(TargetBearing, -MaxImpulse, MaxImpulse)
			local BrakingDist	= SelfTbl.SlewRate ^ 2 / math_abs(FinalAccel) / 2

			if StabSign == Sign then
				StabAmt = StabAmt * math_min(math_max(0, 1 - (math_abs(StabAmt) / MaxImpulse) ^ 2), 1)
			end

			if SelfTbl.Active then
				SelfTbl.SlewRate = math_Clamp(SelfTbl.SlewRate + (math_abs(FinalAccel) * ((Dist + (SelfTbl.SlewRate * 2 * -Sign)) >= BrakingDist and Sign or -Sign)), -SlewMax, SlewMax)

				if SelfTbl.SlewRate ~= 0 and (Dist <= math_abs(FinalAccel)) and (SelfTbl.SlewRate <= FinalAccel) then
					SelfTbl.SlewRate = 0
					SelfTbl.CurrentAngle = SelfTbl.CurrentAngle + TargetBearing / 2
				end
			elseif not SelfTbl.Active and SelfTbl.SlewRate ~= 0 then
				SelfTbl.SlewRate = SelfTbl.SlewRate - (math_min(SlewAccel, math_abs(SelfTbl.SlewRate)) * (SelfTbl.SlewRate >= 0 and 1 or -1))
			end

			SelfTbl.CurrentAngle = SelfTbl.CurrentAngle + math_Clamp(SelfTbl.SlewRate + StabAmt, -SlewMax, SlewMax)

			if SelfTbl.HasArc then
				SelfTbl.CurrentAngle = math_Clamp(SelfTbl.CurrentAngle, -SelfTbl.MaxDeg, -SelfTbl.MinDeg)
			end

			SelfTbl.CurrentAngle = math.NormalizeAngle(SelfTbl.CurrentAngle)

			WireLib.TriggerOutput(self, "Degrees", -SelfTbl.CurrentAngle)

			SelfTbl.SlewFuncs.SetRotatorAngle(self, SelfTbl.Rotator)

			local MotorSpeed = math_Clamp(math_abs(SelfTbl.CurrentAngle - AngleChange), 0, SlewMax) / Tick

			local MotorSpeedPerc = MotorSpeed / SelfTbl.MotorMaxSpeed
			if MotorSpeedPerc > 0.1 and SelfTbl.SoundPlaying == false then
				SetSoundState(self, true, SelfTbl)
			elseif MotorSpeedPerc <= 0.1 and SelfTbl.SoundPlaying == true then
				SetSoundState(self, false, SelfTbl)
			end

			if SelfTbl.SoundPlaying == true then
				if SelfTbl.SoundPath ~= (SelfTbl.CurrentSound or "") then -- should only get set off if the motor is enabled/disabled while the sound is playing
					SetSoundState(self, false, SelfTbl)
				else
					local SoundPitch = math_Clamp(SelfTbl.SoundPitch + math.ceil(MotorSpeedPerc * 30), 0, 255)
					local SoundVolume = SelfTbl.SoundVolume + (SelfTbl.EffortScale * 0.9)

					Sounds.SendAdjustableSound(self, false, SoundPitch, SoundVolume)
				end
			end

			SelfTbl.LastRotatorAngle	= Rotator:GetAngles()

			ENTITY.NextThink(self, Clock.CurTime)

			return true
		end
	end

	do	-- Input/Outputs/Eventually linking
		ACF.AddInputAction("acf_turret", "Active", function(Entity, Value)
			if Entity.Disabled then return end

			Entity.Active = tobool(Value)
		end)

		ACF.AddInputAction("acf_turret", "Angle", function(Entity, Value)
			local Ang = isangle(Value) and Value or angle_zero

			Entity:InputDirection(Ang)
		end)

		ACF.AddInputAction("acf_turret", "Vector", function(Entity, Value)
			local Pos = isvector(Value) and Value or vector_origin

			Entity:InputDirection(Pos)
		end)

		ACF.AddInputAction("acf_turret", "Bearing", function(Entity, Value) -- Only on horizontal drives
			if not isnumber(Value) then return end

			Entity:InputDirection(Value)
		end)

		ACF.AddInputAction("acf_turret", "Elevation", function(Entity, Value) -- Only on vertical drives
			if not isnumber(Value) then return end

			Entity:InputDirection(Value)
		end)
	end

	do	-- Activation and Damage handling

		function ENT:Enable()
			self:UpdateOverlay()
		end

		function ENT:Disable()
			local SelfTbl = ENTITY.GetTable(self)

			SelfTbl.Active 	= false
			SelfTbl.SlewRate	= 0
			self:UpdateOverlay()
		end

		------------------

		function ENT:ACF_Activate(Recalc)
			local SelfTbl = ENTITY.GetTable(self)
			local SelfACF = SelfTbl.ACF

			local PhysObj	= SelfACF.PhysObj
			local Area		= PHYSOBJ.GetSurfaceArea(PhysObj) * ACF.InchToCmSq
			local Armour	= SelfTbl.ScaledArmor
			local Health	= (Area / ACF.Threshold) * 5
			local Percent	= 1

			if Recalc and SelfACF.Health and SelfACF.MaxHealth then
				Percent = SelfACF.Health / SelfACF.MaxHealth
			end

			SelfACF.Area		= Area
			SelfACF.Health		= Health * Percent
			SelfACF.MaxHealth	= Health
			SelfACF.Armour		= Armour * Percent
			SelfACF.MaxArmour	= Armour
			SelfACF.Type		= "Prop"
		end

		local TempDamageVector = Vector(0, 0, 0)
		function ENT:ACF_OnDamage(DmgResult, DmgInfo)
			local SelfTbl = ENTITY.GetTable(self)

			local Health = SelfTbl.ACF.Health
			local HitRes = DmgResult:Compute()

			if DmgInfo.Attacker and IsValid(DmgInfo.Attacker) then
				local Attacker = DmgInfo.Attacker
				-- If the damage source is from an ammo crate or fueltank, store the time this damage took place...
				local Cookoff = (Attacker:GetClass() == "acf_ammo" or Attacker:GetClass() == "acf_fueltank") and Attacker.Exploding == true
				if Cookoff then	SelfTbl.ShouldCookoff = Clock.CurTime end

				-- If damaged by a cookoff in the last second, and the turret will die, then launch the turret
				if (SelfTbl.ShouldCookoff and (Clock.CurTime - SelfTbl.ShouldCookoff) < 1) and HitRes.Damage >= SelfTbl.ACF.Health and SelfTbl.Disconnect == false then
					SelfTbl.Disconnect	= true

					ENTITY.SetParent(self, nil)
					local PO = ENTITY.GetPhysicsObject(self)
					if IsValid(PO) then
						PHYSOBJ.EnableMotion(PO, true)
						local Mass = PHYSOBJ.GetMass(PO)

						-- Start force direction (selfpos - attacker pos)
						local Force = ENTITY.GetPos(self)
						VECTOR.Sub(Force, ENTITY.GetPos(Attacker))
						VECTOR.Normalize(Force)

						-- Multiply drection by mass
						VECTOR.Mul(Force, Mass)
						-- Multiply by mass ratio 
						VECTOR.Mul(Force, Mass / (Mass + SelfTbl.TurretData.TotalMass))

						-- Setup offset as pos + ringsize randomness
						local Offset = ENTITY.GetPos(self)
						local RandMin, RandMax = -SelfTbl.RingSize / 2, SelfTbl.RingSize / 2
						VECTOR.SetUnpacked(TempDamageVector, math.Rand(RandMin, RandMax), math.Rand(RandMin, RandMax), math.Rand(RandMin, RandMax))
						VECTOR.Add(Offset, TempDamageVector)

						-- Apply cookoff force
						PHYSOBJ.ApplyForceOffset(PO, Force, Offset)
					end

					TimerSimple(7.5, function()
						if not IsValid(self) then return end
						self:Remove()
					end)
				end
			end

			HitRes.Kill = false

			local NewHealth = math_max(0, Health - HitRes.Damage)

			SelfTbl.ACF.Health = NewHealth
			SelfTbl.ACF.Armour = SelfTbl.ACF.MaxArmour * (NewHealth / SelfTbl.ACF.MaxHealth)

			SelfTbl.DamageScale = math_max((SelfTbl.ACF.Health / (SelfTbl.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)
			self:UpdateOverlay()

			return HitRes
		end

		function ENT:ACF_OnRepaired() -- Normally has OldArmor, OldHealth, Armor, and Health passed
			local SelfTbl = ENTITY.GetTable(self)
			SelfTbl.DamageScale = math_max((SelfTbl.ACF.Health / (SelfTbl.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)

			SelfTbl.ACF.Armour = SelfTbl.ACF.MaxArmour * (SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth)

			self:UpdateOverlay()
		end

		function ENT:CFW_OnParented(Entity, _) -- Potentially called many times a second, so we won't force mass to update
			local SelfTbl = ENTITY.GetTable(self)
			local Class   = ENTITY.GetClass(self)

			if Class == "acf_turret_rotator" then return end

			self:UpdateTurretMass(false)

			-- Should only be called when parenting, checks the position of the motor relative to the ring
			-- Shooouuld be using CFW_OnParented as it was made with this in mind, but turret entities will overwrite it with the above function to ensure everything is captured
			if Class == "acf_turret_motor" then Entity:ValidatePlacement() end
			if IsValid(SelfTbl.Motor) then SelfTbl.Motor:ValidatePlacement() end
		end

		function ENT:GetCost()
			local SelfTbl   = ENTITY.GetTable(self)
			local Size		= SelfTbl.TurretData.RingSize

			if SelfTbl.Turret == "Turret-H" then
				return 0.1 * Size
			else
				return 0.2 * Size
			end
		end

		function ENT:OnRemove()
			local SelfTbl   = ENTITY.GetTable(self)
			-- TODO: Destroy sound when that gets added

			if IsValid(SelfTbl.Motor) then
				SelfTbl.Motor:ValidatePlacement()
				SelfTbl:Unlink(SelfTbl.Motor)
			end

			if IsValid(SelfTbl.Gyro) then self:Unlink(SelfTbl.Gyro) end

			WireLib.Remove(self)
		end
	end
end