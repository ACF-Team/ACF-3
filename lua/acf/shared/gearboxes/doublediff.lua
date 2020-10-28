-- Double Differential 
-- Weight
local GearDDSW = 45
local GearDDMW = 85
local GearDDLW = 180
-- Torque Rating
local GearDDST = 20000
local GearDDMT = 45000
local GearDDLT = 100000
-- general description
local DDDesc = "\n\nA Double Differential transmission allows for a multitude of radii as well as a neutral steer."

-- Inline
ACF_DefineGearbox("DoubleDiff-T-S", {
	name = "Double Differential, Small",
	desc = "A light duty regenerative steering transmission." .. DDDesc,
	model = "models/engines/transaxial_s.mdl",
	category = "Regenerative Steering",
	weight = GearDDSW,
	parentable = true,
	switch = 0.2,
	maxtq = GearDDST,
	gears = 1,
	doublediff = true,
	doubleclutch = true,
	geartable = {
		[0] = 0,
		[1] = 1,
		[-1] = 1
	}
})

ACF_DefineGearbox("DoubleDiff-T-M", {
	name = "Double Differential, Medium",
	desc = "A medium regenerative steering transmission." .. DDDesc,
	model = "models/engines/transaxial_m.mdl",
	category = "Regenerative Steering",
	weight = GearDDMW,
	parentable = true,
	switch = 0.35,
	maxtq = GearDDMT,
	gears = 1,
	doublediff = true,
	doubleclutch = true,
	geartable = {
		[0] = 0,
		[1] = 1,
		[-1] = 1
	}
})

ACF_DefineGearbox("DoubleDiff-T-L", {
	name = "Double Differential, Large",
	desc = "A heavy regenerative steering transmission." .. DDDesc,
	model = "models/engines/transaxial_l.mdl",
	category = "Regenerative Steering",
	weight = GearDDLW,
	parentable = true,
	switch = 0.5,
	maxtq = GearDDLT,
	gears = 1,
	doublediff = true,
	doubleclutch = true,
	geartable = {
		[0] = 0,
		[1] = 1,
		[-1] = 1
	}
})

local function InitGearbox(Gearbox)
	Gearbox.DoubleDiff = true
	Gearbox.SteerRate  = 0

	Gearbox:SetBodygroup(1, 1)
end

ACF.RegisterGearboxClass("DoubleDiff", {
	Name		= "Double Differential",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	},
	OnSpawn = InitGearbox,
	OnUpdate = InitGearbox,
	SetupInputs = function(List)
		List[#List + 1] = "Steer Rate"
	end,
	OnLast = function(Gearbox)
		Gearbox.DoubleDiff = nil
		Gearbox.SteerRate  = nil

		Gearbox:SetBodygroup(1, 0)
	end,
})

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("DoubleDiff-T-S", "DoubleDiff", {
		Name		= "Double Differential, Small",
		Description	= "A light duty regenerative steering transmission.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= GearDDSW,
		Switch		= 0.2,
		MaxTorque	= GearDDST,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("DoubleDiff-T-M", "DoubleDiff", {
		Name		= "Double Differential, Medium",
		Description	= "A medium regenerative steering transmission.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= GearDDMW,
		Switch		= 0.35,
		MaxTorque	= GearDDMT,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("DoubleDiff-T-L", "DoubleDiff", {
		Name		= "Double Differential, Large",
		Description	= "A heavy regenerative steering transmission.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= GearDDLW,
		Switch		= 0.5,
		MaxTorque	= GearDDLT,
		DualClutch	= true,
	})
end
