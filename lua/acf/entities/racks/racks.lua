local Classes = ACF.Classes

Classes.DefineClass("ACF.Racks.1xRK", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Single Munition Rack"
	CLASS.Description	= "A rather long but light rack that can hold a single missile or bomb."
	CLASS.Model		= "models/missiles/rkx1.mdl"
	CLASS.Mass		= 79
	CLASS.Year		= 1915
	CLASS.Armor		= 10
	CLASS.Preview = {
		Height = 50,
		FOV    = 60,
	}

	CLASS.CanDropMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, 0, 2.5), Direction = Vector(0, 0, -1) }
	}
end)

Classes.DefineClass("ACF.Racks.1xRK_small", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Small Single Munition Rack"
	CLASS.Description	= "A shorter version of the regular single munition rack, tends to be limited to smaller munitions."
	CLASS.Model		= "models/missiles/rkx1_sml.mdl"
	CLASS.Mass		= 31
	CLASS.Year		= 1915
	CLASS.Armor		= 10
	CLASS.Preview = {
		Height = 100,
		FOV    = 60,
	}

	CLASS.CanDropMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, 0, 2.5), Direction = Vector(0, 0, -1) }
	}
end)

Classes.DefineClass("ACF.Racks.2xRK", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Dual Munitions Rack"
	CLASS.Description	= "A rather lightweight rack with two mounting points separated horizontally."
	CLASS.Model		= "models/missiles/rack_double.mdl"
	CLASS.Mass		= 160
	CLASS.Year		= 1915
	CLASS.Armor		= 10
	CLASS.Preview = {
		FOV = 85,
	}

	CLASS.CanDropMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(4, -14, -1.7), Direction = Vector(0, -1, 0), Angle = Angle(0, 0, -90) },
		{ Name = "missile2", Position = Vector(4, 14, -1.7), Direction = Vector(0, 1, 0), Angle = Angle(0, 0, 90) }
	}
end)

Classes.DefineClass("ACF.Racks.3xRK", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Triple Munitions Rack"
	CLASS.Description	= "Based on the BRU-42 Triple Ejector Rack, it can hold up to three bombs."
	CLASS.Model		= "models/missiles/bomb_3xrk.mdl"
	CLASS.Mass		= 61
	CLASS.Year		= 1936
	CLASS.Armor		= 10
	CLASS.Preview = {
		FOV = 75,
	}

	CLASS.CanDropMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(-4, 0, -8.8), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(-4, 3.7, -0.2), Direction = Vector(0, 0.75, -0.75), Angle = Angle(0, 0, 45) },
		{ Name = "missile3", Position = Vector(-4, -3.7, -0.2), Direction = Vector(0, -0.75, -0.75), Angle = Angle(0, 0, -45) },
	}
end)

Classes.DefineClass("ACF.Racks.4xRK", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Quad Munitions Rack"
	CLASS.Description	= "Despite its rather small size, it can hold up to 4 different munitions."
	CLASS.Model		= "models/missiles/rack_quad.mdl"
	CLASS.Mass		= 92
	CLASS.Year		= 1936
	CLASS.Armor		= 10
	CLASS.Preview = {
		FOV = 115,
	}

	CLASS.CanDropMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, -12.5, -4.5), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(0, 12.5, -4.5), Direction = Vector(0, 0, -1) },
		{ Name = "missile3", Position = Vector(0, 13, 9), Direction = Vector(0, 1, 0), Angle = Angle(0, 0, 90) },
		{ Name = "missile4", Position = Vector(0, -13, 9), Direction = Vector(0, -1, 0), Angle = Angle(0, 0, -90) },
	}
end)

Classes.DefineClass("ACF.Racks.2x AGM-114", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Dual Hellfire Rack"
	CLASS.Description	= "Based on the upper section of the M299 Launcher, can load up to two missiles."
	CLASS.Model		= "models/missiles/agm_114_2xrk.mdl"
	CLASS.Mass		= 60
	CLASS.Year		= 1984
	CLASS.Armor		= 5
	CLASS.Preview = {
		Height = 90,
		FOV    = 60,
	}

	CLASS.CanDropMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, -7.85, 4.9), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(0, 8.05, 4.9), Direction = Vector(0, 0, -1) },
	}
end)

Classes.DefineClass("ACF.Racks.4x AGM-114", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Quad Hellfire Rack"
	CLASS.Description	= "Based on the M299 Launcher, it's capable of loading up to four missiles."
	CLASS.Model		= "models/missiles/agm_114_4xrk.mdl"
	CLASS.Mass		= 162
	CLASS.Year		= 1984
	CLASS.Armor		= 5
	CLASS.Preview = {
		FOV = 100,
	}

	CLASS.CanDropMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, -7.85, 4.9), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(0, 8.05, 4.9), Direction = Vector(0, 0, -1) },
		{ Name = "missile3", Position = Vector(0, -7.85, -13), Direction = Vector(0, 0, -1) },
		{ Name = "missile4", Position = Vector(0, 8.05, -13), Direction = Vector(0, 0, -1) }
	}
end)

Classes.DefineClass("ACF.Racks.1xAT3RK", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Single 9M14 Rack"
	CLASS.Description	= "Based on the 9P111 Portable Launcher, it can load a single 9M14 missile."
	CLASS.Model		= "models/missiles/at3rk.mdl"
	CLASS.Mass		= 17
	CLASS.Year		= 1969
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		FOV = 110,
	}

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(3.4, -0.2, 0.95) }
	}
end)

Classes.DefineClass("ACF.Racks.1xAT3RKS", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Single 9M14 Rail"
	CLASS.Description	= "Consisting of only the launch rail, it can be used to carry a single 9M14 missile on any kind of vehicle."
	CLASS.Model		= "models/missiles/at3rs.mdl"
	CLASS.Mass		= 8
	CLASS.Year		= 1972
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		FOV = 80,
	}

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(21, -0.2, 6.1) }
	}
end)
