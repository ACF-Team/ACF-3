local ACF            = ACF
local Missiles       = ACF.Missiles
local Classes        = ACF.Classes
local Clock          = ACF.Utilities.Clock
local Sounds         = ACF.Utilities.Sounds
local ActiveMissiles = ACF.ActiveMissiles
local hook           = hook
local next           = next
local Inputs         = { "Detonate (Force the missile to explode.)" }
local Outputs        = { "Entity (The missile itself.) [ENTITY]" }
local DefaultSound   = "acf_missiles/missiles/missile_rocket.mp3"

-- Calls an optional launcher method, see launcher_sv.lua for the interface.
local function CallLauncher(Missile, Method, ...)
	local Launcher = Missile.ACF_Launcher
	local Func     = Launcher and Launcher[Method]

	if Func then return Func(Launcher, Missile, ...) end
end

-- Mirrors what an ammo crate does for the missile it hands out, but driven by the spec.
local function SetupRound(Missile, Spec)
	local Ammo       = Spec.Ammo
	local BulletData = Ammo:ServerConvert()

	BulletData.Crate  = Missile:EntIndex()
	BulletData.Owner  = Missile:CPPIGetOwner()
	BulletData.Gun    = Missile
	BulletData.Filter = Missile.Filter

	Missile.RoundData  = Ammo
	Missile.BulletData = BulletData

	if Ammo.OnFirst then
		Ammo:OnFirst(Missile)
	end

	hook.Run("ACF_OnAmmoFirst", Ammo, Missile)

	Ammo:Network(Missile, BulletData)

	local Guidance   = Missiles.CloneInstance(Spec.Guidance)
	local Fuze       = Missiles.CloneInstance(Spec.Fuze)
	local Navigation = Missiles.CloneInstance(Spec.Navigation)

	if Guidance.OnFirst then Guidance:OnFirst(Missile) end
	if Fuze.OnFirst then Fuze:OnFirst(Missile) end
	if Guidance.Configure then Guidance:Configure(Missile) end
	if Fuze.Configure then Fuze:Configure(Missile) end

	Missile.GuidanceData   = Guidance
	Missile.FuzeData       = Fuze
	Missile.NavigationData = Navigation
end

