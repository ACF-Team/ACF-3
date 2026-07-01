local ACF      	      = ACF
local Clock           = ACF.Utilities.Clock

local IsEntityValid   = ACF.Optimizations.IsEntityValid
local IsPhysObjValid  = ACF.Optimizations.IsPhysObjValid
local ENTITY          = FindMetaTable("Entity")
local VECTOR          = FindMetaTable("Vector")
local PHYSOBJ         = FindMetaTable("PhysObj")

local function GetBaseplateProperties(Ent, Self, SelfPos, SelfRadius)
	if Ent == Self then return false end

	if not IsEntityValid(Ent) then return false end
	if ENTITY.GetClass(Ent) ~= "acf_baseplate" then return false end
	if not Ent.BaseplateSize then return false end
	if ENTITY.IsPlayerHolding(Ent) then return false end

	local Physics     = ENTITY.GetPhysicsObject(Ent)
	if not IsPhysObjValid(Physics) then return false end

	local EntTable  = ENTITY.GetTable(Ent)

	local EntX, EntY = VECTOR.Unpack(EntTable.BaseplateSize)

	local Pos         = PHYSOBJ.GetPos(Physics)
	local Radius      = math.sqrt((EntX / 2) ^ 2 + (EntY / 2) ^ 2)

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

			if not BP1Table.BaseplateSize or not BP2Table.BaseplateSize then continue end
			if ENTITY.IsPlayerHolding(BP1) or ENTITY.IsPlayerHolding(BP2) then continue end

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

			local BP1LinImpulse, BP1AngImpulse = PHYSOBJ.CalculateForceOffset(Physics1, BP1Force, IntersectionCenter)
			PHYSOBJ.ApplyForceCenter(Physics1, BP1LinImpulse)
			PHYSOBJ.ApplyTorqueCenter(Physics1, PHYSOBJ.LocalToWorldVector(Physics1, BP1AngImpulse * 2)) -- Are you sure this was a good idea?
			BP1:PlayBaseplateRepulsionSound(Vel1)

			local BP2LinImpulse, BP2AngImpulse = PHYSOBJ.CalculateForceOffset(Physics2, BP2Force, IntersectionCenter)
			PHYSOBJ.ApplyForceCenter(Physics2, BP2LinImpulse)
			PHYSOBJ.ApplyTorqueCenter(Physics2, PHYSOBJ.LocalToWorldVector(Physics2, BP2AngImpulse * 2)) -- Are you sure this was a good idea?
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