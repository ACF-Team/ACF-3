local Classes = ACF.Classes

Classes.DefineClass("ACF.ArmorTypes.BaseArmorType", function() end)

-- Name       : full display name
-- ShortName  : abbreviated display name, used where space is limited (e.g. the cost comparison grid)
-- Density stored in g/cm^3 (equivalently kg/L)
-- CostMul    : points per m^3
-- HealthMul  : health pool per unit volume
-- KineticMul : RHA equivalent multiplier vs kinetic (AP) threats
-- ChemicalMul: RHA equivalent multiplier vs chemical energy (HEAT/shaped charge) threats
-- SpallMul   : multiplier on spall fragment mass produced when this material is penetrated

-- Explosive Reactive Armor (optional, only set on reactive types):
-- IsExplosive       : marks the material as reactive; convexes detonate when penetrated with enough kinetic energy
-- ExplosiveThreshold: kinetic energy (KJ) a penetrating round must carry to set off the reactive charge
-- ExplosiveFiller   : fraction of the convex's mass that detonates as HE filler when triggered
-- UnspentMul        : fraction of KineticMul/ChemicalMul kept by rounds below ExplosiveThreshold
-- FlyerClearance    : multiple of the convex's MinWidth that must be open in front of the face, otherwise the plate counts as unspent

-- Default special type. Does not set mass, but abysmal for armor usage
Classes.DefineClass("ACF.ArmorTypes.Default", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Default"
    CLASS.Name        = "Default"
    CLASS.ShortName   = "Default"
    CLASS.Description = "Allows you to set a custom weight. Bad for armor."
    CLASS.Density     = 0.1
    CLASS.CostMul     = 5
    CLASS.HealthMul   = 1e-4
    CLASS.KineticMul  = 1e-4
    CLASS.ChemicalMul = 1e-4
    CLASS.SpallMul    = 1e-4
end)

-- Flesh
Classes.DefineClass("ACF.ArmorTypes.Flesh", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Flesh"
    CLASS.Name        = "Flesh"
    CLASS.ShortName   = "Flesh"
    CLASS.Description = "Soft tissue, used to represent crew members. Lab-grown for your convenience."
    CLASS.Density     = 1.1 -- https://www.sciencedirect.com/topics/immunology-and-microbiology/body-density
    CLASS.CostMul     = 4.5
    CLASS.HealthMul   = 0.005
    CLASS.KineticMul  = 0.03
    CLASS.ChemicalMul = 0.03
    CLASS.SpallMul    = 0.2
end)

-- Diesel
Classes.DefineClass("ACF.ArmorTypes.Diesel", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Diesel"
    CLASS.Name        = "Diesel"
    CLASS.ShortName   = "Diesel"
    CLASS.Description = "Provides slight CE protection. Does not detonate."
    CLASS.SuppressLoad = true
    CLASS.Density     = 0.745 -- lua/acf/entities/fuel_types/diesel.lua (0.745 kg/L)
    CLASS.CostMul     = 1.8
    CLASS.HealthMul   = 0.00318878
    CLASS.KineticMul  = 0.1
    CLASS.ChemicalMul = 0.3
    CLASS.SpallMul    = 0.1
end)

-- Petrol
Classes.DefineClass("ACF.ArmorTypes.Petrol", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Petrol"
    CLASS.Name        = "Petrol"
    CLASS.ShortName   = "Petrol"
    CLASS.Description = "Provides negligible protection. Prone to detonate when penetrated or damaged."
    CLASS.SuppressLoad = true
    CLASS.Density     = 0.832 -- lua/acf/entities/fuel_types/petrol.lua (0.832 kg/L)
    CLASS.CostMul     = 2.07
    CLASS.HealthMul   = 0.00255102
    CLASS.KineticMul  = 0.1
    CLASS.ChemicalMul = 0.1
    CLASS.SpallMul    = 0.1
end)

