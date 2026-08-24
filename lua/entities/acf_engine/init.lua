AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF
local Mobility    = ACF.Mobility
local MobilityObj = Mobility.Objects
local MaxDistance = ACF.MobilityLinkDistance * ACF.MobilityLinkDistance

local ENTITY 			= FindMetaTable("Entity")
local PHYSOBJ			= FindMetaTable("PhysObj")

local IsEntityValid		= ACF.Optimizations.IsEntityValid
local IsPhysObjValid	= ACF.Optimizations.IsPhysObjValid

--===============================================================================================--
-- Engine class setup
--===============================================================================================--
do
	ACF.RegisterClassLink("acf_engine", "acf_fueltank", function(Engine, Target)
		local TargetFuelType = ACF.Classes.GetTypeName(Target:ACF_GetUserVar("FuelType"):GetType())

		if Engine.FuelTanks[Target] then return false, "This engine is already linked to this fuel tank!" end
		if Target.Engines[Engine] then return false, "This engine is already linked to this fuel tank!" end
		if not Engine.FuelTypes[TargetFuelType] then return false, "Cannot link because fuel type is incompatible." end
		if Target.NoLinks then return false, "This fuel tank doesn't allow linking." end
		if Engine:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "This fuel tank is too far away from this engine." end

		Engine.FuelTanks[Target] = true
		Target.Engines[Engine] = true

		Engine:UpdateOverlay()
		Target:UpdateOverlay()

		Target:InvalidateClientInfo()

		return true, "Engine linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_engine", "acf_fueltank", function(Engine, Target)
		if Engine.FuelTanks[Target] or Target.Engines[Engine] then
			if Engine.FuelTank == Target then
				Engine.FuelTank = next(Engine.FuelTanks, Target)
			end

			Engine.FuelTanks[Target] = nil
			Target.Engines[Engine]	 = nil

			Engine:UpdateOverlay()
			Target:UpdateOverlay()

			Target:InvalidateClientInfo()

			return true, "Engine unlinked successfully!"
		end

		return false, "This engine is not linked to this fuel tank."
	end)

	ACF.RegisterClassLink("acf_engine", "acf_gearbox", function(Engine, Target)
		if Engine.Gearboxes[Target] then return false, "This engine is already linked to this gearbox." end
		if Engine:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "This gearbox is too far away from this engine!" end

		-- make sure the angle is not excessive
		local InPos = Target:LocalToWorld(Target.In.Pos)
		local OutPos = Engine:LocalToWorld(Engine.Out.Pos)

		if ACF.IsDriveshaftAngleExcessive(Target, Target.In, Engine, Engine.Out) then
			return false, "Cannot link due to excessive driveshaft angle!"
		end

		local Link = MobilityObj.Link(Engine, Target)

		Link:SetOrigin(Engine.Out)
		Link:SetTargetPos(Target.In)
		Link:SetAxis(Direction)

		Link.RopeLen = (OutPos - InPos):Length()

		Engine.Gearboxes[Target] = Link
		Target.Engines[Engine]   = true

		Engine:UpdateOverlay()
		Target:UpdateOverlay()

		Engine:InvalidateClientInfo()

		return true, "Engine linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_engine", "acf_gearbox", function(Engine, Target)
		if not Engine.Gearboxes[Target] then
			return false, "This engine is not linked to this gearbox."
		end

		local Rope = Engine.Gearboxes[Target].Rope

		if IsValid(Rope) then Rope:Remove() end

		Engine.Gearboxes[Target] = nil
		Target.Engines[Engine]	 = nil

		Engine:UpdateOverlay()
		Target:UpdateOverlay()

		Engine:InvalidateClientInfo()

		return true, "Engine unlinked successfully!"
	end)
end

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Damage       = ACF.Damage
local Utilities    = ACF.Utilities
local Clock        = Utilities.Clock
local Sounds       = Utilities.Sounds
local Messages     = Utilities.Messages
local Contraption  = ACF.Contraption
local UnlinkSound  = "physics/metal/metal_box_impact_bullet%s.wav"
local UnlinkExhSnd = "physics/metal/metal_sheet_impact_bullet%s.wav"
local IsValid      = IsValid
local Clamp        = math.Clamp
local Round        = math.Round
local Remap        = math.Remap
local Max          = math.max
local Min          = math.min
local TimerCreate  = timer.Create
local TimerRemove  = timer.Remove
local TickInterval = engine.TickInterval

