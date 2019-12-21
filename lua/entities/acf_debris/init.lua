AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:Wake()
	end

	timer.Simple(30, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end
