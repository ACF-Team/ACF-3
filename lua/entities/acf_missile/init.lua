AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-------------------------------[[ Local Functions ]]-------------------------------

local ACF            = ACF
local TraceData      = { start = true, endpos = true, filter = true }
local GravityCvar    = GetConVar("sv_gravity")
local GravityVector  = Vector(0, 0, -GravityCvar:GetFloat())
local ActiveMissiles = ACF.ActiveMissiles
local Ballistics     = ACF.Ballistics
local Classes        = ACF.Classes
local Clock          = ACF.Utilities.Clock
local Sounds         = ACF.Utilities.Sounds
local Damage         = ACF.Damage
local Debug			 = ACF.Debug
local Missiles       = Classes.Missiles
local InputActions   = ACF.GetInputActions("acf_missile")
local hook           = hook
local Inputs         = { "Detonate (Force the missile to explode.)" }
local Outputs        = { "Entity (The missile itself.) [ENTITY]" }

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

local function UpdateBodygroups(Missile, Phase)
	local Sources = Missile.Bodygroups

	if Sources then
		for _, V in pairs(Missile:GetBodyGroups()) do
			local Source = Sources[string.lower(V.name)]

			if Source then
				ApplyBodySubgroup(Missile, V, Source, Phase)
			end
		end
	end
end

local function UpdateSkin(Missile)
	local BulletData = Missile.BulletData
	local Skins = Missile.SkinIndex

	if not BulletData then return end
	if not Skins then return end

	Missile:SetSkin(Skins[BulletData.Type] or 0)
end

local function LaunchEffect(Missile)
	local Sound = Missile.Sound

	Sounds.SendSound(Missile.Launcher, Sound, 180, math.random(99, 101), 1)
end

local function SetMotorState(Missile, Enabled)
	if Missile.MotorEnabled == Enabled then return end

	if Enabled then
		if Missile.NoThrust then return end
		if Missile.Detonated then return end

		Missile.Thrust = Missile.MaxThrust
		Missile:SetNW2Float("LightSize", Missile.BulletData.Caliber)

		LaunchEffect(Missile)

		if Missile.Effect then
			timer.Simple(0, function()
				if not IsValid(Missile) then return end
				if not Missile.MotorEnabled then return end

				ParticleEffectAttach(Missile.Effect, PATTACH_POINT_FOLLOW, Missile, Missile:LookupAttachment("exhaust") or 0)
			end)
		end
	else
		Missile.Thrust = 0
		Missile:StopParticles()
		Missile:SetNW2Float("LightSize", 0)
	end

	Missile.MotorEnabled = Enabled
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

local Navigation = {}

-- Chase - Simply steers itself towards the target
-- Applicable to anti radiation missiles, and others not needing lead
function Navigation.Chase(TimeToHit, RelPos)
	local Scalar   = 9 / TimeToHit^2
	local Pos      = RelPos
	return Scalar * Pos - GravityVector
end

-- Proportional navigation - Takes the relative position and velocity into account
-- Applicable to early generation missiles
function Navigation.PN(TimeToHit, RelPos, RelVel)
	local Scalar = 9 / TimeToHit^2
	local Pos    = RelPos
	local Vel    = RelVel * TimeToHit
	return Scalar * (Pos + Vel) - GravityVector
end

-- Augmented proportional navigation - Takes the relative position, velocity and acceleration into account
-- Applicable to most modern missiles
function Navigation.APN(TimeToHit, RelPos, RelVel, RelAcc)
	local Scalar = 9 / TimeToHit^2
	local Pos    = RelPos
	local Vel    = RelVel * TimeToHit
	local Acc    = RelAcc * TimeToHit^2 * 0.5
	return Scalar * (Pos + Vel + Acc) - GravityVector
end

local MIN_BOUNDS = -math.pow(2, 14)
local MAX_BOUNDS = math.pow(2, 14)

