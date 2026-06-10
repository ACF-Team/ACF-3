local ACF       = ACF
local Types     = ACF.Classes.ArmorTypes

-- Density stored in kg/cm^3
-- HealthMul  : multiplier on volume-derived health pool (toughness beyond density)
-- KineticMul : RHA equivalent multiplier vs kinetic (AP) threats
-- ChemicalMul: RHA equivalent multiplier vs chemical energy (HEAT/shaped charge) threats


-- Aluminum
local Armor = Types.Register("Aluminum")
function Armor:OnLoaded()
    self.Name        = "Aluminum"
    self.Description = "Lightweight but weak armor."
    self.Density     = 2.7e-3
    self.HealthMul   = 0.8
    self.KineticMul  = 0.5
    self.ChemicalMul = 0.6
end

-- RHA
local Armor = Types.Register("RHA")
function Armor:OnLoaded()
    self.Name        = "RHA"
    self.Description = "Rolled Homogeneous Armor, balanced protection."
    self.Density     = 7.84e-3
    self.HealthMul   = 1.0
    self.KineticMul  = 1.0
    self.ChemicalMul = 1.0
end

-- Rubber
local Armor = Types.Register("Rubber")
function Armor:OnLoaded()
    self.Name        = "Rubber"
    self.Description = "Flexible but offers minimal protection."
    self.Density     = 1.5e-3
    self.HealthMul   = 1.5
    self.KineticMul  = 0.2
    self.ChemicalMul = 0.3
end

-- Textolite
local Armor = Types.Register("Textolite")
function Armor:OnLoaded()
    self.Name        = "Textolite"
    self.Description = "Composite material, good for lightweight applications."
    self.Density     = 1.8e-3
    self.HealthMul   = 1.0
    self.KineticMul  = 0.4
    self.ChemicalMul = 0.5
end

-- Tungsten
local Armor = Types.Register("Tungsten")
function Armor:OnLoaded()
    self.Name        = "Tungsten"
    self.Description = "Very dense and strong, but heavy."
    self.Density     = 19.25e-3
    self.HealthMul   = 0.7
    self.KineticMul  = 1.5
    self.ChemicalMul = 1.2
end

-- DU
local Armor = Types.Register("DU")
function Armor:OnLoaded()
    self.Name        = "Depleted Uranium"
    self.Description = "Extremely dense with high protection."
    self.Density     = 18.7e-3
    self.HealthMul   = 0.9
    self.KineticMul  = 1.3
    self.ChemicalMul = 1.1
end

-- Light ERA
local Armor = Types.Register("LightERA")
function Armor:OnLoaded()
    self.Name        = "Light ERA"
    self.Description = "Explosive Reactive Armor, effective against shaped charges."
    self.Density     = 5e-3
    self.HealthMul   = 0.5
    self.KineticMul  = 0.3
    self.ChemicalMul = 3.0
end

-- Heavy ERA
local Armor = Types.Register("HeavyERA")
function Armor:OnLoaded()
    self.Name        = "Heavy ERA"
    self.Description = "Heavy Explosive Reactive Armor, offers some protection against kinetic threats too."
    self.Density     = 10e-3
    self.HealthMul   = 0.6
    self.KineticMul  = 0.6
    self.ChemicalMul = 2.0
end

-- Flesh
local Armor = Types.Register("Flesh")
function Armor:OnLoaded()
    self.Name        = "Flesh"
    self.Description = "Soft biological tissue."
    self.Density     = 1.0e-3
    self.HealthMul   = 0.5
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.1
    self.SuppressLoad = true
end
