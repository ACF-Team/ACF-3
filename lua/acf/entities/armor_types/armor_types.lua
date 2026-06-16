local ACF       = ACF
local Types     = ACF.Classes.ArmorTypes

-- Density stored in kg/m^3
-- CostMul    : points per m^3
-- HealthMul  : health pool per unit volume
-- KineticMul : RHA equivalent multiplier vs kinetic (AP) threats
-- ChemicalMul: RHA equivalent multiplier vs chemical energy (HEAT/shaped charge) threats
-- SpallMul   : multiplier on spall fragment mass produced when this material is penetrated

-- Explosive Reactive Armor (optional, only set on reactive types):
-- IsExplosive       : marks the material as reactive; convexes detonate when penetrated with enough kinetic energy
-- ExplosiveThreshold: kinetic energy (KJ) a penetrating round must carry to set off the reactive charge
-- ExplosiveFiller   : fraction of the convex's mass that detonates as HE filler when triggered

-- Default special type. Does not set mass, but abysmal for armor usage
local Armor = Types.Register("Default")
function Armor:OnLoaded()
    self.Name        = "Default"
    self.Description = "Used as a default material for entities. Not intended to provide any protection."
    self.SuppressLoad = true
    self.Density     = 100
    self.CostMul     = 2.21
    self.HealthMul   = 10
    self.KineticMul  = 1e-4
    self.ChemicalMul = 1e-4
    self.SpallMul    = 1e-4
end

-- Flesh
local Armor = Types.Register("Flesh")
function Armor:OnLoaded()
    self.Name        = "Flesh"
    self.Description = "Soft tissue, used to represent crew members. Lab-grown for your convenience."
    self.Density     = 1100 -- https://www.sciencedirect.com/topics/immunology-and-microbiology/body-density
    self.CostMul     = 5
    self.HealthMul   = 33
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.1
    self.SpallMul    = 0.2
end

-- Diesel
local Armor = Types.Register("Diesel")
function Armor:OnLoaded()
    self.Name        = "Diesel"
    self.Description = "Diesel fuel, provides some protection against shaped charges. Doesn't explode, unlike petrol and Li-Ion batteries."
    self.SuppressLoad = true
    self.Density     = 745 -- lua/acf/entities/fuel_types/diesel.lua (0.745 kg/L)
    self.CostMul     = 2
    self.HealthMul   = 5
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.3
    self.SpallMul    = 0.1
end

-- Petrol
local Armor = Types.Register("Petrol")
function Armor:OnLoaded()
    self.Name        = "Petrol"
    self.Description = "Petrol fuel, provides negligible protection. Prone to detonate when penetrated or damaged."
    self.SuppressLoad = true
    self.Density     = 832 -- lua/acf/entities/fuel_types/petrol.lua (0.832 kg/L)
    self.CostMul     = 2.3
    self.HealthMul   = 4
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.1
    self.SpallMul    = 0.1
end

-- Li-Ion
local Armor = Types.Register("LiIon")
function Armor:OnLoaded()
    self.Name        = "Li-Ion Battery"
    self.Description = "Lithium-ion battery cells. Prone to detonate when penetrated or damaged."
    self.SuppressLoad = true
    self.Density     = 3890 -- lua/acf/entities/fuel_types/electric.lua (3.89 kg/L)
    self.CostMul     = 8
    self.HealthMul   = 2
    self.KineticMul  = 0.3
    self.ChemicalMul = 0.3
    self.SpallMul    = 0.5
end

-- Aluminum
local Armor = Types.Register("Aluminum")
function Armor:OnLoaded()
    self.Name        = "Aluminum"
    self.Description = "Decent protection for its price and density."
    self.Density     = 2700 -- https://en.wikipedia.org/wiki/Aluminium
    self.CostMul     = 17.9
    self.HealthMul   = 216
    self.KineticMul  = 0.5
    self.ChemicalMul = 0.6
    self.SpallMul    = 0.5
end

-- RHA
local Armor = Types.Register("RHA")
function Armor:OnLoaded()
    self.Name        = "RHA"
    self.Description = "Rolled Homogeneous Armor. The standard by which all other armor types are measured."
    self.Density     = 7840 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    self.CostMul     = 39.2 -- Reference: 0.005 points/kg
    self.HealthMul   = 784
    self.KineticMul  = 1.0
    self.ChemicalMul = 1.0
    self.SpallMul    = 1.0
