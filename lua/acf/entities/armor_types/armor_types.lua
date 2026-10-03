local ACF       = ACF
local Types     = ACF.Classes.ArmorTypes

-- Name       : full display name
-- ShortName  : abbreviated display name, used where space is limited (e.g. the cost comparison grid)
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
    self.ShortName   = "Default"
    self.Description = "Used as a default material for entities. Not intended to provide any protection."
    self.Density     = 100
    self.CostMul     = 2.21
    self.HealthMul   = 0.0127551
    self.KineticMul  = 1e-4
    self.ChemicalMul = 1e-4
    self.SpallMul    = 1e-4
end

-- Flesh
local Armor = Types.Register("Flesh")
function Armor:OnLoaded()
    self.Name        = "Flesh"
    self.ShortName   = "Flesh"
    self.Description = "Soft tissue, used to represent crew members. Lab-grown for your convenience."
    self.Density     = 1100 -- https://www.sciencedirect.com/topics/immunology-and-microbiology/body-density
    self.CostMul     = 5
    self.HealthMul   = 0.01
    self.KineticMul  = 0.03
    self.ChemicalMul = 0.03
    self.SpallMul    = 0.2
end

-- Diesel
local Armor = Types.Register("Diesel")
function Armor:OnLoaded()
    self.Name        = "Diesel"
    self.ShortName   = "Diesel"
    self.Description = "Diesel fuel, provides some protection against shaped charges. Doesn't explode, unlike petrol and Li-Ion batteries."
    self.SuppressLoad = true
    self.Density     = 745 -- lua/acf/entities/fuel_types/diesel.lua (0.745 kg/L)
    self.CostMul     = 2
    self.HealthMul   = 0.00637755
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.3
    self.SpallMul    = 0.1
end

-- Petrol
local Armor = Types.Register("Petrol")
function Armor:OnLoaded()
    self.Name        = "Petrol"
    self.ShortName   = "Petrol"
    self.Description = "Petrol fuel, provides negligible protection. Prone to detonate when penetrated or damaged."
    self.SuppressLoad = true
    self.Density     = 832 -- lua/acf/entities/fuel_types/petrol.lua (0.832 kg/L)
    self.CostMul     = 2.3
    self.HealthMul   = 0.00510204
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.1
    self.SpallMul    = 0.1
end

-- Li-Ion
local Armor = Types.Register("LiIon")
function Armor:OnLoaded()
    self.Name        = "Li-Ion Battery"
    self.ShortName   = "Li-Ion"
    self.Description = "Lithium-ion battery cells. Prone to detonate when penetrated or damaged."
    self.SuppressLoad = true
    self.Density     = 3890 -- lua/acf/entities/fuel_types/electric.lua (3.89 kg/L)
    self.CostMul     = 8
    self.HealthMul   = 0.00255102
    self.KineticMul  = 0.3
    self.ChemicalMul = 0.3
    self.SpallMul    = 0.5
end

local Armor = Types.Register("Wing")
function Armor:OnLoaded()
    self.Name        = "Aircraft Aluminum"
    self.ShortName   = "Aircraft Aluminum"
    self.Description = "For aircraft wings and similar hollow structures. Very light."
    self.Density     = 1080 -- https://en.wikipedia.org/wiki/Aluminium
    self.CostMul     = 12
    self.HealthMul   = 0.110204
    self.KineticMul  = 0.2
    self.ChemicalMul = 0.24
    self.SpallMul    = 0.2
    self.Color       = Color(127, 0, 95)
end


-- Aluminum
local Armor = Types.Register("Aluminum")
function Armor:OnLoaded()
    self.Name        = "Aluminum"
    self.ShortName   = "Aluminum"
    self.Description = "Decent protection for its price and density."
    self.Density     = 2700 -- https://en.wikipedia.org/wiki/Aluminium
    self.CostMul     = 30
    self.HealthMul   = 0.5
    self.KineticMul  = 0.5
    self.ChemicalMul = 0.3
    self.SpallMul    = 0.5
    self.Color       = Color(255, 255, 255)
end

-- RHA
local Armor = Types.Register("RHA")
function Armor:OnLoaded()
    self.Name        = "RHA"
    self.ShortName   = "RHA"
    self.Description = "Rolled Homogeneous Armor. The standard by which all other armor types are measured."
    self.Density     = 7840 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    self.CostMul     = 54 -- Reference: 0.005 points/kg
    self.HealthMul   = 1
    self.KineticMul  = 1.0
    self.ChemicalMul = 1.0
    self.SpallMul    = 1.0
    self.Color       = Color(145, 145, 145)
