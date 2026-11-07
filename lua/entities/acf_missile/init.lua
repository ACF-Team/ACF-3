AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-------------------------------[[ Local Functions ]]-------------------------------

local ACF          = ACF
local Missiles     = ACF.Missiles
local Ballistics   = ACF.Ballistics
local Clock        = ACF.Utilities.Clock
local Damage       = ACF.Damage
local Debug        = ACF.Debug
local InputActions = ACF.GetInputActions("acf_missile")
local hook         = hook

local function ApplyBodySubgroup(Missile, Group, Source, Phase)
	local Target = Source.DataSource(Missile)

	if not Group.submodels then return end
	if not Target then return end
	if not Source[Target] then return end
	if not Source[Target][Phase] then return end

	Target = Source[Target][Phase]

	for K, V in pairs(Group.submodels) do
		if Target == V then
			Missile:SetBodygroup(Group.id, K)

			return
		end
	end
end

-- TODO: Hitting players with the Dud should hurt/kill them
local function Dud(Missile)
	local PhysObj   = Missile:GetPhysicsObject()
	local HitNormal = Missile.HitNormal
	local Velocity  = Missile.ACF_Velocity
	local CurDir    = Missile.CurDir

	if HitNormal then
		local Dot = CurDir:Dot(HitNormal)
		local NewDir = CurDir - 2 * Dot * HitNormal
		local VelMul = (0.8 + Dot * 0.7) * Velocity:Length()

		Velocity = NewDir * VelMul
	end

	if IsValid(PhysObj) then
		PhysObj:EnableGravity(true)
		PhysObj:EnableMotion(true)
		PhysObj:SetVelocity(Velocity)
	end

	timer.Simple(30, function()
		if IsValid(Missile) then
			Missile:Remove()
		end
	end)
end

local MIN_BOUNDS = -math.pow(2, 14)
local MAX_BOUNDS = math.pow(2, 14)

hook.Add("CanDrive", "acf_missile_CanDrive", function(_, Entity)
	if Missiles.IsActive(Entity) then return false end
end)

ACF.AddInputAction("acf_missile", "Detonate", function(Entity, Value)
	if not Entity.Launched then return end

	if Value ~= 0 then
		local BulletData = Entity.BulletData
		if BulletData.AmmoType == "ACF.Ammunition.HEAT" then
			BulletData.AmmoType = "ACF.Ammunition.HE"
			Entity:SetNW2String("AmmoType", "ACF.Ammunition.HE")
		end
		Entity:Detonate(true)
	end
end)

-------------------------------[[ Global Functions ]]-------------------------------

function ENT:GetSpec()
	return self.Spec
end

--- Where command guidance steers from: the launcher's origin, or where the missile was launched.
function ENT:GetLaunchOrigin()
	return Missiles.GetLaunchOrigin(self)
end

--- The entity the missile was fired from (e.g. its rack), whose linked computer/radar guidance uses. Nil without one.
function ENT:GetLauncherEntity()
	return Missiles.GetLauncherEntity(self)
end

--- Worth one round from its source crate, charged here so ground reloads aren't free.
function ENT:GetCost()
	local selftbl = self:GetTable()
	local Ammo    = selftbl.RoundData

	if not Ammo then return 0 end -- BulletData isn't built yet

	local Cost = Ammo:GetCost(selftbl.BulletData)

	if selftbl.GuidanceData then
		Cost = Cost + selftbl.GuidanceData:GetCost()
	end

	if selftbl.FuzeData then
		Cost = Cost + selftbl.FuzeData:GetCost()
	end

	return Cost * 1.2
end

