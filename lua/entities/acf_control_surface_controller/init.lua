AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Contraption = ACF.Contraption
local Damage      = ACF.Damage

local PLACEHOLDER_MODEL = "models/holograms/cube.mdl"

local TICK    = engine.TickInterval()
local CurTime = CurTime
local deg     = math.deg
local atan2   = math.atan2
local Clamp   = math.Clamp

local function UpdateController(Entity)
	Entity.ACF = Entity.ACF or {}

	Entity:SetScaledModel(PLACEHOLDER_MODEL)
	Entity:SetSize(Vector(8, 8, 4))

	Entity.Name = "Control Surface Controller"

	-- Per-axis online effectiveness estimates + last-tick memory for the self-tuning loop / slew limiter.
	Entity.EffPitch = ACF.FlightModel.Defaults.EffInit
	Entity.EffYaw   = ACF.FlightModel.Defaults.EffInit
	Entity.EffRoll  = ACF.FlightModel.Defaults.EffInit
	Entity.LastPitchRate, Entity.LastYawRate, Entity.LastRollRate = 0, 0, 0
	Entity.LastPitchCmd,  Entity.LastYawCmd,  Entity.LastRollCmd  = 0, 0, 0

	Entity:SetNWString("WireName", "ACF Control Surface Controller")

	ACF.Activate(Entity, true)
	Contraption.SetMass(Entity, 25)
end

--==============================================================================================--
-- Linking: one baseplate (the airframe it steers) + any control surfaces (the actuators).
--==============================================================================================--
ACF.RegisterClassLink("acf_control_surface_controller", "acf_baseplate", function(This, Baseplate)
	if This.Baseplate == Baseplate then return false, "This controller is already linked to this baseplate!" end
	if IsValid(This.Baseplate) then return false, "This controller already has a baseplate; unlink it first." end

	This.Baseplate = Baseplate
	This:UpdateOverlay()

	return true, "Baseplate linked successfully."
end)

ACF.RegisterClassUnlink("acf_control_surface_controller", "acf_baseplate", function(This, Baseplate)
	if This.Baseplate ~= Baseplate then return false, "This controller is not linked to this baseplate!" end

	This.Baseplate = nil
	This:UpdateOverlay()

	return true, "Baseplate unlinked successfully."
end)

ACF.RegisterClassLink("acf_control_surface_controller", "acf_control_surface", function(This, Surface)
	This.Surfaces = This.Surfaces or {}
	if This.Surfaces[Surface] then return false, "This surface is already linked to this controller!" end

	This.Surfaces[Surface] = true
	This:UpdateOverlay()

	return true, "Control surface linked successfully."
end)

ACF.RegisterClassUnlink("acf_control_surface_controller", "acf_control_surface", function(This, Surface)
	if not (This.Surfaces and This.Surfaces[Surface]) then return false, "This surface is not linked to this controller!" end

	This.Surfaces[Surface] = nil
	Surface:SetDeflection(0)
	This:UpdateOverlay()

	return true, "Control surface unlinked successfully."
end)

ACF.RegisterLinkSource("acf_control_surface_controller", "Baseplate", true)
ACF.RegisterLinkSource("acf_control_surface_controller", "Surfaces")

--==============================================================================================--
-- Wire input: Active + the three interchangeable aim inputs. The last aim received is the one used.
--==============================================================================================--
ACF.AddInputAction("acf_control_surface_controller", "Active", function(Entity, Value)
	Entity.Active = tobool(Value)
end)

ACF.AddInputAction("acf_control_surface_controller", "AimDirection", function(Entity, Value)
	if not isvector(Value) then return end
	Entity.AimMode = "dir"
	Entity.AimValue = Value
end)

ACF.AddInputAction("acf_control_surface_controller", "AimPos", function(Entity, Value)
	if not isvector(Value) then return end
	Entity.AimMode = "pos"
	Entity.AimValue = Value
end)

ACF.AddInputAction("acf_control_surface_controller", "AimAngle", function(Entity, Value)
	if not isangle(Value) then return end
	Entity.AimMode = "angle"
	Entity.AimValue = Value
end)

-- Resolves the stored aim input into a unit world direction, or nil if there is no usable aim.
local function ResolveAim(T, BP)
	local Mode, Value = T.AimMode, T.AimValue
	if not Mode or Value == nil then return nil end

	local Dir
	if Mode == "dir" then
		Dir = Value
	elseif Mode == "pos" then
		Dir = Value - BP:GetPos()
	else -- angle
		Dir = Value:Forward()
	end

	if Dir:LengthSqr() < 1e-6 then return nil end
	return Dir:GetNormalized()
end

