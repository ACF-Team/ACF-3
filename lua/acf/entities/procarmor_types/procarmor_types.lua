local ACF       = ACF
local Types     = ACF.Classes.ProcArmorTypes

-- Aluminum
local Armor = Types.Register("Aluminum")
function Armor:OnLoaded()
    self.Name = "Aluminum"
    self.Description = "Lightweight but weak armor."
end

-- RHA
local Armor = Types.Register("RHA")
function Armor:OnLoaded()
    self.Name = "RHA"
    self.Description = "Rolled Homogeneous Armor, balanced protection."
end

-- Rubber
local Armor = Types.Register("Rubber")
function Armor:OnLoaded()
    self.Name = "Rubber"
    self.Description = "Flexible but offers minimal protection."
end

-- Tungsten
local Armor = Types.Register("Tungsten")
function Armor:OnLoaded()
    self.Name = "Tungsten"
    self.Description = "Very dense and strong, but heavy."
end

-- DU
local Armor = Types.Register("DU")
function Armor:OnLoaded()
    self.Name = "Depleted Uranium"
    self.Description = "Extremely dense with high protection."
end