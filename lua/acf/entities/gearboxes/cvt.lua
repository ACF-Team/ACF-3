-- CVT (continuously variable transmission)
local ACF       = ACF
local Classes   = ACF.Classes

-- Weight
local GearCVTSW = 65
local StWB = 0.75 -- Straight weight bonus mulitplier

-- Torque Rating
local GearCVTST = 700
local StTB = 1.25 -- Straight torque bonus multiplier

local function InitGearbox(Gearbox)
	local Gears = Gearbox.Gears

	Gearbox.CVT      = true
	Gearbox.CVTRatio = 0

	WireLib.TriggerOutput(Gearbox, "Min Target RPM", Gears.MinRPM)
	WireLib.TriggerOutput(Gearbox, "Max Target RPM", Gears.MaxRPM)
end

Classes.DefineClass("ACF.Gearboxes.CVT", "ACF.Gearboxes.BaseGearbox", function()
	CLASS.Name		= "CVT"
	CLASS.CreateMenu	= ACF.CVTGearboxMenu
	CLASS.Gears = {
		Min		= 0,
		Max		= 2,
	}
	CLASS.OnSpawn = InitGearbox
	CLASS.OnUpdate = InitGearbox
	CLASS.VerifyData = function(Data)
		local Min, Max = Data.MinRPM, Data.MaxRPM

		Data.Gears[1] = 0.01

		if not Min then
			Min = ACF.CheckNumber(Data.Gear3, 3000)

			Data.Gear3 = nil
		end

		if not Max then
			Max = ACF.CheckNumber(Data.Gear4, 5000)

			Data.Gear4 = nil
		end

		Data.MinRPM = math.Clamp(Min, 1, 9900)
		Data.MaxRPM = math.Clamp(Max, Data.MinRPM + 100, 10000)
	end
	CLASS.SetupInputs = function(_, List)
		List[#List + 1] = "CVT Ratio (Manually sets the gear ratio on the gearbox.)"
	end
	CLASS.SetupOutputs = function(_, List)
		local Count = #List

		List[Count + 1] = "Min Target RPM (Sets the lower targeted RPM for the CVT to maintain.)"
		List[Count + 2] = "Max Target RPM (Sets the upper targeted RPM for the CVT to maintain.)"
	end
	CLASS.OnLast = function(Gearbox)
		Gearbox.CVT      = nil
		Gearbox.CVTRatio = nil
	end
	CLASS.WriteGearOverlay = function(Gearbox, State)
		local Text    = "%s - %s RPM"
		local Gears   = Gearbox.Gears
		local Reverse = ACF.ConvertGearRatio(Gears[2], Gearbox.GearboxLegacyRatio)
		local Min     = math.Round(Gearbox.MinRPM)
		local Max     = math.Round(Gearbox.MaxRPM)

		State:AddGearRatio("Reverse Gear", Reverse, "", Gearbox.GearboxLegacyRatio, true)
		State:AddKeyValue("Target", Text:format(Min, Max))
	end
end)

do -- Scalable Gearboxes
	Classes.DefineClass("ACF.Gearboxes.CVT-L", "ACF.Gearboxes.CVT", function()
		CLASS.Name			= "CVT, Inline"
		CLASS.Description		= "An inline gearbox capable of keeping an engine within a specified RPM range by constantly adjusting the gear ratio."
		CLASS.Model			= "models/engines/linear_s.mdl"
		CLASS.Mass			= GearCVTSW
		CLASS.Switch			= 0.15
		CLASS.MaxTorque		= GearCVTST
		CLASS.CanDualClutch	= true
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Gearboxes.CVT-T", "ACF.Gearboxes.CVT", function()
		CLASS.Name			= "CVT, Transaxial"
		CLASS.Description		= "A transaxial gearbox capable of keeping an engine within a specified RPM range by constantly adjusting the gear ratio."
		CLASS.Model			= "models/engines/transaxial_s.mdl"
		CLASS.Mass			= GearCVTSW
		CLASS.Switch			= 0.15
		CLASS.MaxTorque		= GearCVTST
		CLASS.CanDualClutch	= true
		CLASS.Preview = {
			FOV = 85,
		}
	end)

	Classes.DefineClass("ACF.Gearboxes.CVT-ST", "ACF.Gearboxes.CVT", function()
		CLASS.Name		= "CVT, Straight"
		CLASS.Description	= "A straight-through gearbox capable of keeping an engine within a specified RPM range by constantly adjusting the gear ratio."
		CLASS.Model		= "models/engines/t5small.mdl"
		CLASS.Mass		= math.floor(GearCVTSW * StWB)
		CLASS.Switch		= 0.15
		CLASS.MaxTorque	= math.floor(GearCVTST * StTB)
		CLASS.Preview = {
			FOV = 105,
		}
	end)
end

ACF.SetCustomAttachments("models/engines/t5small.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 20), Ang = Angle(0, -180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 20), Ang = Angle(0, -180, 90) },
})

local Models = {
	{ Model = "models/engines/t5small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Straight = {
			Pos       = Vector(0, 12.5, -0.75) * Scale,
			Scale     = Vector(6.5, 15, 8) * Scale,
			Sensitive = true
		},
		Clutch = {
			Pos   = Vector(0, 2.5, 0) * Scale,
			Scale = Vector(11, 5, 11) * Scale
		}
	})
end