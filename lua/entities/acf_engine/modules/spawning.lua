local ACF         = ACF
local Mobility    = ACF.Mobility
local MobilityObj = Mobility.Objects
local Fuel        = Mobility.Fuel
local MaxDistance = ACF.MobilityLinkDistance * ACF.MobilityLinkDistance

local Contraption  = ACF.Contraption
local TimerRemove  = timer.Remove

--===============================================================================================--
-- Engine class linking and setup
--===============================================================================================--
do
    ACF.RegisterClassLink("acf_engine", "acf_gearbox", function(Engine, Target)
        if Engine.Gearboxes[Target] then return false, "This engine is already linked to this gearbox." end
        if Engine:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "This gearbox is too far away from this engine!" end

        -- make sure the angle is not excessive
        local InPos = Target:LocalToWorld(Target.In.Pos)
        local OutPos = Engine:LocalToWorld(Engine.Out.Pos)

        if ACF.IsDriveshaftAngleExcessive(Target, Target.In, Engine, Engine.Out) then
            return false, "Cannot link due to excessive driveshaft angle!"
        end

        local Link = MobilityObj.Link(Engine, Target)

        Link:SetOrigin(Engine.Out)
        Link:SetTargetPos(Target.In)
        Link:SetAxis(Direction)

        Link.RopeLen = (OutPos - InPos):Length()

        Engine.Gearboxes[Target] = Link
        Target.Engines[Engine]   = true

        Engine:UpdateOverlay()
        Target:UpdateOverlay()

        Engine:InvalidateClientInfo()

        return true, "Engine linked successfully!"
    end)

    ACF.RegisterClassUnlink("acf_engine", "acf_gearbox", function(Engine, Target)
        if not Engine.Gearboxes[Target] then
            return false, "This engine is not linked to this gearbox."
        end

        local Rope = Engine.Gearboxes[Target].Rope

        if IsValid(Rope) then Rope:Remove() end

        Engine.Gearboxes[Target] = nil
        Target.Engines[Engine]	 = nil

        Engine:UpdateOverlay()
        Target:UpdateOverlay()

        Engine:InvalidateClientInfo()

        return true, "Engine unlinked successfully!"
    end)
end

