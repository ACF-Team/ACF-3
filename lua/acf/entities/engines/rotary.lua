local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("R", {
	Name		= "Rotary Engine",
	Description	= "Wankels have rather wide powerbands, but are very high strung."
})

do
	Engines.RegisterItem("900cc-R", "R", {
		Name		 = "0.9L Rotary",
		Description	 = "Small 2-rotor Wankel, suited for yard use.",
		Model		 = "models/engines/wankel_2_small.mdl",
		Sound		 = "acf_base/engines/wankel_small.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 50,
		Torque		 = 97,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 950,
			Limit	= 9200,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("1.3L-R", "R", {
		Name		 = "1.3L Rotary",
		Description	 = "Medium 2-rotor Wankel.",
		Model		 = "models/engines/wankel_2_med.mdl",
		Sound		 = "acf_base/engines/wankel_medium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 140,
		Torque		 = 155,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 950,
			Limit	= 9000,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("2.0L-R", "R", {
		Name		 = "2.0L Rotary",
		Description	 = "High performance 3-rotor Wankel.",
		Model		 = "models/engines/wankel_3_med.mdl",
		Sound		 = "acf_base/engines/wankel_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 200,
		Torque		 = 235,
		FlywheelMass = 0.1,
		RPM = {
			Idle	= 950,
			Limit	= 9500,
		},
		Preview = {
			FOV = 105,
		},
	})
end

ACF.SetCustomAttachment("models/engines/wankel_4_med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/wankel_3_med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/wankel_2_med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/wankel_2_small.mdl", "driveshaft", Vector(), Angle(0, 0, 90))

ACF.AddHitboxes("models/engines/wankel_4_med.mdl", {
	Main = {
		Pos       = Vector(13),
		Scale     = Vector(26.5, 13, 17),
		Sensitive = true
	}
})

ACF.AddHitboxes("models/engines/wankel_3_med.mdl", {
	Main = {
		Pos       = Vector(10.25),
		Scale     = Vector(22,13,17),
		Sensitive = true
	}
})

ACF.AddHitboxes("models/engines/wankel_2_med.mdl", {
	Main = {
		Pos       = Vector(7.5),
		Scale     = Vector(16, 13, 17),
		Sensitive = true
	}
})

ACF.AddHitboxes("models/engines/wankel_2_small.mdl", {
	Main = {
		Pos       = Vector(6),
		Scale     = Vector(13, 10, 14),
		Sensitive = true
	}
})
