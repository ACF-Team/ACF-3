AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Contraption = ACF.Contraption
local Damage      = ACF.Damage

local PLACEHOLDER_MODEL = "models/holograms/cube.mdl"
local AIR_DENSITY = 1.225

-- Lift/torque coefficients (T = CT*rho*n^2*D^4, Q = CQ*rho*n^2*D^5, n in rev/s). Tuned so a 2-blade 6m
-- rotor at a few hundred RPM hovers a light helicopter at partial collective, leaving headroom to climb.
local CT_PER_BLADE = 0.020
local CQ_PER_BLADE = 0.0016
local THRUST_EXP   = 0.85
local TILT_MAX     = 0.30 -- tangent of the max cyclic disc tilt (~17 deg) at full command
local TORQUE_MULT  = ACF.TorqueMult or 1 -- drivetrain torque convention (see mobility/objects_sv/link.lua)

local deg = math.deg

local function BladeCoefficients(Blades)
	return CT_PER_BLADE * (Blades ^ THRUST_EXP), CQ_PER_BLADE * Blades
end

-- Drivetrain link (mirrors acf_propeller / acf_waterjet).
local function GenerateLinkTable(Gearbox, Rotor)
	local InPos      = Rotor.In and Rotor.In.Pos or Vector()
	local InPosWorld = Rotor:LocalToWorld(InPos)
	local OutPos, Side, Plane

	if Gearbox:WorldToLocal(InPosWorld).y < 0 then
		Plane, OutPos, Side = Gearbox.OutL, Gearbox.OutL.Pos, 0
	else
		Plane, OutPos, Side = Gearbox.OutR, Gearbox.OutR.Pos, 1
	end

	local OutPosWorld    = Gearbox:LocalToWorld(OutPos)
	local Excessive, Ang = ACF.IsDriveshaftAngleExcessive(Rotor, Rotor.In, Gearbox, Plane)
	if Excessive then return nil, Ang end

	local Link = ACF.Mobility.Objects.Link(Gearbox, Rotor)
	Link:SetOrigin(OutPos)
	Link:SetTargetPos(InPos)
	Link:SetAxis(Rotor.In and Plane.Dir or Rotor:GetPhysicsObject():WorldToLocalVector(Gearbox:GetRight()))
	Link.OutDirection = Plane.Dir
	Link.Side         = Side
	Link.RopeLen      = (OutPosWorld - InPosWorld):Length()

	return Link, Ang
end

local function UpdateRotor(Entity)
	local Blades   = Entity:ACF_GetUserVar("Blades") or 2
	local Diameter = Entity:ACF_GetUserVar("Diameter") or 6

	Entity.ACF = Entity.ACF or {}

	Entity:SetScaledModel(PLACEHOLDER_MODEL)
	Entity:SetSize(Vector(Diameter * 4, Diameter * 4, Diameter * 1.5)) -- hub marker (visual only)

	Entity.Blades    = Blades
	Entity.Diameter  = Diameter
	Entity.Rho       = AIR_DENSITY
	Entity.CT, Entity.CQ = BladeCoefficients(Blades)
	Entity.Name      = ("%d-Blade Main Rotor"):format(Blades)
	Entity.LastThrust = 0

	Entity:SetNWString("WireName", "ACF Main Rotor")

	ACF.Activate(Entity, true)
	Contraption.SetMass(Entity, 20 * Blades * Diameter)
end

ACF.RegisterClassLink("acf_rotor", "acf_gearbox", function(This, Gearbox)
	if Gearbox.Effectors[This] then return false, "This rotor is already linked to this gearbox!" end

	local Link, Ang = GenerateLinkTable(Gearbox, This)
	if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(Ang) .. " deg)" end

	Gearbox.Effectors[This] = Link
	This.Gearboxes[Gearbox] = Link
	Gearbox:InvalidateClientInfo()

	return true, "Rotor linked successfully."
end)

ACF.RegisterClassUnlink("acf_rotor", "acf_gearbox", function(This, Gearbox)
	if not Gearbox.Effectors[This] then return false, "This rotor is not linked to this gearbox!" end

	Gearbox.Effectors[This] = nil
	This.Gearboxes[Gearbox] = nil

	return true, "Rotor unlinked successfully."
end)

ACF.RegisterLinkSource("acf_rotor", "Gearboxes")

ACF.AddInputAction("acf_rotor", "Collective",  function(Entity, Value) Entity.Collective  = math.Clamp(tonumber(Value) or 0, 0, 1) end)
ACF.AddInputAction("acf_rotor", "CyclicPitch", function(Entity, Value) Entity.CyclicPitch = math.Clamp(tonumber(Value) or 0, -1, 1) end)
ACF.AddInputAction("acf_rotor", "CyclicRoll",  function(Entity, Value) Entity.CyclicRoll  = math.Clamp(tonumber(Value) or 0, -1, 1) end)

