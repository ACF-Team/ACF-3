-- RHA Steel (MIL-DTL-12560)
-- https://www.alternatewars.com/BBOW/Ballistics/Term/Armor_Material.htm

local ACF   = ACF
local Types = ACF.Classes.ArmorTypes
local Armor = Types.Register("RHA")

-- Length (mm), Density(g/cm3)
function ACF.RHAe(Length, Density)
	return Length * (Density / 7.84)
end

function Armor:OnLoaded()
	self.Name		 = "Rolled Homogenous Armor"
	self.Density     = 7.84 -- g/cm3
	self.Tensile     = 1111
	self.Description = "The standard of durability and weight."
end

function Armor:GetMass(Volume)
	return Volume * self.Density * ACF.gCmToKgIn
end