end

-- HHRHA
local Armor = Types.Register("HHRHA")
function Armor:OnLoaded()
    self.Name        = "High Hardness RHA"
    self.ShortName   = "HHRHA"
    self.Description = "Harder than RHA, but more brittle."
    self.Density     = 7850 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    self.CostMul     = 68
    self.HealthMul   = 0.75
    self.KineticMul  = 1.25
    self.ChemicalMul = 1.15
    self.SpallMul    = 1.3
    self.Color       = Color(255, 137, 137)
end

-- Gun Steel
local Armor = Types.Register("GunSteel")
function Armor:OnLoaded()
    self.Name        = "Gun Steel"
    self.ShortName   = "Gun Steel"
    self.Description = "Material intended to represent guns. Much healthier than components, but worse in protection per unit volume for balance reasons."
    self.SuppressLoad = true
    self.Density     = 7840 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    self.CostMul     = 39.2
    self.HealthMul   = 2
    self.KineticMul  = 0.7
    self.ChemicalMul = 0.7
    self.SpallMul    = 1.0
end

-- Component Material
local Armor = Types.Register("Component")
function Armor:OnLoaded()
    self.Name        = "Component"
    self.ShortName   = "Component"
    self.Description = "Material intended to represent components. Better protection than Gun Steel, but worse health for balance reasons."
    self.SuppressLoad = true
    self.Density     = 2700 -- https://en.wikipedia.org/wiki/Aluminium
    self.CostMul     = 17.9
    self.HealthMul   = 0.03
    self.KineticMul  = 0.1
    self.ChemicalMul = 0.1
    self.SpallMul    = 1
end

-- Rubber
local Armor = Types.Register("Rubber")
function Armor:OnLoaded()
    self.Name        = "Rubber"
    self.ShortName   = "Rubber"
    self.Description = "Very cheap and light, but offers very little protection and does not stop spall."
    self.Density     = 1150 -- Typical vulcanized rubber, 1100-1200 kg/m^3
    self.CostMul     = 11.5 -- Kept at 0.01 points/kg
    self.HealthMul   = 0.7
    self.KineticMul  = 0.3 -- Hydrodynamic limit is 0.38, lower since RHA still has some strength
    self.ChemicalMul = 0.38 -- Hydrodynamic jet penetration, sqrt of the density ratio to RHA
    self.SpallMul    = 0.8 -- Behaves like a fluid at high velocity, so it is a poor spall liner
    self.Color       = Color(36, 36, 36)
end

-- Textolite
local Armor = Types.Register("Textolite")
function Armor:OnLoaded()
    self.Name        = "Textolite"
    self.ShortName   = "Textolite"
    self.Description = "Layered fibrous laminate material. Not much protection, but is cheap and light."
    self.Density     = 1800 -- * http://www.china-anza.com/2-1-7-textolite-3025.html
    self.CostMul     = 30
    self.HealthMul   = 0.2
    self.KineticMul  = 0.5
    self.ChemicalMul = 0.7
    self.SpallMul    = 0.3
    self.Color       = Color(255, 191, 0)
end

-- Aramid
local Armor = Types.Register("Aramid")
function Armor:OnLoaded()
    self.Name        = "Aramid"
    self.ShortName   = "Aramid"
    self.Description = "Kevlar style aramid fiber laminate. Poor protection against large threats, but an excellent spall liner. Expensive and tears easily."
    self.Density     = 1300 -- Aramid and resin laminate, the fiber alone is 1440 kg/m^3
    self.CostMul     = 52 -- Reference: 0.04 points/kg
    self.HealthMul   = 0.35
    self.KineticMul  = 0.45
    self.ChemicalMul = 0.4
    self.SpallMul    = 0.05
    self.Color       = Color(95, 160, 120)
end

-- DU
local Armor = Types.Register("DU")
function Armor:OnLoaded()
    self.Name        = "Depleted Uranium"
    self.ShortName   = "DU"
    self.Description = "Expensive and dense with high protection."
    self.Density     = 19050 -- https://en.wikipedia.org/wiki/Uranium
    self.CostMul     = 157
    self.HealthMul   = 2.14668
    self.KineticMul  = 1.8
    self.ChemicalMul = 1.3
    self.SpallMul    = 1.3
    self.Color       = Color(140, 255, 168)
end

