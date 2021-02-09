-- Contraption-aware functionality

-- Local Funcs ----------------------------------
-- These functions are used within this file and made global at the end

local ColGroupFilter = {[1] = true, [2] = true}

local function GetAncestor(Ent)
	if not IsValid(Ent) then return nil end

	local Parent = Ent
	local Last

	while IsValid(Parent:GetParent()) do
		Last   = Parent
		Parent = Parent:GetParent()
	end

	return Parent, Last
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

	for K in pairs(Phys) do -- Go through the all physical ents (There's probably less of those than the parented ones)
		if Pare[K] then -- Remove them from parented table
			Pare[K] = nil
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

function ACF_CalcMassRatio(Ent, Tally)
	local TotMass  = 0
	local PhysMass = 0
	local Time     = CurTime()

	-- Tally Vars
	local Power = 0
	local Fuel  = 0
	local PhysN = 0
	local ParN 	= 0
	local OthN  = 0
	local ConN	= 0

	local Physical, Parented = GetEnts(Ent)
	local Constraints = {}

	for K in pairs(Physical) do
		local Phys = K:GetPhysicsObject()

		if not IsValid(Phys) then
			Physical[K] = nil

			OthN = OthN + 1
		else
			if Tally then
				local Class = K:GetClass()

				if Class == "acf_engine" then
					Power = Power + K.peakkw * 1.34
				elseif Class == "acf_fueltank" then
					Fuel = Fuel + K.Capacity
				end

				if K.Constraints then -- Tally up constraints
					for _, Con in pairs(K.Constraints) do
						if IsValid(Con) and Con.Type ~= "NoCollide" and not Constraints[Con] then -- NoCollides aren't a real constraint
							Constraints[Con] = true
							ConN = ConN + 1
						end
					end
				end

				PhysN = PhysN + 1
			end


			local Mass = Phys:GetMass()

			TotMass  = TotMass + Mass
			PhysMass = PhysMass + Mass

			if ColGroupFilter[K:GetCollisionGroup()] then
				K:SetCollisionGroup(COLLISION_GROUP_NONE)
			end
		end
	end

	for K in pairs(Parented) do
		local Phys = K:GetPhysicsObject()

		if not IsValid(Phys) then
			Physical[K] = nil

			OthN = OthN + 1
		else
			if Tally then
				local Class = K:GetClass()

				if Class == "acf_engine" then
					Power = Power + K.peakkw * 1.34
				elseif Class == "acf_fueltank" then
					Fuel = Fuel + K.Capacity
				end

				ParN = ParN + 1
			end

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
		K.acfphystotal      = PhysMass
		K.acftotal          = TotMass
		K.acflastupdatemass = Time
	end

	if Tally then
		return Power, Fuel, PhysN, ParN, ConN, Ent:CPPIGetOwner():GetName(), OthN
	end
end

do -- ACF Parent Detouring 
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
end

do -- ASSUMING DIRECT CONTROL
	local ENT = FindMetaTable("Entity")
	local OBJ = FindMetaTable("PhysObj")

	do -- SetMass
		-- Reject any changes to mass on ACF entities
		-- Mass can only be set to whatever Ent.ACF.LegalMass is
		local SetMass = SetMass or OBJ.SetMass

		function OBJ:SetMass(Number)
			local Ent = self:GetEntity()

			if Ent.IsACFEntity and Ent.ACF and Number ~= Ent.ACF.LegalMass then
				return
			end

			SetMass(self, Number)
		end
	end

	do -- SetModel
		-- Reject any changes to the model on ACF entities
		-- Models can only be set to whatever Ent.ACF.Model is
		local SetModel = SetModel or ENT.SetModel

		function ENT:SetModel(String)
			if self.IsACFEntity and self.ACF and String ~= self.ACF.Model then
				return
			end

			SetModel(self, String)
		end
	end

	do -- SetSolid
		-- Reject any changes to the solidity on ACF entities
		local SetSolid = SetSolid or ENT.SetSolid

		function ENT:SetSolid(Number)
			if self.IsACFEntity and Number ~= SOLID_VPHYSICS then
				return
			end

			SetSolid(self, Number)
		end
	end

	do -- SetNoDraw
		local SetNoDraw = SetNoDraw or ENT.SetNoDraw

		function ENT:SetNoDraw(Bool)
			if Bool and self.IsACFEntity then
				return
			end

			SetNoDraw(self, Bool)
		end
	end
end

-- Globalize ------------------------------------
ACF_GetAllPhysicalEntities 	= GetAllPhysicalEntities
ACF_GetAllChildren 			= GetAllChildren
ACF_GetEnts 				= GetEnts
ACF_GetAncestor 			= GetAncestor