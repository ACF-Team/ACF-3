local ACF         = ACF
local Classes     = ACF.Classes
local Contraption = ACF.Contraption
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock
local AmmoTypes   = Classes.AmmoTypes

local DefaultType = "ACF.Piledrivers.Piledriver"

do -- Spawning
    function ENT:ACF_PreSpawn(_, _, _, Data)
        self.ACF = {}

        local Weapon = Data.Weapon
        local Class  = Classes.GetTypeByName(Weapon and Weapon.Type or DefaultType) or Classes.GetTypeByName(DefaultType)

        self:SetScaledModel(Class.Model)
    end

    function ENT:ACF_OnSpawn(_)
        local AmmoType = AmmoTypes.Get("ACF.Ammunition.HP")

        self.RoundData    = AmmoType()
        self.LastThink    = Clock.CurTime
        self.State        = "Loading"
        self.Firing       = false
        self.Charge       = 0
        self.SingleCharge = 0
        self.CurrentShot  = 0
    end

    function ENT:ACF_PostSpawn()
        WireLib.TriggerOutput(self, "State", "Loading")
    end
end

do -- Updating
    function ENT:ACF_PostUpdateEntityData()
        local Weapon  = self:ACF_GetUserVar("Weapon")
        local Class   = Weapon:GetType()
        local Caliber = Weapon.Caliber or Weapon.BaseCaliber
        local Scale   = Caliber / Weapon.BaseCaliber
        local Mass    = math.floor(Weapon.Mass * Scale)

        self.ACF.Model = Weapon.Model -- Must be set before changing model

        self:SetScaledModel(Weapon.Model)
        self:SetScale(Scale)

        self.Name        = Caliber .. "mm " .. Weapon.Name
        self.ShortName   = Caliber .. "mm" .. Weapon.ShortName
        self.EntType     = Weapon.Name
        self.ClassData   = Class
        self.Caliber     = Caliber
        self.Cyclic      = 60 / Weapon.Cyclic
        self.MagSize     = Weapon.MagSize or 1
        self.ChargeRate  = Weapon.ChargeRate or 0.1
        self.SpikeLength = Weapon.Round.MaxLength * Scale
        self.Muzzle      = self:WorldToLocal(self:GetAttachment(self:LookupAttachment("muzzle")).Pos)

        WireLib.TriggerOutput(self, "Reload Time", self.Cyclic)
        WireLib.TriggerOutput(self, "Rate of Fire", 60 / self.Cyclic)

        do -- Updating bulletdata
            local Ammo = self.RoundData

            -- The round pipeline resolves specs from the weapon class' name (see GetWeaponSpecs),
            -- so we hand it a flat, legacy-shaped tool data table rather than the entity's nested data.
            local RoundData = {
                Weapon     = Classes.GetTypeName(Class),
                Caliber    = Caliber,
                Destiny    = "Piledrivers",
                AmmoType   = "ACF.Ammunition.HP",
                Projectile = self.SpikeLength,
                Propellant = 0,
            }

            Ammo.SpikeLength = self.SpikeLength
            local BulletData  = Ammo:ServerConvert(RoundData)
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

            hook.Run("ACF_OnAmmoFirst", Ammo, self, RoundData, Class)

            Ammo:Network(self, self.BulletData)

            WireLib.TriggerOutput(self, "Spike Mass", math.Round(BulletData.ProjMass * 1000, 2))
            WireLib.TriggerOutput(self, "Muzzle Velocity", math.Round(BulletData.MuzzleVel * ACF.Scale, 2))
        end

        -- Set NWvars
        self:SetNWString("WireName", "ACF " .. self.Name)

        ACF.Activate(self, true)

        Contraption.SetMass(self, Mass)
    end
end