-- Li-Ion
Classes.DefineClass("ACF.ArmorTypes.LiIon", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "LiIon"
    CLASS.Name        = "Li-Ion Battery"
    CLASS.ShortName   = "Li-Ion"
    CLASS.Description = "Provides slight protection. Prone to detonate when penetrated or damaged."
    CLASS.SuppressLoad = true
    CLASS.Density     = 3.89 -- lua/acf/entities/fuel_types/electric.lua (3.89 kg/L)
    CLASS.CostMul     = 7.2
    CLASS.HealthMul   = 0.00127551
    CLASS.KineticMul  = 0.3
    CLASS.ChemicalMul = 0.3
    CLASS.SpallMul    = 0.5
end)

Classes.DefineClass("ACF.ArmorTypes.Wing", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Wing"
    CLASS.Name        = "Aircraft Aluminum"
    CLASS.ShortName   = "Aircraft Aluminum"
    CLASS.Description = "For aircraft wings and similar hollow structures. Very light."
    CLASS.Density     = 1.08 -- https://en.wikipedia.org/wiki/Aluminium
    CLASS.CostMul     = 10.8
    CLASS.HealthMul   = 0.055102
    CLASS.KineticMul  = 0.2
    CLASS.ChemicalMul = 0.24
    CLASS.SpallMul    = 0.2
    CLASS.Color       = Color(127, 0, 95)
end)

-- Aluminum
Classes.DefineClass("ACF.ArmorTypes.Aluminum", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Aluminum"
    CLASS.Name        = "Aluminum"
    CLASS.ShortName   = "Aluminum"
    CLASS.Description = "Lower resistance than RHA, but substantially lighter."
    CLASS.Density     = 2.7 -- https://en.wikipedia.org/wiki/Aluminium
    CLASS.CostMul     = 27
    CLASS.HealthMul   = 0.25
    CLASS.KineticMul  = 0.5
    CLASS.ChemicalMul = 0.3
    CLASS.SpallMul    = 0.5
    CLASS.Color       = Color(255, 255, 255)
end)

-- RHA
Classes.DefineClass("ACF.ArmorTypes.RHA", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "RHA"
    CLASS.Name        = "RHA"
    CLASS.ShortName   = "RHA"
    CLASS.Description = "Standard steel armor used mostly by WW2 and early cold war tanks."
    CLASS.Density     = 7.84 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    CLASS.CostMul     = 38.7 -- Reference: 0.005 points/kg
    CLASS.HealthMul   = 1
    CLASS.KineticMul  = 1.0
    CLASS.ChemicalMul = 1.0
    CLASS.SpallMul    = 1.0
    CLASS.Color       = Color(145, 145, 145)
end)

-- HHRHA
Classes.DefineClass("ACF.ArmorTypes.HHRHA", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "HHRHA"
    CLASS.Name        = "Maraging Steel"
    CLASS.ShortName   = "Maraging Steel"
    CLASS.Description = "Higher resistance than RHA, but more expensive and less healthy."
    CLASS.Density     = 7.85 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    CLASS.CostMul     = 59.4
    CLASS.HealthMul   = 0.1325
    CLASS.KineticMul  = 1.25
    CLASS.ChemicalMul = 1.15
    CLASS.SpallMul    = 1.3
    CLASS.Color       = Color(255, 137, 137)
end)

-- Gun Steel
Classes.DefineClass("ACF.ArmorTypes.GunSteel", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "GunSteel"
    CLASS.Name        = "Gun Steel"
    CLASS.ShortName   = "Gun Steel"
    CLASS.Description = "Material intended to represent guns. Much healthier than components, but worse in protection per unit volume for balance reasons."
    CLASS.SuppressLoad = true
    CLASS.Density     = 7.84 -- https://metalzenith.com/blogs/steel-properties/rha-steel-properties-and-key-applications-in-defense
    CLASS.CostMul     = 35.28
    CLASS.HealthMul   = 1
    CLASS.KineticMul  = 0.7
    CLASS.ChemicalMul = 0.7
    CLASS.SpallMul    = 1.0
end)

