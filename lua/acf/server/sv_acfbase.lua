function ACF_UpdateVisualHealth(Entity)
	if Entity.ACF.PrHealth == Entity.ACF.Health then return end

	if not ACF_HealthUpdateList then
		ACF_HealthUpdateList = {}

		-- We should send things slowly to not overload traffic.
		timer.Create("ACF_HealthUpdateList", 1, 1, function()
			local Table = {}

			for _, v in pairs(ACF_HealthUpdateList) do
				if IsValid(v) then
					table.insert(Table, {
						ID = v:EntIndex(),
						Health = v.ACF.Health,
						MaxHealth = v.ACF.MaxHealth
					})
				end
			end

			net.Start("ACF_RenderDamage")
			net.WriteTable(Table)
			net.Broadcast()
			ACF_HealthUpdateList = nil
		end)
	end

	table.insert(ACF_HealthUpdateList, Entity)
end

function ACF_Activate(Entity, Recalc)
	--Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local PhysObj = Entity:GetPhysicsObject()

	if not IsValid(PhysObj) then return end

	if Entity.SpecialHealth then
		Entity:ACF_Activate(Recalc)
		return
	end

	Entity.ACF = Entity.ACF or {}
	Entity.ACF.PhysObj = Entity:GetPhysicsObject()

	local Count = PhysObj:GetMesh() and #PhysObj:GetMesh() or nil

	if Count and Count > 100 then
		Entity.ACF.Area = (PhysObj:GetSurfaceArea() * 6.45) * 0.52505066107
	else
		local Size = Entity.OBBMaxs(Entity) - Entity.OBBMins(Entity)

		Entity.ACF.Area = ((Size.x * Size.y) + (Size.x * Size.z) + (Size.y * Size.z)) * 6.45 --^ 1.15
	end

	Entity.ACF.Ductility = Entity.ACF.Ductility or 0
	local Area = Entity.ACF.Area
	local Ductility = math.Clamp(Entity.ACF.Ductility, -0.8, 0.8)
	local Armour = ACF_CalcArmor(Area, Ductility, Entity:GetPhysicsObject():GetMass()) -- So we get the equivalent thickness of that prop in mm if all its weight was a steel plate
	local Health = (Area / ACF.Threshold) * (1 + Ductility) -- Setting the threshold of the prop Area gone
	local Percent = 1

	if Recalc and Entity.ACF.Health and Entity.ACF.MaxHealth then
		Percent = Entity.ACF.Health / Entity.ACF.MaxHealth
	end

	Entity.ACF.Health = Health * Percent
	Entity.ACF.MaxHealth = Health
	Entity.ACF.Armour = Armour * (0.5 + Percent / 2)
	Entity.ACF.MaxArmour = Armour * ACF.ArmorMod
	Entity.ACF.Type = nil
	Entity.ACF.Mass = PhysObj:GetMass()

	if Entity:IsPlayer() or Entity:IsNPC() then
		Entity.ACF.Type = "Squishy"
	elseif Entity:IsVehicle() then
		Entity.ACF.Type = "Vehicle"
	else
		Entity.ACF.Type = "Prop"
	end
end

--[[ ACF Legality Check
	All SENTs MUST have:
		ENT.ACF.PhysObj defined when spawned
		ENT.ACF.LegalMass defined
		ENT.ACF.Model defined

		function ENT:Enable()
			self.Disabled = nil

			<code>

			ACF_CheckLegal(self)
		end

	function ENT:Disable()
		self.Disabled = true

		timer.Simple(ACF.IllegalDisableTime, function()
			if IsValid(self) then
				self:Enable()
			end
		end)

		<code>
	end
]]--
function ACF_IsLegal(Entity)
	local Phys = Entity:GetPhysicsObject()

	if Entity.ACF.PhysObj ~= Phys then
		if Phys:GetVolume() then
			Entity.ACF.PhysObj = Phys -- Updated PhysObj
		else
			Entity:Remove() -- Remove spherical trash
			return false, "Invalid physics" -- This shouldn't even run
		end
	end
	if Entity:GetModel() ~= Entity.ACF.Model then return false, "Incorrect model" end
	if Entity:GetNoDraw() then return false, "Not drawn" end
	if Phys:GetMass() < Entity.ACF.LegalMass then return false, "Underweight" end -- You can make it heavier than the legal mass if you want
	if Entity:GetSolid() ~= SOLID_VPHYSICS then return false, "Not solid" end -- Entities must always be solid
	if Entity.ClipData and next(Entity.ClipData) then return false, "Visual Clip" end -- No visclip

	return true