--==============================================================================================--
-- The control loop.
--==============================================================================================--
local function ZeroOutputs(self, T)
	if T.LastPitchCmd == 0 and T.LastYawCmd == 0 and T.LastRollCmd == 0 and T.OutputsZeroed then return end
	T.OutputsZeroed = true
	T.LastPitchCmd, T.LastYawCmd, T.LastRollCmd = 0, 0, 0
	WireLib.TriggerOutput(self, "Pitch", 0)
	WireLib.TriggerOutput(self, "Yaw", 0)
	WireLib.TriggerOutput(self, "Roll", 0)

	if T.Surfaces then
		for Surface in pairs(T.Surfaces) do
			if IsValid(Surface) then Surface:SetDeflection(0) else T.Surfaces[Surface] = nil end
		end
	end
end

-- Distributes a normalised (-1..1) per-axis command to each linked surface, using the surface's geometric
-- effectiveness about its axis so the sign (and aileron differential) is automatic, scaled to its max throw.
local function Distribute(T, BPMass, Right, Up, Fwd, PitchCmd, YawCmd, RollCmd)
	local Surfaces = T.Surfaces
	if not Surfaces then return end

	local FM = ACF.FlightModel

	for Surface in pairs(Surfaces) do
		if not IsValid(Surface) then Surfaces[Surface] = nil continue end

		local Axis = Surface.ControlAxis
		local Cmd, AxisVec
		if Axis == "Pitch" then Cmd, AxisVec = PitchCmd, Right
		elseif Axis == "Yaw" then Cmd, AxisVec = YawCmd, Up
		else Cmd, AxisVec = RollCmd, Fwd end

		-- Effectiveness = (r x liftDir) . axis: the moment this surface makes about its axis per unit lift.
		local R       = Surface:GetPos() - BPMass
		local LiftDir = Surface:GetUp()
		local Eff     = R:Cross(LiftDir):Dot(AxisVec)

		Surface:SetDeflection(FM.AllocateDeflection(Cmd, Eff) * (Surface.MaxDeflection or 20))
	end
end

function ENT:Think()
	local T = self:GetTable()
	self:NextThink(CurTime())

	local BP = T.Baseplate
	if not (T.Active and IsValid(BP)) then ZeroOutputs(self, T) return true end

	local Phys = BP:GetPhysicsObject()
	if not IsValid(Phys) then ZeroOutputs(self, T) return true end

	local Aim = ResolveAim(T, BP)
	if not Aim then ZeroOutputs(self, T) return true end
	T.OutputsZeroed = false

	local FM = ACF.FlightModel
	local P  = FM.Defaults

	local Fwd, Right, Up = BP:GetForward(), BP:GetRight(), BP:GetUp()

	-- Pointing error as a world rotation axis (Fwd x Aim). Projected on the body axes it gives sign-correct
	-- pitch/yaw setpoints with no hand-tuned sign knobs.
	local Cross    = Fwd:Cross(Aim)
	local PitchErr = deg(Cross:Dot(Right))
	local YawErr   = deg(Cross:Dot(Up))
	local CurrentBank = deg(atan2(Right.z, Up.z))

	-- Outer loop: pointing error -> target body rate (deg/s). Pitch points directly. YAW fades out as bank
	-- increases: once banked, the aim's lateral offset is meant to be resolved by the pitch PULL (bank-to-
	-- turn), and a pointing-based rudder command there points the *opposite* way (adverse yaw) and skids the
	-- craft into a spin. Near wings-level the rudder points normally.
	local YawFade  = Clamp(1 - math.abs(CurrentBank) / P.SurfMaxBank, 0, 1)
	local PitchSet = Clamp(P.AimRateGain * PitchErr, -P.AimRateMax, P.AimRateMax)
	local YawSet   = Clamp(P.AimRateGain * YawErr * YawFade, -P.AimRateMax, P.AimRateMax)

	-- Roll is bank-to-turn: command a BANK ANGLE proportional to the turn (heading) error and hold it -- the
	-- pitch pull carries the nose around. Driving a bank ANGLE (not "roll until the aim is overhead") means it
	-- settles at a bank and returns to level as the error shrinks, so it can never wind into a continuous roll.
	local DesiredBank = Clamp(P.SurfBankGain * YawErr, -P.SurfMaxBank, P.SurfMaxBank)
	local RollSet     = Clamp(P.RollKp * (CurrentBank - DesiredBank), -P.RollRateMax, P.RollRateMax)

	-- Measured body rates: the angular velocity axis projected onto each body axis.
	local AngVel    = Phys:LocalToWorldVector(Phys:GetAngleVelocity())
	local PitchRate = AngVel:Dot(Right)
	local YawRate   = AngVel:Dot(Up)
	local RollRate  = AngVel:Dot(Fwd)

	-- Inner loop: plant-inverse deflection command (-1..1) for each axis, using the online effectiveness
	-- estimate learned per axis.
	local PitchCmd = FM.AutoTuneDeflection(PitchSet - PitchRate, T.EffPitch, P)
	local YawCmd   = FM.AutoTuneDeflection(YawSet   - YawRate,   T.EffYaw,   P)
	local RollCmd  = FM.AutoTuneDeflection(RollSet  - RollRate,  T.EffRoll,  P)

	-- Slew-limit the output so nothing slams the surfaces tick-to-tick.
	local Slew = P.CmdSlew * TICK
	PitchCmd = math.Approach(T.LastPitchCmd, PitchCmd, Slew)
	YawCmd   = math.Approach(T.LastYawCmd,   YawCmd,   Slew)
	RollCmd  = math.Approach(T.LastRollCmd,  RollCmd,  Slew)

	-- Learn each axis' effectiveness from last tick's command and the accel it produced (guarded/clamped).
	T.EffPitch = FM.EstimateEffectiveness(T.EffPitch, (PitchRate - T.LastPitchRate) / TICK, T.LastPitchCmd, P)
	T.EffYaw   = FM.EstimateEffectiveness(T.EffYaw,   (YawRate   - T.LastYawRate)   / TICK, T.LastYawCmd,   P)
	T.EffRoll  = FM.EstimateEffectiveness(T.EffRoll,  (RollRate  - T.LastRollRate)  / TICK, T.LastRollCmd,  P)

	T.LastPitchRate, T.LastYawRate, T.LastRollRate = PitchRate, YawRate, RollRate

	local BPMass = BP:LocalToWorld(Phys:GetMassCenter())
	Distribute(T, BPMass, Right, Up, Fwd, PitchCmd, YawCmd, RollCmd)

	T.LastPitchCmd, T.LastYawCmd, T.LastRollCmd = PitchCmd, YawCmd, RollCmd

	WireLib.TriggerOutput(self, "Pitch", PitchCmd)
	WireLib.TriggerOutput(self, "Yaw", YawCmd)
	WireLib.TriggerOutput(self, "Roll", RollCmd)
	WireLib.TriggerOutput(self, "Heading", math.Round(YawErr, 1))
	WireLib.TriggerOutput(self, "Elevation", math.Round(PitchErr, 1))

	return true
