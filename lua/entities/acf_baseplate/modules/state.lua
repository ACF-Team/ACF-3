local ACF      		= ACF
local Notify        = ACF.Utilities.Notify

local Clock          = ACF.Utilities.Clock
local ENTITY         = FindMetaTable("Entity")
local PHYSOBJ        = FindMetaTable("PhysObj")
local IsPhysObjValid = ACF.Optimizations.IsPhysObjValid

function ENT:CFW_PreParentedTo(_, NewEntity)
	if IsValid(NewEntity) then
		Notify.EntityWarning(self, "Cannot parent an ACF baseplate to another entity", "Baseplates are expected to be the root ancestor of a contraption, and parenting them would break that guarantee.")
	end

	return false
end

function ENT:PhysicsCollide(CollisionData, Collider)
	local BaseplateType = self:ACF_GetUserVar("BaseplateType")
	local Hook = BaseplateType.PhysicsCollide
	if Hook then
		Hook(BaseplateType, self, CollisionData, Collider)
	end
end

function ENT:Think()
	local BaseplateType = self:ACF_GetUserVar("BaseplateType")
	local Hook = BaseplateType.Think
	if Hook then
		return Hook(BaseplateType, self)
	end
end

-- Note(TMF): I reckon that this is kinda janky, but entity:GetLocalAngularVelocity() simply doesn't work, and neither it is from the gearbox side.
function ENT:GetAngularVelocity()
	local SelfTbl = ENTITY.GetTable(self)
	local Now     = Clock.CurTime

	if Now < (SelfTbl.AngVelNext or 0) then return SelfTbl.AngVel end

	SelfTbl.AngVelNext = Now + ACF.BaseAngVelSampleRate -- A break of pattern here, we're sampling deltas ahead of time, not behind like the rest. 

	local Phys = ENTITY.GetPhysicsObject(self)
	SelfTbl.AngVel = IsPhysObjValid(Phys) and PHYSOBJ.GetAngleVelocity(Phys) or nil

	return SelfTbl.AngVel
end