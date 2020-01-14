-- Contraption-aware functionality

-- Local Funcs ----------------------------------
-- These functions are used within this file and made global at the end
local function GetAncestor(Ent)
	if not IsValid(Ent) then return nil end

	local Parent = Ent

	while IsValid(Parent:GetParent()) do
		Parent = Parent:GetParent()
	end

	return Parent
end

local function GetAllPhysicalEntities(Ent, Tab)
	if not IsValid(Ent) then return end

	local Res = Tab or {}

	if Res[Ent] then
		return
	else
		Res[Ent] = true

		if Ent.Constraints then
			for _, V in pairs(Ent.Constraints) do
				if V.Type ~= "NoCollide" then
					GetAllPhysicalEntities(V.Ent1, Res)
					GetAllPhysicalEntities(V.Ent2, Res)
				end
			end
		end
	end

	return Res
end

local function GetAllChildren(Ent, Tab)
	if not IsValid(Ent) then return end

	local Res = Tab or {}

	for K in pairs(Ent:GetChildren()) do
		if Res[K] then continue end
		Res[K] = true
		GetAllChildren(K, Res)
	end

	return Res
end

local function GetEnts(Ent)
	local Ancestor = GetAncestor(Ent)
	local Phys = GetAllPhysicalEntities(Ancestor)
	local Pare = GetAllChildren(Ancestor)

	for K in pairs(Phys) do
		for P in pairs(GetAllChildren(K)) do
			Pare[P] = true
		end
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

function ACF_CalcMassRatio(Ent, Pwr)
	if not IsValid(Ent) then return end

	local TotMass  = 0
	local PhysMass = 0
	local Power    = 0
	local Fuel     = 0
	local Time     = CurTime()

	local Physical, Parented = GetEnts(Ent)

	for K in pairs(Physical) do
		if Pwr then
			if K:GetClass() == "acf_engine" then
				Power = Power + (K.peakkw * 1.34)
				Fuel = K.RequiresFuel and 2 or Fuel
			elseif K:GetClass() == "acf_fueltank" then
				Fuel = math.max(Fuel, 1)
			end
		end

		local Phys = K:GetPhysicsObject() -- This should always exist, but just in case

		if IsValid(Phys) then
			local Mass = Phys:GetMass()

			TotMass  = TotMass + Mass
			PhysMass = PhysMass + Mass
		end
	end

	for K in pairs(Parented) do
		if Physical[K] then continue end -- Skip overlaps

		if Pwr then
			if K:GetClass() == "acf_engine" then
				Power = Power + (K.peakkw * 1.34)
				Fuel = K.RequiresFuel and 2 or Fuel
			elseif K:GetClass() == "acf_fueltank" then
				Fuel = math.max(Fuel, 1)
			end
		end

		local Phys = K:GetPhysicsObject()

		if IsValid(Phys) then
			TotMass = TotMass + Phys:GetMass()
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

	if Pwr then
		return {
			Power = Power,
			Fuel = Fuel
		}
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