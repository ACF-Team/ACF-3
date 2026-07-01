local ACF       = ACF
local Classes   = ACF.Classes

local Gear2SW = 20

Classes.DefineClass("ACF.Gearboxes.Transfer", "ACF.Gearboxes.BaseGearbox", function()
	CLASS.Name		= "Transfer Case"
	CLASS.CreateMenu	= ACF.ManualGearboxMenu
	CLASS.Gears = {
		Min	= 0,
		Max	= 2,
	}
end)

do -- Scalable gearboxes
	Classes.DefineClass("ACF.Gearboxes.2Gear-L", "ACF.Gearboxes.Transfer", function()
		CLASS.Name			= "Transfer Case, Inline"
		CLASS.Description		= "2 speed gearbox. Useful for low/high range and tank turning."
		CLASS.Model			= "models/engines/linear_s.mdl"
		CLASS.Mass			= Gear2SW
		CLASS.Switch			= 0.3
		CLASS.MaxTorque		= 6000
		CLASS.DualClutch		= true
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Gearboxes.2Gear-T", "ACF.Gearboxes.Transfer", function()
		CLASS.Name			= "Transfer Case"
		CLASS.Description		= "2 speed gearbox. Useful for low/high range and tank turning."
		CLASS.Model			= "models/engines/transaxial_s.mdl"
		CLASS.Mass			= Gear2SW
		CLASS.Switch			= 0.3
		CLASS.MaxTorque		= 6000
		CLASS.DualClutch		= true
		CLASS.Preview = {
			FOV = 85,
		}
	end)
end