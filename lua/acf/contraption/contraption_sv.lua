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
		if Res[V] or not IsValid(V) then continue end

		Res[V] = true
		Contraption.GetAllChildren(V, Res)
	end

	return Res
end

function Contraption.GetEnts(Ent)
	local Con      = Ent:GetContraption()
	local ConEnts  = Con and Con.ents or {[Ent] = true}
	local Children = Ent:GetFamilyChildren()
	local Phys     = {}
	local Pare     = {}
	local Dtch     = {}

	for K in pairs(ConEnts) do
		if Children[K] then
			Pare[K] = true
		else
			local CurFamily = K:GetFamily()

			if CurFamily and CurFamily:GetRoot() ~= K then
				Pare[K] = true
			elseif ACF.IsEntityEligiblePhysmass(K) then
				Phys[K] = true
			else
				Dtch[K] = true
			end
		end
	end

	return Phys, Pare, Dtch
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
	local Con      = Ent:GetContraption()
	local PhysMass = 0
	local Time     = CurTime()

	-- Tally Vars
	local Power = 0
	local Fuel  = 0
	local PhysN = 0
	local ParN 	= 0
	local OthN  = 0
	local ConN	= 0

	local Physical, Parented, Detached = Contraption.GetEnts(Ent)
	local Constraints = {}

	-- Duplex pairs iterates over Physical, then Detached - but we can make Detached nil
	-- if DetachedPhysmassRatio == false
	for K in ACF.DuplexPairs(Physical, ACF.DetachedPhysmassRatio and Detached or nil) do
		local Phys = K:GetPhysicsObject()

		if not IsValid(Phys) then
			Physical[K] = nil
			OthN = OthN + 1
		else
			if Tally then
				local Class = K:GetClass()

				if Class == "acf_engine" then
					Power = Power + K.PeakPower * ACF.KwToHp
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
					Power = Power + K.PeakPower * ACF.KwToHp
				elseif Class == "acf_fueltank" then
					Fuel = Fuel + K.Capacity
				end

				ParN = ParN + 1
			end
		end
	end

	local TotMass = Con and Con.totalMass or PhysMass

	for _ in pairs(Detached) do
		OthN = OthN + 1
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

	for K in pairs(Detached) do
		K.acfphystotal      = PhysMass
		K.acftotal          = TotMass
		K.acflastupdatemass = Time
	end

	if Tally then
		local Owner = Ent:CPPIGetOwner()

		return Power, Fuel, PhysN, ParN, ConN, IsValid(Owner) and Owner:Name() or "Unknown", OthN, TotMass, PhysMass
	end
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

	hook.Add("Initialize", "ACF Meta Detour", function()
		timer.Simple(1, function()
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
			local IsVehicle 				= ENT.IsVehicle
			EntDetours.SetNoDraw			= SetNoDraw
			EntDetours.SetModel				= SetModel
			EntDetours.PhysicsInitSphere	= PhysicsInitSphere
			EntDetours.SetCollisionBounds	= SetCollisionBounds
			EntDetours.SetCollisionGroup	= SetCollisionGroup
			EntDetours.SetNotSolid			= SetNotSolid
			EntDetours.IsVehicle			= IsVehicle

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
				if Ent.IsACFEntity and not Ent.ACF_UserWeighable then Contraption.SetMass(Ent, Ent.ACF.Mass) return end

				if Ent.ACF_OnMassChange then
					Ent:ACF_OnMassChange(self:GetMass(), Mass)
				end

				SetMass(self, Mass)
			end

			function ENT:SetModel(Model)
				if self.IsACFEntity then Contraption.SetModel(self, self.ACF.Model) return end

				SetModel(self, Model)
			end

			function ENT:IsVehicle()
				if self.IsACFEntity and self.ACF_DetourIsVehicle then
					return self:ACF_DetourIsVehicle()
				end
				return IsVehicle(self)
			end

			-- All of these should prevent the relevant functions from occurring on ACF entities, but only if LegalChecks are enabled
			-- Will also call ACF.CheckLegal at the same time as preventing the function usage, because likely something else is amiss
			function ENT:PhysicsInitSphere(...)
				if self.IsACFEntity and ACF.LegalChecks then ACF.CheckLegal(self) return false end

				self._IsSpherical	= true

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
				-- NOTE: Slight delay added to this check in order to account for baseplate conversion otherwise failing
				if not IsValid(self) then return end
				if self.IsACFEntity and ACF.LegalChecks then
					timer.Simple(0, function() if not IsValid(self) then return end ACF.CheckLegal(self) end)
				end

				SetNotSolid(self, ...)
			end

			hook.Remove("Initialize", "ACF Meta Detour")
		end)
	end)
end