local ACF       = ACF
local Damage    = ACF.Damage
local Objects   = Damage.Objects
local Effects   = ACF.Utilities.Effects
local DamageCoef = ACF.DamageCoef
local Queue = {} -- Queue[Entity] = { [ConvexID] = Step }; always broadcast
local QueueTime = 0.5 -- Seconds to buffer damage updates before sending

util.AddNetworkString("ACF_Damage")

-- Writes a { {Entity, Convexes}, ... } batch in the wire format shared by SendQueue and the full-sync hook.
local function WriteBatch(Batch)
	net.WriteUInt(#Batch, 8)

	for i = 1, #Batch do
		local Entity, Convexes = Batch[i][1], Batch[i][2]

		net.WriteUInt(Entity:EntIndex(), 13)
		net.WriteUInt(table.Count(Convexes), 8)

		for ConvexID, Step in pairs(Convexes) do
			net.WriteUInt(ConvexID, 9)
			net.WriteUInt(Step, 4)
		end
	end
end

local function SendQueue()
	local Batch = {}

	-- Validate the entities in the queue still exist
	for Entity, Convexes in pairs(Queue) do
		if IsValid(Entity) then
			Batch[#Batch + 1] = {Entity, Convexes}
		end
	end

	Queue = {}

	if #Batch == 0 then return end -- Nothing to send - Anything that was in the queue became invalid

	net.Start("ACF_Damage")
	WriteBatch(Batch)
	net.Broadcast()
end

--- Helper function used to efficiently network visual damage updates on individual convexes.
--- Updates are quantized to 10% health steps to reduce network traffic (you can't really tell the difference with smaller steps anyway)
--- @param Entity entity The entity owning the convex.
--- @param ConvexID number The convex's index into the entity's volumetric mesh.
function Damage.NetworkConvex(Entity, ConvexID)
	local MeshData = Entity.ACF_Volumetric_Mesh
	local Convex    = MeshData and MeshData.Convexes[ConvexID]

	if not Convex then return end
	if Convex.MaxHealth == 0 then return end

	local Value = Convex.Health / Convex.MaxHealth
	local Step  = math.Round(Value * 10) -- Integer 0-10, snapped to nearest 10% boundary

	if Step == 10 and not Convex.LastDamageStep then return end -- Never visually damaged; nothing changed, nothing to send
	if Convex.LastDamageStep == Step then return end

	Convex.LastDamageStep = Step

	if not next(Queue) then
		timer.Create("ACF_DamageQueue", QueueTime, 1, SendQueue)
	end

	local Convexes = Queue[Entity]
	if not Convexes then
		Convexes = {}
		Queue[Entity] = Convexes
	end

	Convexes[ConvexID] = Step
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
		local NormDir    = Bullet.Flight:GetNormalized()
		local AmmoType   = ACF.Classes.AmmoTypes.Get(Bullet.Type)
		local MulField   = (AmmoType and AmmoType.IsChemical) and "ChemicalMul" or "KineticMul"

		-- The ballistics layer resolves the impact to a single convex (Bullet.ConvexHit) so each convex
		-- is damaged as its own event. Older/meshless callers (blasts) fall back to summing every live convex.
		local ConvexHit  = Bullet.ConvexHit
		local ConvexHits = ConvexHit and { ConvexHit } or ACF.GetConvexHits(Entity, Trace.HitPos, NormDir)

		local Penetration = Bullet:GetPenetration()
		local Thickness, Angle
		local HitPos = Trace.HitPos
		if #ConvexHits > 0 then
			Thickness = 0

			-- Penetration is spent sequentially as the round traverses each convex in hit order. Each convex
			-- removes only the channel it was actually bored through, so a round that stalls partway (or never
			-- penetrates) carves a shorter tunnel instead of always assuming a full-thickness penetration.
			local Budget = Penetration
			local Hits   = {}
			for _, Hit in ipairs(ConvexHits) do
				local Effective = Hit.GeoThick * Hit.ArmorType[MulField] -- Effective armor (RHA mm) this convex presents along the path
				local Consumed  = math.min(Effective, Budget) -- Effective armor actually defeated before the round stalls
				local Frac      = Effective > 0 and (Consumed / Effective) or 0 -- Fraction of this convex's geometric thickness traversed

				Thickness = Thickness + Effective
				Budget    = Budget - Consumed
				Hits[#Hits + 1] = { ConvexID = Hit.ConvexID, Volume = Hit.GeoThick * Frac * 0.1 * Bullet.ProjArea / ACF.InchToCmCu } -- (mm)(mm to cm)(cm^2) = cm^3, then cm^3 to in^3
			end

			Angle = 0 -- GeoThick already accounts for obliquity
			DmgInfo:SetConvexHits(Hits)

			if ConvexHit then HitPos = ConvexHit.EntryPos end -- Land effects/decals on the struck convex's face
		else
			Thickness = 0
			Angle     = ACF.GetHitAngle(Trace, Bullet.Flight)
		end

		DmgResult:SetArea(Bullet.ProjArea)
		DmgResult:SetPenetration(Penetration)
		DmgResult:SetThickness(Thickness)
		DmgResult:SetAngle(Angle)
		DmgResult:SetFactor(Thickness / Bullet.Diameter)

		DmgInfo:SetAttacker(Bullet.Owner)
		DmgInfo:SetInflictor(Bullet.Gun)
		DmgInfo:SetType(DMG_BULLET)
		DmgInfo:SetOrigin(Bullet.Pos)
		DmgInfo:SetHitPos(HitPos)
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

		SourceDamage:SetAttacker(IsValid(Attacker) and Attacker or game.GetWorld())
		SourceDamage:SetInflictor(IsValid(Inflictor) and Inflictor or game.GetWorld())
		SourceDamage:SetDamage(Damage)
		SourceDamage:SetDamageForce(Direction * ForceMult)
		SourceDamage:SetDamageType(Explosive and DMG_BLAST or DMG_BULLET)
		SourceDamage:SetDamagePosition(HitPos)

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
function Damage.doPropDamage(Entity, DmgResult, DmgInfo)
	local HitRes = DmgResult:Compute()
	HitRes.Damage = HitRes.Damage * DamageCoef -- Erroneous :(
	HitRes.Kill = false

	-- Mark contraption as in combat when taking damage
	local Contraption = Entity:CFW_GetContraption()
	if Contraption then
		Contraption.InCombat = engine.TickCount()
	end

	local MeshData   = Entity.ACF_Volumetric_Mesh
	local ConvexHits = DmgInfo and DmgInfo:GetConvexHits()

	if MeshData and ConvexHits then
		if Entity.IsACFEntity then
			-- ACF entities defer convex damage to the entity's total health rather than depleting the convexes themselves.
			-- In the future, this should be replaced with a per convex damage system. This is for some backwards compatibility.
			local EntACF    = Entity.ACF
			local TotalLoss = 0

			for _, Hit in ipairs(ConvexHits) do
				local Convex = MeshData.Convexes[Hit.ConvexID]
				TotalLoss    = TotalLoss + (Hit.Volume / Convex.Volume) * DamageCoef
			end

			EntACF.Health = math.max(0, EntACF.Health - TotalLoss)
		else
			for _, Hit in ipairs(ConvexHits) do
				local Convex     = MeshData.Convexes[Hit.ConvexID]
				local HealthLoss = (Hit.Volume / Convex.Volume) * DamageCoef

				Convex.Health = math.max(0, Convex.Health - HealthLoss)

				Damage.NetworkConvex(Entity, Hit.ConvexID)
			end
		end
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

hook.Add("ACF_OnLoadPlayer", "ACF Render Damage", function(Player)
	local Batch = {}

	for _, Entity in ents.Iterator() do
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then continue end

		local Convexes
		for ConvexID, Convex in ipairs(MeshData.Convexes) do
			local Step = Convex.LastDamageStep
			if not Step or Step >= 10 then continue end

			Convexes = Convexes or {}
			Convexes[ConvexID] = Step
		end

		if Convexes then
			Batch[#Batch + 1] = {Entity, Convexes}
		end
	end

	if #Batch == 0 then return end

	net.Start("ACF_Damage")
	WriteBatch(Batch)
	net.Send(Player)
end)
