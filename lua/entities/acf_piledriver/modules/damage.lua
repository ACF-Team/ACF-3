local ACF       = ACF
local Sounds    = ACF.Utilities.Sounds
local Impact    = "physics/metal/metal_barrel_impact_hard%s.wav"

-- The entity won't even attempt to shoot if this function returns false
function ENT:AllowShoot()
    if self.Disabled then return false end
    if self.RetryShoot then return false end

    return self.Firing
end

-- The entity should produce a "click" sound if this function returns false
function ENT:CanShoot()
    if not ACF.GunsCanFire then return false end
    if not ACF.AllowFunEnts then return false end
    if self.CurrentShot == 0 then return false end

    local CanFire = hook.Run("ACF_PreFireWeapon", self)

    return CanFire
end

function ENT:Shoot()
    if not self:AllowShoot() then return end

    local Delay = self.Cyclic

    if self:CanShoot() then
        local Sound  = self.SoundPath or Impact:format(math.random(5, 6))
        local Pitch  = self.SoundPitch and math.Clamp(self.SoundPitch * 100, 0, 255) or math.Rand(98, 102)
        local Volume = self.SoundVolume or 1
        local Bullet = self.BulletData

        if Sound ~= "" then
            Sounds.SendSound(self, Sound, 70, Pitch, Volume)
        end
        self:SetSequence("load")

        Bullet.Owner  = self:GetUser(self.Inputs.Fire.Src) -- Must be updated on every shot
        Bullet.Pos    = self:LocalToWorld(self.Muzzle)
        Bullet.Flight = self:GetForward() * Bullet.MuzzleVel * ACF.MeterToInch

        self.RoundData:Create(self, Bullet)

        self:Consume()
        self:SetState("Loading")

        self.Loading = true

        timer.Simple(0.35, function()
            if not IsValid(self) then return end

            self:SetSequence("idle")
        end)
    else
        Sounds.SendSound(self, "weapons/pistol/pistol_empty.wav", 70, math.Rand(98, 102), 1)

        Delay = 1
    end

    if not self.RetryShoot then
        self.RetryShoot = true

        timer.Simple(Delay, function()
            if not IsValid(self) then return end

            self.RetryShoot = nil

            if self.Loading then
                self.Loading = nil

                if self.CurrentShot > 0 then
                    self:SetState("Loaded")
                end
            end

            self:Shoot()
        end)
    end
end
