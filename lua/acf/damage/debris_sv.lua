util.AddNetworkString("ACF_Debris")

local Contraption = ACF.Contraption
local ValidDebris = ACF.ValidDebris
local ChildDebris = ACF.ChildDebris
local Queue       = {}

local function SendQueue()
	for Entity, Data in pairs(Queue) do
		local JSON = util.TableToJSON(Data)

		net.Start("ACF_Debris")
			net.WriteString(JSON)
		net.SendPVS(Data.Position)

		Queue[Entity] = nil
	end
end

local function DebrisNetter(Entity, Normal, Power, CanGib, Ignite)
	if not ACF.GetServerBool("CreateDebris") then return end
	if Queue[Entity] then return end

	local Current = Entity:GetColor()
	local New     = Vector(Current.r, Current.g, Current.b) * math.Rand(0.3, 0.6)

	if not next(Queue) then
		timer.Create("ACF_DebrisQueue", 0, 1, SendQueue)
	end

	Queue[Entity] = {
		Position = Entity:GetPos(),
		Angles   = Entity:GetAngles(),
		Material = Entity:GetMaterial(),
		Model    = Entity:GetModel(),
		Color    = Color(New.x, New.y, New.z, Current.a),
		Normal   = Normal,
		Power    = Power,
		CanGib   = CanGib or nil,
		Ignite   = Ignite or nil,
	}
end

function ACF.KillChildProps(Entity, BlastPos, Energy)
	local Explosives = {}
	local Children 	 = Contraption.GetAllChildren(Entity)
	local Count		 = 0

	-- do an initial processing pass on children, separating out explodey things to handle last
	for Ent in pairs(Children) do
		Ent.ACF_Killed = true -- mark that it's already processed

		if not ValidDebris[Ent:GetClass()] then
			Children[Ent] = nil -- ignoring stuff like holos, wiremod components, etc.
		else
			Ent:SetParent()

			if Ent.IsExplosive and not Ent.Exploding then
				Explosives[Ent] = true
				Children[Ent] 	= nil
			else
				Count = Count + 1
			end
		end
	end

	-- HE kill the children of this ent, instead of disappearing them by removing parent
	if next(Children) then
		local DebrisChance 	= math.Clamp(ChildDebris / Count, 0, 1)
		local Power 		= Energy / math.min(Count,3)

		for Ent in pairs( Children ) do
			if math.random() < DebrisChance then
				ACF.HEKill(Ent, (Ent:GetPos() - BlastPos):GetNormalized(), Power, nil, DmgInfo)
			else
				constraint.RemoveAll(Ent)

				Ent:Remove()
			end
		end
	end

	-- explode stuff last, so we don't re-process all that junk again in a new explosion
	if next(Explosives) then
		for Ent in pairs(Explosives) do
			Ent.Inflictor = Entity.Inflictor

			Ent:Detonate()
		end
	end
end

local function Gib(Entity,DmgInfo)
	Entity:PrecacheGibs()

	local dmg = DamageInfo()
	dmg:SetDamage(Entity:Health())
	if DmgInfo and IsValid(DmgInfo.Attacker) then dmg:SetAttacker(DmgInfo.Attacker) else dmg:SetAttacker(Entity) end
	if DmgInfo and IsValid(DmgInfo.Inflictor) then dmg:SetInflictor(DmgInfo.Inflictor) else dmg:SetInflictor(Entity) end
	dmg:SetDamageType(DMG_ALWAYSGIB)

	timer.Simple(0,function()
		if not IsValid(Entity) then return end
		Entity:TakeDamageInfo(dmg)
	end)
end

function ACF.HEKill(Entity, Normal, Energy, BlastPos, DmgInfo) -- blast pos is an optional world-pos input for flinging away children props more realistically
	-- if it hasn't been processed yet, check for children
	if not Entity.ACF_Killed then
		ACF.KillChildProps(Entity, BlastPos or Entity:GetPos(), Energy)
	end

	local Radius = Entity:BoundingRadius()
	local Debris = {}
	local Class = Entity:GetClass()
	local CanBreak = (Class == "prop_physics") and (Entity:Health() > 0)

	if not CanBreak then DebrisNetter(Entity, Normal, Energy, false, true) end -- if we can't break the prop into its own gibs, then use ACF's system

	if ACF.GetServerBool("CreateFireballs") then
		local Fireballs = math.Clamp(Radius * 0.01, 1, math.max(10 * ACF.GetServerNumber("FireballMult", 1), 1))
		local Min, Max = Entity:OBBMins(), Entity:OBBMaxs()
		local Pos = Entity:GetPos()
		local Ang = Entity:GetAngles()

		for _ = 1, Fireballs do -- should we base this on prop volume?
			local Fireball = ents.Create("acf_debris")

			if not IsValid(Fireball) then break end -- we probably hit edict limit, stop looping

			local Lifetime = math.Rand(5, 15)
			local Offset   = ACF.RandomVector(Min, Max)

			Offset:Rotate(Ang)

			Fireball:SetPos(Pos + Offset)
			Fireball:Spawn()
			Fireball:Ignite(Lifetime)

			timer.Simple(Lifetime, function()
				if not IsValid(Fireball) then return end

				Fireball:Remove()
			end)

			local Phys = Fireball:GetPhysicsObject()

			if IsValid(Phys) then
				Phys:ApplyForceOffset(Normal * Energy / Fireballs, Fireball:GetPos() + VectorRand())
			end

			Debris[Fireball] = true
		end
	end

	constraint.RemoveAll(Entity)

	if CanBreak then
		Gib(Entity,DmgInfo)
	else
		Entity:Remove()
	end

	return Debris
end

function ACF.APKill(Entity, Normal, Power, DmgInfo)
	if not IsValid(Entity) then return end

	local Class = Entity:GetClass()
	local CanBreak = (Class == "prop_physics") and (Entity:Health() > 0)

	ACF.KillChildProps(Entity, Entity:GetPos(), Power) -- kill the children of this ent, instead of disappearing them from removing parent

	if not CanBreak then DebrisNetter(Entity, Normal, Power, true, false) end -- if we can't break the prop into its own gibs, then use ACF's system

	constraint.RemoveAll(Entity)

	if CanBreak then
		Gib(Entity,DmgInfo)
	else
		Entity:Remove()
	end
end
