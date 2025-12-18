local ACF      		= ACF

local function BaseplateRepulsionCheck(Ent)
	if IsValid(Ent:GetParent()) then return true end
	return ACF.IsEntityEligiblePhysmass(Ent)
end

local function GetBaseplateProperties(Ent)
	if not IsValid(Ent) then return false end
	if Ent:GetClass() ~= "acf_baseplate" then return false end
	if Ent:IsPlayerHolding() then return false end

	local Physics     = Ent:GetPhysicsObject()
	if not IsValid(Physics) then return false end

	local Contraption = Ent:GetContraption()
	if not Contraption then return end

	local Now = CurTime()
	-- This is kinda disgusting to read
	-- The AABB should be cached off and only repopulated every now and then.
	-- Getting it every tick would be way too expensive.
	-- To reduce exploit potential, the repolling rate for this cached data is randomized.
	if not Ent.ACF_CacheBaseplateData then Ent.ACF_CacheBaseplateData = {} end
	local ACF_CacheBaseplateData = Ent.ACF_CacheBaseplateData
	if not ACF_CacheBaseplateData.LastTime or (Now - ACF_CacheBaseplateData.LastTime) > math.Rand(0.2, 0.5) then
		ACF_CacheBaseplateData.Mins, ACF_CacheBaseplateData.Maxs, ACF_CacheBaseplateData.Center = Contraption:GetAABB(BaseplateRepulsionCheck)
		ACF_CacheBaseplateData.LastTime = Now
	end

	local Mins, Maxs, Center = ACF_CacheBaseplateData.Mins, ACF_CacheBaseplateData.Maxs, ACF_CacheBaseplateData.Center
	-- debugoverlay.Box(Center, Mins - Center, Maxs - Center, 0.1, Color(155, 155, 155, 50))
	local Pos         = Physics:GetPos()
	local Radius      = Maxs:Distance(Mins) / 2

	local Vel         = Physics:GetVelocity()
	local PhysMass    = Physics:GetMass()
	local TotalMass	  = Contraption.totalMass

	return true, Physics, Mins, Maxs, Center, Pos, Vel, Contraption, PhysMass, TotalMass, Radius
end

local function CalculateSphereIntersection(Pos1, Radius1, Pos2, Radius2)
	local Dir = Pos2 - Pos1
	local Dist = Dir:Length()
	Dir:Normalize()

	local Intersection = Dist - Radius1 - Radius2
	return Intersection, Dir, (Pos1 * Radius1 + Pos2 * Radius2) / (Radius1 + Radius2)
end

local function CalculateBoxIntersection(Mins1, Maxs1, Mins2, Maxs2)
	if not util.IsBoxIntersectingBox(Mins1, Maxs1, Mins2, Maxs2) then return false end
	
	local min1x, min1y, min1z = Mins1:Unpack()
	local max1x, max1y, max1z = Maxs1:Unpack()
	local min2x, min2y, min2z = Mins2:Unpack()
	local max2x, max2y, max2z = Maxs2:Unpack()

	local ix = math.min(max1x, max2x) - math.max(min1x, min2x)
	local iy = math.min(max1y, max2y) - math.max(min1y, min2y)
	local iz = math.min(max1z, max2z) - math.max(min1z, min2z)

	return true, math.min(ix, iy, iz)
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

			local Valid1, Physics1, Mins1, Maxs1, _, Pos1, Vel1, Contraption1, PhysMass1, TotalMass1, Radius1 = GetBaseplateProperties(BP1)
			local Valid2, Physics2, Mins2, Maxs2, _, Pos2, Vel2, Contraption2, PhysMass2, TotalMass2, Radius2 = GetBaseplateProperties(BP2)

			if not Valid1 or not Valid2 then continue end
			if Contraption1 == Contraption2 then continue end

			local SphereIntersectionDistance, IntersectionDirection, IntersectionCenter = CalculateSphereIntersection(Pos1, Radius1, Pos2, Radius2)

			if SphereIntersectionDistance > 0 then continue end

			-- Sphere checks are less expensive than box checks, so if the sphere check passes, perform the box check
			local IsIntersecting, IntersectionDistance = CalculateBoxIntersection(Mins1, Maxs1, Mins2, Maxs2)
			if not IsIntersecting then continue end
			IntersectionDistance = -IntersectionDistance

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
	local Now  = CurTime()
	local Prev = self.LastPlayRepulsionSound
	if Prev and Now - Prev < 0.75 then return end

	self.LastPlayRepulsionSound = Now
	self:EmitSound(Hard and "MetalVehicle.ImpactHard" or "MetalVehicle.ImpactSoft", 150, math.Rand(0.92, 1.05), 1, CHAN_AUTO, 0, 0)
end