end

-- Gun Steel
local Armor = Types.Register("GunSteel")
function Armor:OnLoaded()
    self.Name        = "Gun Steel"
    self.Description = "Material intended to represent guns. Much healthier than components, but worse in protection per unit volume for balance reasons."
    self.SuppressLoad = true
    self.Density     = 7840 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    self.CostMul     = 39.2
    self.HealthMul   = 1568
    self.KineticMul  = 0.7
    self.ChemicalMul = 0.7
    self.SpallMul    = 1.0
end

-- Component Material
local Armor = Types.Register("Component")
function Armor:OnLoaded()
    self.Name        = "Component Material"
    self.Description = "Material intended to represent components. Better protection than Gun Steel, but worse health for balance reasons."
    self.SuppressLoad = true
    self.Density     = 2700 -- https://en.wikipedia.org/wiki/Aluminium
    self.CostMul     = 17.9
    self.HealthMul   = 54
    self.KineticMul  = 0.5
    self.ChemicalMul = 0.5
    self.SpallMul    = 1
end

-- Rubber
local Armor = Types.Register("Rubber")
function Armor:OnLoaded()
    self.Name        = "Rubber"
    self.Description = "Very cheap and light, but offers very little protection."
    self.Density     = 1500 -- * https://rubberandseal.com/what-is-the-density-of-rubber-sheets/
    self.CostMul     = 12
    self.HealthMul   = 350
    self.KineticMul  = 0.15
    self.ChemicalMul = 0.35
    self.SpallMul    = 0.1
end

-- Textolite
local Armor = Types.Register("Textolite")
function Armor:OnLoaded()
    self.Name        = "Textolite"
    self.Description = "Layered fibrous laminate material. Not much protection, but is cheap and light."
    self.Density     = 1800 -- * http://www.china-anza.com/2-1-7-textolite-3025.html
    self.CostMul     = 14.7
    self.HealthMul   = 180
    self.KineticMul  = 0.4
    self.ChemicalMul = 0.5
    self.SpallMul    = 0.3
end

-- Tungsten
local Armor = Types.Register("Tungsten")
function Armor:OnLoaded()
    self.Name        = "Tungsten"
    self.Description = "Extremely expensive and dense for equivalently good protection."
    self.Density     = 19250 -- https://en.wikipedia.org/wiki/Tungsten
    self.CostMul     = 72.2
    self.HealthMul   = 1347.5
    self.KineticMul  = 1.4
    self.ChemicalMul = 1.2
    self.SpallMul    = 0.8
end

-- DU
local Armor = Types.Register("DU")
function Armor:OnLoaded()
    self.Name        = "Depleted Uranium"
    self.Description = "Expensive and dense with high protection."
    self.Density     = 18700 -- https://pubmed.ncbi.nlm.nih.gov/11218253/
    self.CostMul     = 69.3
    self.HealthMul   = 1683
    self.KineticMul  = 1.3
    self.ChemicalMul = 1.1
    self.SpallMul    = 1.3
end

-- Light ERA
local Armor = Types.Register("LightERA")
function Armor:OnLoaded()
    self.Name        = "Light ERA"
    self.Description = "Explosive Reactive Armor. Effective primarily against shaped charges. Will explode when hit with enough energy."
    self.Density     = 5000 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    self.CostMul     = 39.7
    self.HealthMul   = 250
    self.KineticMul  = 0.3
    self.ChemicalMul = 3.0
    self.SpallMul    = 0.1

    self.IsExplosive        = true
    self.ExplosiveThreshold = 100 -- KJ; sensitive, will trigger off autocannon-grade rounds and up
    self.ExplosiveFiller    = 0.05
end

-- Heavy ERA
local Armor = Types.Register("HeavyERA")
function Armor:OnLoaded()
    self.Name        = "Heavy ERA"
    self.Description = "Heavy Explosive Reactive Armor. Offers better protection against kinetic threats and takes more energy to detonate than Light ERA, but is twice as dense and more expensive."
    self.Density     = 10000 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    self.CostMul     = 47.1
    self.HealthMul   = 600
    self.KineticMul  = 0.6
    self.ChemicalMul = 2.0
    self.SpallMul    = 0.2

    self.IsExplosive        = true
    self.ExplosiveThreshold = 500 -- KJ; needs a heavier penetrator to set off
    self.ExplosiveFiller    = 0.08
end