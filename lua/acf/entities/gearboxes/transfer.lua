local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

local Gear2SW = 20

-- Old gearbox scales
local ScaleT = 0.75
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5

Gearboxes.Register("Transfer", {
	Name		= "Transfer Case",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 2,
	}
})

do -- Scalable gearboxes
	Gearboxes.RegisterItem("2Gear-L", "Transfer", {
		Name			= "Transfer Case, Inline",
		Description		= "2 speed gearbox. Useful for low/high range and tank turning.",
		Model			= "models/engines/linear_s.mdl",
		Mass			= Gear2SW,
		Switch			= 0.3,
		MaxTorque		= 6000,
		DualClutch		= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("2Gear-T", "Transfer", {
		Name			= "Transfer Case",
		Description		= "2 speed gearbox. Useful for low/high range and tank turning.",
		Model			= "models/engines/transaxial_s.mdl",
		Mass			= Gear2SW,
		Switch			= 0.3,
		MaxTorque		= 6000,
		DualClutch		= true,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Pre-Scalable Inline/Transaxial Gearboxes
	local OldGearboxTypes = {"L", "T"}

	for _, GearboxType in ipairs(OldGearboxTypes) do
		local OldCategory = "2Gear-" .. GearboxType

		-- Regular Gearboxes
		Gearboxes.AddItemAlias("Transfer", OldCategory, OldCategory .. "-S", {
			Scale = ScaleS,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias("Transfer", OldCategory, OldCategory .. "-M", {
			Scale = ScaleM,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias("Transfer", OldCategory, OldCategory .. "-L", {
			Scale = ScaleL,
			InvertGearRatios = true,
		})

		-- ACF Extras Gearboxes
		Gearboxes.AddItemAlias("Transfer", OldCategory, OldCategory .. "-T", {
			Scale = ScaleT,
			InvertGearRatios = true,
		})
	end
end