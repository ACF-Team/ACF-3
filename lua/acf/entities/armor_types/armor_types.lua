local ACF       = ACF
local Types     = ACF.Classes.ArmorTypes

-- Density stored in kg/cm^3
-- Cost       : points per cm^3
-- HealthMul  : multiplier on volume-derived health pool (toughness beyond density)
-- KineticMul : RHA equivalent multiplier vs kinetic (AP) threats
-- ChemicalMul: RHA equivalent multiplier vs chemical energy (HEAT/shaped charge) threats
-- SpallMul   : multiplier on spall fragment mass produced when this material is penetrated

-- Default special type. Does not set mass, but abysmal for armor usage
local Armor = Types.Register("Default")
function Armor:OnLoaded()
    self.Name        = "Default"
    self.Description = "Does not set mass, used for default props."
    self.SuppressLoad = true
    self.Density     = 1e-4
    self.Cost        = 2.21e-6
    self.HealthMul   = 1
    self.KineticMul  = 1e-4
    self.ChemicalMul = 1e-4
    self.SpallMul    = 1e-4
end

-- Flesh
local Armor = Types.Register("Flesh")
function Armor:OnLoaded()
    self.Name        = "Flesh"
    self.Description = "Soft tissue found in crew"
    self.Density     = 1.1e-3 -- https://www.sciencedirect.com/topics/immunology-and-microbiology/body-density
    self.Cost        = 5e-6
    self.HealthMul   = 0.3
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.1
    self.SpallMul    = 1.5
end

-- Diesel
local Armor = Types.Register("Diesel")
function Armor:OnLoaded()
    self.Name        = "Diesel"
    self.Description = "Diesel fuel, provides no real protection and poses a fire risk when penetrated."
    self.Density     = 0.745e-3 -- lua/acf/entities/fuel_types/diesel.lua (0.745 kg/L)
    self.Cost        = 2e-6
    self.HealthMul   = 0.05
    self.KineticMul  = 0.02
    self.ChemicalMul = 0.02
    self.SpallMul    = 1.5
end

-- Petrol
local Armor = Types.Register("Petrol")
function Armor:OnLoaded()
    self.Name        = "Petrol"
    self.Description = "Petrol fuel, provides no real protection and is highly flammable when penetrated."
    self.Density     = 0.832e-3 -- lua/acf/entities/fuel_types/petrol.lua (0.832 kg/L)
    self.Cost        = 2.2e-6
    self.HealthMul   = 0.05
    self.KineticMul  = 0.02
    self.ChemicalMul = 0.02
    self.SpallMul    = 2.0
end

-- Li-Ion
local Armor = Types.Register("LiIon")
function Armor:OnLoaded()
    self.Name        = "Li-Ion Battery"
    self.Description = "Lithium-ion battery cells, fragile and prone to thermal runaway when penetrated."
    self.Density     = 3.89e-3 -- lua/acf/entities/fuel_types/electric.lua (3.89 kg/L)
    self.Cost        = 5e-5
    self.HealthMul   = 0.2
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.1
    self.SpallMul    = 1.8
end

-- Aluminum
local Armor = Types.Register("Aluminum")
function Armor:OnLoaded()
    self.Name        = "Aluminum"
    self.Description = "Lightweight but weak armor."
    self.Density     = 2.7e-3 -- https://en.wikipedia.org/wiki/Aluminium
    self.Cost        = 1.79e-5
    self.HealthMul   = 0.8
    self.KineticMul  = 0.5
    self.ChemicalMul = 0.6
    self.SpallMul    = 0.5
end

-- RHA
local Armor = Types.Register("RHA")
function Armor:OnLoaded()
    self.Name        = "RHA"
    self.Description = "Rolled Homogeneous Armor, balanced protection."
    self.Density     = 7.84e-3 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    self.Cost        = 3.92e-5 -- Reference: 0.005 points/kg
    self.HealthMul   = 1.0
    self.KineticMul  = 1.0
    self.ChemicalMul = 1.0
    self.SpallMul    = 1.0
end

-- Rubber
local Armor = Types.Register("Rubber")
function Armor:OnLoaded()
    self.Name        = "Rubber"
    self.Description = "Flexible but offers minimal protection."
    self.Density     = 1.5e-3 -- * https://rubberandseal.com/what-is-the-density-of-rubber-sheets/
    self.Cost        = 1.16e-5
    self.HealthMul   = 1.5
    self.KineticMul  = 0.2
    self.ChemicalMul = 0.3
    self.SpallMul    = 0.5
end

-- Textolite
local Armor = Types.Register("Textolite")
function Armor:OnLoaded()
    self.Name        = "Textolite"
    self.Description = "Composite material, good for lightweight applications."
    self.Density     = 1.8e-3 -- * http://www.china-anza.com/2-1-7-textolite-3025.html
    self.Cost        = 1.47e-5
    self.HealthMul   = 1.0
    self.KineticMul  = 0.4
    self.ChemicalMul = 0.5
    self.SpallMul    = 0.6
end

-- Tungsten
local Armor = Types.Register("Tungsten")
function Armor:OnLoaded()
    self.Name        = "Tungsten"
    self.Description = "Very dense and strong, but heavy."
    self.Density     = 19.25e-3 -- https://en.wikipedia.org/wiki/Tungsten
    self.Cost        = 7.22e-5
    self.HealthMul   = 0.7
    self.KineticMul  = 1.5
    self.ChemicalMul = 1.2
    self.SpallMul    = 0.8
end

-- DU
local Armor = Types.Register("DU")
function Armor:OnLoaded()
    self.Name        = "Depleted Uranium"
    self.Description = "Extremely dense with high protection."
    self.Density     = 18.7e-3 -- https://pubmed.ncbi.nlm.nih.gov/11218253/
    self.Cost        = 6.93e-5
    self.HealthMul   = 0.9
    self.KineticMul  = 1.3
    self.ChemicalMul = 1.1
    self.SpallMul    = 1.0
end

-- Light ERA
local Armor = Types.Register("LightERA")
function Armor:OnLoaded()
    self.Name        = "Light ERA"
    self.Description = "Explosive Reactive Armor, effective against shaped charges."
    self.Density     = 5e-3 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    self.Cost        = 3.97e-5
    self.HealthMul   = 0.5
    self.KineticMul  = 0.3
    self.ChemicalMul = 3.0
    self.SpallMul    = 0.2
end

-- Heavy ERA
local Armor = Types.Register("HeavyERA")
function Armor:OnLoaded()
    self.Name        = "Heavy ERA"
    self.Description = "Heavy Explosive Reactive Armor, offers some protection against kinetic threats too."
    self.Density     = 10e-3 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    self.Cost        = 4.71e-5
    self.HealthMul   = 0.6
    self.KineticMul  = 0.6
    self.ChemicalMul = 2.0
    self.SpallMul    = 0.3
end