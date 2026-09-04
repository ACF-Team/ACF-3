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

local AppendCache = {}
local function Append(File, Text)
	if not AppendCache[File] then
		AppendCache[File] = {}
	end
	AppendCache[File][#AppendCache[File] + 1] = Text
end
timer.Create("MergeAppends", 1, 0, function()
	for k, v in pairs(AppendCache) do
		local File = k
		local Text = table.concat(v)
		file.Append(File, Text)
	end
	table.Empty(AppendCache)
end)

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

-- Helicopter actuators: main rotors (driven by pitch/roll cyclic) and tail rotors (driven by yaw). Linking
-- any rotor puts the controller in HELICOPTER mode (see Think): it points the nose with the rotor disc + tail
-- instead of airplane-style bank-to-turn, and drops the airspeed-based protections that don't apply at hover.
ACF.RegisterClassLink("acf_control_surface_controller", "acf_rotor", function(This, Rotor)
	This.Rotors = This.Rotors or {}
	if This.Rotors[Rotor] then return false, "This rotor is already linked to this controller!" end
	This.Rotors[Rotor] = true
	This:UpdateOverlay()
	return true, "Main rotor linked successfully."
end)

ACF.RegisterClassUnlink("acf_control_surface_controller", "acf_rotor", function(This, Rotor)
	if not (This.Rotors and This.Rotors[Rotor]) then return false, "This rotor is not linked to this controller!" end
	This.Rotors[Rotor] = nil
	if IsValid(Rotor) then Rotor:SetCyclic(0, 0) end
	This:UpdateOverlay()
	return true, "Main rotor unlinked successfully."
end)

ACF.RegisterClassLink("acf_control_surface_controller", "acf_tail_rotor", function(This, Tail)
	This.TailRotors = This.TailRotors or {}
	if This.TailRotors[Tail] then return false, "This tail rotor is already linked to this controller!" end
	This.TailRotors[Tail] = true
	This:UpdateOverlay()
	return true, "Tail rotor linked successfully."
end)

ACF.RegisterClassUnlink("acf_control_surface_controller", "acf_tail_rotor", function(This, Tail)
	if not (This.TailRotors and This.TailRotors[Tail]) then return false, "This tail rotor is not linked to this controller!" end
	This.TailRotors[Tail] = nil
	if IsValid(Tail) then Tail:SetYaw(0) end
	This:UpdateOverlay()
	return true, "Tail rotor unlinked successfully."
end)

ACF.RegisterLinkSource("acf_control_surface_controller", "Baseplate", true)
ACF.RegisterLinkSource("acf_control_surface_controller", "Surfaces")
ACF.RegisterLinkSource("acf_control_surface_controller", "Rotors")
ACF.RegisterLinkSource("acf_control_surface_controller", "TailRotors")

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
	if T.Rotors then
		for Rotor in pairs(T.Rotors) do
			if IsValid(Rotor) then Rotor:SetCyclic(0, 0) else T.Rotors[Rotor] = nil end
		end
	end
	if T.TailRotors then
		for Tail in pairs(T.TailRotors) do
			if IsValid(Tail) then Tail:SetYaw(0) else T.TailRotors[Tail] = nil end
		end
	end
end

-- Distributes a normalised (-1..1) per-axis command to each linked surface, using the surface's geometric
-- effectiveness about its axis so the sign (and aileron differential) is automatic, scaled to its max throw.
local function Distribute(T, BPMass, Right, Up, Fwd, PitchCmd, YawCmd, RollCmd)
	local FM = ACF.FlightModel

	if T.Surfaces then
		for Surface in pairs(T.Surfaces) do
			if not IsValid(Surface) then T.Surfaces[Surface] = nil continue end

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

	-- Helicopter actuators: main rotor takes pitch/roll as cyclic disc tilt (which pitches/rolls the fuselage
	-- to point the nose), the tail rotor takes yaw. Same normalised commands the surfaces get.
	if T.Rotors then
		for Rotor in pairs(T.Rotors) do
			if IsValid(Rotor) then Rotor:SetCyclic(PitchCmd, RollCmd) else T.Rotors[Rotor] = nil end
		end
	end
	if T.TailRotors then
		for Tail in pairs(T.TailRotors) do
			if IsValid(Tail) then Tail:SetYaw(YawCmd) else T.TailRotors[Tail] = nil end
		end
	end
end

-- Snapshot of the airframe + every linked surface's geometry, so a bad build (tiny/mis-placed surfaces,
-- weak inertia, etc.) is visible. Written to data/flight_build_<id>.txt, refreshed periodically.
local function DumpBuild(self, T, BP, Phys, Right, Up, Fwd, BPMass)
	local Con   = BP.CFW_GetContraption and BP:CFW_GetContraption()
	local Total = (Con and Con.totalMass) or Phys:GetMass()
	local I     = Phys:GetInertia()
	local L = {
		string.format("baseplate mass=%.1f  totalMass=%.1f  massRatio=%.3f", Phys:GetMass(), Total, Phys:GetMass() / Total),
		string.format("inertia kg*m2 = %.2f, %.2f, %.2f  (pitch/Y? roll/X? yaw/Z? = engine local axes)", I.x, I.y, I.z),
		string.format("planform m2 = %.2f", (BP.AeroAreas and BP.AeroAreas.Planform) or 0),
		"surface: axis, area_m2, maxDeflDeg, Rx, Ry, Rz (in, from CoM), eff(sign=moment dir), health",
	}
	if T.Surfaces then
		for S in pairs(T.Surfaces) do
			if not IsValid(S) then continue end
			local Axis = S.ControlAxis
			local AV   = Axis == "Pitch" and Right or Axis == "Yaw" and Up or Fwd
			local R    = S:GetPos() - BPMass
			local Eff  = R:Cross(S:GetUp()):Dot(AV)
			L[#L + 1] = string.format("%s, %.3f, %d, %.0f, %.0f, %.0f, %.1f, %.2f",
				Axis, S.Area or 0, S.MaxDeflection or 0, R.x, R.y, R.z, Eff, S:GetHealthRatio())
		end
	end
	file.Write("flight_build_" .. self:EntIndex() .. ".txt", table.concat(L, "\n"))
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

	-- Outer loop: pointing error -> target body rate (deg/s). Pitch AND yaw both point directly at the aim
	-- (their setpoints are the exact body-frame components of the rotation Fwd->Aim, so together they always
	-- drive the nose onto target at any bank). The bank-to-turn roll below is secondary/for feel -- it does
	-- not have to resolve the aim by itself, so yaw is never faded out (that just traps the pointing error).
	local YawSet = Clamp(P.AimRateGain * YawErr, -P.AimRateMax, P.AimRateMax)

	-- Energy protection: a sustained hard bank + pull bleeds airspeed; unchecked it mushes into a low-speed
	-- stall/departure. As speed drops toward stall, ease the bank and the nose-up pull so the craft unloads
	-- and keeps its energy. Full authority at/above TurnVRef, eased right off toward TurnVMin.
	local VelW   = Phys:GetVelocity()
	local Speed  = VelW:Length() * 0.0254
	local Energy = Clamp((Speed - P.TurnVMin) / (P.TurnVRef - P.TurnVMin), 0.15, 1)

	-- Roll (bank-to-turn), computed first so the pitch pull can unload while rolling. Command a BANK ANGLE
	-- proportional to the turn (heading) error and hold it; it settles at a bank and returns to level as the
	-- error shrinks, so it can't wind into a continuous roll. Bank is eased by Energy so a slow craft flattens.
	local DesiredBank = Clamp(P.SurfBankGain * YawErr, -P.SurfMaxBank, P.SurfMaxBank) * Energy
	local RollSet     = Clamp(P.RollKp * (CurrentBank - DesiredBank), -P.RollRateMaxCtl, P.RollRateMaxCtl)

	-- Pitch, with three protections: (1) roll-pitch decoupling -- ease the nose-up pull while rolling hard so
	-- a roll/reversal doesn't couple/adverse-yaw into a departure the (often weak) rudder can't arrest; (2)
	-- energy -- ease the pull when slow; (3) AoA guard -- alpha is the airflow angle below the nose; cap the
	-- nose-up rate as alpha nears stall, and past it the allowance goes negative so it actively unloads.
	local RollUnload = Clamp(1 - math.abs(RollSet) / P.RollUnloadRate, 0.35, 1)
	local PitchSet   = Clamp(P.AimRateGain * PitchErr, -P.AimRateMax, P.AimRateMax)

	local Alpha = 0
	if Speed > 0.5 then
		local vd = VelW / VelW:Length()
		Alpha = deg(atan2(-vd:Dot(Up), vd:Dot(Fwd)))
	end
	local PullLimit = (P.StallGuardAoA - Alpha) * P.AoAGuardGain
	if PitchSet > 0 then PitchSet = PitchSet * Energy * RollUnload end
	if PitchSet > PullLimit then PitchSet = Clamp(PullLimit, -P.AimRateMax, P.AimRateMax) end

	-- HELICOPTER mode (any main rotor linked): point the nose directly with pitch + yaw (rotor cyclic tilts
	-- the fuselage, tail rotor yaws it) and just hold wings level. Bank-to-turn and the airspeed-based stall/
	-- energy protections are airplane-only -- at a hover they'd zero every command -- so they're bypassed.
	if T.Rotors and next(T.Rotors) then
		PitchSet = Clamp(P.AimRateGain * PitchErr, -P.AimRateMax, P.AimRateMax)
		YawSet   = Clamp(P.AimRateGain * YawErr,   -P.AimRateMax, P.AimRateMax)
		RollSet  = Clamp(P.RollKp * CurrentBank,   -P.RollRateMaxCtl, P.RollRateMaxCtl)
	end

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

	T.LogTick = (T.LogTick or 0) + 1
	if T.LogTick % 128 == 0 then DumpBuild(self, T, BP, Phys, Right, Up, Fwd, BPMass) end

	if T.LogFile then
		Append(T.LogFile, string.format(
			"%.2f,%.1f,%.2f,%.2f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.3f,%.3f,%.3f,%.0f,%.0f,%.0f,%.1f,%.2f\n",
			CurTime(), Speed, PitchErr, YawErr, CurrentBank, DesiredBank,
			PitchSet, YawSet, RollSet, PitchRate, YawRate, RollRate, PitchCmd, YawCmd, RollCmd,
			T.EffPitch, T.EffYaw, T.EffRoll, Alpha, Energy))
	end

	WireLib.TriggerOutput(self, "Pitch", PitchCmd)
	WireLib.TriggerOutput(self, "Yaw", YawCmd)
	WireLib.TriggerOutput(self, "Roll", RollCmd)
	WireLib.TriggerOutput(self, "Heading", math.Round(YawErr, 1))
	WireLib.TriggerOutput(self, "Elevation", math.Round(PitchErr, 1))

	return true
