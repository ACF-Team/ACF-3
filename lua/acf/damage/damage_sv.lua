local ACF     = ACF
local Damage  = ACF.Damage
local Objects = Damage.Objects
local Effects = ACF.Utilities.Effects
local Queue   = {}

util.AddNetworkString("ACF_Damage")

local function SendQueue(Target)
	for Entity, Percent in pairs(Queue) do
		timer.Simple(0, function()
			if not IsValid(Entity) then return end

			net.Start("ACF_Damage")
			net.WriteUInt(Entity:EntIndex(), 13)
			net.WriteUInt(Percent * 100, 7)

			if isentity(Target) and IsValid(Target) then
				net.Send(Target)
			else
				net.Broadcast()
			end
		end)

		Queue[Entity] = nil
	end
end

--- Helper function used to efficiently network visual damage updates on props.
--- @param Entity entity The entity to update damage on.
--- @param Target? entity The specific player to send the update to; leave this empty to send to all players.
--- @param NewHealth? number The entity's new amount of health.
--- @param MaxHealth? number The entity's maximum amount of health.
function Damage.Network(Entity, Target, NewHealth, MaxHealth)
	NewHealth = NewHealth or Entity.ACF.NewHealth or 0
	MaxHealth = MaxHealth or Entity.ACF.MaxHealth or 0

	local Value = math.Round(NewHealth / MaxHealth, 2)

	if Value == 0 then return end
	if Value ~= Value then return end

	if not next(Queue) then
		timer.Create("ACF_DamageQueue", 0, 1, function()
			SendQueue(Target)
		end)
	end

	Queue[Entity] = Value
end

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

--- Used to kill and fling the player because it's funny.
--- @param Entity entity The entity to attempt to kill
--- @param Damage number The amount of damage to be dealt to the entity
--- @param HitPos vector The world position to display blood effects at
--- @param Attacker entity The entity that dealt the damage
--- @param Inflictor entity The entity that was used to deal the damage
--- @param Direction vector The normalized direction that the damage is pointing towards
--- @param Explosive boolean Whether this damage should be explosive or not
--- @return boolean # Returns true if the damage has killed the player, false if it has not
function Damage.DoSquishyFlingKill(Entity, Damage, HitPos, Attacker, Inflictor, Direction, Explosive)
	if not Entity:IsPlayer() and not Entity:IsNPC() and not Entity:IsNextBot() then return false end

	local Health = Entity:Health()

	if Damage > Health then
		local SourceDamage = DamageInfo()
		local ForceMult = 25000 -- Arbitrary force multiplier; just change this to whatever feels the best

		SourceDamage:SetAttacker(Attacker)
		SourceDamage:SetInflictor(Inflictor)
		SourceDamage:SetDamage(Damage)
		SourceDamage:SetDamageForce(Direction * ForceMult)
		SourceDamage:SetDamageType(Explosive and DMG_BLAST or DMG_BULLET)

		Entity:TakeDamageInfo(SourceDamage)

		local EffectTable = {
			Origin = HitPos,
			Normal = Direction,
			Flags = 3,
			Scale = 14,
		}

		Effects.CreateEffect("bloodspray", EffectTable, true, true)
		Effects.CreateEffect("BloodImpact", EffectTable, true, true)

		return true
	end

	return false
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
		DmgResult:SetThickness(Size * 0.1)

		HitRes = DmgResult:Compute()
		Damage = HitRes.Damage * 15
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
			DmgResult:SetThickness(Size * 0.1)

			HitRes = DmgResult:Compute()
			Damage = HitRes.Damage * 15
		end
	end

	local Attacker, Inflictor = DmgInfo:GetAttacker(), DmgInfo:GetInflictor()
	local Direction = (DmgInfo.HitPos - DmgInfo.Origin):GetNormalized()
	Damage = Damage * ACF.SquishyDamageMult

	if not ACF.Damage.DoSquishyFlingKill(Entity, Damage, DmgInfo.HitPos, Attacker, Inflictor, Direction, DmgInfo.Type == DMG_BLAST) then
		Entity:TakeDamage(Damage, Attacker, Inflictor)
	end

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
	local Driver	= Entity:GetDriver()

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
	local EntACF = Entity.ACF
	local Health = EntACF.Health
	local HitRes = DmgResult:Compute()

	if HitRes.Damage >= Health then
		if Entity.ACF_KillableButIndestructible then
			HitRes.Kill = false
			Entity.ACF.Health = 0
		else
			HitRes.Kill = true
		end
	else
		local NewHealth = Health - HitRes.Damage
		local MaxHealth = EntACF.MaxHealth

		EntACF.Health = NewHealth
		EntACF.Armour = EntACF.MaxArmour * (0.5 + NewHealth / MaxHealth * 0.5) -- Simulating the plate weakening after a hit

		Damage.Network(Entity, nil, NewHealth, MaxHealth)
	end

	if Entity.ACF_HealthUpdatesWireOverlay then
		Entity:UpdateOverlay()
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
	for _, Entity in ents.Iterator() do
		local Data = Entity.ACF

		if not Data or Data.Health == Data.MaxHealth then continue end

		Damage.Network(Entity, Player)
	end
end)