-- Component Material
Classes.DefineClass("ACF.ArmorTypes.Component", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Component"
    CLASS.Name        = "Component"
    CLASS.ShortName   = "Component"
    CLASS.Description = "Material intended to represent components. Better protection than Gun Steel, but worse health for balance reasons."
    CLASS.SuppressLoad = true
    CLASS.Density     = 2.7 -- https://en.wikipedia.org/wiki/Aluminium
    CLASS.CostMul     = 16.11
    CLASS.HealthMul   = 0.015
    CLASS.KineticMul  = 0.1
    CLASS.ChemicalMul = 0.1
    CLASS.SpallMul    = 1
end)

-- Rubber
Classes.DefineClass("ACF.ArmorTypes.Rubber", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Rubber"
    CLASS.Name        = "Rubber"
    CLASS.ShortName   = "Rubber"
    CLASS.Description = "Very cheap and light, but offers very little protection."
    CLASS.Density     = 1.5 -- * https://rubberandseal.com/what-is-the-density-of-rubber-sheets/
    CLASS.CostMul     = 13.5
    CLASS.HealthMul   = 0.35
    CLASS.KineticMul  = 0.15
    CLASS.ChemicalMul = 0.35
    CLASS.SpallMul    = 0.8
    CLASS.Color       = Color(36, 36, 36)
end)

-- Textolite
Classes.DefineClass("ACF.ArmorTypes.Textolite", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Textolite"
    CLASS.Name        = "Textolite"
    CLASS.ShortName   = "Textolite"
    CLASS.Description = "Layered fibrous laminate material. Not much protection, but is cheap and light."
    CLASS.Density     = 1.8 -- * http://www.china-anza.com/2-1-7-textolite-3025.html
    CLASS.CostMul     = 31.5
    CLASS.HealthMul   = 0.2
    CLASS.KineticMul  = 0.5
    CLASS.ChemicalMul = 0.7
    CLASS.SpallMul    = 0.3
    CLASS.Color       = Color(255, 191, 0)
end)

-- Aramid
Classes.DefineClass("ACF.ArmorTypes.Aramid", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Aramid"
    CLASS.Name        = "Aramid"
    CLASS.ShortName   = "Aramid"
    CLASS.Description = "Very poor resistance compared to RHA, but reduces spalling."
    CLASS.Density     = 1.44 -- https://en.wikipedia.org/wiki/Kevlar
    CLASS.CostMul     = 40.5
    CLASS.HealthMul   = 0.085
    CLASS.KineticMul  = 0.32
    CLASS.ChemicalMul = 0.4
    CLASS.SpallMul    = 0.05 -- Fibres tear instead of shattering
    CLASS.Color       = Color(200, 170, 60)
end)

-- NERA
Classes.DefineClass("ACF.ArmorTypes.NERA", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "NERA"
    CLASS.Name        = "NERA"
    CLASS.ShortName   = "NERA"
    CLASS.Description = "Better chemical but worse kinetic performance compared to RHA. Light weight."
    CLASS.Density     = 2.58
    CLASS.CostMul     = 31.5
    CLASS.HealthMul   = 0.125
    CLASS.KineticMul  = 0.42
    CLASS.ChemicalMul = 1.0
    CLASS.SpallMul    = 0.7
    CLASS.Color       = Color(110, 125, 140)
end)

-- DU
Classes.DefineClass("ACF.ArmorTypes.DU", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "DU"
    CLASS.Name        = "Depleted Uranium"
    CLASS.ShortName   = "DU"
    CLASS.Description = "Higher resistance than RHA, but heavy and slightly expensive."
    CLASS.Density     = 19.05 -- https://en.wikipedia.org/wiki/Uranium
    CLASS.CostMul     = 62.37
    CLASS.HealthMul   = 2.14668
    CLASS.KineticMul  = 1.8
    CLASS.ChemicalMul = 1.3
    CLASS.SpallMul    = 1.3
    CLASS.Color       = Color(140, 255, 168)
end)

