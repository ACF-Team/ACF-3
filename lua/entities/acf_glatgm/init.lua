AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local hook       = hook
local ACF        = ACF
local Missiles   = ACF.ActiveMissiles
local Ballistics = ACF.Ballistics
local Damage     = ACF.Damage
local Clock      = ACF.Utilities.Clock
local TraceData  = { start = true, endpos = true, filter = true }
local ZERO       = Vector()

local function CheckViewCone(Missile, HitPos)
	local Position = Missile.ACF_Position
	local Forward  = Missile.ACF_Velocity:GetNormalized()
	local Direction = (HitPos - Position):GetNormalized()

	return Direction:Dot(Forward) >= Missile.ViewCone
end

local function ClampAngle(Object, Limit)
	local Pitch, Yaw, Roll = Object:Unpack()

	return Angle(
		math.Clamp(Pitch, -Limit, Limit),
		math.Clamp(Yaw, -Limit, Limit),
		math.Clamp(Roll, -Limit, Limit)
	)
end

local function DetonateMissile(Missile, Inflictor)
	local CanExplode = hook.Run("ACF_PreExplodeMissile", Missile, Missile.BulletData)

	if not CanExplode then return end

	if IsValid(Inflictor) and Inflictor:IsPlayer() then
		Missile.Inflictor = Inflictor
	end

	Missile:Detonate()
end

function ACF.MakeGLATGM(Player, Gun, BulletData)
	local CanSpawn = hook.Run("ACF_PreSpawnEntity", "acf_glatgm", Player, BulletData, Gun)
	if CanSpawn == false then return false end

	local Entity = ents.Create("acf_glatgm")
	if not IsValid(Entity) then return end

	local Velocity = math.Clamp(BulletData.MuzzleVel / ACF.Scale, 200, 1600)
	local Caliber  = BulletData.Caliber * 10

	Entity:SetAngles(Gun:GetAngles())
	Entity:SetPos(BulletData.Pos)
	Entity:CPPISetOwner(Player)
	Entity:SetPlayer(Player)
	Entity:Spawn()

	if Caliber >= 140 then
		Entity:SetModel("models/missiles/glatgm/mgm51.mdl")
		Entity:SetModelScale(Caliber / 150, 0)
	elseif Caliber >= 120 then
		Entity:SetModel("models/missiles/glatgm/9m112.mdl")
		Entity:SetModelScale(Caliber / 125, 0)
	else
		Entity:SetModel("models/missiles/glatgm/9m117.mdl")
		Entity:SetModelScale(Caliber * 0.01, 0)
	end

	Entity:PhysicsInit(SOLID_VPHYSICS)
	Entity:SetMoveType(MOVETYPE_VPHYSICS)

	ParticleEffectAttach("Rocket Motor GLATGM", 4, Entity, 1)

	Entity.Owner        = Player
	Entity.Name         = Caliber .. "mm Gun Launched Missile"
	Entity.ShortName    = Caliber .. "mmGLATGM"
	Entity.EntType      = "Gun Launched Anti-Tank Guided Missile"
	Entity.Caliber      = Caliber
	Entity.Weapon       = Gun
	Entity.BulletData   = table.Copy(BulletData)
	Entity.ForcedArmor  = 5 -- All missiles should get 5mm
	Entity.ForcedMass   = BulletData.CartMass
	Entity.UseGuidance  = true
	Entity.ViewCone     = math.cos(math.rad(50)) -- Number inside is on degrees
	Entity.KillTime     = Clock.CurTime + 20
	Entity.GuideDelay   = Clock.CurTime + 0.25 -- Missile won't be guided for the first quarter of a second
	Entity.LastThink    = Clock.CurTime
	Entity.Filter       = Entity.BulletData.Filter
	Entity.Agility      = 50 -- Magic multiplier that controls the agility of the missile
	Entity.IsSubcaliber = Caliber < 100
	Entity.LaunchVel    = math.Round(Velocity * 0.2, 2) * ACF.MeterToInch
	Entity.DiffVel      = math.Round(Velocity * 0.5, 2) * ACF.MeterToInch - Entity.LaunchVel
	Entity.AccelLength  = math.Round(math.Clamp(BulletData.ProjMass / BulletData.PropMass + BulletData.Caliber / 7, 0.2, 10), 2)
	Entity.AccelTime    = Entity.LastThink + Entity.AccelLength
	Entity.Speed        = Entity.LaunchVel
	Entity.SpiralRadius = Entity.IsSubcaliber and 120 / Caliber or nil
	Entity.SpiralSpeed  = Entity.IsSubcaliber and 360 / Entity.AccelLength or nil
	Entity.SpiralAngle  = Entity.IsSubcaliber and 0 or nil
	Entity.ACF_Position = BulletData.Pos
	Entity.ACF_Velocity = BulletData.Flight:GetNormalized() * Entity.LaunchVel
	Entity.Inaccuracy   = 0

	Entity.Filter[#Entity.Filter + 1] = Entity

	local PhysObj = Entity:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:EnableGravity(false)
		PhysObj:EnableMotion(false)
		PhysObj:SetMass(Entity.ForcedMass)
	end

	ACF.Activate(Entity)

	Missiles[Entity] = true

	hook.Run("ACF_OnSpawnEntity", Entity, BulletData, Gun)
	hook.Run("ACF_OnLaunchMissile", Entity)

	return Entity
end

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	if self.Detonated then
		return {
			Damage = 0,
			Loss = 0,
			Kill = false
		}
	end

	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo) -- Calling the standard prop damage function
	local Owner  = DmgInfo:GetAttacker()

	-- If the missile was destroyed, then we detonate it.
	if HitRes.Kill then
		DetonateMissile(self, Owner)

		return HitRes
	elseif HitRes then
		local Ratio = self.ACF.Health / self.ACF.MaxHealth
		local BulletData = self.BulletData

		-- We give it a chance to explode when it gets penetrated aswell.
		if math.random() > 0.55 * Ratio then
			if BulletData.Type == "GLATGM" then
			BulletData.Type = "HE"

			self:SetNW2String("AmmoType", "HE")
			end
			DetonateMissile(self, Owner)

			return HitRes
		end

		-- Turning off the missile's guidance.
		if self.UseGuidance and math.random() > 0.2 * Ratio then
			self.UseGuidance = nil
		end

		-- Any Damage to the liner.
		-- For sake of consistency and reducing of RNG on damage
		if BulletData.Type == "GLATGM" and 0.95 > Ratio then
			BulletData.Type = "HE"

			self:SetNW2String("AmmoType", "HE")
		end
	end

	return HitRes -- This function needs to return HitRes
