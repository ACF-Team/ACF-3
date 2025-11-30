local ACF      		= ACF

function ENT:CFW_PreParentedTo(_, NewEntity)
	if IsValid(NewEntity) then
		local Owner = self:CPPIGetOwner()
		if IsValid(Owner) then
			ACF.SendNotify(Owner, false, "Cannot parent an ACF baseplate to another entity.")
		end
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