local ACF       = ACF
local Classes   = ACF.Classes

-- Weight
local GearDDSW = 45

-- Torque Rating
local GearDDST = 4500

local function InitGearbox(Gearbox)
	Gearbox.DoubleDiff = true
	Gearbox.SteerRate  = 0

	Gearbox:SetBodygroup(1, 1)
end

Classes.DefineClass("ACF.Gearboxes.DoubleDiff", "ACF.Gearboxes.BaseGearbox", function()
	CLASS.Name		= "Double Differential"
	CLASS.CreateMenu	= ACF.ManualGearboxMenu
	CLASS.Gears = {
		Min	= 0,
		Max	= 1,
	}
	CLASS.OnSpawn = InitGearbox
	CLASS.OnUpdate = InitGearbox
	CLASS.SetupInputs = function(_, List)
		List[#List + 1] = "Steer Rate (From -1 to 1, defines the rate of steering.\nSetting it outside the +-0.5 bounds will produce pivot steering.)"
	end
	CLASS.OnLast = function(Gearbox)
		Gearbox.DoubleDiff = nil
		Gearbox.SteerRate  = nil

		Gearbox:SetBodygroup(1, 0)
	end
end)

do -- Transaxial Gearboxes
	Classes.DefineClass("ACF.Gearboxes.DoubleDiff-T", "ACF.Gearboxes.DoubleDiff", function()
		CLASS.Name		= "Double Differential"
		CLASS.Description	= "A light duty regenerative steering transmission."
		CLASS.Model		= "models/engines/transaxial_s.mdl"
		CLASS.Mass		= GearDDSW
		CLASS.Switch		= 0.2
		CLASS.MaxTorque	= GearDDST
		CLASS.DualClutch	= true
		CLASS.Preview = {
			FOV = 85,
		}
	end)
end