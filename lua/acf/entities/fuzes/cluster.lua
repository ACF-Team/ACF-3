local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.Fuze.Cluster", "ACF.Missiles.Fuze.Optical", function(CLASS, BASE)
    CLASS.Name = "Cluster"
    CLASS.Description = "This fuze fires a beam directly ahead and releases bomblets when the beam hits something close by. Distance in inches."

    CLASS.Spread = 30
    CLASS.MinDistance = 500
    CLASS.MaxDistance = 5000
    CLASS.MinBomblets = 1
    CLASS.MaxBomblets = 30

    if CLIENT then
        local ClusterText = "Bomblets : %s\n"

        function CLASS:AddMenuControls(Base, ToolData, Ammo, BulletData, ...)
            BASE.AddMenuControls(self, Base, ToolData, Ammo, BulletData, ...)

            local Bomblets = math.Clamp(math.floor(BulletData.ProjMass / BulletData.Caliber), self.MinBomblets, self.MaxBomblets)
            Base:AddLabel(ClusterText:format(Bomblets))
        end
    else
        function CLASS:PrepareBullet(BulletData)
            local Caliber  = BulletData.Caliber
            local ProjMass = BulletData.ProjMass
            local Rows     = math.max(1, math.floor(ProjMass / Caliber))
            local Count    = math.Clamp(Rows, self.MinBomblets, self.MaxBomblets)

            local BombletData = table.Copy(BulletData)

            BombletData.WeaponType = "ACF.Guns.Cannon"
            BombletData.Caliber    = Caliber
            BombletData.PropMass   = 0
            BombletData.Bomblets   = Count

            -- Split every mass so the cluster carries the same total as the parent shell
            for _, Key in ipairs({ "ProjMass", "FillerMass", "BoomFillerMass", "CasingMass", "LinerMass", "JetMass" }) do
                if BombletData[Key] then
                    BombletData[Key] = BombletData[Key] / Count
                end
            end

            if BombletData.ProjMass and BombletData.ProjArea then
                BombletData.DragCoef = BombletData.ProjArea * 0.0001 / BombletData.ProjMass
            end

            BombletData.CartMass = BombletData.ProjMass -- No propellant

            -- HEAT: jet breakup scales with JetMass^(1/3), jet velocities stay the same
            if BombletData.BreakupTime then
                local Scale = Count ^ (-1 / 3)

                BombletData.BreakupTime = BombletData.BreakupTime * Scale
                BombletData.BreakupDist = BombletData.BreakupDist * Scale

                if BombletData.JetMass then
                    BombletData.JetArea = (BombletData.JetMass / ACF.CopperDensity) / (BombletData.BreakupDist * 100)
                end
            end

            return BombletData
        end

        function CLASS:HandleDetonation(Entity, BulletData)
            local RoundData = Entity.RoundData
            if not RoundData then return end

            local Bullet      = self:PrepareBullet(BulletData)
            local Bomblets    = Bullet.Bomblets
            local Velocity    = BulletData.Flight

            Bullet.Crate  = BulletData.Crate
            Bullet.Owner  = BulletData.Owner
            Bullet.Gun    = BulletData.Gun
            Bullet.Pos    = BulletData.Pos
            Bullet.Flight = Velocity
            Bullet.Filter = BulletData.Filter

            RoundData:Network(Entity, Bullet)

            local EffectTable = {
                Origin = Entity.Position,
                Normal = Entity.CurDir,
                Scale  = math.max(Bomblets ^ 0.33 * ACF.MeterToInch, 1),
            }
            ACF.Utilities.Effects.CreateEffect("ACF_Explosion", EffectTable)

            for _ = 1, Bomblets do
                local Cone = math.tan(math.rad(self.Spread * ACF.GunInaccuracyScale))
                local Spread = (Entity:GetUp() * math.Rand(-1, 1) + Entity:GetRight() * math.Rand(-1, 1)):GetNormalized()
                local ShootDir = (Velocity:GetNormalized() + Cone * Spread * (math.random() ^ (1 / ACF.GunInaccuracyBias))):GetNormalized()

                Bullet.Flight = ShootDir * Velocity:Length()

                RoundData:Create(Entity, Bullet)
            end
        end
    end
end)