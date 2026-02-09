local ACF      		= ACF
local Clock         = ACF.Utilities.Clock

local function GetBaseplateProperties(Ent, Self, SelfPos, SelfRadius)
	if Ent == Self then return false end

	if not IsValid(Ent) then return false end
	if Ent:GetClass() ~= "acf_baseplate" then return false end
	if not Ent.Size then return false end
	if Ent:IsPlayerHolding() then return false end

	local Physics     = Ent:GetPhysicsObject()
	if not IsValid(Physics) then return false end

	local Pos         = Physics:GetPos()
	local Radius      = math.sqrt((Ent.Size[1] / 2) ^ 2 + (Ent.Size[2] / 2) ^ 2)

	if Self and not util.IsSphereIntersectingSphere(SelfPos, SelfRadius, Pos, Radius) then
		return false
	end

	local Vel         = Physics:GetVelocity()
	local Contraption = Ent:GetContraption()
	local PhysMass    = Physics:GetMass()
	local TotalMass	  = Contraption and Contraption.totalMass or PhysMass

	return true, Physics, Pos, Vel, Contraption, PhysMass, TotalMass, Radius
end

local function CalculateSphereIntersection(Pos1, Radius1, Pos2, Radius2)
	local Dir = Pos2 - Pos1
	local Dist = Dir:Length()
	Dir:Normalize()

	local Intersection = Dist - Radius1 - Radius2
	return Intersection, Dir, (Pos1 * Radius1 + Pos2 * Radius2) / (Radius1 + Radius2)
end

hook.Add("Think", "ACF_Baseplate_Collision_Simulation", function()
	local BaseplatesArray = ACF.ActiveBaseplatesArray
	local Count = #BaseplatesArray
	if Count < 2 then return end
	for i = 1, Count do
		for j = 1, Count do
			if i >= j then continue end
			local BP1, BP2 = BaseplatesArray[i], BaseplatesArray[j]

			if not BP1.Size or not BP2.Size then continue end
			if BP1:IsPlayerHolding() or BP2:IsPlayerHolding() then continue end

			local Valid1, Physics1, Pos1, Vel1, Contraption1, PhysMass1, TotalMass1, Radius1 = GetBaseplateProperties(BP1)
			local Valid2, Physics2, Pos2, Vel2, Contraption2, PhysMass2, TotalMass2, Radius2 = GetBaseplateProperties(BP2)

			if not Valid1 or not Valid2 then continue end
			if not Contraption1 or not Contraption2 then continue end
			if Contraption1 == Contraption2 then continue end

			if not ACF.DoesContraptionHavePlayers(Contraption1) or not ACF.DoesContraptionHavePlayers(Contraption2) then continue end
			-- Final chance for addons to handle it. If something returns false, we continue.
			if hook.Run("ACF_OnBaseplateRepulsion", BP1, BP2) == false then continue end

			local IntersectionDistance, IntersectionDirection, IntersectionCenter = CalculateSphereIntersection(Pos1, Radius1, Pos2, Radius2)

			if IntersectionDistance > 0 then continue end

			local CollisionForce1 = ((Vel1 / 4) + ( IntersectionDirection * IntersectionDistance * 150)) * 100
			local CollisionForce2 = ((Vel2 / 4) + (-IntersectionDirection * IntersectionDistance * 150)) * 100

			local BP1Force = CollisionForce1 * math.Clamp(PhysMass1 / TotalMass1, 0, 1)
			local BP2Force = CollisionForce2 * math.Clamp(PhysMass2 / TotalMass2, 0, 1)

			local BP1LinImpulse, BP1AngImpulse = Physics1:CalculateForceOffset(BP1Force, IntersectionCenter)
			Physics1:ApplyForceCenter(BP1LinImpulse)
			Physics1:ApplyTorqueCenter(Physics1:LocalToWorldVector(BP1AngImpulse * 2)) -- Are you sure this was a good idea?
			BP1:PlayBaseplateRepulsionSound(Vel1)

			local BP2LinImpulse, BP2AngImpulse = Physics2:CalculateForceOffset(BP2Force, IntersectionCenter)
			Physics2:ApplyForceCenter(BP2LinImpulse)
			Physics2:ApplyTorqueCenter(Physics2:LocalToWorldVector(BP2AngImpulse * 2)) -- Are you sure this was a good idea?
			BP2:PlayBaseplateRepulsionSound(Vel2)
		end
	end
end)

function ENT:PlayBaseplateRepulsionSound(Vel)
	local Hard = Vel:Length() > 500 and true or false
	local Now  = Clock.CurTime
	local Prev = self.LastPlayRepulsionSound
	if Prev and Now - Prev < 0.75 then return end

	self.LastPlayRepulsionSound = Now
	self:EmitSound(Hard and "MetalVehicle.ImpactHard" or "MetalVehicle.ImpactSoft", 150, math.Rand(0.92, 1.05), 1, CHAN_AUTO, 0, 0)
end