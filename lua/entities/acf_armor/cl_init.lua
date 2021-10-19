include("shared.lua")

local Armors = ACF.Classes.ArmorTypes

function ENT:Update()
    local Armor = Armors[self:GetNW2String("ArmorType", "RHA")]

    self.ArmorClass = Armor
    self.ArmorType  = Armor.ID print(self.ArmorType)
    self.Tensile    = Armor.Tensile
    self.Density    = Armor.Density
end
