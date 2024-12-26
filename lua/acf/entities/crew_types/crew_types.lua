local ACF         = ACF
local CrewTypes = ACF.Classes.CrewTypes

CrewTypes.Register("Loader", {
	Name        = "Loader",
	Description = "Loaders affect the reload rate of your guns. They prefer standing. To a limit, the more space you have the faster they reload.",
	Whitelist = {
		acf_gun = true,
	},
	Mass = 80,
	GLimit = 4,
	GLimitEff = 2,
	ShouldScan = true,
	ScanStep = 27,
})

CrewTypes.Register("Gunner", {
	Name        = "Gunner",
	Description = "Gunners affect the accuracy of your gun. They prefer sitting.",
	Whitelist = {
		acf_gun = true,
		acf_turret = true,
	},
	Mass = 80,
	GLimit = 4,
	GLimitEff = 2,
	ShouldScan = false,
})

CrewTypes.Register("Driver", {
	Name        = "Driver",
	Description = "Drivers affect the fuel efficiency of your engines. They prefer sitting",
	Whitelist = {
		acf_engine = true,
	},
	Mass = 80,
	GLimit = 4,
	GLimitEff = 2,
	ShouldScan = false,
})

CrewTypes.Register("Commander", {
	Name        = "Commander",
	Description = "Commanders coordinate the crew. They prefer sitting.",
	Whitelist = {},
	Mass = 80,
	GLimit = 4,
	GLimitEff = 2,
	ShouldScan = false,
})

CrewTypes.Register("Pilot", {
	Name        = "Pilot",
	Description = "Pilots can sustain higher G tolerances but weigh more (life support systems and G suits). You should only use these on aircraft, ",
	Whitelist = {},
	Mass = 200,
	GLimit = 9,
	GLimitEff = 2,
	ShouldScan = false,
})