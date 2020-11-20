
-- Differentials

local Gear1SW = 10
local Gear1MW = 20
local Gear1LW = 40

ACF.RegisterGearboxClass("Differential", {
	Name		= "Differential",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	}
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("1Gear-L-S", "Differential", {
		Name		= "Differential, Inline, Small",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
	})

	ACF.RegisterGearbox("1Gear-L-M", "Differential", {
		Name		= "Differential, Inline, Medium",
		Description	= "Medium duty differential",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
	})

	ACF.RegisterGearbox("1Gear-L-L", "Differential", {
		Name		= "Differential, Inline, Large",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
	})
end

do -- Inline Dual Clutch Gearboxes
	ACF.RegisterGearbox("1Gear-LD-S", "Differential", {
		Name		= "Differential, Inline, Small, Dual Clutch",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-LD-M", "Differential", {
		Name		= "Differential, Inline, Medium, Dual Clutch",
		Description	= "Medium duty differential",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-LD-L", "Differential", {
		Name		= "Differential, Inline, Large, Dual Clutch",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("1Gear-T-S", "Differential", {
		Name		= "Differential, Small",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
	})

	ACF.RegisterGearbox("1Gear-T-M", "Differential", {
		Name		= "Differential, Medium",
		Description	= "Medium duty differential",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
	})

	ACF.RegisterGearbox("1Gear-T-L", "Differential", {
		Name		= "Differential, Large",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
	})
end

do -- Transaxial Dual Clutch Gearboxes
	ACF.RegisterGearbox("1Gear-TD-S", "Differential", {
		Name		= "Differential, Small, Dual Clutch",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-TD-M", "Differential", {
		Name		= "Differential, Medium, Dual Clutch",
		Description	= "Medium duty differential",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-TD-L", "Differential", {
		Name		= "Differential, Large, Dual Clutch",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
	})
end