-- Count all the existing sounds in a SoundBank
local function GetSoundCount(Engine)
	if not Engine.SoundBanks then return 1 end

	local TotalSounds = 0

	for _, V in ipairs(Engine.SoundBanks) do
		-- Check if our value is actually a table with a valid format.
		if istable(V) and istable(V.Sounds) then
			TotalSounds = TotalSounds + #V.Sounds
		end
	end

	return #Engine.SoundBanks, TotalSounds
end

-- Unwires any wiremod inputs by its name from the entity
local function UnwireInput(Entity, StringInput)
	if not Entity and not IsValid(Entity) then return end
	if not StringInput and not isstring(StringInput) then return end

	local Input = Entity.Inputs and Entity.Inputs[StringInput]
	if not Input then return end

	-- Unwire the exhaust entity
	if Input and IsValid(Input.Src) then
		WireLib.Link_Clear(Entity, StringInput)
	end
end

local function GetNextFuelTank(Engine)
	local FuelTanks = Engine.FuelTanks
	if not next(FuelTanks) then return end

	local Select = next(FuelTanks, Engine.FuelTank) or next(FuelTanks)
	local Start = Select

	repeat
		if Select:CanConsume() then return Select end

		Select = next(FuelTanks, Select) or next(FuelTanks)
	until Select == Start

	return Select:CanConsume() and Select or nil
end

local function CheckDistantFuelTanks(Engine)
	local EnginePos = Engine:GetPos()

	for Tank in pairs(Engine.FuelTanks) do
		if EnginePos:DistToSqr(Tank:GetPos()) > MaxDistance then
			local Sound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(Engine, Sound, 70, 100, 1)
			Sounds.SendSound(Tank, Sound, 70, 100, 1)

			Engine:Unlink(Tank)
		end
	end
end

local function CheckGearboxes(Engine)
	for Ent, Link in pairs(Engine.Gearboxes) do
		local OutPos = Engine:LocalToWorld(Engine.Out.Pos)
		local InPos = Ent:LocalToWorld(Ent.In.Pos)

		-- make sure it is not stretched too far
		if OutPos:Distance(InPos) > Link.RopeLen * 1.5 then
			Engine:Unlink(Ent)
			continue
		end

		if ACF.IsDriveshaftAngleExcessive(Ent, Ent.In, Engine, Engine.Out) then
			Engine:Unlink(Ent)
		end
	end
end

local function CheckDistantExhaust(Engine)
	local Exhaust = Engine.Exhaust
	if not IsValid(Exhaust) or Exhaust == Engine then return end -- Nothing to check if it's unset or already defaulted to the engine itself

	if Engine:GetPos():DistToSqr(Exhaust:GetPos()) > MaxDistance then
		local Sound = UnlinkExhSnd:format(math.random(1, 2))

		Sounds.SendSound(Engine, Sound, 100, 100, 1)
		Sounds.SendSound(Exhaust, Sound, 100, 100, 1)

		Engine.Exhaust = Engine

		UnwireInput(Engine, "Exhaust")

		Sounds.InvalidateSoundInfo(Engine)
	end
end

local function SetActive(Entity, Value, EntTbl)
	EntTbl = EntTbl or Entity:GetTable()
	local ActBool = tobool(Value)

	if EntTbl.Active == ActBool then return end -- Already in the desired state
	if ActBool and EntTbl.Disabled then return end -- Can't activate a disabled engine

	if ActBool then -- Was off, turn on
		EntTbl.Active = true

		Entity:CalcMassRatio(EntTbl)

		EntTbl.LastThink = Clock.CurTime
		EntTbl.Torque    = EntTbl.PeakTorque
		EntTbl.FlyRPM    = EntTbl.IdleRPM * 1.5

		Entity:UpdateSoundBank(EntTbl)
		Entity:NextThink(Clock.CurTime + TickInterval())

		TimerCreate("ACF Engine Clock " .. Entity:EntIndex(), 3, 0, function()
			if not IsEntityValid(Entity) then return end

			CheckGearboxes(Entity)
			CheckDistantFuelTanks(Entity)
			CheckDistantExhaust(Entity)

			Entity:CalcMassRatio(EntTbl)
		end)
	else -- Was on, turn off
		EntTbl.Active    = false
		EntTbl.FlyRPM    = 0
		EntTbl.Torque    = 0

		Entity:DestroyAllSounds()

		TimerRemove("ACF Engine Clock " .. Entity:EntIndex())
	end

	Entity:UpdateOverlay()
	Entity:UpdateOutputs(EntTbl)
end

