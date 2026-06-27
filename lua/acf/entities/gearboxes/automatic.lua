local ACF       = ACF
local Classes   = ACF.Classes

-- Weight
local Gear3SW = 60

-- Torque Rating
local Gear3ST = 900

-- Straight through bonuses
local StWB = 0.75 --straight weight bonus mulitplier
local StTB = 1.25 --straight torque bonus multiplier

-- Shift Time
local ShiftS = 0.25

local function InitGearbox(Gearbox)
	local Gears = Gearbox.Gears

	Gearbox.Automatic  = true
	Gearbox.ShiftScale = 1
	Gearbox.Hold       = false
	Gearbox.Drive      = 0
	Gearbox.GearCount  = Gearbox.MaxGear + 1

	Gears[Gearbox.GearCount] = Gearbox.Reverse

	Gearbox:ChangeDrive(1)
end

Classes.DefineClass("ACF.Gearboxes.Auto", "ACF.Gearboxes.BaseGearbox", function()
	CLASS.Name			= "Automatic"
	CLASS.CreateMenu	= ACF.AutomaticGearboxMenu
	CLASS.CanSetGears 	= true
	CLASS.Gears 		= {
		Min	= 0,
		Max	= 10,
	}
	CLASS.OnSpawn = InitGearbox
	CLASS.OnUpdate = InitGearbox
	CLASS.VerifyData = function(Data, Class)
		do -- Shift point table verification
			local Points = Data.ShiftPoints
			local Mult = Data.ShiftUnit or 1
			local Max = Class.Gears.Max

			if not istable(Points) then
				local Encoded = Data.Gear9 and tostring(Data.Gear9)

				Points = { [0] = -1 }

				if Encoded then
					local Count = 0

					for Point in string.gmatch(Encoded, "[^,]+") do
						Count = Count + 1

						if Count > Max then break end

						Points[Count] = ACF.CheckNumber(Point, Count * 100)
					end
				end

				Data.ShiftPoints = Points
			else
				Points[0] = -1
			end

			for I = 1, Max do
				local Point = ACF.CheckNumber(Points[I])

				if not Point then
					Point = ACF.CheckNumber(Data["Shift" .. I], I * 100) * Mult

					Data["Shift" .. I] = nil
				end

				Points[I] = math.Clamp(Point, 0, 9999)
			end
		end

		do -- Reverse gear verification
			local Reverse = ACF.CheckNumber(Data.Reverse)

			if not Reverse then
				Reverse = ACF.CheckNumber(Data.Gear8, -1)

				Data.Gear8 = nil
			end

			Data.Reverse = math.Clamp(Reverse, ACF.MinGearRatio, ACF.MaxGearRatio)
		end
	end
	CLASS.SetupInputs = function(_, List)
		local Count = #List

		List[Count + 1] = "Hold Gear (If set to a non-zero value, it'll prevent the gearbox from shifting gears.)"
		List[Count + 2] = "Shift Speed Scale (Scales the speeds set for the automatic shifting.)"
	end
	CLASS.OnLast = function(Gearbox)
		Gearbox.Automatic  = nil
		Gearbox.ShiftScale = nil
		Gearbox.Drive      = nil
		Gearbox.Hold       = nil
	end
	CLASS.WriteGearOverlay = function(Gearbox, State)
		local GearText  = ", Upshift @ %s kph / %s mph"
		local Points    = Gearbox.ShiftPoints
		local Gears     = Gearbox.Gears

		for I = 1, Gearbox.MaxGear do
			local Ratio = ACF.ConvertGearRatio(Gears[I], Gearbox.GearboxLegacyRatio)
			local KPH = math.Round(Points[I] / 10.936, 1)
			local MPH = math.Round(Points[I] / 17.6, 1)

			State:AddGearRatio("Gear " .. I, Ratio, GearText:format(KPH, MPH), Gearbox.GearboxLegacyRatio)
		end

		local Reverse = ACF.ConvertGearRatio(Gears[Gearbox.GearCount], Gearbox.GearboxLegacyRatio)
		State:AddGearRatio("Reverse Gear", Reverse, "", Gearbox.GearboxLegacyRatio, true)
	end
end)

do -- Scalable Gearboxes
	Classes.DefineClass("ACF.Gearboxes.Auto-L", "ACF.Gearboxes.Auto", function()
		CLASS.Name			= "Automatic, Inline"
		CLASS.Description		= "An inline gearbox capable of automatically shifting gears based on speed."
		CLASS.Model			= "models/engines/linear_s.mdl"
		CLASS.Mass			= Gear3SW
		CLASS.Switch			= ShiftS
		CLASS.MaxTorque		= Gear3ST
		CLASS.CanDualClutch	= true
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Gearboxes.Auto-T", "ACF.Gearboxes.Auto", function()
		CLASS.Name			= "Automatic, Transaxial"
		CLASS.Description		= "A transaxial gearbox capable of automatically shifting gears based on speed."
		CLASS.Model			= "models/engines/transaxial_s.mdl"
		CLASS.Mass			= Gear3SW
		CLASS.Switch			= ShiftS
		CLASS.MaxTorque		= Gear3ST
		CLASS.CanDualClutch	= true
		CLASS.Preview = {
			FOV = 85,
		}
	end)

	Classes.DefineClass("ACF.Gearboxes.Auto-ST", "ACF.Gearboxes.Auto", function()
		CLASS.Name		= "Automatic, Straight"
		CLASS.Description	= "A straight-through gearbox capable of automatically shifting gears based on speed."
		CLASS.Model		= "models/engines/t5small.mdl"
		CLASS.Mass		= math.floor(Gear3SW * StWB)
		CLASS.Switch		= ShiftS
		CLASS.MaxTorque	= math.floor(Gear3ST * StTB)
		CLASS.Preview = {
			FOV = 105,
		}
	end)
end