-- Called by a Control Surface Controller to drive the disc tilt for aiming (pitch/roll, -1..1).
function ENT:SetCyclic(Pitch, Roll)
	self.CyclicPitch = math.Clamp(Pitch, -1, 1)
	self.CyclicRoll  = math.Clamp(Roll, -1, 1)
end

function ENT:ACF_PreSpawn()
	self.ACF         = {}
	self.Gearboxes   = {}
	self.Collective  = 0
	self.CyclicPitch = 0
	self.CyclicRoll  = 0
	self.LastThrust  = 0

	self:SetScaledModel(PLACEHOLDER_MODEL)
end

function ENT.ACF_CheckSpawnLimit(Player)
	return Player:CheckLimit("_acf_rotor")
end

function ENT:ACF_PostUpdateEntityData()
	UpdateRotor(self)
	WireLib.TriggerOutput(self, "Entity", self)

	if next(self.Gearboxes) then
		for Gearbox in pairs(self.Gearboxes) do
			self:Unlink(Gearbox)
			self:Link(Gearbox)
		end
	end
end

-- Torque the shaft must supply to spin the rotor (drivetrain pulls this). Q = CQ*rho*n^2*D^5.
function ENT:Calc(InputRPM)
	local T = self:GetTable()
	local HealthRatio = T.ACF.Health / T.ACF.MaxHealth
	local N = InputRPM / 60
	return (T.CQ * T.Rho * N * N * T.Diameter ^ 5) / HealthRatio
end

-- Converts delivered shaft torque into rotor lift (up the spin axis, tilted by cyclic for translation/aim)
-- AND the equal-and-opposite REACTION TORQUE dumped on the airframe -- the anti-torque a tail rotor fights.
function ENT:Act(Torque, DeltaTime, MassRatio, FlyRPM)
	local T = self:GetTable()
	self:SetNW2Float("ACF_RotorRPM", FlyRPM)

	local Ancestor = T.Ancestor
	local Phys     = T.AncestorPhys
	if not IsValid(Ancestor) or not IsValid(Phys) then return end

	local HealthRatio = T.ACF.Health / T.ACF.MaxHealth
	local N     = FlyRPM / 60
	local Lift  = T.CT * T.Rho * N * N * T.Diameter ^ 4 * (T.Collective or 0) * HealthRatio

	-- Thrust disc: up the spin axis, tilted by cyclic. The tilt is applied at the rotor position (above the
	-- CoM), so its horizontal component both translates the craft and pitches/rolls the fuselage -- which is
	-- how the controller aims a helicopter (same pitch/roll commands it feeds control surfaces).
	local Up    = self:GetUp()
	local Dir   = Up - self:GetForward() * (T.CyclicPitch or 0) * TILT_MAX + self:GetRight() * (T.CyclicRoll or 0) * TILT_MAX
	Dir:Normalize()

	Phys:ApplyForceOffset(Dir * (Lift * MassRatio), self:GetPos())

	-- Reaction torque on the airframe about the spin axis, opposite the rotor's rotation (mirrors the
	-- drivetrain torque convention). Uncountered, this spins the helicopter -- the tail rotor cancels it.
	local Sign = Torque >= 0 and 1 or -1
	Phys:ApplyTorqueCenter(Up * math.Clamp(deg(Torque * TORQUE_MULT) * DeltaTime * MassRatio, -500000, 500000) * Sign)

	T.LastThrust = Lift
	if T.LastRPM ~= FlyRPM then
		T.LastRPM = FlyRPM
		WireLib.TriggerOutput(self, "RPM", FlyRPM)
	end
	WireLib.TriggerOutput(self, "Thrust", math.Round(Lift))
end

function ENT:Think()
	local T = self:GetTable()
	self:SetNW2Float("ACF_RotorRPM", 0)

	local Ancestor = self:GetAncestor()
	if IsValid(Ancestor) then
		T.Ancestor     = Ancestor
		T.AncestorPhys = Ancestor:GetPhysicsObject()
	end

	self:NextThink(CurTime() + 0.1)
	return true
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
	State:AddKeyValue("Type", self.Name)
	State:AddKeyValue("Diameter", ("%.1f m"):format(self.Diameter or 0))
	State:AddNumber("Thrust (N)", math.Round(self.LastThrust or 0))
	if next(self.Gearboxes) then
		State:AddSuccess("Linked to a gearbox")
	else
		State:AddWarning("Not linked to a gearbox")
	end
end
