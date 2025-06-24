include("shared.lua")

local Armors = ACF.Classes.ArmorTypes

function ENT:Update()
    local Name  = self:GetNW2String("ArmorType", "RHA")
    local Armor = Armors.Get(Name)

    self.ArmorClass = Armor
    self.ArmorType  = Armor.ID
    self.Tensile    = Armor.Tensile
    self.Density    = Armor.Density
end
