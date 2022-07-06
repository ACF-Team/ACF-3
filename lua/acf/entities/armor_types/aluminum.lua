-- 6061 Alumunium alloy
-- https://en.wikipedia.org/wiki/6061_aluminium_alloy

local Types = ACF.Classes.ArmorTypes
local Armor = Types.Register("Aluminum", "RHA")

function Armor:OnLoaded()
	self.Name		 = "6061 Aluminum"
	self.Density     = 2.7 -- g/cm3
	self.Tensile     = 207
	self.Description = "Less dense than steel at the expense of durability."
end