end

function ENT:GetComputer()
	if not self.UseGuidance then return end

	local Weapon = self.Weapon

	if not IsValid(Weapon) then return end

	local Computer = Weapon.Computer

	if not IsValid(Computer) then return end
	if Computer.Disabled then return end
	if not Computer.IsComputer then return end
	if Computer.HitPos == ZERO then return end

	return Computer
end

function ENT:Think()
	if self.Detonated then return end

	local Time = Clock.CurTime

	if Time >= self.KillTime then
		return self:Detonate()
	end

	local DeltaTime = Time - self.LastThink
	local CanGuide  = self.GuideDelay <= Time
	local Computer  = self:GetComputer()
	local CanSee    = IsValid(Computer) and CheckViewCone(self, Computer.HitPos)
	local Position  = self.ACF_Position
	local NextDir, NextAng

	self.Speed = self.LaunchVel + self.DiffVel * math.Clamp(1 - (self.AccelTime - Time) / self.AccelLength, 0, 1)

	if CanGuide and CanSee then
		local Origin      = Computer:LocalToWorld(Computer.Offset)
		local Distance    = Origin:Distance(Position) + self.Speed * 0.15
		local Target      = Origin + Computer.TraceDir * Distance
		local Expected    = (Target - Position):GetNormalized():Angle()
		local Current     = self.ACF_Velocity:GetNormalized():Angle()
		local _, LocalAng = WorldToLocal(Target, Expected, Position, Current)
		local Clamped     = ClampAngle(LocalAng, self.Agility * DeltaTime)
		local _, WorldAng = LocalToWorld(Vector(), Clamped, Position, Current)

		NextAng = WorldAng
		NextDir = WorldAng:Forward()

		self.Inaccuracy = 0
	else
		local Spread = self.Inaccuracy * DeltaTime * 0.005
		local Added  = VectorRand() * Spread

		NextDir = (self.ACF_Velocity:GetNormalized() + Added):GetNormalized()
		NextAng = NextDir:Angle()

		self.Inaccuracy = self.Inaccuracy + DeltaTime * 50
	end

	if self.IsSubcaliber then
		local Current = self.SpiralAngle
		local SpiralRad = self.SpiralRadius
		NextAng:RotateAroundAxis(NextAng:Forward(), Current)

		local Offset = NextDir * self.Speed * DeltaTime + NextAng:Up() * math.sin(Current) * SpiralRad + NextAng:Right() * math.cos(Current) * SpiralRad

		NextDir = (Offset - NextDir):GetNormalized()

		self.SpiralAngle = (Current + self.SpiralSpeed * DeltaTime) % 360
	end


	self.ACF_Position = self.ACF_Position + NextDir * self.Speed * DeltaTime
	self.ACF_Velocity = (self.ACF_Position - Position) / DeltaTime

	TraceData.start  = Position
	TraceData.endpos = self.ACF_Position
	TraceData.filter = self.Filter

	local Result = ACF.trace(TraceData)

	if Result.Hit then
		self.ACF_Position = Result.HitPos

		return self:Detonate()
	end

	self:SetPos(self.ACF_Position)
	self:SetAngles(NextAng)
	self:NextThink(Time)

	self.LastThink = Time

	return true
end

function ENT:Detonate()
	if self.Detonated then return end

	local BulletData = self.BulletData
	local Position   = self.ACF_Position

	BulletData.Filter = self.Filter
	BulletData.Flight = self.ACF_Velocity:GetNormalized() * self.Speed
	BulletData.Pos    = Position
	BulletData.DetonatorAngle = 91

	self.Detonated = true

	local Bullet = Ballistics.CreateBullet(BulletData)

	if BulletData.Type ~= "GLATGM" then
		ACF.DoReplicatedPropHit(self, Bullet)
	end

	self:Remove()
end

function ENT:OnRemove()
	Missiles[self] = nil

	WireLib.Remove(self)
end

function ENT:CFW_OnParented(Entity)
	Entity:SetParent()
end