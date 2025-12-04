local ACF = ACF

ACF.AddInputAction("acf_piledriver", "Fire", function(Entity, Value)
    Entity.Firing = tobool(Value)

    Entity:Shoot()
end)

local Text  = "%s\n\nCharges Left:\n%s / %s\n[%s]\n\nRecharge State:\n%s%%\n[%s]\n\nRecharge Rate: %s charges/s\nRate of Fire: %s rpm\n\nMax Penetration: %s mm\nSpike Velocity: %s m/s\nSpike Length: %s cm\nSpike Mass: %s"
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

function ENT:UpdateOverlayText()
    local Shots   = GetChargeBar(self.Charge / self.MagSize)
    local State   = GetChargeBar(self.SingleCharge)
    local Current = self.CurrentShot
    local Total   = self.MagSize
    local Percent = math.floor(self.SingleCharge * 100)
    local Rate    = self.ChargeRate
    local RoF     = self.Cyclic * 60
    local Bullet  = self.BulletData
    local Display = self.RoundData:GetDisplayData(Bullet)
    local MaxPen  = math.Round(Display.MaxPen, 2)
    local Mass    = ACF.GetProperMass(Bullet.ProjMass)
    local MuzVel  = math.Round(Bullet.MuzzleVel, 2)
    local Length  = Bullet.ProjLength

    return Text:format(self.State, Current, Total, Shots, Percent, State, Rate, RoF, MaxPen, MuzVel, Length, Mass)
end