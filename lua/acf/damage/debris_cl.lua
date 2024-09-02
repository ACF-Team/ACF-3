local ACF     = ACF
local Network = ACF.Networking

local Effects     = ACF.Utilities.Effects
local AllowDebris = GetConVar("acf_debris")
local CollideAll  = GetConVar("acf_debris_collision")
local DebrisLife  = GetConVar("acf_debris_lifetime")
local GibMult     = GetConVar("acf_debris_gibmultiplier")
local GibLife     = GetConVar("acf_debris_giblifetime")
local GibModel    = "models/gibs/metal_gib%s.mdl"

local function Particle(Entity, Effect)
    return CreateParticleSystem(Entity, Effect, PATTACH_ABSORIGIN_FOLLOW)
end

local function FadeAway(Entity)
    if not IsValid(Entity) then return end

    local Smoke = Entity.SmokeParticle
    local Ember = Entity.EmberParticle

    Entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
    Entity:SetRenderFX(kRenderFxFadeSlow) -- NOTE: Not synced to CurTime()
    Entity:CallOnRemove("ACF_Debris_Fade", function()
        Entity:StopAndDestroyParticles()
    end)

    if IsValid(Smoke) then Smoke:StopEmission() end
    if IsValid(Ember) then Ember:StopEmission() end

    timer.Simple(5, function()
        if not IsValid(Entity) then return end

        Entity:Remove()
    end)
end

local function Ignite(Entity, Lifetime, IsGib)
    if IsGib then
        Particle(Entity, "burning_gib_01")

        timer.Simple(Lifetime * 0.2, function()
            if not IsValid(Entity) then return end

            Entity:StopParticlesNamed("burning_gib_01")
        end)
    else
        Entity.SmokeParticle = Particle(Entity, "smoke_small_01b")

        Particle(Entity, "env_fire_small_smoke")

        timer.Simple(Lifetime * 0.4, function()
            if not IsValid(Entity) then return end

            Entity:StopParticlesNamed("env_fire_small_smoke")
        end)
    end
end

local function CreateDebris(Model, Position, Angles, Normal, Power, ShouldIgnite)
    local Debris = ents.CreateClientProp(Model)

    if not IsValid(Debris) then return end

    local Lifetime = DebrisLife:GetFloat() * math.Rand(0.5, 1)

    Debris:SetPos(Position)
    Debris:SetAngles(Angles)
    Debris:SetMaterial("models/props_pipes/GutterMetal01a")

    if not CollideAll:GetBool() then
        Debris:SetCollisionGroup(COLLISION_GROUP_WORLD)
    end

    Debris:Spawn()

    Debris.EmberParticle = Particle(Debris, "embers_medium_01")

    if ShouldIgnite and math.Rand(0, 0.5) < ACF.DebrisIgniteChance then
        Ignite(Debris, Lifetime)
    else
        Debris.SmokeParticle = Particle(Debris, "smoke_exhaust_01a")
    end

    local PhysObj = Debris:GetPhysicsObject()

    if IsValid(PhysObj) then
        PhysObj:ApplyForceOffset(Normal * Power, Position + VectorRand() * 20)
    end

    timer.Simple(Lifetime, function()
        FadeAway(Debris)
    end)

    return Debris
end

local function CreateGib(Position, Angles, Normal, Power, Min, Max)
    local Gib = ents.CreateClientProp(GibModel:format(math.random(1, 5)))

    if not IsValid(Gib) then return end

    local Lifetime = GibLife:GetFloat() * math.Rand(0.5, 1)
    local Offset   = ACF.RandomVector(Min, Max)

    Offset:Rotate(Angles)

    Gib:SetPos(Position + Offset)
    Gib:SetAngles(AngleRand(-180, 180))
    Gib:SetModelScale(math.Rand(0.5, 2))
    Gib:SetMaterial("models/props_pipes/GutterMetal01a")
    Gib:Spawn()

    Gib.SmokeParticle = Particle(Gib, "smoke_gib_01")

    if math.random() < ACF.DebrisIgniteChance then
        Ignite(Gib, Lifetime, true)
    end

    local PhysObj = Gib:GetPhysicsObject()

    if IsValid(PhysObj) then
        PhysObj:ApplyForceOffset(Normal * Power, Gib:GetPos() + VectorRand() * 20)
    end

    timer.Simple(Lifetime, function()
        FadeAway(Gib)
    end)

    return true
end

function ACF.CreateDebris(Model, Position, Angles, Normal, Power, CanGib, Ignite)
    if not AllowDebris:GetBool() then return end
    if not Model then return end

    local Debris = CreateDebris(Model, Position, Angles, Normal, Power, CanGib, Ignite)

    if IsValid(Debris) then
        local Multiplier = GibMult:GetFloat()
        local Radius     = Debris:BoundingRadius()
        local Min        = Debris:OBBMins()
        local Max        = Debris:OBBMaxs()

        if CanGib and Multiplier > 0 then
            local GibCount = math.Clamp(Radius * 0.1, 1, math.max(10 * Multiplier, 1))

            for _ = 1, GibCount do
                if not CreateGib(Position, Angles, Normal, Power, Min, Max) then
                    break
                end
            end
        end
    end

    local EffectTable = {
        Origin = Position, -- TODO: Change this to the hit vector, but we need to redefine HitVec as HitNorm
        Scale = 20,
    }

    Effects.CreateEffect("cball_explode", EffectTable)
end

local EntData = {}

-- Models MIGHT change, but aren't likely to, especially in combat, so rather than running some intensive model checker on entities
-- it would be better to just store it on creation. It's worth a model or two being wrong every now and then for reducing 40+ bytes 
-- into just two bytes when writing the model part of debris
hook.Add("OnEntityCreated", "ACF_Debris_TrackEnts", function(ent)
    timer.Simple(0.001, function()
        if IsValid(ent) then
            local id = ent:EntIndex()
            if id ~= -1 then
                EntData[ent:EntIndex()] = ent:GetModel()
            end
        end
    end)
end)

net.Receive("ACF_Debris", function()
    local EntID    = net.ReadUInt(14)
    local Position = Network.ReadGrainyVector(12)
    local Angles   = Network.ReadGrainyAngle(8)
    local Normal   = Network.ReadGrainyVector(8, 1)
    local Power    = net.ReadUInt(16)
    local CanGib   = net.ReadBool()
    local Ignite   = net.ReadBool()

    ACF.CreateDebris(
        EntData[EntID],
        Position,
        Angles,
        Normal,
        Power,
        CanGib,
        Ignite
    )
end)

game.AddParticles("particles/fire_01.pcf")

PrecacheParticleSystem("burning_gib_01")
PrecacheParticleSystem("env_fire_small_smoke")
PrecacheParticleSystem("smoke_gib_01")
PrecacheParticleSystem("smoke_exhaust_01a")
PrecacheParticleSystem("smoke_small_01b")
PrecacheParticleSystem("embers_medium_01")