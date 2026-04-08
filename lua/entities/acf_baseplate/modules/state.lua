local ACF      		= ACF
local Notify        = ACF.Utilities.Notify

function ENT:CFW_PreParentedTo(_, NewEntity)
	if IsValid(NewEntity) then
		Notify.EntityWarning(self, "Cannot parent an ACF baseplate to another entity", "Baseplates are expected to be the root ancestor of a contraption, and parenting them would break that guarantee.")
	end

	return false
end

function ENT:PhysicsCollide(CollisionData, Collider)
	local Hook = self:ACF_GetUserVar("BaseplateType").PhysicsCollide
	if Hook then
		Hook(self, CollisionData, Collider)
	end
end

function ENT:Think()
	local Hook = self:ACF_GetUserVar("BaseplateType").Think
	if Hook then
		return Hook(self)
	end
end