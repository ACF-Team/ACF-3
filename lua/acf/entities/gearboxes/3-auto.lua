local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local wmul = 1.5
local Gear3SW = 60 * wmul
local Gear3MW = 120 * wmul
local Gear3LW = 240 * wmul

-- Torque Rating
local Gear3ST = 675
local Gear3MT = 2125
local Gear3LT = 10000

-- Straight through bonuses
local StWB = 0.75 --straight weight bonus mulitplier
local StTB = 1.25 --straight torque bonus multiplier

-- Shift Time
local ShiftS = 0.25
local ShiftM = 0.35
local ShiftL = 0.5

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

Gearboxes.Register("3-Auto", {
	Name		= "3-Speed Automatic",
	CreateMenu	= ACF.AutomaticGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 3,
	},
	OnSpawn = InitGearbox,
	OnUpdate = InitGearbox,
	VerifyData = function(Data, Class)
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

			Data.Reverse = math.Clamp(Reverse, -1, 1)
		end
	end,
	SetupInputs = function(_, List)
		local Count = #List

		List[Count + 1] = "Hold Gear (If set to a non-zero value, it'll prevent the gearbox from shifting gears.)"
		List[Count + 2] = "Shift Speed Scale (Scales the speeds set for the automatic shifting.)"
	end,
	OnLast = function(Gearbox)
		Gearbox.Automatic  = nil
		Gearbox.ShiftScale = nil
		Gearbox.Drive      = nil
		Gearbox.Hold       = nil
	end,
	GetGearsText = function(Gearbox)
		local GearText  = "Gear %s: %s, Upshift @ %s kph / %s mph\n"
		local Text      = "%sReverse gear: %s\n"
		local Points    = Gearbox.ShiftPoints
		local Gears     = Gearbox.Gears
		local GearsText = ""

		for I = 1, Gearbox.MaxGear do
			local Ratio = math.Round(Gears[I], 2)
			local KPH = math.Round(Points[I] / 10.936, 1)
			local MPH = math.Round(Points[I] / 17.6, 1)

			GearsText = GearsText .. GearText:format(I, Ratio, KPH, MPH)
		end

		return Text:format(GearsText, math.Round(Gearbox.Reverse, 2))
	end,
})

do -- Inline Gearboxes
	Gearboxes.RegisterItem("3Gear-A-L-S", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Small",
		Description	= "A small, and light 3 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-L-M", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Medium",
		Description	= "A medium sized, 3 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-L-L", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Large",
		Description	= "A large, heavy and sturdy 3 speed inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Inline Dual Clutch Gearboxes
	Gearboxes.RegisterItem("3Gear-A-LD-S", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Small, Dual Clutch",
		Description	= "A small, and light 3 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-LD-M", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Medium, Dual Clutch",
		Description	= "A medium sized, 3 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-LD-L", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 3 speed automatic inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Transaxial Gearboxes
	Gearboxes.RegisterItem("3Gear-A-T-S", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Small",
		Description	= "A small, and light 3 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-T-M", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Medium",
		Description	= "A medium sized, 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-T-L", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Large",
		Description	= "A large, heavy and sturdy 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Transaxial Dual Clutch Gearboxes
	Gearboxes.RegisterItem("3Gear-A-TD-S", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Small, Dual Clutch",
		Description	= "A small, and light 3 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-TD-M", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Medium, Dual Clutch",
		Description	= "A medium sized, 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-TD-L", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Straight-through Gearboxes
	Gearboxes.RegisterItem("3Gear-A-ST-S", "3-Auto", {
		Name		= "3-Speed Auto, Straight, Small",
		Description	= "A small straight-through automatic gearbox",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear3SW * StWB),
		Switch		= ShiftS,
		MaxTorque	= math.floor(Gear3ST * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-ST-M", "3-Auto", {
		Name		= "3-Speed Auto, Straight, Medium",
		Description	= "A medium sized, 3 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear3MW * StWB),
		Switch		= ShiftM,
		MaxTorque	= math.floor(Gear3MT * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("3Gear-A-ST-L", "3-Auto", {
		Name		= "3-Speed Auto, Straight, Large",
		Description	= "A large sized, 3 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear3LW * StWB),
		Switch		= ShiftL,
		MaxTorque	= math.floor(Gear3LT * StTB),
		Preview = {
			FOV = 105,
		},
	})
end
