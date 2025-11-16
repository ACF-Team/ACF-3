local ACF       = ACF

function ENT:ACF_Activate(Recalc)
    local PhysObj = self.ACF.PhysObj
    local Area    = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
    local Armour  = self.Caliber * ACF.ArmorMod
    local Health  = Area / ACF.Threshold
    local Percent = 1

    if Recalc and self.ACF.Health and self.ACF.MaxHealth then
        Percent = self.ACF.Health / self.ACF.MaxHealth
    end

    self.ACF.Area      = Area
    self.ACF.Health    = Health * Percent
    self.ACF.MaxHealth = Health
    self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
    self.ACF.MaxArmour = Armour
    self.ACF.Type      = "Prop"
    self.ACF.Ductility = 0
end