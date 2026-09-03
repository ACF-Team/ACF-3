AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Contraption = ACF.Contraption
local Damage      = ACF.Damage

-- Self-contained aerodynamics (Fin-3 style): each surface finds its own airflow and applies its own force.
local AIR_DENSITY = 1.225   -- kg/m^3 (sea level; a later v-slice makes this fall off with altitude)
local INCH_TO_M   = 0.0254
local MIN_FLOW    = 2       -- m/s below which airflow is too weak to bother with
local SURF_CD0    = 0.02    -- parasitic drag coefficient of the panel
local CurTime     = CurTime

-- Applies the selected surface spec + size to the entity.
local function UpdateSurface(Entity, Surface)
	local Size = Entity:ACF_GetUserVar("SurfaceSize") or 1

	Entity.ACF = Entity.ACF or {}

	-- Flat rectangular panel: chord along local X (forward), span along local Y, thin along Z. This is
	-- also the shape the client renders, tilting it about the spanwise hinge (local Y) to show deflection.
	Entity:SetScaledModel(Surface.Model)
	Entity:SetSize(Vector(Size * 10, Size * 28, Size * 2))

	Entity.Name          = Surface.Name
	Entity.ControlAxis   = Surface.ControlAxis            -- "Pitch" | "Yaw" | "Roll"
	Entity.MaxDeflection = Entity:ACF_GetUserVar("MaxDeflection") or 20
	-- Control authority is proportional to planform area (area ~ size^2).
	Entity.Authority     = (Surface.BaseArea or 2) * Size * Size

	-- Aerodynamic state. Planform area in m^2 (span along local Y * chord along local X); the panel's own
	-- mass centre is where its airflow is sampled and where its force is applied.
	local Phys = Entity:GetPhysicsObject()
	Entity.MassCenter    = IsValid(Phys) and Phys:GetMassCenter() or Vector()
	local OBB            = Entity:OBBMaxs() - Entity:OBBMins()
	Entity.Area          = math.abs(OBB.y) * math.abs(OBB.x) * INCH_TO_M * INCH_TO_M
	Entity.LastPos       = Entity:LocalToWorld(Entity.MassCenter)
	Entity.DeflectionDeg = Entity.DeflectionDeg or 0
	Entity.FilteredLift  = 0
	Entity.FilteredDrag  = 0

	Entity:SetNWString("WireName", "ACF " .. Surface.Name)
	Entity:SetNWString("ACF_ControlAxis", Surface.ControlAxis)

	ACF.Activate(Entity, true)
	Contraption.SetMass(Entity, 15 * Size * Size)
end

ACF.RegisterClassLink("acf_control_surface", "acf_baseplate", function(This, Baseplate)
	if This.Baseplate == Baseplate then return false, "This surface is already linked to this baseplate!" end
	if IsValid(This.Baseplate) then return false, "This surface is already linked to a baseplate; unlink it first." end

	Baseplate.ControlSurfaces = Baseplate.ControlSurfaces or {}
	Baseplate.ControlSurfaces[This] = true
	This.Baseplate = Baseplate
	This:UpdateOverlay()

	return true, "Control surface linked successfully."
end)

ACF.RegisterClassUnlink("acf_control_surface", "acf_baseplate", function(This, Baseplate)
	if This.Baseplate ~= Baseplate then return false, "This surface is not linked to this baseplate!" end

	if Baseplate.ControlSurfaces then Baseplate.ControlSurfaces[This] = nil end
	This.Baseplate = nil

	return true, "Control surface unlinked successfully."
end)

ACF.RegisterLinkSource("acf_control_surface", "Baseplate", true)

function ENT:ACF_PreSpawn(_, _, _, ClientData)
	self.ACF = {}

	local Surface = ACF.Classes.GetSubtypeByName("ACF.ControlSurfaces.BaseSurface", ClientData.Surface)
		or ACF.Classes.GetTypeByName("ACF.ControlSurfaces.Elevator")

	self:SetScaledModel(Surface.Model)
end

function ENT.ACF_CheckSpawnLimit(Player)
	return Player:CheckLimit("_acf_control_surface")
end

function ENT:ACF_PostUpdateEntityData()
	UpdateSurface(self, self:GetSurface())

	WireLib.TriggerOutput(self, "Entity", self)
end

function ENT:PreEntityCopy()
	if IsValid(self.Baseplate) then
		duplicator.StoreEntityModifier(self, "ACFFlightBaseplate", { self.Baseplate:EntIndex() })
	end
end

