AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Contraption = ACF.Contraption
local Damage      = ACF.Damage

-- Small cube placeholder (a hub marker). The physical prop diameter is tracked separately in self.Diameter
-- and does not depend on the visual size.
local PLACEHOLDER_MODEL = "models/holograms/cube.mdl"

-- Air density at sea level (kg/m^3). A later v-slice will make this fall off with altitude.
local AIR_DENSITY = 1.225

-- Blade tuning. Coefficients are dimensional (T = CT * rho * n^2 * D^4, Q = CQ * rho * n^2 * D^5 with
-- n in rev/s), calibrated so a 3-blade 1.9m prop at ~2700 RPM makes ~2.6 kN thrust / ~420 Nm draw,
-- i.e. light-aircraft realistic. Thrust grows sub-linearly with blade count (diminishing returns);
-- torque draw grows linearly, so more blades trade efficiency for compactness.
local CT_PER_BLADE   = 0.0322
local CQ_PER_BLADE   = 0.0023
local THRUST_EXP     = 0.85

-- Solves thrust/torque coefficients from a blade count.
local function BladeCoefficients(Blades)
	return CT_PER_BLADE * (Blades ^ THRUST_EXP), CQ_PER_BLADE * Blades
end

-- Builds the mobility link between a gearbox output and this propeller (mirrors acf_waterjet).
local function GenerateLinkTable(Gearbox, Prop)
	local InPos      = Prop.In and Prop.In.Pos or Vector()
	local InPosWorld = Prop:LocalToWorld(InPos)
	local OutPos, Side, Plane

	if Gearbox:WorldToLocal(InPosWorld).y < 0 then
		Plane  = Gearbox.OutL
		OutPos = Gearbox.OutL.Pos
		Side   = 0
	else
		Plane  = Gearbox.OutR
		OutPos = Gearbox.OutR.Pos
		Side   = 1
	end

	local OutPosWorld     = Gearbox:LocalToWorld(OutPos)
	local Excessive, Deg  = ACF.IsDriveshaftAngleExcessive(Prop, Prop.In, Gearbox, Plane)
	if Excessive then return nil, Deg end

	local Link = ACF.Mobility.Objects.Link(Gearbox, Prop)
	Link:SetOrigin(OutPos)
	Link:SetTargetPos(InPos)
	Link:SetAxis(Prop.In and Plane.Dir or Prop:GetPhysicsObject():WorldToLocalVector(Gearbox:GetRight()))
	Link.OutDirection = Plane.Dir
	Link.Side         = Side
	Link.RopeLen      = (OutPosWorld - InPosWorld):Length()

	return Link, Deg
end

-- Applies the current Blades/Diameter config to the entity (mirrors UpdateEngine).
local function UpdatePropeller(Entity)
	local Blades   = Entity:ACF_GetUserVar("Blades") or 3
	local Diameter = Entity:ACF_GetUserVar("Diameter") or 2

	Entity.ACF = Entity.ACF or {}

	Entity:SetScaledModel(PLACEHOLDER_MODEL)
	-- Keep the marker small (a few inches), scaling gently with diameter so it's visible but not intrusive.
	local CubeUnits = Diameter * 5
	Entity:SetSize(Vector(CubeUnits, CubeUnits, CubeUnits))

	Entity.Blades    = Blades
	Entity.Diameter  = Diameter
	Entity.Rho       = AIR_DENSITY
	Entity.CT, Entity.CQ = BladeCoefficients(Blades)
	Entity.Name      = ("%d-Blade Propeller"):format(Blades)
	Entity.LastThrust = 0

	Entity:SetNWString("WireName", "ACF Propeller")

	ACF.Activate(Entity, true)

	-- Mass grows with blade count and disc area (D^2): a bigger, bladier prop is heavier.
	local Mass = 6 * Blades * Diameter * Diameter
	Contraption.SetMass(Entity, Mass)
end

ACF.RegisterClassLink("acf_propeller", "acf_gearbox", function(This, Gearbox)
	if Gearbox.Effectors[This] then return false, "This propeller is already linked to this gearbox!" end

	local Link, DriveshaftAngle = GenerateLinkTable(Gearbox, This)
	if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(DriveshaftAngle) .. " deg)" end

	Gearbox.Effectors[This] = Link
	This.Gearboxes[Gearbox] = Link

	Gearbox:InvalidateClientInfo()

	return true, "Propeller linked successfully."
end)

