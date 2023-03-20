local ACF     = ACF
local Weapons = ACF.Classes.Weapons

local OldModels = {
	["models/tankgun/tankgun_100mm.mdl"] = true,
	["models/tankgun/tankgun_120mm.mdl"] = true,
	["models/tankgun/tankgun_140mm.mdl"] = true,
	["models/tankgun/tankgun_170mm.mdl"] = true,
	["models/tankgun/tankgun_37mm.mdl"] = true,
	["models/tankgun/tankgun_50mm.mdl"] = true,
	["models/tankgun/tankgun_75mm.mdl"] = true,
}

-- Bodygroup porting information
-- First table defines the bodygroup from the old model
-- Second table defines the index of of a specific body
-- Third can be either a table, defining the values that need to be applied into the new model
-- or "false", if there's no equivalent in the new model
local PortingData = {
	-- Muzzlebrakes
	[1] = {
		[1] = false,
		[2] = false,
		[3] = { [8] = 5 },
		[4] = { [8] = 1 },
		[5] = false,
		[6] = { [8] = 3 },
		[7] = false,
		[8] = false,
		[9] = { [7] = 4 },
		[10] = { [8] = 2 },
		[11] = { [8] = 4 },
	},
	-- Bore evacuators
	[2] = {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = { [9] = 1 },
		[5] = { [9] = 2 },
		[6] = { [9] = 3 },
	},
}


Weapons.Register("C", {
	Name        = "Cannon",
	Description = "Manually loaded weaponry, allows you fire all kinds of rounds at high velocity.",
	Model       = "models/tankgun_new/tankgun_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 2031,
	Spread      = 0.08,
	Round = {
		MaxLength  = 80,
		PropLength = 65,
	},
	Preview = {
		Height = 50,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 20,
		Max  = 170,
	},
	Sounds = {
		[50] = "acf_base/weapons/ac_fire4.mp3",
	},
	VerifyData = function(Data)
		local Model = Data.Model

		if not (Model and OldModels[Model]) then return end

		local Bodygroups = Data.BodyG
		local Result     = {}

		if Bodygroups then
			for Index, Value in pairs(Bodygroups) do
				local OldData = PortingData[Index]

				if not OldData then continue end

				local NewData = OldData[Value]

				if NewData then
					for NewIndex, NewValue in pairs(NewData) do
						Result[NewIndex] = NewValue or nil
					end
				end

				Bodygroups[Index] = nil
			end
		end

		-- Applying cosmetic features to make it look like the old model
		Result[1] = 1
		Result[4] = 1
		Result[5] = 2

		Data.BodyG = Result
	end,
})

Weapons.RegisterItem("37mmC", "C", {
	Caliber = 37,
})

Weapons.RegisterItem("50mmC", "C", {
	Caliber = 50,
})

Weapons.RegisterItem("75mmC", "C", {
	Caliber = 75,
})

Weapons.RegisterItem("100mmC", "C", {
	Caliber = 100,
})

Weapons.RegisterItem("120mmC", "C", {
	Caliber = 120,
})

Weapons.RegisterItem("140mmC", "C", {
	Caliber = 140,
})

do -- Smoothbore compatibility
	Weapons.AddAlias("C", "SB")

	Weapons.RegisterItem("105mmSB", "C", {
		Caliber = 105,
	})

	Weapons.RegisterItem("120mmSB", "C", {
		Caliber = 120,
	})

	Weapons.RegisterItem("140mmSB", "C", {
		Caliber = 140,
	})
end

ACF.SetCustomAttachment("models/tankgun_new/tankgun_100mm.mdl", "muzzle", Vector(175), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun_new/tankgun_100mm.mdl", {
	Breech = {
		Pos       = Vector(-13),
		Scale     = Vector(36, 12.5, 12.5),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(90),
		Scale = Vector(170, 7.5, 7.5)
	}
})