-- Silicon Carbide
local Armor = Types.Register("SiliconCarbide")
function Armor:OnLoaded()
    self.Name        = "Silicon Carbide"
    self.ShortName   = "SiC"
    self.Description = "Excellent protection, but brittle and expensive."
    self.Density     = 3210 -- https://en.wikipedia.org/wiki/Silicon_carbide
    self.CostMul     = 80
    self.HealthMul   = 0.05
    self.KineticMul  = 2.2
    self.ChemicalMul = 1.6
    self.SpallMul    = 1.5
    self.Color       = Color(0, 44, 70)
end

-- Light ERA
local Armor = Types.Register("LightERA")
function Armor:OnLoaded()
    self.Name        = "Light ERA"
    self.ShortName   = "Light ERA"
    self.Description = "Explosive Reactive Armor. Effective primarily against shaped charges. Will explode when hit with enough energy."
    self.Density     = 5000 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    self.CostMul     = 27.79
    self.HealthMul   = 0.23
    self.KineticMul  = 0.3
    self.ChemicalMul = 2.0
    self.PassiveMul  = 0.2
    self.SpallMul    = 0.1
    self.Color       = Color(255, 219, 112)

    self.IsExplosive        = true
    self.ExplosiveThreshold = 100
    self.ExplosiveFiller    = 0.01
end

-- Heavy ERA
local Armor = Types.Register("HeavyERA")
function Armor:OnLoaded()
    self.Name        = "Heavy ERA"
    self.ShortName   = "Heavy ERA"
    self.Description = "Heavy Explosive Reactive Armor. Offers better protection against kinetic threats and takes more energy to detonate than Light ERA, but is twice as dense and more expensive."
    self.Density     = 10000 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    self.CostMul     = 47.1
    self.HealthMul   = 0.55
    self.KineticMul  = 1.33
    self.ChemicalMul = 2.0
    self.PassiveMul  = 0.5
    self.SpallMul    = 0.2
    self.Color       = Color(127, 111, 63)

    self.IsExplosive        = true
    self.ExplosiveThreshold = 200
    self.ExplosiveFiller    = 0.01
end

-- NERA
local Armor = Types.Register("NERA")
function Armor:OnLoaded()
    self.Name        = "NERA"
    self.ShortName   = "NERA"
    self.Description = "Non-Explosive Reactive Armor, steel plates around rubber interlayers like the Abrams turret cassettes. Bulges against shaped charges and long rods, but never detonates. Weaker than ERA against HEAT, in exchange for being safe and sustained."
    self.Density     = 5164 -- 60% RHA and 40% rubber by volume
    self.CostMul     = 40 -- Between the raw material cost (28) and Heavy ERA (47.1), for the cassette assembly
    self.HealthMul   = 0.8
    self.KineticMul  = 0.75 -- Just above the linear steel and rubber mix (0.72), the bulging plates disrupt rods a little
    self.ChemicalMul = 1.5 -- Linear mix is 0.75, the bulge doubles it, still short of ERA's 2.0
    self.SpallMul    = 0.7 -- Steel plates still spall, but the rubber layers soak up some
    self.Color       = Color(110, 125, 140)
end

-- Reinforced Concrete
local Armor = Types.Register("ReinforcedConcrete")
function Armor:OnLoaded()
    self.Name        = "Reinforced Concrete"
    self.ShortName   = "Reinforced Concrete"
    self.Description = "Cheap and weak protection per unit volume compared to RHA, but low enough cost to make up for it in large stationary structures."
    self.Density     = 2500 -- https://www.civilengicon.com/2024/02/density-of-rcc-pcc-sand-cement.html
    self.CostMul     = 6.5
    self.HealthMul   = 0.2
    self.KineticMul  = 0.22
    self.ChemicalMul = 0.3
    self.SpallMul    = 1.6
    self.Color       = Color(70, 70, 70)
end

-- Wood
local Armor = Types.Register("Wood")
function Armor:OnLoaded()
    self.Name        = "Wood"
    self.ShortName   = "Wood"
    self.Description = "The cheapest and lightest material available. Offers almost no meaningful protection against anything, but its low cost and low density make it usable for early aircraft, or non-combat use as scaffolds and housing."
    self.Density     = 900 -- https://www.engineeringtoolbox.com/wood-density-d_40.html specifically oak.
    self.CostMul     = 4
    self.HealthMul   = 0.08
    self.KineticMul  = 0.06
    self.ChemicalMul = 0.07
    self.SpallMul    = 0.75
    self.Color       = Color(133, 94, 66)
end