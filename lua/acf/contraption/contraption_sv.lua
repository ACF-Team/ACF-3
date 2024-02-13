-- Contraption-aware functionality

local ACF = ACF
local Contraption = ACF.Contraption

function Contraption.GetAncestor(Ent)
	if not IsValid(Ent) then return nil end

	local Parent = Ent
	local Last

	while IsValid(Parent:GetParent()) do
		Last   = Parent
		Parent = Parent:GetParent()
	end

	return Parent, Last
end

function Contraption.GetAncestors(Ent)
	local Ancestors = {}
	local Parent    = Ent:GetParent()
	local Count     = 0

	while IsValid(Parent) do
		Count            = Count + 1
		Ancestors[Count] = Parent

		Parent = Parent:GetParent()
	end

	return Ancestors
end

function Contraption.HasAncestor(Ent, Ancestor)
	if not IsValid(Ent) then return false end
	if not IsValid(Ancestor) then return false end

	local Parent = Ent:GetParent()

	while IsValid(Parent) do
		if Parent == Ancestor then
			return true
		end

		Parent = Parent:GetParent()
	end

	return false
end

function Contraption.GetAllPhysicalEntities(Ent, Tab)
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
					Contraption.GetAllPhysicalEntities(V.Ent1, Res)
					Contraption.GetAllPhysicalEntities(V.Ent2, Res)
				end
			end
		end
	end

	return Res
end

function Contraption.GetAllChildren(Ent, Tab)
	local Res = Tab or {}

	for _, V in pairs(Ent:GetChildren()) do
		if not IsValid(V) or Res[V] then continue end

		Res[V] = true
		Contraption.GetAllChildren(V, Res)
	end

	return Res
end