end

--==============================================================================================--
function ENT:ACF_PreSpawn()
	self.ACF        = {}
	self.Surfaces   = {}
	self.Rotors     = {}
	self.TailRotors = {}
	self:SetScaledModel(PLACEHOLDER_MODEL)
end

function ENT.ACF_CheckSpawnLimit(Player)
	return Player:CheckLimit("_acf_control_surface_controller")
end

function ENT:ACF_PostUpdateEntityData()
	UpdateController(self)

	-- Telemetry: fresh CSV per spawn (cleared here), one row/tick while active. Pull from <gmod>/data/.
	self.LogFile = "flight_results_" .. self:EntIndex() .. ".csv"
	file.Write(self.LogFile, "t,speed,pitchErr,yawErr,curBank,desBank,pitchSet,yawSet,rollSet,pitchRate,yawRate,rollRate,pitchCmd,yawCmd,rollCmd,effP,effY,effR,alpha,energy\n")

	WireLib.TriggerOutput(self, "Entity", self)
end

local function IndexList(Set)
	if not Set then return nil end
	local List = {}
	for Ent in pairs(Set) do
		if IsValid(Ent) then List[#List + 1] = Ent:EntIndex() end
	end
	return next(List) and List or nil
end

function ENT:PreEntityCopy()
	local Info = {}

	if IsValid(self.Baseplate) then Info.Baseplate = self.Baseplate:EntIndex() end
	Info.Surfaces   = IndexList(self.Surfaces)
	Info.Rotors     = IndexList(self.Rotors)
	Info.TailRotors = IndexList(self.TailRotors)

	if next(Info) then duplicator.StoreEntityModifier(self, "ACFControlSurfaceController", Info) end
end

function ENT:PostEntityPaste(_, Ent, CreatedEntities)
	local Info = Ent.EntityMods and Ent.EntityMods.ACFControlSurfaceController
	if not Info then return end

	if Info.Baseplate then
		local BP = CreatedEntities[Info.Baseplate]
		if IsValid(BP) then self:Link(BP) end
	end

	for _, Key in ipairs({ "Surfaces", "Rotors", "TailRotors" }) do
		if Info[Key] then
			for _, Index in ipairs(Info[Key]) do
				local Linked = CreatedEntities[Index]
				if IsValid(Linked) then self:Link(Linked) end
			end
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

local function CountValid(Set)
	local N = 0
	if Set then
		for Ent in pairs(Set) do
			if IsValid(Ent) then N = N + 1 else Set[Ent] = nil end
		end
	end
	return N
end

function ENT:ACF_UpdateOverlayState(State)
	if IsValid(self.Baseplate) then
		State:AddSuccess("Linked to a baseplate")
	else
		State:AddWarning("Not linked to a baseplate")
	end

	local Rotors = CountValid(self.Rotors)
	State:AddKeyValue("Mode", Rotors > 0 and "Helicopter" or "Fixed-wing")
	State:AddKeyValue("Control surfaces", CountValid(self.Surfaces))
	if Rotors > 0 or CountValid(self.TailRotors) > 0 then
		State:AddKeyValue("Main / tail rotors", Rotors .. " / " .. CountValid(self.TailRotors))
	end
end
