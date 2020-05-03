-- Contraption-aware functionality

-- Local Funcs ----------------------------------
-- These functions are used within this file and made global at the end

local ColGroupFilter = {COLLISION_GROUP_DEBRIS = true, COLLISION_GROUP_DEBRIS_TRIGGER = true}

local function GetAncestor(Ent)
	if not IsValid(Ent) then return nil end

	local Parent = Ent

	while IsValid(Parent:GetParent()) do
		Parent = Parent:GetParent()
	end

	return Parent
end

local function GetAllPhysicalEntities(Ent, Tab)
	local Res = Tab or {}

	if IsValid(Ent) and not Res[Ent] then
		Res[Ent] = true

		if Ent.Constraints then
			for K, V in pairs(Ent.Constraints) do
				if not IsValid(V) then -- Constraints don't clean up after themselves
					Ent.Constraints[K] = nil -- But we will do Garry a favor and clean up after him
					continue
				end

				if V.Type ~= "NoCollide" then -- NoCollides aren't a real constraint
					GetAllPhysicalEntities(V.Ent1, Res)
					GetAllPhysicalEntities(V.Ent2, Res)
				end
			end
		end
	end

	return Res
end

local function GetAllChildren(Ent, Tab)
	local Res = Tab or {}

	for _, V in pairs(Ent:GetChildren()) do
		if not IsValid(V) or Res[V] then continue end

		Res[V] = true
		GetAllChildren(V, Res)
	end

	return Res
end

local function GetEnts(Ent)
	local Ancestor 	= GetAncestor(Ent)
	local Phys 		= GetAllPhysicalEntities(Ancestor)
	local Pare 		= {}

	for K in pairs(Phys) do
		GetAllChildren(K, Pare)
	end

	return Phys, Pare
end
-------------------------------------------------
function ACF_HasConstraint(Ent)
	if Ent.Constraints then
		for _, V in pairs(Ent.Constraints) do
			if V.Type ~= "NoCollide" then
				return true
			end
		end
	end

	return false
end

function ACF_CalcMassRatio(Ent, Tally)
	local TotMass  = 0
	local PhysMass = 0
	local Time     = CurTime()

	-- Tally Vars
	local Power    = 0
	local Fuel     = 0
	local PhysN    = 0
	local ParN 	   = 0
	local ConN	   = 0

	local Physical, Parented = GetEnts(Ent)

	for K in pairs(Physical) do
		if Tally then
			local Class = K:GetClass()

			if Class == "acf_engine" then
				local Mult = (K.RequiresFuel or next(K.FuelTanks)) and ACF.TorqueBoost or 1

				Power = Power + K.peakkw * 1.34 * Mult
			elseif Class == "acf_fueltank" then
				Fuel = Fuel + K.Capacity
			end

			if K.Constraints then
				for _, Con in pairs(K.Constraints) do
					if IsValid(Con) and Con.Type ~= "NoCollide" then -- NoCollides aren't a real constraint
						ConN = ConN + 1
					end
				end
			end

			PhysN = PhysN + 1
		end

		local Phys = K:GetPhysicsObject() -- This should always exist, but just in case

		if IsValid(Phys) then
			local Mass = Phys:GetMass()

			TotMass  = TotMass + Mass
			PhysMass = PhysMass + Mass

			if ColGroupFilter[K:GetCollisionGroup()] then
				K:SetCollisionGroup(COLLISION_GROUP_NONE)
			end
		end
	end

	for K in pairs(Parented) do
		if Physical[K] then continue end -- Skip overlaps

		if Tally then
			local Class = K:GetClass()

			if Class == "acf_engine" then
				local Mult = (K.RequiresFuel or next(K.FuelTanks)) and ACF.TorqueBoost or 1

				Power = Power + K.peakkw * 1.34 * Mult
			elseif Class == "acf_fueltank" then
				Fuel = Fuel + K.Capacity
			end

			ParN = ParN + 1
		end

		local Phys = K:GetPhysicsObject()

		if IsValid(Phys) then
			TotMass = TotMass + Phys:GetMass()

			if ColGroupFilter[K:GetCollisionGroup()] then
				K:SetCollisionGroup(COLLISION_GROUP_NONE)
			end
		end
	end

	for K in pairs(Physical) do
		K.acfphystotal      = PhysMass
		K.acftotal          = TotMass
		K.acflastupdatemass = Time
	end

	for K in pairs(Parented) do
		if Physical[K] then continue end -- Skip overlaps

		K.acfphystotal      = PhysMass
		K.acftotal          = TotMass
		K.acflastupdatemass = Time
	end

	if Tally then
		return Power, Fuel, PhysN, ParN, ConN, Ent:CPPIGetOwner():Nick()
	end
end

do -- ACF Parent Detouring ----------------------
	local Detours = {}
	function ACF.AddParentDetour(Class, Variable)
		if not Class then return end
		if not Variable then return end

		Detours[Class] = function(Entity)
			return Entity[Variable]
		end
	end

	hook.Add("Initialize", "ACF Parent Detour", function()
		local EntMeta = FindMetaTable("Entity")
		local SetParent = EntMeta.SetParent

		function EntMeta:SetParent(Entity, ...)
			if IsValid(Entity) then
				local Detour = Detours[Entity:GetClass()]

				if Detour then
					Entity = Detour(Entity)
				end
			end

			SetParent(self, Entity, ...)
		end

		hook.Remove("Initialize", "ACF Parent Detour")
	end)
end ---------------------------------------------

-- Globalize ------------------------------------
ACF_GetAllPhysicalEntities 	= GetAllPhysicalEntities
ACF_GetAllChildren 			= GetAllChildren
ACF_GetEnts 				= GetEnts
ACF_GetAncestor 			= GetAncestor