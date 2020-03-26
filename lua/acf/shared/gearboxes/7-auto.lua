-- Weight
local wmul = 1.5
local Gear7SW = 100 * wmul
local Gear7MW = 200 * wmul
local Gear7LW = 400 * wmul

-- Torque Rating
local Gear7ST = 425
local Gear7MT = 1250
local Gear7LT = 10000

-- Straight through bonuses
local StWB = 0.75 --straight weight bonus mulitplier
local StTB = 1.25 --straight torque bonus multiplier

-- Shift Time
local ShiftS = 0.25
local ShiftM = 0.35
local ShiftL = 0.5

ACF.RegisterGearboxClass("7-Auto", {
	Name		= "7-Speed Automatic",
	CreateMenu	= ACF.AutomaticGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 7,
	}
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("7Gear-A-L-S", "7-Auto", {
		Name		= "7-Speed Auto, Inline, Small",
		Description	= "A small, and light 7 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear7SW,
		Switch		= ShiftS,
		MaxTorque	= Gear7ST,
		Automatic	= true,
	})

	ACF.RegisterGearbox("7Gear-A-L-M", "7-Auto", {
		Name		= "7-Speed Auto, Inline, Medium",
		Description	= "A medium sized, 7 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear7MW,
		Switch		= ShiftM,
		MaxTorque	= Gear7MT,
		Automatic	= true,
	})

	ACF.RegisterGearbox("7Gear-A-L-L", "7-Auto", {
		Name		= "7-Speed Auto, Inline, Large",
		Description	= "A large, heavy and sturdy 7 speed inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear7LW,
		Switch		= ShiftL,
		MaxTorque	= Gear7LT,
		Automatic	= true,
	})
end

do -- Inline Dual Clutch Gearboxes
	ACF.RegisterGearbox("7Gear-A-LD-S", "7-Auto", {
		Name		= "7-Speed Auto, Inline, Small, Dual Clutch",
		Description	= "A small, and light 7 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear7SW,
		Switch		= ShiftS,
		MaxTorque	= Gear7ST,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("7Gear-A-LD-M", "7-Auto", {
		Name		= "7-Speed Auto, Inline, Medium, Dual Clutch",
		Description	= "A medium sized, 7 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear7MW,
		Switch		= ShiftM,
		MaxTorque	= Gear7MT,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("7Gear-A-LD-L", "7-Auto", {
		Name		= "7-Speed Auto, Inline, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 7 speed automatic inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear7LW,
		Switch		= ShiftL,
		MaxTorque	= Gear7LT,
		Automatic	= true,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("7Gear-A-T-S", "7-Auto", {
		Name		= "7-Speed Auto, Transaxial, Small",
		Description	= "A small, and light 7 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear7SW,
		Switch		= ShiftS,
		MaxTorque	= Gear7ST,
		Automatic	= true,
	})

	ACF.RegisterGearbox("7Gear-A-T-M", "7-Auto", {
		Name		= "7-Speed Auto, Transaxial, Medium",
		Description	= "A medium sized, 7 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear7MW,
		Switch		= ShiftM,
		MaxTorque	= Gear7MT,
		Automatic	= true,
	})

	ACF.RegisterGearbox("7Gear-A-T-L", "7-Auto", {
		Name		= "7-Speed Auto, Transaxial, Large",
		Description	= "A large, heavy and sturdy 7 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear7LW,
		Switch		= ShiftL,
		MaxTorque	= Gear7LT,
		Automatic	= true,
	})
end

do -- Transaxial Dual Clutch Gearboxes
	ACF.RegisterGearbox("7Gear-A-TD-S", "7-Auto", {
		Name		= "7-Speed Auto, Transaxial, Small, Dual Clutch",
		Description	= "A small, and light 7 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear7SW,
		Switch		= ShiftS,
		MaxTorque	= Gear7ST,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("7Gear-A-TD-M", "7-Auto", {
		Name		= "7-Speed Auto, Transaxial, Medium, Dual Clutch",
		Description	= "A medium sized, 7 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear7MW,
		Switch		= ShiftM,
		MaxTorque	= Gear7MT,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("7Gear-A-TD-L", "7-Auto", {
		Name		= "7-Speed Auto, Transaxial, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 7 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear7LW,
		Switch		= ShiftL,
		MaxTorque	= Gear7LT,
		Automatic	= true,
		DualClutch	= true,
	})
end

do -- Straight-through Gearboxes
	ACF.RegisterGearbox("7Gear-A-ST-S", "7-Auto", {
		Name		= "7-Speed Auto, Straight, Small",
		Description	= "A small straight-through automatic gearbox",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear7SW * StWB),
		Switch		= ShiftS,
		MaxTorque	= math.floor(Gear7ST * StTB),
		Automatic	= true,
	})

	ACF.RegisterGearbox("7Gear-A-ST-M", "7-Auto", {
		Name		= "7-Speed Auto, Straight, Medium",
		Description	= "A medium sized, 7 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear7MW * StWB),
		Switch		= ShiftM,
		MaxTorque	= math.floor(Gear7MT * StTB),
		Automatic	= true,
	})

	ACF.RegisterGearbox("7Gear-A-ST-L", "7-Auto", {
		Name		= "7-Speed Auto, Straight, Large",
		Description	= "A large sized, 7 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear7LW * StWB),
		Switch		= ShiftL,
		MaxTorque	= math.floor(Gear7LT * StTB),
		Automatic	= true,
	})
end
