local ACF = ACF

ACF.Classes.DefineClass("ACF.Piledrivers.Piledriver", function()
	CLASS.Name        	= "Piledriver"
	CLASS.ShortName   	= "PD"
	CLASS.Description 	= "#acf.descs.weapons.pd"
	CLASS.Model       	= "models/piledriver/piledriver_100mm.mdl"
	CLASS.IsScalable  	= true
	CLASS.Mass        	= 1200 -- Relative to the Base caliber
	CLASS.MagSize     	= 15
	CLASS.Cyclic      	= 60
	CLASS.ChargeRate  	= 0.5
	CLASS.Round 		= {
		MaxLength  = 114.3, -- Relative to the Base caliber, in cm
		PropLength = 0,
	}
	CLASS.Preview 		= {
		FOV = 115,
	}
	CLASS.BaseCaliber 	= 100

	MENU_FIELD("Number", "Caliber", {Min = 50, Max = 300, Default = CLASS.BaseCaliber, Decimals = 2})
end)

ACF.SetCustomAttachments("models/piledriver/piledriver_100mm.mdl", {
	{ Name = "muzzle", 	Pos = Vector(20, 0, 0), Ang = Angle(0, 0, 0) },
	{ Name = "tip", 	Pos = Vector(65, 0, 0), Ang = Angle(0, 0, 0) },
})