function ENT:PostEntityPaste(_, Ent, CreatedEntities)
	local EntMods = Ent.EntityMods

	if EntMods.ACFFlightBaseplate then
		local Baseplate = CreatedEntities[EntMods.ACFFlightBaseplate[1]]
		if IsValid(Baseplate) then self:Link(Baseplate) end

		EntMods.ACFFlightBaseplate = nil
	end

	-- AutoRegisterV2 wraps this as the original PostEntityPaste and handles the wire/base dupe info.
end

-- Sets the hinge deflection in DEGREES, clamped to MaxDeflection. Called by a Control Surface Controller
-- or driven directly through the "Deflection" wire input for manual control.
function ENT:SetDeflection(Deg)
	local Max = self.MaxDeflection or 20
	Deg = math.Clamp(tonumber(Deg) or 0, -Max, Max)
	self.DeflectionDeg = Deg

	local Rounded = math.Round(Deg, 1)
	if self.LastDeflection ~= Rounded then
		self.LastDeflection = Rounded
		self:SetNW2Float("ACF_Deflection", Deg) -- degrees; drives the client-side surface animation
		WireLib.TriggerOutput(self, "Deflection", Rounded)
	end
end

ACF.AddInputAction("acf_control_surface", "Deflection", function(Entity, Value)
	Entity:SetDeflection(Value)
end)

-- Self-contained aerodynamics. Each tick the surface reads its OWN airflow as the exact rigid-body velocity
-- at its position (Phys:GetVelocityAtPoint -- includes the craft's rotation, lag-free, no finite-difference
-- noise), computes flat-plate lift + drag through the shared stall curve with its deflection as added
-- camber, and applies the force at its own position on the contraption root. Because the velocity is exact
-- and unlagged, the rotation-induced part is a clean aerodynamic DAMPING moment (no phase lag to turn it
-- into anti-damping), which is what keeps a rotating airframe from diverging.
function ENT:Think()
	local T        = self:GetTable()
	local Ancestor = self:GetAncestor()
	local Phys     = IsValid(Ancestor) and Ancestor:GetPhysicsObject()

	self:NextThink(CurTime())
	if not IsValid(Phys) then return true end

	local CurPos = self:LocalToWorld(T.MassCenter or vector_origin)
	local Vel    = Phys:GetVelocityAtPoint(CurPos) -- exact velocity of this point on the rigid body

	local Length  = Vel:Length()
	local SpeedMs = Length * INCH_TO_M
	if SpeedMs < MIN_FLOW then return true end

	local VNorm = Vel / Length
	local Up    = self:GetUp() -- panel face normal (lift axis) is local Z

	-- Angle of attack of the flow onto the panel, then lift perpendicular to the flow toward the panel's up.
	local UpVel = math.Clamp(VNorm:Dot(Up), -1, 1)
	local AoA   = -math.deg(math.asin(UpVel))

	local LiftDir = Up - VNorm * UpVel -- component of Up perpendicular to the flow
	if LiftDir:LengthSqr() < 1e-6 then return true end
	LiftDir:Normalize()

	local FM     = ACF.FlightModel
	local Cl     = FM.LiftCoefficient(AoA + (T.DeflectionDeg or 0))
	local Cd     = SURF_CD0 + 0.02 * Cl * Cl
	local Health = self:GetHealthRatio()
	local Q      = 0.5 * AIR_DENSITY * (T.Area or 0) * SpeedMs * SpeedMs

	-- Parented mass is invisible to the solver, so scale the force by PhysMass/TotalMass (see acf_propeller).
	local Con       = Ancestor.CFW_GetContraption and Ancestor:CFW_GetContraption()
	local Total     = Con and Con.totalMass or Phys:GetMass()
	local MassRatio = math.Clamp(Phys:GetMass() / Total, 0, 1)

	local Force = (LiftDir * (Q * Cl) - VNorm * (Q * Cd)) * Health
	Phys:ApplyForceOffset(Force * MassRatio, CurPos)

	local RoundAoA = math.Round(AoA, 1)
	if T.LastAoA ~= RoundAoA then
		T.LastAoA = RoundAoA
		WireLib.TriggerOutput(self, "AoA", RoundAoA)
	end

	return true
end

-- Fraction of authority still available given battle damage.
function ENT:GetHealthRatio()
	local H = self.ACF
	if not H or not H.MaxHealth or H.MaxHealth == 0 then return 1 end
	return H.Health / H.MaxHealth
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
	State:AddKeyValue("Axis", self.ControlAxis or "?")
	State:AddNumber("Authority", math.Round(self.Authority or 0, 2))
	if IsValid(self.Baseplate) then
		State:AddSuccess("Linked to a baseplate")
	else
		State:AddWarning("Not linked to a baseplate")
	end
end
