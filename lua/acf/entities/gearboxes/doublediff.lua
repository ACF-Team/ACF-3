local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local GearDDSW = 45

-- Torque Rating
local GearDDST = 4500

-- Old gearbox scales
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5

local function InitGearbox(Gearbox)
	Gearbox.DoubleDiff = true
	Gearbox.SteerRate  = 0

	Gearbox:SetBodygroup(1, 1)
end

Gearboxes.Register("DoubleDiff", {
	Name		= "Double Differential",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	},
	OnSpawn = InitGearbox,
	OnUpdate = InitGearbox,
	SetupInputs = function(_, List)
		List[#List + 1] = "Steer Rate (From -1 to 1, defines the rate of steering.\nSetting it outside the +-0.5 bounds will produce pivot steering.)"
	end,
	OnLast = function(Gearbox)
		Gearbox.DoubleDiff = nil
		Gearbox.SteerRate  = nil

		Gearbox:SetBodygroup(1, 0)
	end,
})

do -- Transaxial Gearboxes
	Gearboxes.RegisterItem("DoubleDiff-T", "DoubleDiff", {
		Name		= "Double Differential",
		Description	= "A light duty regenerative steering transmission.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= GearDDSW,
		Switch		= 0.2,
		MaxTorque	= GearDDST,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.AddItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-S", {
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-M", {
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-L", {
		Scale = ScaleL,
		InvertGearRatios = true,
	})
end