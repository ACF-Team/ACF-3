local ACF = ACF
local Turrets = ACF.Classes.Turrets

Turrets.Register("2-Motor",{
	Name		= "Motors",
	Description	= "Slewing drive motors, to increase operational speeds and get you on target.\nMust be parented to or share the parent with the linked turret drive.\nMust also be close to the linked turret (Within or close to diameter).",
	Entity		= "acf_turret_motor",
	CreateMenu	= ACF.CreateTurretMotorMenu,
	LimitConVar	= {
		Name	= "_acf_turret_motor",
		Amount	= 20,
		Text	= "Maximum number of ACF turret components a player can create."
	},

	GetTorque	= function(Data, CompSize)
		local SizePerc = (CompSize - Data.ScaleLimit.Min) / (Data.ScaleLimit.Max - Data.ScaleLimit.Min)
		return math.Round((Data.Torque.Min * (1 - SizePerc)) + (Data.Torque.Max * SizePerc))
	end,

	CalculateSpeed	= function(self)
		if self.Active == false then return 0 end
		return self.Speed * self.DamageScale
	end,
})

do	-- Motor, should be parented to the turret ring, or share the same parent

	-- Electric motor

	Turrets.RegisterItem("Motor-ELC","2-Motor",{
		Name			= "Electric Motor",
		Description		= "A snappy responsive electric motor, can handle most uses cases but quickly falters under higher weights",
		Model			= "models/engines/emotor-standalone-sml.mdl",
		Sound			= "acf_extra/tankfx/turretelectric2.wav",

		Mass			= 60, -- Base mass, will be further modified by settings
		Speed			= 720, -- Base speed, this will/not/change, and is used in calculating the final speed after teeth calculation
		Efficiency		= 0.9,
		Accel			= 2, -- Time in seconds to reach full speed. Electric motors have instant response

		ScaleLimit		= { -- For scaling the motor size
			Min		= 0.5,
			Max		= 6
		},

		Teeth			= { -- Adjustable for speed versus torque
			Base	= 12,

			Min		= 8,
			Max		= 24,
		},

		Torque			= {
			Min		= 20,
			Max		= 400
		}
	})

	-- Hydraulic motor

	Turrets.RegisterItem("Motor-HYD","2-Motor",{
		Name			= "Hydraulic Motor",
		Description		= "A strong but sluggish hydraulic motor, it'll turn the world over but takes a little bit to get to that point.",
		Model			= "models/xqm/hydcontrolbox.mdl",
		Sound			= "acf_extra/turret/cannon_turn_loop_1.wav",

		Mass			= 80, -- Base mass, will be further modified by settings
		Speed			= 360, -- Base speed, this will/not/change, and is used in calculating the final speed after teeth calculation
		Efficiency		= 0.98,
		Accel			= 8, -- Time in seconds to reach full speed, hydraulic motors have a little spool time

		ScaleLimit		= { -- For scaling the motor size
			Min		= 0.5,
			Max		= 6
		},

		Teeth			= { -- Adjustable for speed versus torque
			Base	= 12,

			Min		= 8,
			Max		= 24,
		},

		Torque			= {
			Min		= 40,
			Max		= 800
		}
	})
end