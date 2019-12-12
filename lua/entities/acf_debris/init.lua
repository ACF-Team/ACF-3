AddCSLuaFile("cl_init.lua")

DEFINE_BASECLASS("base_anim")
ENT.PrintName = "Debris"

-- todo: rename this to acf_debris
function ENT:Initialize()
	self.Timer = CurTime() + 60
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)

	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:Wake()
	end

	timer.Simple(30, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end