end

local IsLegal = ACF_IsLegal
function ACF_CheckLegal(Entity)
	local Legal, Reason = IsLegal(Entity)

	Entity.DisableReason = Reason

	if not Legal then
		Entity:Disable()
		return false
	end

	timer.Simple(math.Rand(1, 3), function()
		if IsValid(Entity) then
			ACF_CheckLegal(Entity)
		end
	end)

	return true
end

local Baddies = {gmod_ghost = true, acf_debris = true, prop_ragdoll = true}
function ACF_Check(Entity)
	if not IsValid(Entity) then return false end

	local PhysObj = Entity:GetPhysicsObject()
	if not IsValid(PhysObj) or PhysObj:GetMass() <= 0 or Entity:IsWorld() or Entity:IsWeapon() then return false end

	local Class = Entity:GetClass()
	if Baddies[Class] or string.find(Class, "func_") then return false end

	if not Entity.ACF then
		ACF_Activate(Entity)
	elseif Entity.ACF.Mass ~= PhysObj:GetMass() or Entity.ACF.PhysObj ~= PhysObj then
		ACF_Activate(Entity, true)
	end

	return Entity.ACF.Type
end

function ACF_Damage(Entity, Energy, FrArea, Angle, Inflictor, Bone, Gun, Type)
	local Activated = ACF_Check(Entity)
	local CanDo = hook.Run("ACF_BulletDamage", Activated, Entity, Energy, FrArea, Angle, Inflictor, Bone, Gun)

	-- above (default) hook does nothing with activated
	if CanDo == false or Activated == false then
		return {
			Damage = 0,
			Overkill = 0,
			Loss = 0,
			Kill = false
		}
	end

	if Entity.SpecialDamage then
		return Entity:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor, Bone, Type)
	elseif Activated == "Prop" then
		return ACF_PropDamage(Entity, Energy, FrArea, Angle, Inflictor, Bone)
	elseif Activated == "Vehicle" then
		return ACF_VehicleDamage(Entity, Energy, FrArea, Angle, Inflictor, Bone, Gun)
	elseif Activated == "Squishy" then
		return ACF_SquishyDamage(Entity, Energy, FrArea, Angle, Inflictor, Bone, Gun)
	end
end

function ACF_CalcDamage(Entity, Energy, FrArea, Angle)
	local armor = Entity.ACF.Armour -- Armor
	local losArmor = armor / math.abs(math.cos(math.rad(Angle)) ^ ACF.SlopeEffectFactor) -- LOS Armor
	local maxPenetration = (Energy.Penetration / FrArea) * ACF.KEtoRHA --RHA Penetration
	local HitRes = {}


	-- Projectile caliber. Messy, function signature
	local caliber = 20 * (FrArea ^ (1 / ACF.PenAreaMod) / 3.1416) ^ 0.5
	-- Breach probability
	local breachProb = math.Clamp((caliber / Entity.ACF.Armour - 1.3) / (7 - 1.3), 0, 1)
	-- Penetration probability
	local penProb = (math.Clamp(1 / (1 + math.exp(-43.9445 * (maxPenetration / losArmor - 1))), 0.0015, 0.9985) - 0.0015) / 0.997

	-- Breach chance roll
	if breachProb > math.random() and maxPenetration > armor then
		HitRes.Damage = FrArea -- Inflicted Damage
		HitRes.Overkill = maxPenetration - armor -- Remaining penetration
		HitRes.Loss = armor / maxPenetration -- Energy loss in percents

		return HitRes
	elseif penProb > math.random() then
		-- Penetration chance roll
		local Penetration = math.min(maxPenetration, losArmor)
		HitRes.Damage = (Penetration / losArmor) ^ 2 * FrArea
		HitRes.Overkill = (maxPenetration - Penetration)
		HitRes.Loss = Penetration / maxPenetration

		return HitRes
	end

	-- Projectile did not breach nor penetrate armor
	local Penetration = math.min(maxPenetration, losArmor)
	HitRes.Damage = (Penetration / losArmor) ^ 2 * FrArea
	HitRes.Overkill = 0
	HitRes.Loss = 1

	return HitRes
