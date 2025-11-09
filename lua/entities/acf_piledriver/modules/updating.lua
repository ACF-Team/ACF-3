local ACF         = ACF
local Classes     = ACF.Classes
local Piledrivers = Classes.Piledrivers
local Contraption = ACF.Contraption
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock

function ENT:ACF_PreUpdateEntityData(Data)
    local Class = Piledrivers.Get(Data.Weapon)
    local Caliber = Data.Caliber
    local Scale   = Caliber / Class.Caliber.Base

    self.ACF.Model = Class.Model -- Must be set before changing model

    self:SetScaledModel(Class.Model)
    self:SetScale(Scale)
end

function ENT:ACF_PostUpdateEntityData(Data)
    local Class = Piledrivers.Get(Data.Weapon)
    local Caliber = Data.Caliber
    local Scale   = Caliber / Class.Caliber.Base
    local Mass    = math.floor(Class.Mass * Scale)

    self.Name        = Caliber .. "mm " .. Class.Name
    self.ShortName   = Caliber .. "mm" .. Class.ID
    self.EntType     = Class.Name
    self.ClassData   = Class
    self.Caliber     = Caliber
    self.Cyclic      = 60 / Class.Cyclic
    self.MagSize     = Class.MagSize or 1
    self.ChargeRate  = Class.ChargeRate or 0.1
    self.SpikeLength = Class.Round.MaxLength * Scale
    self.Muzzle      = self:WorldToLocal(self:GetAttachment(self:LookupAttachment("muzzle")).Pos)

    WireLib.TriggerOutput(self, "Reload Time", self.Cyclic)
    WireLib.TriggerOutput(self, "Rate of Fire", 60 / self.Cyclic)

    do -- Updating bulletdata
        local Ammo = self.RoundData

        Data.AmmoType   = "HP"
        Data.Projectile = self.SpikeLength
        Data.Destiny    = "Piledrivers" -- Required for duping to work right

        Ammo.SpikeLength = self.SpikeLength
        local BulletData  = Ammo:ServerConvert(Data)
        BulletData.Crate  = self:EntIndex()
        BulletData.Filter = { self }
        BulletData.Gun    = self
        BulletData.Hide   = true

        -- Bullet dies on the next tick
        function BulletData:PreCalcFlight()
            if self.KillTime then return end
            if not self.DeltaTime then return end
            if self.LastThink == Clock.CurTime then return end

            self.KillTime = Clock.CurTime
        end

        function BulletData:OnEndFlight(Trace)
            if not ACF.RecoilPush then return end
            if not IsValid(self) then return end
            if not Trace.HitWorld then return end
            if Trace.Fraction == 0 then return end

            local Fraction   = 1 - Trace.Fraction
            local MassCenter = self:LocalToWorld(self:GetPhysicsObject():GetMassCenter())
            local Energy     = self.ProjMass * self.MuzzleVel * ACF.MeterToInch * Fraction

            ACF.KEShove(self, MassCenter, -self:GetForward(), Energy)
        end

        self.BulletData = BulletData

        if Ammo.OnFirst then
            Ammo:OnFirst(self)
        end

        hook.Run("ACF_OnAmmoFirst", Ammo, self, Data, Class)

        Ammo:Network(self, self.BulletData)

        WireLib.TriggerOutput(self, "Spike Mass", math.Round(BulletData.ProjMass * 1000, 2))
        WireLib.TriggerOutput(self, "Muzzle Velocity", math.Round(BulletData.MuzzleVel * ACF.Scale, 2))
    end

    -- Set NWvars
    self:SetNWString("WireName", "ACF " .. self.Name)

    ACF.Activate(self, true)

    Contraption.SetMass(self, Mass)
end