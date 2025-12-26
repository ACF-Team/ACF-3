local ACF = ACF

ACF.AddInputAction("acf_piledriver", "Fire", function(Entity, Value)
    Entity.Firing = tobool(Value)

    Entity:Shoot()
end)

-------------------------------------------------------------------------------

ENT.OverlayDelay = 0.1

function ENT:ACF_UpdateOverlayState(State)
    local Current = self.CurrentShot
    local Total   = self.MagSize
    local Rate    = self.ChargeRate
    local RoF     = self.Cyclic * 60
    local Bullet  = self.BulletData
    local Display = self.RoundData:GetDisplayData(Bullet)
    local MaxPen  = math.Round(Display.MaxPen, 2)
    local Mass    = ACF.GetProperMass(Bullet.ProjMass)
    local MuzVel  = math.Round(Bullet.MuzzleVel, 2)
    local Length  = Bullet.ProjLength

    State:AddLabel(self.State)
    State:AddProgressBar("Charges Left", Current, Total)
    State:AddTimeLeft("Recharge State", CurTime() + ((1 / Rate) - (self.SingleCharge / Rate)), 1 / Rate, true)
    State:AddNumber("Recharge Rate", Rate, " charges/s")
    State:AddNumber("Rate of Fire", RoF, " RPM")
    State:AddNumber("Max Penetration", MaxPen, " mm")
    State:AddNumber("Spike Velocity", MuzVel, " m/s")
    State:AddNumber("Spike Length", Length, " cm")
    State:AddKeyValue("Spike Mass", Mass)
end