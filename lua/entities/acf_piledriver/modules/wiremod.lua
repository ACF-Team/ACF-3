local ACF = ACF

ACF.AddInputAction("acf_piledriver", "Fire", function(Entity, Value)
    Entity.Firing = tobool(Value)

    Entity:Shoot()
end)

local Text  = "Spike Velocity: %s m/s\nSpike Length: %s cm\nSpike Mass: %s"
local Empty = "▯"
local Full  = "▮"

local function GetChargeBar(Percentage)
    local Bar = ""

    for I = 0.05, 0.95, 0.1 do
        Bar = Bar .. (I <= Percentage and Full or Empty)
    end

    return Bar
end

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
    State:AddTimeLeft("Recharge State", CurTime() + ((1 / Rate) - (self.SingleCharge / Rate)), 1 / Rate)
    State:AddNumber("Recharge Rate", Rate, " charges/s")
    State:AddNumber("Rate of Fire", RoF, " RPM")
    State:AddNumber("Max Penetration", MaxPen, " mm")
    State:AddNumber("Spike Velocity", MuzVel, " m/s")
    State:AddNumber("Spike Length", Length, " cm")
    State:AddNumber("Spike Mass", Mass)

    -- return Text:format(self.State, Current, Total, Shots, Percent, State, Rate, RoF, MaxPen, MuzVel, Length, Mass)
end