do -- Random timer crew stuff
	function ENT:FindPropagator()
		local Temp = self:GetParent()
		if IsValid(Temp) and Temp:GetClass() == "acf_baseplate" then return Temp end
		return nil
	end

	function ENT:UpdateFuelMod(cfg)
		local Propagator = self:FindPropagator(cfg)
		local Val = Propagator and Propagator.FuelCrewMod or 0
		self.FuelCrewMod = math.Clamp(Val, ACF.CrewFallbackCoef, 1)
		return self.FuelCrewMod
	end
end
--===============================================================================================--

do -- Spawn and Update functions
	local Classes = ACF.Classes

	-- Engine/engine-type classes are identified by FQN; derive the legacy short id for display by
	-- stripping the namespace prefix (FQNs like "ACF.Engines.5.7-V8" contain dots, so a plain split
	-- on "." won't work).
	local function ShortName(Class, Prefix)
		local Name = Classes.GetTypeName(Class):gsub("^" .. Prefix, "")
		return Name
	end

	local function UpdateEngine(Entity, Engine)
		local EngineClass = Engine:GetType()
		local Group       = Classes.GetBaseClass(EngineClass)
		local Type        = Classes.GetSubtypeByName("ACF.EngineTypes.BaseEngineType", Engine.Type)
			or Classes.GetTypeByName("ACF.EngineTypes.GenericPetrol")
		local Mass        = Engine.Mass

		Entity.ACF = Entity.ACF or {}

		Contraption.SetModel(Entity, Engine.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		Entity.Name              = Engine.Name
		Entity.ShortName         = ShortName(EngineClass, "ACF%.Engines%.")
		Entity.EntType           = Group and Group.Name or Engine.Name
		Entity.ClassData         = Group
		Entity.DefaultSound      = Engine.Sound
		Entity.SoundPitch        = Engine.Pitch or 100
		Entity.SoundVolume       = Engine.Volume or 1
		Entity.DefaultSoundBanks = Engine.SoundBanks or {}

		-- Old single sound engines need to be converted to the new table format. Not that without this everything inherently breaks,
		-- because there are more safeguards along the path. But this is to fix a bug with the overlay... 
		if table.IsEmpty(Entity.DefaultSoundBanks) then
			local Idle = Engine.RPM.Idle
			local Redline = Engine.RPM.Limit

			Entity.SoundBanks = {{
				Sounds = {{
					RPM    = (Idle + Redline) / 2, -- Halfway through or it'll sound weird.
					Path   = Entity.DefaultSound,
					Pitch  = Entity.SoundPitch,
					Volume = Entity.SoundVolume,
				}}
			}}

			Entity.DefaultSoundBanks = Entity.SoundBanks -- Set our default soundbank too
		else
			Entity.SoundBanks = Entity.DefaultSoundBanks
		end

		Entity.SoundBankCount,
		Entity.SoundCount	    = GetSoundCount(Engine)
		Entity.TorqueCurve      = Engine.TorqueCurve
		Entity.PeakTorque       = Engine.Torque
		Entity.PeakPower		= Engine.PeakPower
		Entity.PeakPowerRPM		= Engine.PeakPowerRPM
		Entity.PeakTorqueHeld   = Engine.Torque
		Entity.IdleRPM          = Engine.RPM.Idle
		Entity.PeakMinRPM       = Engine.RPM.PeakMin
		Entity.PeakMaxRPM       = Engine.RPM.PeakMax
		Entity.LimitRPM         = Engine.RPM.Limit
		Entity.RevLimited       = false
		Entity.FlywheelOverride = Engine.RPM.Override
		Entity.FlywheelMass     = Engine.FlywheelMass
		Entity.Inertia          = Engine.FlywheelMass * math.pi ^ 2
		Entity.IsElectric       = Engine.IsElectric
		Entity.IsSpecial        = Engine.IsSpecial
		Entity.IsTrans          = Engine.IsTrans -- driveshaft outputs to the side
		Entity.FuelTypes        = Engine.Fuel or { ["ACF.FuelTypes.Petrol"] = true }
		Entity.FuelType         = next(Engine.Fuel)
		Entity.EngineType       = ShortName(Type, "ACF%.EngineTypes%.")
		Entity.Efficiency       = Type.Efficiency
		Entity.TorqueScale      = Type.TorqueScale
		Entity.HealthMult       = Type.HealthMult
		Entity.HitBoxes         = ACF.GetHitboxes(Engine.Model)
		Entity.Out              = ACF.LocalPlane(Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaft")).Pos), Engine.IsTrans and Vector(0, 1, 0) or Vector(1, 0, 0))

		if Engine.IsTrans then
			Entity.Out = ACF.LocalPlane(vector_origin, Vector(0, 1, 0))
		end

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		-- Calculate base fuel usage
		if Type.CalculateFuelUsage then
			Entity.FuelUse = Type.CalculateFuelUsage(Entity)
		else
			Entity.FuelUse = ACF.FuelRate * Entity.Efficiency * 3e-8
		end

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Mass)
	end

	-- Spawn-only init (runs before Entity:Spawn(), so the model is ready for physics).
	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		self.ACF               = {}
		self.Active            = false
		self.Gearboxes         = {}
		self.FuelTanks         = {}
		self.LastThink         = 0
		self.MassRatio         = 1
		self.FuelUsage         = 0
		self.Throttle          = 0
		self.FlyRPM            = 0
		self.LastPitch         = 0
		self.LastTorque        = 0
		self.LastFuelUsage     = 0
		self.LastPower         = 0
		self.LastRPM           = 0
		self.LastTotalMass     = 0
		self.LastPhysMass      = 0
		self.revLimiterEnabled = true

		-- ClientData isn't verified yet here; resolve defensively for the pre-spawn model. On dupes the
		-- Engine field arrives nested ({Type,Data}) and falls through to the default - PostUpdate fixes it.
		local Engine = Classes.GetSubtypeByName("ACF.Engines.BaseEngine", ClientData.Engine)
			or Classes.GetTypeByName("ACF.Engines.5.7-V8")

		Contraption.SetModel(self, Engine.Model)

		duplicator.ClearEntityModifier(self, "mass")
	end

	function ENT.ACF_CheckSpawnLimit(Player)
		return Player:CheckLimit("_acf_engine")
	end

	function ENT:ACF_PreUpdateEntityData()
		-- Don't reconfigure a running engine; shut it down first (no-op on a fresh spawn).
		if self.Active then self:Disable() end
	end

	function ENT:ACF_PostUpdateEntityData()
		UpdateEngine(self, self:GetEngine())

		-- A reconfigure can invalidate existing links (no-op on a fresh spawn).
		if next(self.Gearboxes) then
			for Gearbox in pairs(self.Gearboxes) do
				self:Unlink(Gearbox)
				self:Link(Gearbox)
			end
		end

		if next(self.FuelTanks) then
			for Tank in pairs(self.FuelTanks) do
				if not self.FuelTypes[Tank.FuelType] then
					self:Unlink(Tank)
				end
			end
		end
	end

	function ENT:ACF_PostSpawn()
		ACF.AugmentedTimer(function(cfg) self:UpdateFuelMod(cfg) end, function() return IsEntityValid(self) end, nil, {MinTime = 0.1, MaxTime = 0.25})
	end

	ACF.RegisterLinkSource("acf_engine", "FuelTanks")
	ACF.RegisterLinkSource("acf_engine", "Gearboxes")

end

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:Enable()
	local Active

	if self.Inputs.Active.Path then
		Active = tobool(self.Inputs.Active.Value)
	else
		Active = true
	end

	SetActive(self, Active, self:GetTable())

	self:UpdateOverlay()
	ACF.CheckLegal(self) -- MARCH: Check parent chain on enabled
end

function ENT:Disable()
	SetActive(self, false, self:GetTable()) -- Turn off the engine

	self:UpdateOverlay()
end

function ENT:UpdateOutputs(SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)
	local FuelUsage = Round(SelfTbl.FuelUsage)
	local Torque    = SelfTbl.Torque
	local FlyRPM    = SelfTbl.FlyRPM
	local Power     = Round(Torque * FlyRPM / 9548.8)

	Torque = Round(Torque)
	FlyRPM = Round(FlyRPM)

	if SelfTbl.LastFuelUsage ~= FuelUsage then
		SelfTbl.LastFuelUsage = FuelUsage
		WireLib.TriggerOutput(self, "Fuel Use", FuelUsage)
	end
	if SelfTbl.LastTorque ~= Torque then
		SelfTbl.LastTorque = Torque
		WireLib.TriggerOutput(self, "Torque", Torque)
	end
	if SelfTbl.LastPower ~= Power then
		SelfTbl.LastPower = Power
		WireLib.TriggerOutput(self, "Power", Power)
	end
	if SelfTbl.LastRPM ~= FlyRPM then
		SelfTbl.LastRPM = FlyRPM
		WireLib.TriggerOutput(self, "RPM", FlyRPM)
	end
end

function ENT:ACF_UpdateOverlayState(State)
	if self.Active then
		State:AddSuccess("Active")
	else
		State:AddWarning("Idle")
	end
	State:AddKeyValue("Type", self.Name)
	State:AddEnginePower("Power", self.PeakPower)
	State:AddEngineTorque("Torque", self.PeakTorque)
	State:AddKeyValue("Powerband", ("%s - %s RPM"):format(self.PeakMinRPM, self.PeakMaxRPM))
	State:AddKeyValue("Redline", ("%s RPM"):format(self.LimitRPM))
	-- Sounds, in case you want to see em...
	local SoundBankCount, TotalSoundsCount = GetSoundCount(self)
	if SoundBankCount == 0 then
		State:AddWarning("No soundbanks were detected!")
	else
		State:AddKeyValue("SoundBanks", SoundBankCount)
	end
	if TotalSoundsCount == 0 then
		State:AddWarning("This engine is muted!")
	else
		State:AddKeyValue("Total Sounds", TotalSoundsCount)
	end
end

ACF.AddInputAction("acf_engine", "Throttle", function(Entity, Value)
	Entity.Throttle = Clamp(Value, 0, 100) * 0.01
end)

ACF.AddInputAction("acf_engine", "Active", function(Entity, Value)
	SetActive(Entity, tobool(Value), Entity:GetTable())
end)

-- Non-directional for now...
-- TODO: Eventually we might want to use an output angle, for particle effects coming out of this very entity or from the engine itself
ACF.AddInputAction("acf_engine", "Exhaust", function(Entity, Value)
	if IsValid(Value) and Entity:GetPos():DistToSqr(Value:GetPos()) > MaxDistance then
		-- Wiring happened anyway and we have no control of that, so we have to unwire.
		Entity.Exhaust = Entity
		UnwireInput(Entity, "Exhaust")

		local Owner = Entity:GetOwner()
		Messages.SendChat(Owner, "Error", "This entity is too far away from the engine!")

		return
	elseif IsValid(Value) then
		Entity.Exhaust = Value
	end
end)

function ENT:ACF_Activate(Recalc)
	local PhysObj = self.ACF.PhysObj
	local Mass    = PhysObj:GetMass()
	local Area    = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
	-- Fucking ArmoUr :face_vomiting: :face_vomiting: :face_vomiting: :face_vomiting: :face_vomiting:
	-- Britons gave us americans the english language so we can sanitize it and have it sound more or less understandable and be more legible!
	-- TODO: Replace this variable name and all instances of it with the correct word and fix the comment since its wrong lol
	local Armour  = Mass * 1000 / Area / 0.78 * ACF.ArmorMod -- Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local Health  = Area / ACF.Threshold
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Area      = Area
	self.ACF.Health    = Health * Percent * self.HealthMult
	self.ACF.MaxHealth = Health * self.HealthMult
	self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armour
	self.ACF.Type      = "Prop"
end

--This function needs to return HitRes
function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	-- Adjusting performance based on damage
	local TorqueMult = Clamp(((1 - self.TorqueScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, self.TorqueScale, 1)

	self.PeakTorque = self.PeakTorqueHeld * TorqueMult

	return HitRes
end

-- The function to either create or update on the client the sounds of an engine by networking the necesary data.
-- Checks only if there was one soundbank with one sound and the latter is an empty path, so it becomes muted and saves on networking.
-- Otherwise just networks RPM and Throttle values to the client. If the client does not have the soundTable, it can just request it.
function ENT:UpdateSoundBank(SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	local SoundBanks = SelfTbl.SoundBanks

	-- TODO: Remove this if it works after the merge and nothing that required this was broken, since we're doing it elsewhere instead.
	-- -- Populate a placeholder SoundTable if none is found for the engine
	-- if table.IsEmpty(SoundBanks) then
	-- 	if table.IsEmpty(SelfTbl.DefaultSoundBanks) then
	-- 		local Idle = SelfTbl.IdleRPM
	-- 		local Redline = SelfTbl.LimitRPM
	-- 		SoundBanks = {{	Sounds = {{
	-- 						RPM = (Idle + Redline) / 2,
	-- 						Path = SelfTbl.DefaultSound,
	-- 						Pitch = SelfTbl.SoundPitch or 100,
	-- 						Volume = SelfTbl.SoundVolume or 1}
	-- 					}
	-- 					}}
	-- 		SelfTbl.SoundBanks = SoundBanks
	-- 	else
	-- 		SelfTbl.SoundBanks = SelfTbl.DefaultSoundBanks
	-- 	end
	-- 	self:UpdateOverlay() -- Update the overlay too!
	-- 	return
	-- end

	local SoundBankCount, SoundCount = GetSoundCount(SelfTbl)

	-- Exit early if only one soundbank was found and has an empty soundpath
	if SoundBankCount == 1 and SoundCount == 1 and SoundBanks[1].Sounds[1].Path == "" then return end

	SelfTbl.SoundBankCount, SelfTbl.SoundCount = SoundBankCount, SoundCount

	local Throttle = Round(SelfTbl.Throttle, 2) * 100
	local RPM = Round(SelfTbl.FlyRPM)

	-- Update the overlay if our engine is off. 
	if not SelfTbl.Active then self:UpdateOverlay() end

	Sounds.SendMultipleAdjustableSounds(self, false, Throttle, RPM)
end

function ENT:DestroyAllSounds()
	Sounds.SendMultipleAdjustableSounds(self, true, _, _)
end

function ENT:ACF_IsLegal()
	local AllowArbitraryParents = ACF.AllowArbitraryParents

	-- MARCH: Craftian's change to ACF.CheckLegal calls caused this to break,
	-- so this self.Active should guard against it.
	if self.Active then
		if not AllowArbitraryParents and not self.ACF_EngineParentValid then
			return false, "Parenting Issue", "The engine must be parented to an ACF baseplate."
		end

		local Contraption = self:CFW_GetContraption()
		if not AllowArbitraryParents and not Contraption then return false, "Parenting Issue", "Not part of a contraption (somehow??)" end -- Will this even be triggered?
	end

	return true
end

function ENT:CFW_PreParentedTo(_, NewParent)
	local ParentValid = IsValid(NewParent) and NewParent:GetClass() == "acf_baseplate"
	self.ACF_EngineParentValid = ParentValid
end

hook.Add("cfw.contraption.entityAdded", "ACF_Engine_ContraptionChecks", function(Contraption, Ent)
	if Ent:GetClass() == "acf_engine" then
		if Contraption.Engines then
			Contraption.Engines[Ent] = true
		else
			Contraption.Engines = {[Ent] = true}
		end

		Contraption.HasEngines   = true
		Contraption.TotalEngines = (Contraption.TotalEngines or 0) + 1
	end
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_Engine_ContraptionChecks", function(Contraption, Ent)
	if Ent:GetClass() == "acf_engine" then
		if Contraption.Engines then
			Contraption.Engines[Ent] = nil
		end

		Contraption.HasEngines   = next(Contraption.Engines) and true or nil
		Contraption.TotalEngines = Contraption.HasEngines and 0 or table.Count(Contraption.Engines)
	end
end)

-- specialized calcmassratio for engines
function ENT:CalcMassRatio(SelfTbl)
	SelfTbl        = SelfTbl or ENTITY.GetTable(self)
	local Con      = ENTITY.CFW_GetContraption(self)
	local PhysMass = 0

	local Physical, _, Detached = Contraption.GetEnts(self)

	-- Duplex pairs iterates over Physical, then Detached - but we can make Detached nil
	-- if DetachedPhysmassRatio == false
	for K in ACF.DuplexPairs(Physical, ACF.DetachedPhysmassRatio and Detached or nil) do
		local Phys = ENTITY.GetPhysicsObject(K) -- Should always exist, but just in case

		if IsPhysObjValid(Phys) then
			local Mass = PHYSOBJ.GetMass(Phys)
			PhysMass   = PhysMass + Mass
		end
	end

	local TotalMass = Con and Con.totalMass or PhysMass

	SelfTbl.MassRatio = PhysMass / TotalMass
	TotalMass = Round(TotalMass, 2)
	PhysMass = Round(PhysMass, 2)

	if SelfTbl.LastTotalMass ~= TotalMass then
		SelfTbl.LastTotalMass = TotalMass
		WireLib.TriggerOutput(self, "Mass", Round(TotalMass, 2))
	end
	if SelfTbl.LastPhysMass ~= PhysMass then
		SelfTbl.LastPhysMass = PhysMass
		WireLib.TriggerOutput(self, "Physical Mass", Round(PhysMass, 2))
	end
end

function ENT:GetConsumption(Throttle, RPM, FuelTank, SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)
	FuelTank = FuelTank or SelfTbl.FuelTank
	if not IsEntityValid(FuelTank) then return 0 end

	if SelfTbl.IsElectric then
		return Throttle * SelfTbl.FuelUse * SelfTbl.Torque * RPM * 1.05e-4 / SelfTbl.FuelCrewMod
	else
		local IdleConsumption = SelfTbl.PeakPower * 5e2
		return SelfTbl.FuelUse * (IdleConsumption + Throttle * SelfTbl.Torque * RPM) / FuelTank.FuelDensity / SelfTbl.FuelCrewMod
	end
end


function ENT:Think()
	local SelfTbl = ENTITY.GetTable(self)

	if not SelfTbl.Active then return end
	if SelfTbl.Disabled then return end

	self:CalcRPM(SelfTbl)

	-- CalcRPM can turn the engine off or disable it (e.g. no fuel or legality issues)
	if not SelfTbl.Active or SelfTbl.Disabled then return end

	self:NextThink(CurTime() + TickInterval())

	return true
end

-- We're doing an experiment here. It seems that the entity table stores the functions for the entity
-- class as well. So we don't need to do self:Function for every entity (which would invoke the __index function)
-- If true then we should apply this in the rest of the hot paths.
function ENT:CalcRPM(SelfTbl)
	-- Reusing these entity table pointers helps us cut down on __index calls
	-- This helps to massively improve performance throughout the entire drivetrain
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	local ClockTime  = Clock.CurTime
	local DeltaTime  = ClockTime - SelfTbl.LastThink
	local FuelTank   = GetNextFuelTank(SelfTbl)
	local IsElectric = SelfTbl.IsElectric
	local LimitRPM   = SelfTbl.LimitRPM
	local FlyRPM     = SelfTbl.FlyRPM

	-- Determine if the rev limiter will engage or disengage
	local RevLimited = false
	if SelfTbl.revLimiterEnabled and not IsElectric then
		if FlyRPM > LimitRPM * 0.99 then
			RevLimited = true
		elseif FlyRPM < LimitRPM * 0.95 then
			RevLimited = false
		end

		SelfTbl.RevLimited = RevLimited
	end
	local Throttle = RevLimited and 0 or SelfTbl.Throttle

	-- Calculate fuel usage
	if IsEntityValid(FuelTank) then
		SelfTbl.FuelTank = FuelTank
		SelfTbl.FuelType = FuelTank.FuelType

		local Consumption = SelfTbl.GetConsumption(self, Throttle, FlyRPM, FuelTank, SelfTbl) * DeltaTime

		SelfTbl.FuelUsage = 60 * Consumption / DeltaTime
		ENTITY.GetTable(FuelTank).Consume(FuelTank, Consumption)
	elseif ACF.RequireFuel then -- Stay active if fuel consumption is disabled
		SetActive(self, false, SelfTbl)

		SelfTbl.FuelUsage = 0

		return 0
	end

	-- Calculate the current torque from flywheel RPM
	local IdleRPM    = SelfTbl.IdleRPM
	local PeakRPM    = IsElectric and SelfTbl.FlywheelOverride or SelfTbl.PeakMaxRPM
	local Inertia    = SelfTbl.Inertia
	local PeakTorque = SelfTbl.PeakTorque
	local Drag       = PeakTorque * (Max(FlyRPM - IdleRPM, 0) / PeakRPM) * (1 - Throttle) / Inertia

	local Torque = 0

	if Throttle ~= 0 and FlyRPM < LimitRPM then
		local Percent = Remap(FlyRPM, IdleRPM, LimitRPM, 0, 1)
		Torque = Throttle * ACF.GetTorque(SelfTbl.TorqueCurve, Percent) * PeakTorque -- * (FlyRPM < LimitRPM and 1 or 0)
	end

	SelfTbl.Torque = Torque

	-- Let's accelerate the flywheel based on that torque
	FlyRPM = Min(Max(FlyRPM + Torque / Inertia - Drag, 0), LimitRPM)

	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	local Boxes      = 0
	local TotalReqTq = 0

	-- This is the presently available torque from the engine
	local TorqueDiff = Max(FlyRPM - IdleRPM, 0) * Inertia

	-- The resulting torque output would be 0 when there's no throttle anyways, so we'll just skip the calculations entirely
	if Throttle ~= 0 then
		local BoxesTbl = SelfTbl.Gearboxes

		-- Get the requirements for torque for the gearboxes (Max clutch rating minus any wheels currently spinning faster than the Flywheel)
		for Ent, Link in pairs(BoxesTbl) do
			local EntTable = ENTITY.GetTable(Ent)
			if not EntTable.Disabled then
				Boxes = Boxes + 1
				Link.ReqTq = EntTable.Calc(Ent, FlyRPM, Inertia)
				TotalReqTq = TotalReqTq + Link.ReqTq
			end
		end

		-- Calculate the ratio of total requested torque versus what's available
		local AvailRatio = Min(TorqueDiff / TotalReqTq / Boxes, 1)

		local MassRatio = SelfTbl.MassRatio

		-- Split the torque fairly between the gearboxes who need it
		for Ent, Link in pairs(BoxesTbl) do
			Link:TransferGearbox(Ent, Link.ReqTq * AvailRatio * MassRatio, DeltaTime, MassRatio, FlyRPM)
			--Ent:Act(Link.ReqTq * AvailRatio * MassRatio, DeltaTime, MassRatio)
		end
	end

	SelfTbl.FlyRPM = FlyRPM - Min(TorqueDiff, TotalReqTq) / Inertia
	SelfTbl.LastThink = ClockTime

	SelfTbl.UpdateSoundBank(self, SelfTbl)
	SelfTbl.UpdateOutputs(self, SelfTbl)
end

function ENT:PreEntityCopy()
	if next(self.Gearboxes) then
		local Gearboxes = {}

		for Gearbox in pairs(self.Gearboxes) do
			Gearboxes[#Gearboxes + 1] = Gearbox:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFGearboxes", Gearboxes)
	end

	if next(self.FuelTanks) then
		local Tanks = {}

		for Tank in pairs(self.FuelTanks) do
			Tanks[#Tanks + 1] = Tank:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFFuelTanks", Tanks)
	end

	-- AutoRegisterV2 wraps this as the original PreEntityCopy and handles the wire/base dupe info.
end

function ENT:PostEntityPaste(_, Ent, CreatedEntities)
	local EntMods = Ent.EntityMods

	-- Backwards compatibility
	if EntMods.GearLink then
		local Entities = EntMods.GearLink.entities

		for _, EntID in ipairs(Entities) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.GearLink = nil
	end

	-- Backwards compatibility
	if EntMods.FuelLink then
		local Entities = EntMods.FuelLink.entities

		for _, EntID in ipairs(Entities) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.FuelLink = nil
	end

	if EntMods.ACFGearboxes then
		for _, EntID in ipairs(EntMods.ACFGearboxes) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.ACFGearboxes = nil
	end

	if EntMods.ACFFuelTanks then
		for _, EntID in ipairs(EntMods.ACFFuelTanks) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.ACFFuelTanks = nil
	end

	-- AutoRegisterV2 wraps this as the original PostEntityPaste and handles the wire/base dupe info.
end

function ENT:GetCost()
	local selftbl = self:GetTable()

	return Max(5, (selftbl.PeakTorque / 160) + (selftbl.PeakPower / 80))
end

-- Remove-only teardown. Captured by AutoRegisterV2 as OrigOnRemove; the generated OnRemove still runs
-- ACF_OnEntityLast + WireLib cleanup around this.
function ENT:OnRemove(IsFullUpdate)
	if IsFullUpdate then return end

	local Class = self.ClassData

	if Class and Class.OnLast then
		Class.OnLast(self, Class)
	end

	self:DestroyAllSounds()

	for Gearbox in pairs(self.Gearboxes) do
		self:Unlink(Gearbox)
	end

	for Tank in pairs(self.FuelTanks) do
		self:Unlink(Tank)
	end

	TimerRemove("ACF Engine Clock " .. self:EntIndex())
end

do	-- NET SURFER 2.0
	util.AddNetworkString("ACF_RequestEngineInfo")
	util.AddNetworkString("ACF_InvalidateEngineInfo")

	function ENT:InvalidateClientInfo()
		net.Start("ACF_InvalidateEngineInfo")
			net.WriteEntity(self)
		net.Broadcast()
	end

	net.Receive("ACF_RequestEngineInfo", function(_, Ply)
		local Entity = net.ReadEntity()

		if IsEntityValid(Entity) then
			local Outputs    = {}
			local FuelTanks  = {}
			local ExhaustEnt = Entity.Exhaust
			local Driveshaft = Entity.Out.Pos

			if next(Entity.Gearboxes) then
				for E in pairs(Entity.Gearboxes) do
					Outputs[#Outputs + 1] = E:EntIndex()
				end
			end

			if next(Entity.FuelTanks) then
				for E in pairs(Entity.FuelTanks) do
					FuelTanks[#FuelTanks + 1] = E:EntIndex()
				end
			end

			net.Start("ACF_RequestEngineInfo")
				net.WriteEntity(Entity)
				net.WriteEntity(ExhaustEnt)
				net.WriteVector(Driveshaft)
				net.WriteUInt(#Outputs, 6)
				net.WriteUInt(#FuelTanks, 6)

				if next(Outputs) then
					for _, E in ipairs(Outputs) do
						net.WriteUInt(E, MAX_EDICT_BITS)
					end
				end

				if next(FuelTanks) then
					for _, E in ipairs(FuelTanks) do
						net.WriteUInt(E, MAX_EDICT_BITS)
					end
				end
			net.Send(Ply)
		end
	end)
end