AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Contraption = ACF.Contraption
local Damage      = ACF.Damage

local PLACEHOLDER_MODEL = "models/holograms/cube.mdl"
local CurTime = CurTime

-- BASE_THRUST: sideways thrust (N) at full yaw command, size 1 (tunable authority).
-- ANTI_TORQUE: sideways thrust (N) per deg/s of yaw rate -- the automatic anti-torque damper that cancels
-- the main rotor's reaction spin and holds heading. Health-scaled, so losing the tail rotor lets it spin.
local BASE_THRUST = 6000
local ANTI_TORQUE = 220

local function UpdateTailRotor(Entity)
	local Size = Entity:ACF_GetUserVar("Size") or 1

	Entity.ACF = Entity.ACF or {}

	Entity:SetScaledModel(PLACEHOLDER_MODEL)
	Entity:SetSize(Vector(Size * 6, Size * 6, Size * 6))

	Entity.Name      = "Tail Rotor"
	Entity.MaxThrust = BASE_THRUST * Size * Size
	Entity.YawCmd    = Entity.YawCmd or 0

	Entity:SetNWString("WireName", "ACF Tail Rotor")

	ACF.Activate(Entity, true)
	Contraption.SetMass(Entity, 20 * Size * Size)
end

ACF.AddInputAction("acf_tail_rotor", "Yaw", function(Entity, Value)
	Entity.YawCmd = math.Clamp(tonumber(Value) or 0, -1, 1)
end)

-- Called by a Control Surface Controller to drive yaw (-1..1).
function ENT:SetYaw(Value)
	self.YawCmd = math.Clamp(Value, -1, 1)
end

function ENT:GetHealthRatio()
	local H = self.ACF
	if not H or not H.MaxHealth or H.MaxHealth == 0 then return 1 end
	return H.Health / H.MaxHealth
end

-- Each tick: sideways thrust = commanded yaw + automatic anti-torque (a yaw-rate damper that opposes the
-- main rotor's reaction spin), applied at the tail so it yaws the airframe. Scaled by health -> shoot the
-- tail rotor off and the anti-torque vanishes, so the main reaction torque spins the helicopter (punishment).
function ENT:Think()
	local T        = self:GetTable()
	local Ancestor = self:GetAncestor()
	local Phys     = IsValid(Ancestor) and Ancestor:GetPhysicsObject()

	self:NextThink(CurTime())
	if not IsValid(Phys) then return true end

	local Up      = Ancestor:GetUp()
	local AngVel  = Phys:LocalToWorldVector(Phys:GetAngleVelocity())
	local YawRate = AngVel:Dot(Up)

	local Health = self:GetHealthRatio()
	local Force  = (T.YawCmd or 0) * (T.MaxThrust or 0) - ANTI_TORQUE * YawRate
	Force = Force * Health

	local Con       = Ancestor.CFW_GetContraption and Ancestor:CFW_GetContraption()
	local Total     = (Con and Con.totalMass) or Phys:GetMass()
	local MassRatio = math.Clamp(Phys:GetMass() / Total, 0, 1)

	Phys:ApplyForceOffset(self:GetRight() * (Force * MassRatio), self:GetPos())

	return true
end

function ENT:ACF_PreSpawn()
	self.ACF    = {}
	self.YawCmd = 0
	self:SetScaledModel(PLACEHOLDER_MODEL)
end

function ENT.ACF_CheckSpawnLimit(Player)
	return Player:CheckLimit("_acf_tail_rotor")
end

function ENT:ACF_PostUpdateEntityData()
	UpdateTailRotor(self)
	WireLib.TriggerOutput(self, "Entity", self)
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
	State:AddNumber("Max thrust (N)", math.Round(self.MaxThrust or 0))
	State:AddNumber("Health", math.Round(self:GetHealthRatio() * 100) .. "%")
end