function Contraption.GetEnts(Ent)
	local Ancestor 	= Contraption.GetAncestor(Ent)
	local Phys 		= Contraption.GetAllPhysicalEntities(Ancestor)
	local Pare 		= {}

	for K in pairs(Phys) do
		Contraption.GetAllChildren(K, Pare)
	end

	for K in pairs(Phys) do -- Go through the all physical ents (There's probably less of those than the parented ones)
		if Pare[K] then -- Remove them from parented table
			Pare[K] = nil
		end
	end

	return Phys, Pare
end
-------------------------------------------------
function Contraption.HasConstraints(Ent)
	if Ent.Constraints then
		for _, V in pairs(Ent.Constraints) do
			if V.Type ~= "NoCollide" then
				return true
			end
		end
	end

	return false
end

function Contraption.CalcMassRatio(Ent, Tally)
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

	local Physical, Parented = Contraption.GetEnts(Ent)
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
					Power = Power + K.PeakPower * 1.34
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
					Power = Power + K.PeakPower * 1.34
				elseif Class == "acf_fueltank" then
					Fuel = Fuel + K.Capacity
				end

				ParN = ParN + 1
			end

			TotMass = TotMass + Phys:GetMass()

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
		local Owner = Ent:CPPIGetOwner()

		return Power, Fuel, PhysN, ParN, ConN, IsValid(Owner) and Owner:Name() or "Unknown", OthN
	end
end

do -- ACF Parent Detouring
	local Detours = {}

	function Contraption.AddParentDetour(Class, Variable)
		if not Class then return end
		if not Variable then return end

		Detours[Class] = function(Entity)
			return Entity[Variable]
		end
	end

	hook.Add("Initialize", "ACF Parent Detour", function()
		timer.Simple(1,function()
			local EntMeta = FindMetaTable("Entity")
			local SetParent = SetParent or EntMeta.SetParent
			local GetParent = GetParent or EntMeta.GetParent

			function EntMeta:SetParent(Entity, ...)
				if not IsValid(self) then return end
				local SavedParent
				if (IsValid(self:GetParent()) and self:GetParent().ACF_OnParented) and not IsValid(Entity) then
					self:GetParent():ACF_OnParented(self,false)
				end

				if IsValid(Entity) then
					local Detour = Detours[Entity:GetClass()]

					if Entity.ACF_OnParented then
						SavedParent = Entity
					end

					if Detour then
						Entity = Detour(Entity) or Entity
					end
				end

				SetParent(self, Entity, ...)

				if IsValid(SavedParent) then
					SavedParent:ACF_OnParented(self,true)
				end
			end

			function EntMeta:GetParent()
				if not IsValid(self) then return end
				local Parent = GetParent(self)

				if IsValid(Parent) then
					local Detour = Detours[Parent:GetClass()]

					if Detour then
						Parent = Detour(Parent) or Parent
					end
				end

				return Parent
			end

			hook.Remove("Initialize", "ACF Parent Detour")
		end)
	end)
end

do -- ASSUMING DIRECT CONTROL

	local BlockedTools = {
		proper_clipping	= true,
		makespherical	= true
	}

	local BlockedGroups = {
		[COLLISION_GROUP_DEBRIS]		= true,
		[COLLISION_GROUP_IN_VEHICLE]	= true,
		[COLLISION_GROUP_VEHICLE_CLIP]	= true,
		[COLLISION_GROUP_DOOR_BLOCKER]	= true
	}

	-- If allowed, will remove existing makespherical dupe modifiers on ACF entities
	hook.Add("OnEntityCreated", "ACF Exploitables Stubbing", function(Entity)
		if not ACF.LegalChecks then return end
		if not IsValid(Entity) then return end
		if not Entity.IsACFEntity then return end

		duplicator.ClearEntityModifier(Entity, "sphere")
		duplicator.ClearEntityModifier(Entity, "MakeSphericalCollisions")
	end)

	-- This, if allowed, will prevent physical clips from happening on ACF entities, except for procedural armor
	hook.Add("ProperClippingCanPhysicsClip", "ACF Block PhysicsClip", function(Entity)
		if not ACF.LegalChecks then return true end
		if Entity.IsACFArmor then return true end
		if Entity.IsACFEntity then return false end
	end)

	-- This, if allowed, will block ProperClipping from putting clips on any ACF entities, except for procedural armor
	hook.Add("CanTool", "ACF Block ProperClipping", function(_, Trace, Tool)
		if not ACF.LegalChecks then return end

		if not BlockedTools[Tool] then return end

		-- Special case, allow this but block on everything else
		if Trace.Entity.IsACFArmor and Tool == "proper_clipping" then return true end

		if Trace.Entity.IsACFEntity then return false end
	end)

	hook.Add("Initialize", "ACF Meta Detour",function()
		timer.Simple(1,function()
			Contraption.Detours = Contraption.Detours or {
				ENT			= {},
				OBJ			= {},
			}

			local ENT = FindMetaTable("Entity")
			local OBJ = FindMetaTable("PhysObj")

			local EntDetours	= Contraption.Detours.ENT
			local ObjDetours	= Contraption.Detours.OBJ

			local SetMass		= OBJ.SetMass
			ObjDetours.SetMass	= SetMass

			local SetNoDraw					= ENT.SetNoDraw
			local SetModel					= ENT.SetModel
			local PhysicsInitSphere			= ENT.PhysicsInitSphere
			local SetCollisionBounds		= ENT.SetCollisionBounds
			local SetCollisionGroup			= ENT.SetCollisionGroup
			local SetNotSolid				= ENT.SetNotSolid
			EntDetours.SetNoDraw			= SetNoDraw
			EntDetours.SetModel				= SetModel
			EntDetours.PhysicsInitSphere	= PhysicsInitSphere
			EntDetours.SetCollisionBounds	= SetCollisionBounds
			EntDetours.SetCollisionGroup	= SetCollisionGroup
			EntDetours.SetNotSolid			= SetNotSolid

			-- Convenience functions that will set the Mass/Model variables in the ACF table for the entity
			function Contraption.SetMass(Entity, Mass)
				Entity.ACF.Mass	=	 Mass

				if Entity.ACF_OnMassChange then
					Entity:ACF_OnMassChange(Entity:GetPhysicsObject():GetMass(), Mass)
				end

				SetMass(Entity:GetPhysicsObject(), Mass)
			end

			function Contraption.SetModel(Entity, Model)
				Entity.ACF.Model	= Model

				SetModel(Entity, Model)
			end

			function OBJ:SetMass(Mass)
				local Ent = self:GetEntity()

				-- Required due for AD2 support, if this isn't present then entities will never get set to their required weight on dupe paste
				if Ent.IsACFEntity then Contraption.SetMass(Ent, Ent.ACF.Mass) return end

				if Ent.ACF_OnMassChange then
					Ent:ACF_OnMassChange(self:GetMass(), Mass)
				end

				SetMass(self, Mass)
			end

			function ENT:SetModel(Model)
				if self.IsACFEntity then Contraption.SetModel(self, self.ACF.Model) return end

				SetModel(self, Model)
			end

			-- All of these should prevent the relevant functions from occurring on ACF entities, but only if LegalChecks are enabled
			-- Will also call ACF.CheckLegal at the same time as preventing the function usage, because likely something else is amiss
			function ENT:PhysicsInitSphere(...)
				if self.IsACFEntity and ACF.LegalChecks then ACF.CheckLegal(self) return false end

				return PhysicsInitSphere(self, ...)
			end

			function ENT:SetCollisionBounds(...)
				if self.IsACFEntity and ACF.LegalChecks then ACF.CheckLegal(self) return end

				SetCollisionBounds(self, ...)
			end

			function ENT:SetCollisionGroup(Group)
				if self.IsACFEntity and ACF.LegalChecks and (BlockedGroups[Group] == true) then ACF.CheckLegal(self) return end

				SetCollisionGroup(self, Group)
			end

			function ENT:SetNoDraw(...)
				if self.IsACFEntity and ACF.LegalChecks then ACF.CheckLegal(self) return end

				SetNoDraw(self, ...)
			end

			function ENT:SetNotSolid(...)
				if self.IsACFEntity then ACF.CheckLegal(self) end

				SetNotSolid(self, ...)
			end

			hook.Remove("Initialize","ACF Meta Detour")
		end)
	end)
end