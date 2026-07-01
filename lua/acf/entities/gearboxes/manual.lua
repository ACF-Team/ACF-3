local ACF       = ACF
local Classes   = ACF.Classes

-- Weight
local Gear4SW = 50
local StWB = 0.75 -- Straight weight bonus mulitplier

-- Torque Rating
local Gear4ST = 1000
local StTB = 1.25 -- Straight torque bonus multiplier

Classes.DefineClass("ACF.Gearboxes.Manual", "ACF.Gearboxes.BaseGearbox", function()
	CLASS.Name		= "Manual"
	CLASS.CreateMenu	= ACF.ManualGearboxMenu
	CLASS.CanSetGears = true
	CLASS.Gears = {
		Min	= 0,
		Max	= 10,
	}
end)

do -- Scalable Gearboxes
	Classes.DefineClass("ACF.Gearboxes.Manual-L", "ACF.Gearboxes.Manual", function()
		CLASS.Name			= "Manual, Inline"
		CLASS.Description		= "A standard inline gearbox that requires manual gear shifting."
		CLASS.Model			= "models/engines/linear_s.mdl"
		CLASS.Mass			= Gear4SW
		CLASS.Switch			= 0.15
		CLASS.MaxTorque		= Gear4ST
		CLASS.CanDualClutch	= true
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Gearboxes.Manual-T", "ACF.Gearboxes.Manual", function()
		CLASS.Name			= "Manual, Transaxial"
		CLASS.Description		= "A standard transaxial gearbox that requires manual gear shifting."
		CLASS.Model			= "models/engines/transaxial_s.mdl"
		CLASS.Mass			= Gear4SW
		CLASS.Switch			= 0.15
		CLASS.MaxTorque		= Gear4ST
		CLASS.CanDualClutch	= true
		CLASS.Preview = {
			FOV = 85,
		}
	end)

	Classes.DefineClass("ACF.Gearboxes.Manual-ST", "ACF.Gearboxes.Manual", function()
		CLASS.Name		= "Manual, Straight"
		CLASS.Description	= "A standard straight-through gearbox that requires manual gear shifting."
		CLASS.Model		= "models/engines/t5small.mdl"
		CLASS.Mass		= math.floor(Gear4SW * StWB)
		CLASS.Switch		= 0.15
		CLASS.MaxTorque	= math.floor(Gear4ST * StTB)
		CLASS.Preview = {
			FOV = 105,
		}
	end)
end