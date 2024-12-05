include("shared.lua")

local Armors = ACF.Classes.ArmorTypes

language.Add("Cleanup_acf_armor", "ACF Armor Plates")
language.Add("Cleaned_acf_armor", "Cleaned up all ACF armor plates!")
language.Add("SBoxLimit__acf_armor", "You've reached the ACF armor plates limit!")

function ENT:Update()
    local Name  = self:GetNW2String("ArmorType", "RHA")
    local Armor = Armors.Get(Name)

    self.ArmorClass = Armor
    self.ArmorType  = Armor.ID
    self.Tensile    = Armor.Tensile
    self.Density    = Armor.Density
end