ACF.RegisterClassUnlink("acf_propeller", "acf_gearbox", function(This, Gearbox)
	if not Gearbox.Effectors[This] then return false, "This propeller is not linked to this gearbox!" end

	Gearbox.Effectors[This] = nil
	This.Gearboxes[Gearbox] = nil

	return true, "Propeller unlinked successfully."
end)

ACF.RegisterLinkSource("acf_propeller", "Gearboxes")

function ENT:ACF_PreSpawn()
	self.ACF        = {}
	self.Gearboxes  = {}
	self.LastThrust = 0

	self:SetScaledModel(PLACEHOLDER_MODEL)
end

function ENT.ACF_CheckSpawnLimit(Player)
	return Player:CheckLimit("_acf_propeller")
end

function ENT:ACF_PostUpdateEntityData()
	UpdatePropeller(self)

	WireLib.TriggerOutput(self, "Entity", self)

	-- A reconfigure can invalidate existing links; refresh them.
	if next(self.Gearboxes) then
		for Gearbox in pairs(self.Gearboxes) do
			self:Unlink(Gearbox)
			self:Link(Gearbox)
		end
	end
end

-- Required torque for the shaft to spin the propeller at InputRPM (the drivetrain pulls this each tick).
-- Q = CQ * rho * n^2 * D^5, with n in rev/s. Divided by HealthRatio so a damaged prop drags harder.
function ENT:Calc(InputRPM)
	local SelfTbl = self:GetTable()

	local HealthRatio = SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth
	local N           = InputRPM / 60
	local CQ, Rho, D  = SelfTbl.CQ, SelfTbl.Rho, SelfTbl.Diameter
	local Q_req       = CQ * Rho * N * N * D * D * D * D * D

	return Q_req / HealthRatio
end

-- Converts delivered shaft torque into forward thrust on the airframe.
-- T = CT * rho * n^2 * D^4, with n in rev/s.
-- Thrust IS scaled by the drivetrain's MassRatio (PhysMass/TotalMass): parented mass is invisible to the
-- physics solver, so the ancestor phys object only carries PhysMass. Multiplying the applied force by
-- MassRatio makes the effective acceleration F/TotalMass instead of F/PhysMass, i.e. the craft responds as
-- if it weighs its full parented+physical mass. Self-powered producers (jets/rockets, later v-slices) do
-- NOT receive a drivetrain MassRatio, so they must compute their own PhysMass/TotalMass correction.
function ENT:Act(Torque, _, MassRatio, FlyRPM)
	local SelfTbl = self:GetTable()

	self:SetNW2Float("ACF_PropellerRPM", FlyRPM)

	local Ancestor = SelfTbl.Ancestor
	local Phys     = SelfTbl.AncestorPhys
	if not IsValid(Ancestor) or not IsValid(Phys) then return end

	local HealthRatio = SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth
	local N           = FlyRPM / 60
	local CT, Rho, D  = SelfTbl.CT, SelfTbl.Rho, SelfTbl.Diameter
	local T           = CT * Rho * N * N * D * D * D * D

	local Sign   = Torque >= 0 and 1 or -1
	local Thrust = T * Sign * HealthRatio * MassRatio

	Phys:ApplyForceOffset(self:GetForward() * Thrust, self:GetPos())

	SelfTbl.LastThrust = T * Sign

	if SelfTbl.LastRPM ~= FlyRPM then
		SelfTbl.LastRPM = FlyRPM
		WireLib.TriggerOutput(self, "RPM", FlyRPM)
	end
	WireLib.TriggerOutput(self, "Thrust", SelfTbl.LastThrust)
end

function ENT:Think()
	local SelfTbl = self:GetTable()

	self:SetNW2Float("ACF_PropellerRPM", 0)

	local Ancestor = self:GetAncestor()
	if IsValid(Ancestor) then
		SelfTbl.Ancestor     = Ancestor
		SelfTbl.AncestorPhys = Ancestor:GetPhysicsObject()
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

-- This function needs to return HitRes
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