--- Spawns an unlaunched missile from a spec. Returns the missile, or nil/false and an error string.
--- @param Spec table From Missiles.CreateSpec or Missiles.SpecFromCrate
--- @param Options table { Owner, Pos, Ang, Launcher?, Parent?, Hidden?, Protected?, Filter?, Color?, Model? }
function Missiles.Create(Spec, Options)
	if not (istable(Spec) and Spec.Class and Spec.Ammo) then return nil, "Invalid spec" end
	if not istable(Options) then return nil, "Options must be a table" end

	local Owner = Options.Owner
	if not (IsValid(Owner) or Owner == game.GetWorld()) then return nil, "Options.Owner must be a valid player or the world" end
	if not isvector(Options.Pos) then return nil, "Options.Pos must be a vector" end
	if not isangle(Options.Ang) then return nil, "Options.Ang must be an angle" end

	local Data       = Spec.Class
	local Class      = Classes.GetBaseClass(Data)
	local Round      = Data.Round
	local Length     = Data.Length
	local Caliber    = Data.Caliber
	local BulletData = Spec.BulletData
	local Percent    = math.max(0.5, (BulletData.ProjLength + BulletData.PropLength) / Round.MaxLength)

	local CanSpawn = hook.Run("ACF_PreSpawnEntity", "acf_missile", Owner, Spec)
	if CanSpawn == false then return false, "Blocked by ACF_PreSpawnEntity" end

	local Missile = ents.Create("acf_missile")
	if not IsValid(Missile) then return nil, "Couldn't create acf_missile" end

	Missile:SetAngles(Options.Ang)
	Missile:SetPos(Options.Pos)
	Missile:SetColor(Options.Color or color_white)
	Missile:CPPISetOwner(Owner)
	Missile:SetPlayer(Owner)

	if IsValid(Options.Parent) then
		Missile:SetParent(Options.Parent)
	end

	Missile:Spawn()

	local Filter = { Missile }

	if Options.Filter then
		for _, Entity in ipairs(Options.Filter) do
			Filter[#Filter + 1] = Entity
		end
	end

	Missile.Spec            = Spec
	Missile.ACF_Launcher    = Options.Launcher
	Missile.Owner           = Owner
	Missile.Name            = Data.Name
	Missile.ShortName       = Data.ID
	Missile.EntType         = Class.Name
	Missile.Caliber         = Caliber
	Missile.Filter          = Filter
	Missile.SeekCone        = Data.SeekCone
	Missile.ViewCone        = Data.ViewCone
	Missile.SkinIndex       = Data.SkinIndex
	Missile.NoThrust        = Data.NoThrust or Class.NoThrust
	Missile.Sound           = Data.Sound or Class.Sound or DefaultSound
	Missile.ReloadTime      = (Data.ReloadTime or 10) * Percent
	Missile.ForcedMass      = Data.Mass or 10
	Missile.ForcedArmor     = Round.Armor
	Missile.Effect          = Data.Effect or Class.Effect
	Missile.NoDamage        = Options.Protected or Data.NoDamage
	Missile.HitDeviate      = Data.HitDeviate
	Missile.ExhaustPos      = Data.ExhaustPos or Vector()
	Missile.Bodygroups      = Data.Bodygroups
	Missile.RoundDef        = Round
	Missile.RackModel       = Options.Model or Round.RackModel
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
	Missile.RotAxis         = Vector()
	Missile.UseGuidance     = true
	Missile.MotorEnabled    = false
	Missile.Thrust          = 0
	Missile.ThinkDelay      = 0.1
	Missile.Inputs          = WireLib.CreateInputs(Missile, Inputs)
	Missile.Outputs         = WireLib.CreateOutputs(Missile, Outputs)

	hook.Run("ACF_OnSpawnEntity", "acf_missile", Missile, Spec)

	WireLib.TriggerOutput(Missile, "Entity", Missile)

	Missile:UpdateModel(Missile.RackModel or Missile.RealModel)

	SetupRound(Missile, Spec)

	if Options.Hidden then
		Missile:SetNotSolid(true)
		Missile:SetNoDraw(true)
	end

	Missiles.InitMotor(Missile)

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

	Missile:UpdateBodygroups("OnRack")
	Missile:UpdateSkin()

	return Missile
end

--- Releases a missile made with Missiles.Create: unparents it, lights the motor, starts guidance and arms the fuze.
--- @param Options table? { Velocity?, Direction?, MotorDelay?, Misfire? }
function Missiles.Launch(Missile, Options)
	if not IsValid(Missile) then return end
	if Missile.Launched then return end

	Options = Options or {}

	local BulletData = Missile.BulletData
	local Direction  = Options.Direction and Options.Direction:GetNormalized() or Missile:GetForward()
	local Velocity   = (Options.Velocity or Vector()) + Missile.SpeedBoost * Direction
	local DeltaTime  = engine.TickInterval()
	local Position   = Missile:GetPos()
	local Sound      = CallLauncher(Missile, "GetLaunchSound")

	if Sound then
		Missile.Sound = Sound
	end

	BulletData.Flight = Velocity
	BulletData.Pos    = Position

	Missile.Launched     = true
	Missile.ThinkDelay   = DeltaTime
	Missile.GhostPeriod  = Clock.CurTime + (Missile.RoundDef.GhostingPeriod or ACF.GhostPeriod)
	Missile.NoDamage     = nil
	Missile.LastThink    = Clock.CurTime - DeltaTime
	Missile.ACF_Position = Position
	Missile.LastPos      = Position
	Missile.ACF_Velocity = Velocity
	Missile.LastVel      = Velocity
	Missile.CurDir       = Direction
	Missile.LaunchPos    = Position
	Missile.LaunchAng    = Direction:Angle()

	Missile.ACF_InvisibleToBallistics = false
	Missile.ACF_InvisibleToTrace = false

	if Missile.RackModel then
		Missile:UpdateModel(Missile.RealModel)
	end

	-- Filtering is mutual, so in-flight missiles from the same launcher don't hit this one either
	local Filter = Missile.Filter

	for _, Entity in ipairs(CallLauncher(Missile, "GetMissileFilter") or {}) do
		Filter[#Filter + 1] = Entity

		if ActiveMissiles[Entity] and Entity.Filter then
			Entity.Filter[#Entity.Filter + 1] = Missile
		end
	end

	Sounds.SendSound(Missile, "phx/epicmetal_hard.wav", 70, math.random(99, 101), 1)
	Missile:SetNotSolid(false)
	Missile:SetNoDraw(false)
	Missile:SetParent()

	Missile:DoFlight()

	if Options.Misfire then
		Missile.Disabled = true

		return Missile:Detonate()
	end

	ActiveMissiles[Missile] = true

	local Delay = Options.MotorDelay

	if Delay and Delay > 0 and Missile.CanDelay and CallLauncher(Missile, "CanDelayMotor") ~= false then
		timer.Simple(Delay, function()
			if not IsValid(Missile) then return end

			Missiles.SetMotorState(Missile, true)
		end)
	else
		Missiles.SetMotorState(Missile, true)
	end

	Missile.GuidanceData:Configure(Missile)
	Missile.GuidanceData:OnLaunched(Missile)

	Missile.FuzeData:Configure()

	Missile.NavigationData:Configure(Missile)

	Missile:UpdateBodygroups("OnLaunch")
	Missile:UpdateSkin()

	hook.Run("ACF_OnLaunchMissile", Missile)
end

--- Blows a missile up on purpose (wire input, script, shot down). ACF_PreExplodeMissile can cancel it.
--- @param Inflictor Entity? Player credited with the kill
function Missiles.Detonate(Missile, Inflictor)
	if not IsValid(Missile) then return end

	local CanExplode = hook.Run("ACF_PreExplodeMissile", Missile, Missile.BulletData)

	if not CanExplode then return end

	if IsValid(Inflictor) and Inflictor:IsPlayer() then
		Missile.Inflictor = Inflictor
	end

	Missile:Detonate(true)
end

--- Iterates every missile in flight: for Missile in Missiles.IterateActive() do ... end
function Missiles.IterateActive()
	return next, ActiveMissiles, nil
end

function Missiles.IsActive(Missile)
	return ActiveMissiles[Missile] == true
end

--- Internal: the missile entity reports its own removal here.
function Missiles.OnRemoved(Missile)
	ActiveMissiles[Missile] = nil

	CallLauncher(Missile, "OnMissileRemoved", Missile.Launched == true)
end

--- Internal: the launcher's origin, falling back to where the missile was launched (or currently is).
function Missiles.GetLaunchOrigin(Missile)
	local Pos, Ang = CallLauncher(Missile, "GetLaunchOrigin")

	if Pos then return Pos, Ang end

	return Missile.LaunchPos or Missile:GetPos(), Missile.LaunchAng or Missile:GetAngles()
end

--- Internal: the entity the launcher fires from, or nil.
function Missiles.GetLauncherEntity(Missile)
	local Entity = CallLauncher(Missile, "GetEntity")

	if IsValid(Entity) then return Entity end
end