-- TODO: Missiles must base their movement off an ACF bullet
local function CalcFlight(Missile)
	if not Missile.Launched then return end
	if Missile.Detonated then return end

	local Time = Clock.CurTime
	local DeltaTime = Time - Missile.LastThink
	Missile.LastThink = Time

	if DeltaTime <= 0 then return end

	local Pos            = Missile.ACF_Position
	local Dir            = Missile.CurDir
	local LastVel        = Missile.LastVel
	local LastSpeed      = LastVel:Length()
	local LastSpeedSqr   = LastVel:LengthSqr()
	local VelNorm        = LastVel:GetNormalized()
	local LiftMultiplier = LastSpeedSqr * Missile.FinMultiplier / Missile.Mass -- Lift per sin(AoA)

	-- Torque from the back fins
	local Inertia = Missile.Inertia
	local Torque  = Dir:Cross(LastVel) * LastSpeed * Missile.TorqueMul

	--Guidance calculations
	local Guidance    = Missile.UseGuidance and Missile.GuidanceData:GetGuidance(Missile)
	local TargetPos   = Guidance and Guidance.TargetPos

	-- debugoverlay.Line(Missile.ACF_Position, TargetPos, 10, Color(0, 0, 255), true)
	if TargetPos then
		-- Getting the relative position, velocity and acceleration
		local RelPos = TargetPos - Pos
		local RelVel = (RelPos - (Missile.LastRelPos or RelPos)) / DeltaTime
		local RelAcc = (RelVel - (Missile.LastRelVel or RelVel)) / DeltaTime
		-- Filtering the acceleration
		Missile.FilteredAcc = (Missile.FilteredAcc or RelAcc) * 0.8 + RelAcc * 0.2
		local Dist          = RelPos:Length()
		local RelSpd        = RelVel:Length()
		local TimeToHit     = math.min(Dist / RelSpd, 60)
		local PredSpeed     = RelSpd + Missile.Thrust / Missile.Mass * math.min(Missile.MotorLength, TimeToHit) * 0.5
		TimeToHit           = math.min(Dist / PredSpeed, 60)
		-- Guidance
		local Nav = Missile.Navigation(TimeToHit, RelPos, RelVel, Missile.FilteredAcc)
		-- Making the acceleration perpendicular to the velocity and limiting it
		Nav = Nav - Nav:Dot(VelNorm) * VelNorm
		if Nav:Length() > Missile.GLimit then
			Nav = Nav:GetNormalized() * Missile.GLimit
		end
		-- Calculating the AoA (and subsequent direction) that produces the desired acceleration
		local TargetAoA = math.deg(math.asin(math.min(Nav:Length() / LiftMultiplier, 1)))
		local AoAAxis   = VelNorm:Cross(Nav):GetNormalized()
		local TargetAng = VelNorm:Angle()
		TargetAng:RotateAroundAxis(AoAAxis, TargetAoA)
		local TargetDir = TargetAng:Forward()
		-- Turning the missile to the target direction
		local Agility   = Missile.Agility * math.min(1, Missile.ControlSurfMul * LastSpeedSqr) / Inertia
		local Axis      = Dir:Cross(TargetDir):GetNormalized()
		local AngDiff   = math.deg(math.acos(math.Clamp(TargetDir:Dot(Dir), -1, 1)))
		Missile.RotAxis = Axis * math.min(Agility, AngDiff / DeltaTime)

		Missile.LastRelPos = RelPos
		Missile.LastRelVel = RelVel
	end

	-- debugoverlay.Line(Pos, Pos + Missile.RotAxis * 10, 10, Color(0, 0, 255), true)
	-- debugoverlay.Line(Pos, Pos + Torque / Inertia * DeltaTime * 10, 10, Color(255, 0, 0), true)
	Missile.RotAxis = Missile.RotAxis + Torque / Inertia * DeltaTime
	local DirAng  = Dir:Angle()
	DirAng:RotateAroundAxis(Missile.RotAxis:GetNormalized(), Missile.RotAxis:Length() * DeltaTime)
	Dir = DirAng:Forward()
	Missile.RotAxis = Missile.RotAxis * (1 - 0.7 * DeltaTime)
	-- debugoverlay.Line(Missile.ACF_Position, Missile.ACF_Position + Missile.RotAxis * 10, 10, Color(255, 0, 0), true)

	local FuelMod = math.Clamp(Missile.MotorLength / DeltaTime, 0, 1)
	if Missile.MotorEnabled then
		if Missile.MotorLength <= 0 then
			SetMotorState(Missile, false)
		else
			Missile.MotorLength = math.max(Missile.MotorLength - DeltaTime, 0)

			-- Update the missile's mass and inertia according to the remaining fuel
			Missile.Mass = Missile.ProjMass + Missile.PropMass * Missile.MotorLength / Missile.MaxMotorLength
			Missile.Inertia	= Missile.AreaOfInertia * Missile.Mass
		end
	end

	local Thrust    = Dir * FuelMod * Missile.Thrust / Missile.Mass
	local Up        = Dir:Cross(LastVel):Cross(Dir):GetNormalized()
	local DotSimple = Up.x * VelNorm.x + Up.y * VelNorm.y + Up.z * VelNorm.z
	local Lift      = -Up * DotSimple * LiftMultiplier

	-- debugoverlay.Line(Missile.ACF_Position, Missile.ACF_Position + VelNorm * 10, 10, Color(0, 0, 255), true)
	-- debugoverlay.Line(Missile.ACF_Position, Missile.ACF_Position + Up * 10, 10, Color(255, 0, 0), true)
	-- debugoverlay.Line(Missile.ACF_Position, Missile.ACF_Position + Dir * 10, 10, Color(255, 0, 0), true)
	local Drag      = LastVel * (Missile.DragCoef * LastSpeed) / ACF.DragDiv * ACF.Scale / Missile.Mass
	local Vel       = LastVel + (GravityVector + Thrust + Lift - Drag) * DeltaTime
	local EndPos    = Pos + Vel * DeltaTime

	Missile.ACF_Velocity = Vel

	--Hit detection
	TraceData.start = Pos
	TraceData.endpos = EndPos
	TraceData.filter = Missile.Filter

	local Result = ACF.trace(TraceData)
	local Ghosted = Time < Missile.GhostPeriod
	local GhostHit = Ghosted and Result.HitWorld
	local HitSky   = Result.HitSky

	-- If hitting the sky, continue so they can leave the map.
	if Missile.InSky and not Result.HitWorld and Pos[3] < Missile.InSky then
		Missile.InSky = nil
	end

	if not Missile.InSky and Result.Hit and (GhostHit or not Ghosted) then
		if HitSky then
			Missile.InSky = Result.HitPos[3]
			-- ^^ This is the Z component. We will not exit the sky until we go lower than this.
			-- The reason this matters is in case we hit the sky but then there's a skybox right above the sky, etc.
			-- So only exit sky-ignoring when we cross the same boundary we crossed entering it
		else
			Missile.HitNormal = Result.HitNormal
			Missile.Disabled = GhostHit

			Missile:DoFlight(Result.HitPos)
			Missile:Detonate()
			return
		end
	end

	if Missile.FuzeData:GetDetonate(Missile, Missile.GuidanceData) then
		Missile:Detonate()

		return
	end

	Missile.LastVel = Vel
	Missile.LastPos = Pos
	Missile.ACF_Position = EndPos
	Missile.CurDir = Dir

	--Missile trajectory debugging
	Debug.Line(Pos, EndPos, 10, Color(0, 255, 0))

	Missile:DoFlight()