end

function ACF_PropDamage(Entity, Energy, FrArea, Angle)
	local HitRes = ACF_CalcDamage(Entity, Energy, FrArea, Angle)
	HitRes.Kill = false

	if HitRes.Damage >= Entity.ACF.Health then
		HitRes.Kill = true
	else
		Entity.ACF.Health = Entity.ACF.Health - HitRes.Damage
		Entity.ACF.Armour = math.Clamp(Entity.ACF.MaxArmour * (0.5 + Entity.ACF.Health / Entity.ACF.MaxHealth / 2) ^ 1.7, Entity.ACF.MaxArmour * 0.25, Entity.ACF.MaxArmour) --Simulating the plate weakening after a hit

		--math.Clamp( Entity.ACF.Ductility, -0.8, 0.8 )
		if Entity.ACF.PrHealth then
			ACF_UpdateVisualHealth(Entity)
		end

		Entity.ACF.PrHealth = Entity.ACF.Health
	end

	return HitRes
end

function ACF_VehicleDamage(Entity, Energy, FrArea, Angle, Inflictor, _, Gun)
	local HitRes = ACF_CalcDamage(Entity, Energy, FrArea, Angle)
	local Driver = Entity:GetDriver()

	if IsValid(Driver) then
		ACF_SquishyDamage(Driver, Energy, FrArea, Angle, Inflictor, math.Rand(0, 7), Gun)
	end

	HitRes.Kill = false

	if HitRes.Damage >= Entity.ACF.Health then
		HitRes.Kill = true
	else
		Entity.ACF.Health = Entity.ACF.Health - HitRes.Damage
		Entity.ACF.Armour = Entity.ACF.Armour * (0.5 + Entity.ACF.Health / Entity.ACF.MaxHealth / 2) --Simulating the plate weakening after a hit
	end

	return HitRes
end