-- Silicon Carbide
Classes.DefineClass("ACF.ArmorTypes.SiliconCarbide", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "SiliconCarbide"
    CLASS.Name        = "Silicon Carbide"
    CLASS.ShortName   = "SiC"
    CLASS.Description = "Very high resistance compared to RHA, but very brittle and expensive."
    CLASS.Density     = 3.21 -- https://en.wikipedia.org/wiki/Silicon_carbide
    CLASS.CostMul     = 72
    CLASS.HealthMul   = 0.025
    CLASS.KineticMul  = 2.2
    CLASS.ChemicalMul = 1.6
    CLASS.SpallMul    = 1.5
    CLASS.Color       = Color(0, 44, 70)
end)

-- Light ERA
Classes.DefineClass("ACF.ArmorTypes.LightERA", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "LightERA"
    CLASS.Name        = "Light ERA"
    CLASS.ShortName   = "Light ERA"
    CLASS.Description = "Better chemical resistance than RHA at the cost of worse kinetic performance and one time use."
    CLASS.Density     = 5 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    CLASS.CostMul     = 25.011
    CLASS.HealthMul   = 0.115
    CLASS.KineticMul  = 0.3
    CLASS.ChemicalMul = 2.0
    CLASS.PassiveMul  = 0.2
    CLASS.SpallMul    = 0.1
    CLASS.Color       = Color(255, 219, 112)

    CLASS.IsExplosive        = true
    CLASS.ExplosiveThreshold = 100
    CLASS.ExplosiveFiller    = 0.01
    CLASS.UnspentMul         = 0.25
    CLASS.FlyerClearance     = 1.5
end)

-- Heavy ERA
Classes.DefineClass("ACF.ArmorTypes.HeavyERA", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "HeavyERA"
    CLASS.Name        = "Heavy ERA"
    CLASS.ShortName   = "Heavy ERA"
    CLASS.Description = "Better kinetic resistance than light ERA at the cost of being heavier and more expensive."
    CLASS.Density     = 10 -- * https://below-the-turret-ring.blogspot.com/2016/04/explosive-reactive-armor-some-history.html
    CLASS.CostMul     = 42.39
    CLASS.HealthMul   = 0.275
    CLASS.KineticMul  = 1.33
    CLASS.ChemicalMul = 2.0
    CLASS.PassiveMul  = 0.5
    CLASS.SpallMul    = 0.2
    CLASS.Color       = Color(127, 111, 63)

    CLASS.IsExplosive        = true
    CLASS.ExplosiveThreshold = 200
    CLASS.ExplosiveFiller    = 0.01
    CLASS.UnspentMul         = 0.25
    CLASS.FlyerClearance     = 1.5
end)

-- Reinforced Concrete
Classes.DefineClass("ACF.ArmorTypes.ReinforcedConcrete", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "ReinforcedConcrete"
    CLASS.Name        = "Reinforced Concrete"
    CLASS.ShortName   = "Reinforced Concrete"
    CLASS.Description = "Decent protection per volume and cheap, but very heavy."
    CLASS.Density     = 2.5 -- https://www.civilengicon.com/2024/02/density-of-rcc-pcc-sand-cement.html
    CLASS.CostMul     = 5.85
    CLASS.HealthMul   = 0.1
    CLASS.KineticMul  = 0.22
    CLASS.ChemicalMul = 0.3
    CLASS.SpallMul    = 1.6
    CLASS.Color       = Color(70, 70, 70)
end)

-- Wood
Classes.DefineClass("ACF.ArmorTypes.Wood", "ACF.ArmorTypes.BaseArmorType", function(CLASS)
    CLASS.ID          = "Wood"
    CLASS.Name        = "Wood"
    CLASS.ShortName   = "Wood"
    CLASS.Description = "The cheapest and lightest material available. Offers almost no meaningful protection."
    CLASS.Density     = 0.9 -- https://www.engineeringtoolbox.com/wood-density-d_40.html specifically oak.
    CLASS.CostMul     = 3.6
    CLASS.HealthMul   = 0.04
    CLASS.KineticMul  = 0.06
    CLASS.ChemicalMul = 0.07
    CLASS.SpallMul    = 0.75
    CLASS.Color       = Color(133, 94, 66)
end)
