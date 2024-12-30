local ACF         = ACF
local CrewTypes = ACF.Classes.CrewTypes

CrewTypes.Register("Loader", {
	Name        = "Loader",
	Description = "Loaders affect the reload rate of your guns. They prefer standing. To a limit, the more space you have the faster they reload.",
	LimitConVar	= {
		Name	= "_acf_crew_loader",
		Amount	= 4,
		Text	= "Maximum number of loaders a player can have."
	},
	Whitelist = {		-- What entities can this crew type can link to and affect
		acf_gun = true, -- Loaders affect gun reload rates
	},
	Mass = 80,			-- Mass (kg) of a single crew member
	GForces = {
		Efficiencies = {
			Min = 0,	-- Minimum Gs before efficiency starts dropping
			Max = 3,	-- Maximum Gs before efficiency is 0
		},
		Damages = {
			Min = 3,	-- Minimum Gs before damage starts being applied
			Max = 6,	-- Maximum Gs before instant death
		}
	},
	ShouldScan = true,	-- Whether to check space around the crew
	ScanStep = 3,		-- How many parts of a scan to update each time
	UpdateFocus = function(Crew) -- Represents the fraction of efficiency a crew can give to its linked entities
		local Count = table.Count(Crew.Targets)
		Crew.Focus = (Count > 0) and 1 / Count or 1
	end
})

CrewTypes.Register("Gunner", {
	Name        = "Gunner",
	Description = "Gunners affect the accuracy of your gun. They prefer sitting.",
	LimitConVar	= {
		Name	= "_acf_crew_gunner",
		Amount	= 4,
		Text	= "Maximum number of gunners a player can have."
	},
	Whitelist = {
		acf_gun = true,		-- Gunners affect gun accuracy
		acf_turret = true,
	},
	Mass = 80,
	GForces = {
		Efficiencies = {
			Min = 0,	-- Minimum Gs before efficiency starts dropping
			Max = 3,	-- Maximum Gs before efficiency is 0
		},
		Damages = {
			Min = 3,	-- Minimum Gs before damage starts being applied
			Max = 6,	-- Maximum Gs before instant death
		}
	},
	ShouldScan = false,
	UpdateFocus = function(Crew)
		Crew.Focus = 1
	end
})

CrewTypes.Register("Driver", {
	Name        = "Driver",
	Description = "Drivers affect the fuel efficiency of your engines. They prefer sitting",
	LimitConVar	= {
		Name	= "_acf_crew_driver",
		Amount	= 2,
		Text	= "Maximum number of drivers a player can have."
	},
	Whitelist = {
		acf_engine = true, -- Drivers affect engine fuel efficiency
	},
	Mass = 80,
	GForces = {
		Efficiencies = {
			Min = 0,	-- Minimum Gs before efficiency starts dropping
			Max = 3,	-- Maximum Gs before efficiency is 0
		},
		Damages = {
			Min = 3,	-- Minimum Gs before damage starts being applied
			Max = 6,	-- Maximum Gs before instant death
		}
	},
	ShouldScan = false,
	UpdateFocus = function(Crew)
		Crew.Focus = 1
	end
})

CrewTypes.Register("Commander", {
	Name        = "Commander",
	Description = "Commanders coordinate the crew. They prefer sitting.",
	Whitelist = {
		acf_gun = true, -- Only to support RWS
	},
	LimitConVar	= {
		Name	= "_acf_crew_commander",
		Amount	= 1,
		Text	= "Maximum number of commanders a player can have."
	},
	Mass = 80,
	GForces = {
		Efficiencies = {
			Min = 0,	-- Minimum Gs before efficiency starts dropping
			Max = 3,	-- Maximum Gs before efficiency is 0
		},
		Damages = {
			Min = 3,	-- Minimum Gs before damage starts being applied
			Max = 6,	-- Maximum Gs before instant death
		}
	},
	ShouldScan = false,
	UpdateFocus = function(Crew) -- Represents the fraction of efficiency a crew can give to its linked entities
		local Count = table.Count(Crew.Targets) + 1 -- +1 for commanding the crew
		Crew.Focus = (Count > 0) and 1 / Count or 1
	end
})

CrewTypes.Register("Pilot", {
	Name        = "Pilot",
	Description = "Pilots can sustain higher G tolerances but weigh more (life support systems and G suits). You should only use these on aircraft, ",
	Whitelist = {},
	LimitConVar	= {
		Name	= "_acf_crew_pilot",
		Amount	= 2,
		Text	= "Maximum number of pilots a player can have."
	},
	Mass = 200,			-- Pilots weigh more due to life support systems and G suits
	GForces = {
		Efficiencies = {
			Min = 0,	-- Minimum Gs before efficiency starts dropping
			Max = 3,	-- Maximum Gs before efficiency is 0
		},
		Damages = {
			Min = 3,	-- Minimum Gs before damage starts being applied
			Max = 6,	-- Maximum Gs before instant death
		}
	},
	ShouldScan = false,
	UpdateFocus = function(Crew) return 1 end
})