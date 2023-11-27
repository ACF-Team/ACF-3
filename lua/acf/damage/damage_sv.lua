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
	local Hitbox = ACF.GetBestSquishyHitBox(Entity, DmgInfo:GetHitPos(), (DmgInfo:GetHitPos() - DmgInfo:GetOrigin()):GetNormalized())
	local Size   = Entity:BoundingRadius()
	local HitRes = DmgResult:GetBlank()
	local Damage = 0

	DmgResult:SetFactor(1) -- We don't care about the penetration factor on squishy targets

	if Hitbox == "none" then -- Default damage
		DmgResult:SetThickness(Size * 0.2 * 0.02)

		HitRes = DmgResult:Compute()
		Damage = HitRes.Damage * 20
	else
		-- Using player armor for fake armor works decently, as even if you don't take actual damage, the armor takes 1 point of damage, so it can potentially wear off
		-- These funcs are also done on a hierarchy sort of system, so if the helmet is penetrated, then DamageHead is called, same for Vest -> Chest
		if Hitbox == "helmet" then
			Damage, HitRes = ACF.SquishyFuncs.DamageHelmet(Entity, HitRes, DmgResult)
		elseif Hitbox == "head" then
			Damage, HitRes = ACF.SquishyFuncs.DamageHead(Entity, HitRes, DmgResult)
		elseif Hitbox == "vest" then
			Damage, HitRes = ACF.SquishyFuncs.DamageVest(Entity, HitRes, DmgResult)
		elseif Hitbox == "chest" then
			Damage, HitRes = ACF.SquishyFuncs.DamageChest(Entity, HitRes, DmgResult)
		else
			DmgResult:SetThickness(Size * 0.2 * 0.02)

			HitRes = DmgResult:Compute()
			Damage = HitRes.Damage * 10
		end
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
