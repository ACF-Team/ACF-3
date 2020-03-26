-- Weight
local wmul = 1.5
local Gear5SW = 80 * wmul
local Gear5MW = 160 * wmul
local Gear5LW = 320 * wmul

-- Torque Rating
local Gear5ST = 550
local Gear5MT = 1700
local Gear5LT = 10000

-- Straight through bonuses
local StWB = 0.75 --straight weight bonus mulitplier
local StTB = 1.25 --straight torque bonus multiplier

-- Shift Time
local ShiftS = 0.25
local ShiftM = 0.35
local ShiftL = 0.5

ACF.RegisterGearboxClass("5-Auto", {
	Name		= "5-Speed Automatic",
	CreateMenu	= ACF.AutomaticGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 5,
	}
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("5Gear-A-L-S", "5-Auto", {
		Name		= "5-Speed Auto, Inline, Small",
		Description	= "A small, and light 5 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear5SW,
		Switch		= ShiftS,
		MaxTorque	= Gear5ST,
		Automatic	= true,
	})

	ACF.RegisterGearbox("5Gear-A-L-M", "5-Auto", {
		Name		= "5-Speed Auto, Inline, Medium",
		Description	= "A medium sized, 5 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear5MW,
		Switch		= ShiftM,
		MaxTorque	= Gear5MT,
		Automatic	= true,
	})

	ACF.RegisterGearbox("5Gear-A-L-L", "5-Auto", {
		Name		= "5-Speed Auto, Inline, Large",
		Description	= "A large, heavy and sturdy 5 speed inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear5LW,
		Switch		= ShiftL,
		MaxTorque	= Gear5LT,
		Automatic	= true,
	})
end

do -- Inline Dual Clutch Gearboxes
	ACF.RegisterGearbox("5Gear-A-LD-S", "5-Auto", {
		Name		= "5-Speed Auto, Inline, Small, Dual Clutch",
		Description	= "A small, and light 5 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear5SW,
		Switch		= ShiftS,
		MaxTorque	= Gear5ST,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("5Gear-A-LD-M", "5-Auto", {
		Name		= "5-Speed Auto, Inline, Medium, Dual Clutch",
		Description	= "A medium sized, 5 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear5MW,
		Switch		= ShiftM,
		MaxTorque	= Gear5MT,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("5Gear-A-LD-L", "5-Auto", {
		Name		= "5-Speed Auto, Inline, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 5 speed automatic inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear5LW,
		Switch		= ShiftL,
		MaxTorque	= Gear5LT,
		Automatic	= true,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("5Gear-A-T-S", "5-Auto", {
		Name		= "5-Speed Auto, Transaxial, Small",
		Description	= "A small, and light 5 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear5SW,
		Switch		= ShiftS,
		MaxTorque	= Gear5ST,
		Automatic	= true,
	})

	ACF.RegisterGearbox("5Gear-A-T-M", "5-Auto", {
		Name		= "5-Speed Auto, Transaxial, Medium",
		Description	= "A medium sized, 5 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear5MW,
		Switch		= ShiftM,
		MaxTorque	= Gear5MT,
		Automatic	= true,
	})

	ACF.RegisterGearbox("5Gear-A-T-L", "5-Auto", {
		Name		= "5-Speed Auto, Transaxial, Large",
		Description	= "A large, heavy and sturdy 5 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear5LW,
		Switch		= ShiftL,
		MaxTorque	= Gear5LT,
		Automatic	= true,
	})
end

do -- Transaxial Dual Clutch Gearboxes
	ACF.RegisterGearbox("5Gear-A-TD-S", "5-Auto", {
		Name		= "5-Speed Auto, Transaxial, Small, Dual Clutch",
		Description	= "A small, and light 5 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear5SW,
		Switch		= ShiftS,
		MaxTorque	= Gear5ST,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("5Gear-A-TD-M", "5-Auto", {
		Name		= "5-Speed Auto, Transaxial, Medium, Dual Clutch",
		Description	= "A medium sized, 5 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear5MW,
		Switch		= ShiftM,
		MaxTorque	= Gear5MT,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("5Gear-A-TD-L", "5-Auto", {
		Name		= "5-Speed Auto, Transaxial, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 5 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear5LW,
		Switch		= ShiftL,
		MaxTorque	= Gear5LT,
		Automatic	= true,
		DualClutch	= true,
	})
end

do -- Straight-through Gearboxes
	ACF.RegisterGearbox("5Gear-A-ST-S", "5-Auto", {
		Name		= "5-Speed Auto, Straight, Small",
		Description	= "A small straight-through automatic gearbox",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear5SW * StWB),
		Switch		= ShiftS,
		MaxTorque	= math.floor(Gear5ST * StTB),
		Automatic	= true,
	})

	ACF.RegisterGearbox("5Gear-A-ST-M", "5-Auto", {
		Name		= "5-Speed Auto, Straight, Medium",
		Description	= "A medium sized, 5 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear5MW * StWB),
		Switch		= ShiftM,
		MaxTorque	= math.floor(Gear5MT * StTB),
		Automatic	= true,
	})

	ACF.RegisterGearbox("5Gear-A-ST-L", "5-Auto", {
		Name		= "5-Speed Auto, Straight, Large",
		Description	= "A large sized, 5 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear5LW * StWB),
		Switch		= ShiftL,
		MaxTorque	= math.floor(Gear5LT * StTB),
		Automatic	= true,
	})
end
