local math   = math
local ACF    = ACF
local Damage = ACF.TempDamage

function Damage.isValidTarget(Entity)
	local Type = ACF.Check(Entity)

	if not Type then return false end
	if not Entity.Exploding then return false end
	if Type ~= "Squishy" then return true end

	return Entity:Health() > 0
end

function Damage.getRandomPos(Entity)
	local IsChar = Entity.ACF.Type == "Squishy"

	if IsChar then
		-- Scale down the "hitbox" since most of the character is in the middle
		local Mins = Entity:OBBMins() * 0.65
		local Maxs = Entity:OBBMaxs() * 0.65
		local X    = math.Rand(Mins[1], Maxs[1])
		local Y    = math.Rand(Mins[2], Maxs[2])
		local Z    = math.Rand(Mins[3], Maxs[3])

		return Entity:LocalToWorld(Vector(X, Y, Z))
	end

	local Mesh = Entity:GetPhysicsObject():GetMesh()

	if not Mesh then -- Spherical collisions
		local Mins = Entity:OBBMins()
		local Maxs = Entity:OBBMaxs()
		local X    = math.Rand(Mins[1], Maxs[1])
		local Y    = math.Rand(Mins[2], Maxs[2])
		local Z    = math.Rand(Mins[3], Maxs[3])
		local Rand = Vector(X, Y, Z)

		-- Attempt to a random point in the sphere
		return Entity:LocalToWorld(Rand:GetNormalized() * math.Rand(1, Entity:BoundingRadius() * 0.5))
	else
		local Rand = math.random(3, #Mesh / 3) * 3
		local P    = Vector()

		for I = Rand - 2, Rand do P = P + Mesh[I].pos end

		return Entity:LocalToWorld(P / 3) -- Attempt to hit a point on a face of the mesh
	end
end
