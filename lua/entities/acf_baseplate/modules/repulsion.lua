local ACF      	      = ACF
local Clock           = ACF.Utilities.Clock

local IsEntityValid   = ACF.Optimizations.IsEntityValid
local IsPhysObjValid  = ACF.Optimizations.IsPhysObjValid
local ENTITY          = FindMetaTable("Entity")
local VECTOR          = FindMetaTable("Vector")
local PHYSOBJ         = FindMetaTable("PhysObj")

local COLLISION_SCALE = 15000
local MOMENTUM_SCALE = 1
local TOTAL_SCALE = 1

local zero_vec = Vector(0, 0, 0)

-- Bounding sphere enclosing the family of a baseplate.
local function GetFamilyBoundingSphere(Ent, EntTable)
	-- Rate limit for optimization
	if Clock.CurTime > (EntTable.FamilyBoundsDelay or 0) then
		EntTable.FamilyBoundsDelay = Clock.CurTime + 3 + math.Rand(-1, 1)

		-- I don't know why family isn't valid sometimes... oh well.
		local Family = Ent:GetFamily()
		if Family then
			local Verts = Family:GetOBB()
			local MinCorner, MaxCorner = Verts[1], Verts[8]
			EntTable.FamilyBoundsLocalPos = ENTITY.WorldToLocal(Ent, (MinCorner + MaxCorner) * 0.5)
			EntTable.FamilyBoundsRadius   = VECTOR.Distance(MinCorner, MaxCorner) * 0.5
		end
	end

	local LocalPos = EntTable.FamilyBoundsLocalPos or zero_vec
	local Radius = EntTable.FamilyBoundsRadius or 0

	return ENTITY.LocalToWorld(Ent, LocalPos), Radius
end

local function GetBaseplateProperties(Ent, Self, SelfPos, SelfRadius)
	if Ent == Self then return false end

	if not IsEntityValid(Ent) then return false end
	if ENTITY.GetClass(Ent) ~= "acf_baseplate" then return false end
	if not Ent.Size then return false end
	if ENTITY.IsPlayerHolding(Ent) then return false end

	local Physics     = ENTITY.GetPhysicsObject(Ent)
	if not IsPhysObjValid(Physics) then return false end

	local EntTable  = ENTITY.GetTable(Ent)
	local Pos, Radius = GetFamilyBoundingSphere(Ent, EntTable)

	if Self and not util.IsSphereIntersectingSphere(SelfPos, SelfRadius, Pos, Radius) then
		return false
	end

	local Vel         = PHYSOBJ.GetVelocity(Physics)
	local Contraption = ENTITY.CFW_GetContraption(Ent)
	local PhysMass    = PHYSOBJ.GetMass(Physics)
	local TotalMass	  = Contraption and Contraption.totalMass or PhysMass

	return true, Physics, Pos, Vel, Contraption, PhysMass, TotalMass, Radius
end

local function CalculateSphereIntersection(Pos1, Radius1, Pos2, Radius2)
	local Dir = Pos2 - Pos1
	local Dist = VECTOR.Length(Dir)
	VECTOR.Normalize(Dir)

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
			if not IsValid(BP1) or not IsValid(BP2) then continue end

			local BP1Table, BP2Table = ENTITY.GetTable(BP1), ENTITY.GetTable(BP2)

			if not BP1Table.Size or not BP2Table.Size then continue end
			if ENTITY.IsPlayerHolding(BP1) or ENTITY.IsPlayerHolding(BP2) then continue end

			local Valid1, Physics1, Pos1, Vel1, Contraption1, PhysMass1, TotalMass1, Radius1 = GetBaseplateProperties(BP1)
			local Valid2, Physics2, Pos2, Vel2, Contraption2, PhysMass2, TotalMass2, Radius2 = GetBaseplateProperties(BP2)

			if not Valid1 or not Valid2 then continue end
			if not Contraption1 or not Contraption2 then continue end
			if Contraption1 == Contraption2 then continue end

			-- if not ACF.DoesContraptionHavePlayers(Contraption1) or not ACF.DoesContraptionHavePlayers(Contraption2) then continue end
			-- Final chance for addons to handle it. If something returns false, we continue.
			if hook.Run("ACF_OnBaseplateRepulsion", BP1, BP2) == false then continue end

			local IntersectionDistance, IntersectionDirection, IntersectionCenter = CalculateSphereIntersection(Pos1, Radius1, Pos2, Radius2)
			if IntersectionDistance > 0 then continue end

			-- Velocity orthogonal to the collision direction is irrelevant...
			local VelAlongNormal = VECTOR.Dot(Vel2 - Vel1, IntersectionDirection)

			-- Compute the impulse needed to preserve the momentum of the system along the direction of the collision
			-- If they're moving away from each other, ignore.
			-- J = m * deltaV = m(v' - v) -> v' = v + J / m
			-- Newton's third law guarantees equal and opposite forces -> Equal and opposite impulses over short time -> J_a = -J_b = J
			-- v'_a = v_a + J_a / m_a = v_a + J / m_a
			-- v'_b = v_b + J_b / m_b = v_b - J / m_b
			-- Assuming a perfectly inelastic collision, v'_a = v'_b = v'
			-- v_a + J / m_a = v_b - J / m_b -> J(1/m_a + 1/m_b) = v_b - v_a -> J = (v_b - v_a) / (1/m_a + 1/m_b)
			local ImpulseMagnitude = (VelAlongNormal < 0) and (-VelAlongNormal / (1 / TotalMass1 + 1 / TotalMass2)) or 0

			local CollisionForce1 = (-IntersectionDirection * ImpulseMagnitude * MOMENTUM_SCALE) + (IntersectionDirection * IntersectionDistance * COLLISION_SCALE)
			local CollisionForce2 = ( IntersectionDirection * ImpulseMagnitude * MOMENTUM_SCALE) + (-IntersectionDirection * IntersectionDistance * COLLISION_SCALE)

			local BP1Force = CollisionForce1 * math.Clamp(PhysMass1 / TotalMass1, 0, 1) * TOTAL_SCALE
			local BP2Force = CollisionForce2 * math.Clamp(PhysMass2 / TotalMass2, 0, 1) * TOTAL_SCALE

			PHYSOBJ.ApplyForceOffset(Physics1, BP1Force, IntersectionCenter)
			BP1:PlayBaseplateRepulsionSound(Vel1)

			PHYSOBJ.ApplyForceOffset(Physics2, BP2Force, IntersectionCenter)
			BP2:PlayBaseplateRepulsionSound(Vel2)
		end
	end
end)

function ENT:PlayBaseplateRepulsionSound(Vel)
	local SelfTbl = ENTITY.GetTable(self)
	local Hard = VECTOR.Length(Vel) > 500 and true or false
	local Now  = Clock.CurTime
	local Prev = SelfTbl.LastPlayRepulsionSound
	if Prev and Now - Prev < 0.75 then return end

	SelfTbl.LastPlayRepulsionSound = Now
	ENTITY.EmitSound(self, Hard and "MetalVehicle.ImpactHard" or "MetalVehicle.ImpactSoft", 150, math.Rand(0.92, 1.05), 1, CHAN_AUTO, 0, 0)
end