do -- Spawn and Update functions
    local Classes = ACF.Classes

    -- Engine/engine-type classes are identified by FQN; derive the legacy short id for display by
    -- stripping the namespace prefix (FQNs like "ACF.Engines.5.7-V8" contain dots, so a plain split
    -- on "." won't work).
    local function GetShortName(Class, Prefix)
        local Name = Classes.GetTypeName(Class):gsub("^" .. Prefix, "")
        return Name
    end

    local function UpdateEngine(Entity, Engine)
        local EngineClass  = Engine:GetType()
        local Group        = Classes.GetBaseClass(EngineClass)
        local Type         = Classes.GetSubtypeByName("ACF.EngineTypes.BaseEngineType", Engine.Type)
            or Classes.GetTypeByName("ACF.EngineTypes.GenericPetrol")
        local Mass         = Engine.Mass
        local ShortName    = GetShortName(EngineClass, "ACF%.Engines%.")
        local Displacement = not Engine.IsElectric and Engine.Displacement or Engine.PeakPower

        Entity.ACF = Entity.ACF or {}

        Contraption.SetModel(Entity, Engine.Model)

        Entity:PhysicsInit(SOLID_VPHYSICS)
        Entity:SetMoveType(MOVETYPE_VPHYSICS)

        Entity.Name             = Engine.Name
        Entity.ShortName        = ShortName
        Entity.EntType          = Group and Group.Name or Engine.Name
        Entity.ClassData        = Group
        Entity.Displacement		= Displacement
        Entity.DefaultSound     = Engine.Sound
        Entity.SoundPitch       = Engine.Pitch or 1
        Entity.SoundVolume      = Engine.SoundVolume or 1
        Entity.TorqueCurve      = Engine.TorqueCurve
        Entity.PeakTorque       = Engine.Torque
        Entity.PeakPower		= Engine.PeakPower
        Entity.PeakPowerRPM		= Engine.PeakPowerRPM
        Entity.PeakTorqueHeld   = Engine.Torque
        Entity.IdleRPM          = Engine.RPM.Idle
        Entity.PeakMinRPM       = Engine.RPM.PeakMin
        Entity.PeakMaxRPM       = Engine.RPM.PeakMax
        Entity.LimitRPM         = Engine.RPM.Limit
        Entity.RevLimited       = false
        Entity.FlywheelOverride = Engine.RPM.Override
        Entity.FlywheelMass     = Engine.FlywheelMass
        Entity.Inertia          = Engine.FlywheelMass * math.pi ^ 2
        Entity.IsElectric       = Engine.IsElectric
        Entity.IsTrans          = Engine.IsTrans -- driveshaft outputs to the side
        Entity.FuelTypes        = Engine.Fuel or { ["ACF.FuelTypes.Petrol"] = true }
        Entity.FuelType         = next(Engine.Fuel)
        Entity.EngineType       = GetShortName(Type, "ACF%.EngineTypes%.")
        Entity.Efficiency       = Type.Efficiency
        Entity.TorqueScale      = Type.TorqueScale
        Entity.HealthMult       = Type.HealthMult
        Entity.HitBoxes         = ACF.GetHitboxes(Engine.Model)
        Entity.Out              = ACF.LocalPlane(Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaft")).Pos), Engine.IsTrans and Vector(0, 1, 0) or Vector(1, 0, 0))

        if Engine.IsTrans then
            Entity.Out = ACF.LocalPlane(vector_origin, Vector(0, 1, 0))
        end
        Entity.IsSpecial        = Engine.IsSpecial
        Entity.SoundPath        = Entity.SoundPath or Engine.Sound

        Entity:ACF_SetEntityName("ACF " .. Entity.Name)

        --calculate base fuel usage
        if Type.CalculateFuelUsage then
            Entity.FuelUse = Type.CalculateFuelUsage(Entity)
        else
            Entity.FuelUse = ACF.FuelRate * Entity.Efficiency * 3e-8
        end

        ACF.Activate(Entity, true)

        Contraption.SetMass(Entity, Mass)
    end

    -- Spawn-only init (runs before Entity:Spawn(), so the model is ready for physics).
    function ENT:ACF_PreSpawn(_, _, _, ClientData)
        self.ACF               = {}
        self.Active            = false
        self.Displacement      = 0
        self.Gearboxes         = {}
        self.FuelTanks         = {}
        self.LastThink         = 0
        self.MassRatio         = 1
        self.FuelUsage         = 0
        self.Throttle          = 0
        self.IdleThrottle      = 0
        self.FlyRPM            = 0
        self.IsDestroyed       = false
        self.LastPitch         = 0
        self.LastTorque        = 0
        self.LastFuelUsage     = 0
        self.LastPower         = 0
        self.LastRPM           = 0
        self.LastIdleThrottle  = 0
        self.LastTotalMass     = 0
        self.LastPhysMass      = 0
        self.revLimiterEnabled = true

        -- ClientData isn't verified yet here; resolve defensively for the pre-spawn model. On dupes the
        -- Engine field arrives nested ({Type,Data}) and falls through to the default - PostUpdate fixes it.
        local Engine = Classes.GetSubtypeByName("ACF.Engines.BaseEngine", ClientData.Engine)
            or Classes.GetTypeByName("ACF.Engines.5.7-V8")

        Contraption.SetModel(self, Engine.Model)

        duplicator.ClearEntityModifier(self, "mass")
    end

    function ENT.ACF_CheckSpawnLimit(Player)
        return Player:CheckLimit("_acf_engine")
    end

    function ENT:ACF_PreUpdateEntityData()
        -- Don't reconfigure a running engine; shut it down first (no-op on a fresh spawn).
        if self.Active then self:Disable() end
    end

    function ENT:ACF_PostUpdateEntityData()
        UpdateEngine(self, self:GetEngine())

        -- A reconfigure can invalidate existing links (no-op on a fresh spawn).
        if next(self.Gearboxes) then
            for Gearbox in pairs(self.Gearboxes) do
                self:Unlink(Gearbox)
                self:Link(Gearbox)
            end
        end

        -- Supported fuel types may have changed (no-op on a fresh spawn, which isn't parented yet)
        if self.ACF_FuelParent then Fuel.Join(self) end
    end

    function ENT:PreEntityCopy()
        if next(self.Gearboxes) then
            local Gearboxes = {}

            for Gearbox in pairs(self.Gearboxes) do
                Gearboxes[#Gearboxes + 1] = Gearbox:EntIndex()
            end

            duplicator.StoreEntityModifier(self, "ACFGearboxes", Gearboxes)
        end

        -- AutoRegisterV2 wraps this as the original PreEntityCopy and handles the wire/base dupe info.
    end

    function ENT:PostEntityPaste(_, Ent, CreatedEntities)
        local EntMods = Ent.EntityMods

        -- Backwards compatibility
        if EntMods.GearLink then
            local Entities = EntMods.GearLink.entities

            for _, EntID in ipairs(Entities) do
                self:Link(CreatedEntities[EntID])
            end

            EntMods.GearLink = nil
        end

        -- Fuel tanks are found through shared parents now; drop old link data
        EntMods.FuelLink     = nil
        EntMods.ACFFuelTanks = nil

        if EntMods.ACFGearboxes then
            for _, EntID in ipairs(EntMods.ACFGearboxes) do
                self:Link(CreatedEntities[EntID])
            end

            EntMods.ACFGearboxes = nil
        end

        -- AutoRegisterV2 wraps this as the original PostEntityPaste and handles the wire/base dupe info.
    end

    function ENT:GetCost()
        local selftbl = self:GetTable()

        return 5 + selftbl.PeakPower / ACF.EngineKwPerPoint
    end

    -- Remove-only teardown. Captured by AutoRegisterV2 as OrigOnRemove; the generated OnRemove still runs
    -- ACF_OnEntityLast + WireLib cleanup around this.
    function ENT:OnRemove(IsFullUpdate)
        if IsFullUpdate then return end

        local Class = self.ClassData

        if Class and Class.OnLast then
            Class.OnLast(self, Class)
        end

        self:DestroySound()

        for Gearbox in pairs(self.Gearboxes) do
            self:Unlink(Gearbox)
        end

        Fuel.Leave(self)

        TimerRemove("ACF Engine Clock " .. self:EntIndex())
    end

    ACF.RegisterLinkSource("acf_engine", "FuelTanks")
    ACF.RegisterLinkSource("acf_engine", "Gearboxes")
end