function ENT:UpdateModel(Model)
	self:SetModel(Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

function ENT:UpdateBodygroups(Phase)
	local Sources = self.Bodygroups

	if not Sources then return end

	for _, V in pairs(self:GetBodyGroups()) do
		local Source = Sources[string.lower(V.name)]

		if Source then
			ApplyBodySubgroup(self, V, Source, Phase)
		end
	end
end

function ENT:UpdateSkin()
	local BulletData = self.BulletData
	local Skins = self.SkinIndex

	if not BulletData then return end
	if not Skins then return end

	self:SetSkin(Skins[BulletData.AmmoType] or 0)
end

function ENT:DoFlight(ToPos, ToDir)
	local NewPos = ToPos or self.ACF_Position
	local NewDir = ToDir or self.CurDir

	-- Destroy the missile if it is out of bounds. Allow OOB upward, though.
	do
		local X, Y, Z = NewPos:Unpack()
		if X < MIN_BOUNDS or X > MAX_BOUNDS or Y < MIN_BOUNDS or Y > MAX_BOUNDS or Z < MIN_BOUNDS then
			self:Remove()
			return
		end
	end

	self:SetPos(NewPos)
	self:SetAngles(NewDir:Angle())

	self.BulletData.Pos = NewPos
end

function ENT:TriggerInput(Name, Value)
	local Action = InputActions[Name]

	if Action then
		Action(self, Value)
	end
end

function ENT:Detonate(Destroyed)
	if self.Detonated then return end

	local PhysObj = self:GetPhysicsObject()
	local BulletData = self.BulletData
	local Fuze = self.FuzeData
	self:SetNotSolid(true)
	self:SetNoDraw(true)

	self.Detonated = true

	Missiles.SetMotorState(self, false)

	ACF.ActiveMissiles[self] = nil

	if not Destroyed then
		self.Disabled = self.Disabled or self.FuzeData and not self.FuzeData:IsArmed()

		if self.Disabled then
			return Dud(self)
		end
	end

	BulletData.Pos = BulletData.Pos or   self:GetPos()
	BulletData.Flight = self.ACF_Velocity or Vector(0, 0, 0)

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
	end

	timer.Simple(1, function()
		if not IsValid(self) then return end

		self:Remove()
	end)

	if Fuze.HandleDetonation then
		return Fuze:HandleDetonation(self, BulletData)
	end

	if BulletData.Pos and Debug.SetDeveloperLevel(1) then
		Debug.SetTarget(self:CPPIGetOwner())
		Debug.Line(BulletData.Pos, BulletData.Pos + BulletData.Flight, 10, Color(255, 128, 0))
	end

	BulletData.DetonatorAngle = 91

	local Bullet = Ballistics.CreateBullet(BulletData)

	if BulletData.AmmoType ~= "ACF.Ammunition.HEAT" then
		ACF.DoReplicatedPropHit(self, Bullet)
	end
end

function ENT:Think()
	self:NextThink(Clock.CurTime + self.ThinkDelay)

	Missiles.CalcFlight(self)

	return true
end

local Properties = { bodygroups = true, skin = true }

function ENT:CanProperty(_, Property)
	if Properties[Property] then return false end

	return true
end

function ENT:OnRemove()
	if self.GuidanceData then
		self.GuidanceData:OnRemoved(self)
	end

	Missiles.OnRemoved(self)

	WireLib.Remove(self)
end

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	if self.Detonated or self.NoDamage then
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
		local BulletData = self.BulletData

		if BulletData.AmmoType == "ACF.Ammunition.HEAT" then
			BulletData.AmmoType = "ACF.Ammunition.HE"

			self:SetNW2String("AmmoType", "ACF.Ammunition.HE")
		end
		Missiles.Detonate(self, Owner)

		return HitRes
	elseif HitRes then
		--If the missile is still on a rack it will be ignored
		if not self.Launched then
			return HitRes
		end

		local Ratio      = self.ACF.Health / self.ACF.MaxHealth
		local BulletData = self.BulletData

		-- The missile will be considered destroyed when it gets penetrated.
		if DmgResult.Penetration > self.ForcedArmor then
			-- New death mechanic for ASM,AAM,ARM,SAM,ARTY,FFAR
			if self.HitDeviate then
				BulletData.AmmoType = "ACF.Ammunition.HP"
				self:SetNW2String("AmmoType", "ACF.Ammunition.HP")
				self.UseGuidance = nil
				self.Broken = true -- Missile has broken up; radars shouldn't be able to detect it anymore
				local MissileAngles = self.CurDir:Angle()
				local LocalSpin  = VectorRand(-15, 15) / Ratio
				self.RotAxis = MissileAngles:Up() * LocalSpin.z + MissileAngles:Right() * LocalSpin.y + MissileAngles:Forward() * LocalSpin.x
				self.TorqueMul = 98

				timer.Simple(Ratio,
					function()
						if not IsValid(self) then
							return
						end

						self:SetNoDraw(true)
						self:SetNotSolid(true)

						local Effect = EffectData()
						Effect:SetOrigin(self:GetPos())
						Effect:SetRadius(BulletData.Caliber)
						Effect:SetScale(BulletData.FillerMass or 1)
						util.Effect("ACF_Explosion", Effect)

						local GibModel	= "models/gibs/metal_gib%s.mdl"
						self:SetNW2String("FlightModel", GibModel:format(math.random(1, 5)))
						Missiles.Detonate(self, Owner)
					end
				)
			else -- Old instant death mechanic for BOMB,GBOMB,GBU,UAR
				if BulletData.AmmoType == "ACF.Ammunition.HEAT" then
					BulletData.AmmoType = "ACF.Ammunition.HE"
					self:SetNW2String("AmmoType", "ACF.Ammunition.HE")
				end
				Missiles.Detonate(self, Owner)
			end
			return HitRes
		end

		-- Chance for any damage to disable the missile's motor.
		if self.MotorLength > 0 and math.random() > 0.35 * Ratio then
			self.MotorLength = 0

			Missiles.SetMotorState(self, false)
		end

		-- Chance for any damage to disable the missile's guidance.
		if self.UseGuidance and math.random() > 0.2 * Ratio then
			self.UseGuidance = nil
		end
	end

	return HitRes -- This function needs to return HitRes
end

function ENT:CFW_PreParented()
	return false
end