function ACF_SquishyDamage(Entity, Energy, FrArea, Angle, Inflictor, Bone, Gun)
	local Size = Entity:BoundingRadius()
	local Mass = Entity:GetPhysicsObject():GetMass()
	local HitRes = {}
	local Damage = 0

	--We create a dummy table to pass armour values to the calc function
	local Target = {
		ACF = {
			Armour = 0.1
		}
	}

	if (Bone) then
		--This means we hit the head
		if (Bone == 1) then
			Target.ACF.Armour = Mass * 0.02 --Set the skull thickness as a percentage of Squishy weight, this gives us 2mm for a player, about 22mm for an Antlion Guard. Seems about right
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, Angle) --This is hard bone, so still sensitive to impact angle
			Damage = HitRes.Damage * 20

			--If we manage to penetrate the skull, then MASSIVE DAMAGE
			if HitRes.Overkill > 0 then
				Target.ACF.Armour = Size * 0.25 * 0.01 --A quarter the bounding radius seems about right for most critters head size
				HitRes = ACF_CalcDamage(Target, Energy, FrArea, 0)
				Damage = Damage + HitRes.Damage * 100
			end

			Target.ACF.Armour = Mass * 0.065 --Then to check if we can get out of the other side, 2x skull + 1x brains
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, Angle)
			Damage = Damage + HitRes.Damage * 20
		elseif (Bone == 0 or Bone == 2 or Bone == 3) then
			--This means we hit the torso. We are assuming body armour/tough exoskeleton/zombie don't give fuck here, so it's tough
			Target.ACF.Armour = Mass * 0.08 --Set the armour thickness as a percentage of Squishy weight, this gives us 8mm for a player, about 90mm for an Antlion Guard. Seems about right
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, Angle) --Armour plate,, so sensitive to impact angle
			Damage = HitRes.Damage * 5

			if HitRes.Overkill > 0 then
				Target.ACF.Armour = Size * 0.5 * 0.02 --Half the bounding radius seems about right for most critters torso size
				HitRes = ACF_CalcDamage(Target, Energy, FrArea, 0)
				Damage = Damage + HitRes.Damage * 50 --If we penetrate the armour then we get into the important bits inside, so DAMAGE
			end

			Target.ACF.Armour = Mass * 0.185 --Then to check if we can get out of the other side, 2x armour + 1x guts
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, Angle)
		elseif (Bone == 4 or Bone == 5) then
			--This means we hit an arm or appendage, so ormal damage, no armour
			Target.ACF.Armour = Size * 0.2 * 0.02 --A fitht the bounding radius seems about right for most critters appendages
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, 0) --This is flesh, angle doesn't matter
			Damage = HitRes.Damage * 30 --Limbs are somewhat less important
		elseif (Bone == 6 or Bone == 7) then
			Target.ACF.Armour = Size * 0.2 * 0.02 --A fitht the bounding radius seems about right for most critters appendages
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, 0) --This is flesh, angle doesn't matter
			Damage = HitRes.Damage * 30 --Limbs are somewhat less important
		elseif (Bone == 10) then
			--This means we hit a backpack or something
			Target.ACF.Armour = Size * 0.1 * 0.02 --Arbitrary size, most of the gear carried is pretty small
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, 0) --This is random junk, angle doesn't matter
			Damage = HitRes.Damage * 2 --Damage is going to be fright and shrapnel, nothing much		
		else --Just in case we hit something not standard
			Target.ACF.Armour = Size * 0.2 * 0.02
			HitRes = ACF_CalcDamage(Target, Energy, FrArea, 0)
			Damage = HitRes.Damage * 30
		end
	else --Just in case we hit something not standard
		Target.ACF.Armour = Size * 0.2 * 0.02
		HitRes = ACF_CalcDamage(Target, Energy, FrArea, 0)
		Damage = HitRes.Damage * 10
	end

	--if Ammo == true then
	--	Entity.KilledByAmmo = true
	--end
	Entity:TakeDamage(Damage, Inflictor, Gun)
	--if Ammo == true then
	--	Entity.KilledByAmmo = false
	--end
	HitRes.Kill = false
	--print(Damage)
	--print(Bone)

	return HitRes
end

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

function ACF_GetAncestor(Ent)
	if not IsValid(Ent) then return nil end

	local Parent = Ent

	while IsValid(Parent:GetParent()) do
		Parent = Parent:GetParent()
	end

	Ent.acfphysparent = Parent

	return Parent
end

function ACF_GetAllPhysicalEntities(Ent, Tab)
	if not IsValid(Ent) then return end

	local Res = Tab or {}

	if Res[Ent] then
		return
	else
		Res[Ent] = true

		if Ent.Constraints then
			for _, V in pairs(Ent.Constraints) do
				if V.Type ~= "NoCollide" then
					ACF_GetAllPhysicalEntities(V.Ent1, Res)
					ACF_GetAllPhysicalEntities(V.Ent2, Res)
				end
			end
		end
	end

	return Res
end

function ACF_GetAllChildren(Ent, Tab)
	if not IsValid(Ent) then return end

	local Res = Tab or {}

	for K in pairs(Ent:GetChildren()) do
		Res[K] = true
		ACF_GetAllChildren(K, Res)
	end

	return Res
end

function ACF_GetEnts(Ent)
	local Ancestor = ACF_GetAncestor(Ent)
	local Phys = ACF_GetAllPhysicalEntities(Ancestor)
	local Pare = ACF_GetAllChildren(Ancestor)

	for K in pairs(Phys) do
		for P in pairs(ACF_GetAllChildren(K)) do
			Pare[P] = true
		end
	end

	return Phys, Pare
end