end

--==============================================================================================--
function ENT:ACF_PreSpawn()
	self.ACF      = {}
	self.Surfaces = {}
	self:SetScaledModel(PLACEHOLDER_MODEL)
end

function ENT.ACF_CheckSpawnLimit(Player)
	return Player:CheckLimit("_acf_control_surface_controller")
end

function ENT:ACF_PostUpdateEntityData()
	UpdateController(self)

	WireLib.TriggerOutput(self, "Entity", self)
end

function ENT:PreEntityCopy()
	local Info = {}

	if IsValid(self.Baseplate) then Info.Baseplate = self.Baseplate:EntIndex() end

	if self.Surfaces then
		local List = {}
		for Surface in pairs(self.Surfaces) do
			if IsValid(Surface) then List[#List + 1] = Surface:EntIndex() end
		end
		if next(List) then Info.Surfaces = List end
	end

	if next(Info) then duplicator.StoreEntityModifier(self, "ACFControlSurfaceController", Info) end
end

function ENT:PostEntityPaste(_, Ent, CreatedEntities)
	local Info = Ent.EntityMods and Ent.EntityMods.ACFControlSurfaceController
	if not Info then return end

	if Info.Baseplate then
		local BP = CreatedEntities[Info.Baseplate]
		if IsValid(BP) then self:Link(BP) end
	end

	if Info.Surfaces then
		for _, Index in ipairs(Info.Surfaces) do
			local Surface = CreatedEntities[Index]
			if IsValid(Surface) then self:Link(Surface) end
		end
	end

	Ent.EntityMods.ACFControlSurfaceController = nil
end

function ENT:ACF_Activate(Recalc)
	local PhysObj = self.ACF.PhysObj
	local Mass    = PhysObj:GetMass()
	local Area    = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
	local Armour  = Mass * 1000 / Area / 0.78 * ACF.ArmorMod
	local Health  = Area / ACF.Threshold
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Area      = Area
	self.ACF.Health    = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armour
	self.ACF.Type      = "Prop"
end

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	return Damage.doPropDamage(self, DmgResult, DmgInfo)
end

function ENT:ACF_UpdateOverlayState(State)
	local Count = 0
	if self.Surfaces then
		for Surface in pairs(self.Surfaces) do
			if IsValid(Surface) then Count = Count + 1 else self.Surfaces[Surface] = nil end
		end
	end

	if IsValid(self.Baseplate) then
		State:AddSuccess("Linked to a baseplate")
	else
		State:AddWarning("Not linked to a baseplate")
	end

	State:AddKeyValue("Control surfaces", Count)
end
