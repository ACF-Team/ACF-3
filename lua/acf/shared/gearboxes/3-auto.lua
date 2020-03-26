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

ACF.RegisterGearboxClass("3-Auto", {
	Name		= "3-Speed Automatic",
	CreateMenu	= ACF.AutomaticGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 3,
	},
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("3Gear-A-L-S", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Small",
		Description	= "A small, and light 3 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		Automatic	= true,
	})

	ACF.RegisterGearbox("3Gear-A-L-M", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Medium",
		Description	= "A medium sized, 3 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		Automatic	= true,
	})

	ACF.RegisterGearbox("3Gear-A-L-L", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Large",
		Description	= "A large, heavy and sturdy 3 speed inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		Automatic	= true,
	})
end

do -- Inline Dual Clutch Gearboxes
	ACF.RegisterGearbox("3Gear-A-LD-S", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Small, Dual Clutch",
		Description	= "A small, and light 3 speed automatic inline gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("3Gear-A-LD-M", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Medium, Dual Clutch",
		Description	= "A medium sized, 3 speed automatic inline gearbox",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("3Gear-A-LD-L", "3-Auto", {
		Name		= "3-Speed Auto, Inline, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 3 speed automatic inline gearbox",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		Automatic	= true,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("3Gear-A-T-S", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Small",
		Description	= "A small, and light 3 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		Automatic	= true,
	})

	ACF.RegisterGearbox("3Gear-A-T-M", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Medium",
		Description	= "A medium sized, 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		Automatic	= true,
	})

	ACF.RegisterGearbox("3Gear-A-T-L", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Large",
		Description	= "A large, heavy and sturdy 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		Automatic	= true,
	})
end

do -- Transaxial Dual Clutch Gearboxes
	ACF.RegisterGearbox("3Gear-A-TD-S", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Small, Dual Clutch",
		Description	= "A small, and light 3 speed automatic gearbox, with a somewhat limited max torque rating",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear3SW,
		Switch		= ShiftS,
		MaxTorque	= Gear3ST,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("3Gear-A-TD-M", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Medium, Dual Clutch",
		Description	= "A medium sized, 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear3MW,
		Switch		= ShiftM,
		MaxTorque	= Gear3MT,
		Automatic	= true,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("3Gear-A-TD-L", "3-Auto", {
		Name		= "3-Speed Auto, Transaxial, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 3 speed automatic gearbox",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear3LW,
		Switch		= ShiftL,
		MaxTorque	= Gear3LT,
		Automatic	= true,
		DualClutch	= true,
	})
end

do -- Straight-through Gearboxes
	ACF.RegisterGearbox("3Gear-A-ST-S", "3-Auto", {
		Name		= "3-Speed Auto, Straight, Small",
		Description	= "A small straight-through automatic gearbox",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear3SW * StWB),
		Switch		= ShiftS,
		MaxTorque	= math.floor(Gear3ST * StTB),
		Automatic	= true,
	})

	ACF.RegisterGearbox("3Gear-A-ST-M", "3-Auto", {
		Name		= "3-Speed Auto, Straight, Medium",
		Description	= "A medium sized, 3 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear3MW * StWB),
		Switch		= ShiftM,
		MaxTorque	= math.floor(Gear3MT * StTB),
		Automatic	= true,
	})

	ACF.RegisterGearbox("3Gear-A-ST-L", "3-Auto", {
		Name		= "3-Speed Auto, Straight, Large",
		Description	= "A large sized, 3 speed automatic straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear3LW * StWB),
		Switch		= ShiftL,
		MaxTorque	= math.floor(Gear3LT * StTB),
		Automatic	= true,
	})
end