end

local function DetonateMissile(Missile, Inflictor)
	local CanExplode = hook.Run("ACF_PreExplodeMissile", Missile, Missile.BulletData)

	if not CanExplode then return end

	if IsValid(Inflictor) and Inflictor:IsPlayer() then
		Missile.Inflictor = Inflictor
	end

	Missile:Detonate(true)
end

cvars.AddChangeCallback("sv_gravity", function(_, _, Value)
	GravityVector.z = -Value
end, "ACF Missile Gravity")

hook.Add("CanDrive", "acf_missile_CanDrive", function(_, Entity)
	if ActiveMissiles[Entity] then return false end
end)

hook.Add("ACF_OnLaunchMissile", "ACF Missile Rack Filter", function(Missile)
	local Count = #Missile.Filter

	for K in pairs(ActiveMissiles) do
		if Missile ~= K and Missile.Launcher == K.Launcher then
			Count = Count + 1

			K.Filter[#K.Filter + 1] = Missile
			Missile.Filter[Count] = K
		end
	end
end)

ACF.AddInputAction("acf_missile", "Detonate", function(Entity, Value)
	if not Entity.Launched then return end

	if Value ~= 0 then
		local BulletData = Entity.BulletData
		if BulletData.Type == "HEAT" then
			BulletData.Type = "HE"
			Entity:SetNW2String("AmmoType", "HE")
		end
		Entity:Detonate(true)
	end
end)

-------------------------------[[ Global Functions ]]-------------------------------

-- TODO: Make ACF Missiles compliant with ACF legal checks. How to deal with SetNoDraw and SetNotSolid tho
function ACF.MakeMissile(Player, Pos, Ang, Rack, MountPoint, Crate)
	local BulletData = Crate.BulletData
	local Class      = Classes.GetGroup(Missiles, BulletData.Id)
	local Data       = Class.Lookup[BulletData.Id]
	local Round      = Data.Round
	local Length     = Data.Length
	local Caliber    = Data.Caliber
	local Percent    = math.max(0.5, (BulletData.ProjLength + BulletData.PropLength) / Round.MaxLength)

	local CanSpawn = hook.Run("ACF_PreSpawnEntity", "acf_missile", Player, Data, Class, Crate)
	if CanSpawn == false then return false end

	local Missile = ents.Create("acf_missile")
	if not IsValid(Missile) then return end

	Missile:SetAngles(Rack:LocalToWorldAngles(Ang))
	Missile:SetPos(Rack:LocalToWorld(Pos))
	Missile:SetColor(Crate:GetColor())
	Missile:CPPISetOwner(Player)
	Missile:SetPlayer(Player)
	Missile:SetParent(Rack)
	Missile:Spawn()

	Missile.Owner           = Player
	Missile.Name            = Data.Name
	Missile.ShortName       = Data.ID
	Missile.EntType         = Class.Name
	Missile.Caliber         = Caliber
	Missile.Launcher        = Rack
	Missile.MountPoint      = MountPoint
	Missile.Filter          = { Rack }
	Missile.SeekCone        = Data.SeekCone
	Missile.ViewCone        = Data.ViewCone
	Missile.SkinIndex       = Data.SkinIndex
	Missile.NoThrust        = Data.NoThrust or Class.NoThrust
	Missile.Sound           = Data.Sound or Class.Sound or "acf_missiles/missiles/missile_rocket.mp3"
	Missile.ReloadTime      = (Data.ReloadTime or 10) * Percent
	Missile.ForcedMass      = Data.Mass or 10
	Missile.ForcedArmor     = Round.Armor
	Missile.Effect          = Data.Effect or Class.Effect
	Missile.NoDamage        = Rack.ProtectMissile or Data.NoDamage
	Missile.ExhaustPos      = Data.ExhaustPos or Vector()
	Missile.Bodygroups      = Data.Bodygroups
	Missile.RackModel       = Rack.MissileModel or Round.RackModel
	Missile.RealModel       = Round.Model
	Missile.DragCoef        = Round.DragCoef
	Missile.MaxThrust       = Round.Thrust
	Missile.FuelConsumption = Round.FuelConsumption * 0.001
	Missile.StarterPercent  = Round.StarterPercent
	Missile.FinMultiplier   = Round.FinMul
	Missile.GLimit          = Round.GLimit * 9.81 * ACF.MeterToInch
	Missile.CanDelay        = Round.CanDelayLaunch
	Missile.MaxLength       = Round.MaxLength
	Missile.Agility         = (Data.Agility or 1) * 1e10
	Missile.ProjMass        = BulletData.ProjMass
	Missile.PropMass        = BulletData.PropMass
	Missile.Mass            = Missile.ProjMass + Missile.PropMass
	Missile.AreaOfInertia   = (3 * Caliber ^ 2 + Length ^ 2) / 12
	Missile.Inertia         = Missile.AreaOfInertia * Missile.Mass
	Missile.Length          = Length
	Missile.TorqueMul       = Length * 0.15 * Round.TailFinMul
	Missile.ControlSurfMul  = (Round.MaxAgilitySpeed * ACF.MeterToInch) ^ -2
	Missile.Navigation      = Navigation[Data.Navigation]
	Missile.RotAxis         = Vector()
	Missile.UseGuidance     = true
	Missile.MotorEnabled    = false
	Missile.Thrust          = 0
	Missile.ThinkDelay      = 0.1
	Missile.Inputs          = WireLib.CreateInputs(Missile, Inputs)
	Missile.Outputs         = WireLib.CreateOutputs(Missile, Outputs)

	hook.Run("ACF_OnSpawnEntity", "acf_missile", Missile, Data, Class, Crate)

	WireLib.TriggerOutput(Missile, "Entity", Missile)

	Missile:UpdateModel(Missile.RackModel or Missile.RealModel)
	Missile:CreateBulletData(Crate)

	if Rack.HideMissile then
		Missile:SetNotSolid(true)
		Missile:SetNoDraw(true)
	end

	if Missile.NoThrust then
		Missile.MotorLength = 0
		Missile.SpeedBoost = 0
	else
		local TotalLength = Missile.BulletData.PropMass / (Missile.FuelConsumption * Missile.MaxThrust)

		Missile.MaxMotorLength = TotalLength
		Missile.MotorLength = (1 - Missile.StarterPercent) * TotalLength
		Missile.SpeedBoost = Missile.StarterPercent * TotalLength * Missile.MaxThrust / (Missile.ProjMass + Missile.PropMass * 0.5)
	end

	if Missile.NoDamage then
		Missile.ACF_InvisibleToBallistics = true
		Missile.ACF_InvisibleToTrace = true
	end

	local PhysObj = Missile:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:SetMass(Missile.ForcedMass)
		PhysObj:EnableGravity(false)
		PhysObj:EnableMotion(false)
	end

	UpdateBodygroups(Missile, "OnRack")
	UpdateSkin(Missile)

	return Missile
end

function ENT:CreateBulletData(Crate)
	local Ammo = Crate.RoundData
	local Data = {}

	-- Creating a copy of the basic data stored on the crate
	for _, V in ipairs(Crate.DataStore) do
		Data[V] = Crate[V]
	end

	Data.Destiny = ACF.FindWeaponrySource(Data.Weapon)

	self.ToolData          = Data
	self.RoundData         = Ammo
	self.BulletData        = Ammo:ServerConvert(Data)
	self.BulletData.Crate  = self:EntIndex()
	self.BulletData.Owner  = self:GetPlayer()
	self.BulletData.Gun    = self
	self.BulletData.Filter = self.Filter

	if Ammo.OnFirst then
		Ammo:OnFirst(self)
	end

	hook.Run("ACF_OnAmmoFirst", Ammo, self, Data)

	Ammo:Network(self, self.BulletData)
end

function ENT:UpdateModel(Model)
	self:SetModel(Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

function ENT:Launch(Delay, IsMisfire)
	if self.Launched then return end

	local BulletData = self.BulletData
	local Point      = self.MountPoint
	local Rack       = self.Launcher
	local Flight     = BulletData.Flight or self:LocalToWorldAngles(Point.Angle):Forward()
	local Velocity   = Rack.ACF_Velocity + self.SpeedBoost * Flight
	local DeltaTime  = engine.TickInterval()

	if Rack.SoundPath and Rack.SoundPath ~= "" then
		self.Sound = Rack.SoundPath
	end

	BulletData.Flight = Velocity
	BulletData.Pos    = Rack:LocalToWorld(Point.Position)

	self.Launched     = true
	self.ThinkDelay   = DeltaTime
	self.GhostPeriod  = Clock.CurTime + ACF.GhostPeriod
	self.NoDamage     = nil
	self.LastThink    = Clock.CurTime - DeltaTime
	self.ACF_Position = BulletData.Pos
	self.LastPos      = self.ACF_Position
	self.ACF_Velocity = Velocity
	self.LastVel      = Velocity
	self.CurDir       = Flight

	self.ACF_InvisibleToBallistics = false
	self.ACF_InvisibleToTrace = false

	if self.RackModel then
		self:UpdateModel(self.RealModel)
	end

	for _, Missile in pairs(Rack.Missiles) do
		self.Filter[#self.Filter + 1] = Missile
	end

	Sounds.SendSound(self, "phx/epicmetal_hard.wav", 70, math.random(99, 101), 1)
	self:SetNotSolid(false)
	self:SetNoDraw(false)
	self:SetParent()

	self:DoFlight()

	if IsMisfire then
		self.Disabled = true

		return self:Detonate()
	end

	ActiveMissiles[self] = true

	if Delay and self.CanDelay and Rack.CanDropMissile then
		timer.Simple(Delay, function()
			if not IsValid(self) then return end

			SetMotorState(self, true)
		end)
	else
		SetMotorState(self, true)
	end

	self.GuidanceData:Configure(self)
	self.GuidanceData:OnLaunched(self)

	self.FuzeData:Configure()

	UpdateBodygroups(self, "OnLaunch")
	UpdateSkin(self)

	hook.Run("ACF_OnLaunchMissile", self)
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

	SetMotorState(self, false)

	ActiveMissiles[self] = nil

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

	if BulletData.Pos then
		Debug.Line(BulletData.Pos, BulletData.Pos + BulletData.Flight, 10, Color(255, 128, 0))
	end

	BulletData.DetonatorAngle = 91

	local Bullet = Ballistics.CreateBullet(BulletData)

	if BulletData.Type ~= "HEAT" then
		ACF.DoReplicatedPropHit(self, Bullet)
	end
end

function ENT:Think()
	self:NextThink(Clock.CurTime + self.ThinkDelay)

	CalcFlight(self)

	return true
end

local Properties = { bodygroups = true, skin = true }

function ENT:CanProperty(_, Property)
	if Properties[Property] then return false end

	return true
end

function ENT:OnRemove()
	ActiveMissiles[self] = nil

	if self.GuidanceData then
		self.GuidanceData:OnRemoved(self)
	end

	if IsValid(self.Launcher) and not self.Launched then
		self.Launcher:UpdateLoad(self.MountPoint)
	end

	WireLib.Remove(self)
end

function ENT:ACF_Activate(Recalc)
	local PhysObj = self.ACF.PhysObj
	local Area    = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
	local Armor   = self.ForcedArmor
	local Health  = Area / ACF.Threshold
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Area      = Area
	self.ACF.Ductility = 0
	self.ACF.Health    = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour    = Armor * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armor * ACF.ArmorMod
	self.ACF.Mass      = self.ForcedMass
	self.ACF.Type      = "Prop"
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

		if BulletData.Type == "HEAT" then
			BulletData.Type = "HE"

			self:SetNW2String("AmmoType", "HE")
		end
		DetonateMissile(self, Owner)

		return HitRes
	elseif HitRes then
		local Ratio      = self.ACF.Health / self.ACF.MaxHealth
		local BulletData = self.BulletData

		-- The missile should detonate when it gets penetrated, but only have a chance to detonate if not penetrated.
		if math.random() > 0.55 * Ratio or DmgResult.Penetration > self.ForcedArmor then
			if BulletData.Type == "HEAT" then
				BulletData.Type = "HE"

				self:SetNW2String("AmmoType", "HE")
			end
			DetonateMissile(self, Owner)

			return HitRes
		end

		-- Chance for any damage to disable the missile's motor.
		if self.MotorLength > 0 and math.random() > 0.35 * Ratio then
			self.MotorLength = 0

			SetMotorState(self, false)
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