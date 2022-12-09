local ACF     = ACF
local Damage  = ACF.Damage
local Objects = Damage.Objects
local Network = ACF.Networking

--- Returns the penetration of a blast.
-- @param Energy The energy of the blast in KJ.
-- @param Area The area of the blast in cm2.
-- @return The penetration of the blast in RHA mm.
function Damage.getBlastPenetration(Energy, Area)
	return Energy / Area * 0.25 -- NOTE: 0.25 is what ACF.KEtoRHA used to be set at.
end

--- Helper function used to generate DamageResult and DamageInfo objects from projectile information.
-- @param Bullet A bullet object.
-- @param Trace The result table of a trace.
-- @return A properly formatted DamageResult object.
-- @return A properly formatted DamageInfo object.
function Damage.getBulletDamage(Bullet, Trace)
	local Entity    = Trace.Entity
	local DmgResult = Objects.DamageResult()
	local DmgInfo   = Objects.DamageInfo()

	if ACF.Check(Entity) then
		local Thickness = Entity.ACF.Armour

		DmgResult:SetArea(Bullet.ProjArea)
		DmgResult:SetPenetration(Bullet:GetPenetration())
		DmgResult:SetThickness(Thickness)
		DmgResult:SetAngle(ACF.GetHitAngle(Trace, Bullet.Flight))
		DmgResult:SetFactor(Thickness / Bullet.Diameter)

		DmgInfo:SetAttacker(Bullet.Owner)
		DmgInfo:SetInflictor(Bullet.Gun)
		DmgInfo:SetType(DMG_BULLET)
		DmgInfo:SetOrigin(Bullet.Pos)
		DmgInfo:SetHitPos(Trace.HitPos)
		DmgInfo:SetHitGroup(Trace.HitGroup)
	end

	return DmgResult, DmgInfo
end
--- Used to inflict damage to any entity that was tagged as "Squishy" by ACF.Check.
-- This function will be internally used by ACF.Damage.dealDamage, you're not expected to use it.
-- @param Entity The entity that will get damaged.
-- @param DmgResult A DamageResult object.
-- @param DmgInfo A DamageInfo object.
-- @return The output of the DamageResult object.
function Damage.doSquishyDamage(Entity, DmgResult, DmgInfo)
	local Bone   = DmgInfo:GetHitGroup()
	local Size   = Entity:BoundingRadius()
	local Mass   = Entity:GetPhysicsObject():GetMass()
	local HitRes = DmgResult:GetBlank()
	local Damage = 0

	DmgResult:SetFactor(1) -- We don't care about the penetration factor on squishy targets

	if Bone then
		--This means we hit the head
		if Bone == 1 then
			--Set the skull thickness as a percentage of Squishy weight, this gives us 2mm for a player, about 22mm for an Antlion Guard. Seems about right
			DmgResult:SetThickness(Mass * 0.02)

			HitRes = DmgResult:Compute()
			Damage = HitRes.Damage * 20

			--If we manage to penetrate the skull, then MASSIVE DAMAGE
			if HitRes.Overkill > 0 then
				--A quarter the bounding radius seems about right for most critters head size
				DmgResult:SetThickness(Size * 0.25 * 0.01)

				HitRes = DmgResult:Compute()
				Damage = Damage + HitRes.Damage * 100
			end

			-- Then to check if we can get out of the other side, 2x skull + 1x brains
			DmgResult:SetThickness(Mass * 0.065)

			HitRes = DmgResult:Compute()
			Damage = Damage + HitRes.Damage * 20
		elseif Bone == 0 or Bone == 2 or Bone == 3 then
			-- This means we hit the torso. We are assuming body armour/tough exoskeleton/zombie don't give fuck here, so it's tough
			-- Set the armour thickness as a percentage of Squishy weight, this gives us 8mm for a player, about 90mm for an Antlion Guard. Seems about right
			DmgResult:SetThickness(Mass * 0.08)

			HitRes = DmgResult:Compute()
			Damage = HitRes.Damage * 5

			if HitRes.Overkill > 0 then
				-- Half the bounding radius seems about right for most critters torso size
				DmgResult:SetThickness(Size * 0.5 * 0.02)

				HitRes = DmgResult:Compute()
				Damage = Damage + HitRes.Damage * 50 -- If we penetrate the armour then we get into the important bits inside, so DAMAGE
			end

			--Then to check if we can get out of the other side, 2x armour + 1x guts
			DmgResult:SetThickness(Mass * 0.185)

			HitRes = DmgResult:Compute()
		elseif Bone == 10 then
			-- This means we hit a backpack or something
			-- Arbitrary size, most of the gear carried is pretty small
			DmgResult:SetThickness(Size * 0.1 * 0.02)

			HitRes = DmgResult:Compute()
			Damage = HitRes.Damage * 2 -- Damage is going to be fright and shrapnel, nothing much
		else
			--Just in case we hit something not standard
			DmgResult:SetThickness(Size * 0.2 * 0.02)

			HitRes = DmgResult:Compute()
			Damage = HitRes.Damage * 30
		end
	else
		-- Just in case we hit something not standard
		DmgResult:SetThickness(Size * 0.2 * 0.02)

		HitRes = DmgResult:Compute()
		Damage = HitRes.Damage * 10
	end

	Entity:TakeDamage(Damage, DmgInfo:GetAttacker(), DmgInfo:GetInflictor())

	HitRes.Kill = false

	return HitRes
end

--- Used to inflict damage to any entity that was tagged as "Vehicle" by ACF.Check.
-- This function will be internally used by ACF.Damage.dealDamage, you're not expected to use it.
-- @param Entity The entity that will get damaged.
-- @param DmgResult A DamageResult object.
-- @param DmgInfo A DamageInfo object.
-- @return The output of the DamageResult object.
function Damage.doVehicleDamage(Entity, DmgResult, DmgInfo)
	local Driver = Entity:GetDriver()

	if IsValid(Driver) then
		DmgInfo:SetHitGroup(math.random(0, 7)) -- Hit a random part of the driver

		Damage.dealDamage(Driver, DmgResult, DmgInfo) -- Deal direct damage to the driver
	end

	return Damage.doPropDamage(Entity, DmgResult, DmgInfo) -- We'll just damage it like a regular prop
end

--- Used to inflict damage to any entity that was tagged as "Prop" by ACF.Check.
-- This function will be internally used by ACF.Damage.dealDamage, you're not expected to use it.
-- @param Entity The entity that will get damaged.
-- @param DmgResult A DamageResult object.
-- @param DmgInfo A DamageInfo object.
-- @return The output of the DamageResult object.
function Damage.doPropDamage(Entity, DmgResult)
	local Health = Entity.ACF.Health
	local HitRes = DmgResult:Compute()

	if HitRes.Damage >= Health then
		HitRes.Kill = true
	else
		local NewHealth = Health - HitRes.Damage

		Entity.ACF.Health = NewHealth
		Entity.ACF.Armour = Entity.ACF.MaxArmour * (0.5 + NewHealth / Entity.ACF.MaxHealth * 0.5) -- Simulating the plate weakening after a hit

		Network.Broadcast("ACF_Damage", Entity)
	end

	return HitRes
end

--- Used to inflict damage to entities recognized by ACF.
-- @param Entity The entity that will get damaged.
-- @param DmgResult A DamageResult object.
-- @param DmgInfo A DamageInfo object.
-- @return A table containing the damage done to the entity.
-- Most of the time, this table will be the output of the DamageResult object.
function Damage.dealDamage(Entity, DmgResult, DmgInfo)
	local Type   = ACF.Check(Entity)
	local HitRes = DmgResult:GetBlank()

	if not Type then return HitRes end

	local HookResult = hook.Run("ACF_PreDamageEntity", Entity, DmgResult, DmgInfo)

	if HookResult == false then return HitRes end

	if Entity.ACF_PreDamage then
		local MethodResult = Entity:ACF_PreDamage(DmgResult, DmgInfo)

		if MethodResult == false then return HitRes end
	end

	hook.Run("ACF_OnDamageEntity", Entity, DmgResult, DmgInfo)

	if Entity.ACF_OnDamage then
		HitRes = Entity:ACF_OnDamage(DmgResult, DmgInfo)
	elseif Type == "Prop" then
		HitRes = Damage.doPropDamage(Entity, DmgResult, DmgInfo)
	elseif Type == "Vehicle" then
		HitRes = Damage.doVehicleDamage(Entity, DmgResult, DmgInfo)
	elseif Type == "Squishy" then
		HitRes = Damage.doSquishyDamage(Entity, DmgResult, DmgInfo)
	end

	hook.Run("ACF_PostDamageEntity", Entity, DmgResult, DmgInfo)

	if Entity.ACF_PostDamage then
		Entity:ACF_PostDamage(DmgResult, DmgInfo)
	end

	return HitRes or DmgResult:GetBlank()
end

hook.Add("ACF_OnPlayerLoaded", "ACF Render Damage", function(Player)
	for _, Entity in ipairs(ents.GetAll()) do
		local Data = Entity.ACF

		if not Data or Data.Health == Data.MaxHealth then continue end

		Network.Send("ACF_Damage", Player, Entity)
	end
end)

Network.CreateSender("ACF_Damage", function(Queue, Entity)
	local Value = math.Round(Entity.ACF.Health / Entity.ACF.MaxHealth, 2)

	if Value == 0 then return end
	if Value ~= Value then return end

	Queue[Entity:EntIndex()] = Value
end)
