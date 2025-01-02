--[[
Most of the crew type specific properties and logic is specified here.

Must be specified:
Name, Description, LimitConVar, Whitelist, Mass, UpdateFocus, UpdateEfficiency
]]--


local ACF         = ACF
local CrewTypes = ACF.Classes.CrewTypes

CrewTypes.Register("Loader", {
	Name        = "Loader",
	Description = "Loaders affect the reload rate of your guns. They prefer standing. To a limit, the more space you have the faster they reload.",
	LimitConVar	= {			-- ConVar to limit the number of crew members of this type a player can have
		Name	= "_acf_crew_loader",
		Amount	= 4,
		Text	= "Maximum number of loaders a player can have."
	},
	Whitelist = {			-- What entities can this crew type can link to and affect
		acf_gun = true, 	-- Loaders affect gun reload rates
	},
	Mass = 80,				-- Mass (kg) of a single crew member
	LeanInfo = {			-- Specifying this table enables leaning efficiency calculations
		Min = 15,			-- Best efficiency before this angle (Degs)
		Max = 90,			-- Worst efficiency after this angle (Degs)
	},
	GForceInfo = {
		Efficiencies = {	-- Specifying this table enables G force efficiency calculations
			Min = 0,		-- Best efficiency before this (Gs)
			Max = 3,		-- Worst efficiency after this (Gs)
		},
		Damages = {			-- Specifying this table enables G force damage calculations
			Min = 6,		-- Damage starts being applied after this (Gs)
			Max = 9,		-- Instant death after this (Gs)
		}
	},
	SpaceInfo = {			-- Specifying this table enables spatial scans (if linked to a gun)
		ScanStep = 27,		-- How many parts of a scan to update each time
	},
	OnLink = function(Crew, Target) -- Called when a crew member links to an entity
		if Target:GetClass() ~= "acf_gun" then return end
		Crew.ShouldScan = true
	end,
	OnUnlink = function(Crew, Target) -- Called when a crew member unlinks from an entity
		if Target:GetClass() ~= "acf_gun" then return end
		if table.Count(Crew.TargetsByType["acf_gun"]) == 0 then
			Crew.ShouldScan = false
		end
	end,
	UpdateLowFreq = function(Crew)
		-- Go through every bullet linked to the gun, and find the longest shell
		local LongestLength = 0
		local LongestBullet = nil
		for Gun in pairs(Crew.TargetsByType["acf_gun"] or {}) do
			if not IsValid(Gun) then continue end
			for Crate in pairs(Gun.Crates) do
				local BulletData = Crate.BulletData
				local Length = BulletData.PropLength + BulletData.ProjLength
				if Length > LongestLength then
					LongestLength = Length
					LongestBullet = BulletData
				end
			end
		end

		-- If we find such a bullet, set the scan box and hull to match it
		if LongestBullet then
			local Length = LongestLength / 2.54 -- CM to inches
			local Caliber = LongestBullet.Caliber / 2.54 -- CM to inches
			Crew.ScanBox = Vector(Length, Length, Caliber)
			Crew.ScanHull = Vector(Caliber, Caliber, Caliber)
		end
	end,
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		local CommanderEff = Commander and Commander.TotalEff or 0
		-- print("Loader Commander Eff: ", CommanderEff * ACF.CrewCommanderCoef)
		-- print("Loader Self Eff: ", MyEff * ACF.CrewSelfCoef)
		Crew.TotalEff = math.Clamp(CommanderEff * ACF.CrewCommanderCoef + MyEff * ACF.CrewSelfCoef, ACF.CrewFallbackCoef, 1)
	end,
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
	LeanInfo = {			-- Specifying this table enables leaning efficiency calculations
		Min = 15,			-- Best efficiency before this angle (Degs)
		Max = 90,			-- Worst efficiency after this angle (Degs)
	},
	GForceInfo = {
		Efficiencies = {
			Min = 0,	-- Best efficiency before this (Gs)
			Max = 3,	-- Worst efficiency after this (Gs)
		},
		Damages = {
			Min = 6,	-- Damage starts being applied after this (Gs)
			Max = 9,	-- Instant death after this (Gs)
		}
	},
	CanLink = function(Crew, Target) -- Called when a crew member tries to link to an entity
		if Crew.GunName and Target.Name ~= Crew.GunName then return false, "Gunners can only be linked to one type of gun" end
		return true, "Crew linked."
	end,
	OnLink = function(Crew, Target) -- Called when a crew member links to an entity
		if Target:GetClass() ~= "acf_gun" then return end
		Crew.GunName = Target.Name
	end,
	OnUnlink = function(Crew, Target) -- Called when a crew member unlinks from an entity
		if Target:GetClass() ~= "acf_gun" then return end
		if table.Count(Crew.TargetsByType["acf_gun"]) == 0 then
			Crew.GunName = nil
		end
	end,
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		local CommanderEff = Commander and Commander.TotalEff or 1
		Crew.TotalEff = math.Clamp(CommanderEff * ACF.CrewCommanderCoef + MyEff * ACF.CrewSelfCoef, ACF.CrewFallbackCoef, 1)
	end,
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
	GForceInfo = {
		Efficiencies = {
			Min = 0,	-- Best efficiency before this (Gs)
			Max = 3,	-- Worst efficiency after this (Gs)
		},
		Damages = {
			Min = 6,	-- Damage starts being applied after this (Gs)
			Max = 9,	-- Instant death after this (Gs)
		}
	},
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		local CommanderEff = Commander and Commander.TotalEff or 1
		Crew.TotalEff = math.Clamp(CommanderEff * ACF.CrewCommanderCoef + MyEff * ACF.CrewSelfCoef, ACF.CrewFallbackCoef, 1)
	end,
	UpdateFocus = function(Crew)
		Crew.Focus = 1
	end
})

CrewTypes.Register("Commander", {
	Name        = "Commander",
	Description = "Commanders coordinate the crew. They prefer sitting.",
	Whitelist = {
		acf_gun = true, 	-- Only to support RWS
	},
	LimitConVar	= {
		Name	= "_acf_crew_commander",
		Amount	= 1,
		Text	= "Maximum number of commanders a player can have."
	},
	Mass = 80,
	LeanInfo = {			-- Specifying this table enables leaning efficiency calculations
		Min = 15,			-- Best efficiency before this angle (Degs)
		Max = 90,			-- Worst efficiency after this angle (Degs)
	},
	GForceInfo = {
		Efficiencies = {
			Min = 0,		-- Best efficiency before this (Gs)
			Max = 3,		-- Worst efficiency after this (Gs)
		},
		Damages = {
			Min = 6,		-- Damage starts being applied after this (Gs)
			Max = 9,		-- Instant death after this (Gs)
		}
	},
	SpaceInfo = {			-- Specifying this table enables spatial scans (if linked to a gun)
		ScanStep = 3,		-- How many parts of a scan to update each time
	},
	CanLink = function(Crew, Target) -- Called when a crew member tries to link to an entity
		if Crew.GunName and Target.Name ~= Crew.GunName then return false, "Commanders can only be linked to one type of gun" end
		return true, "Crew linked."
	end,
	OnLink = function(Crew, Target) -- Called when a crew member links to an entity
		if Target:GetClass() ~= "acf_gun" then return end
		Crew.GunName = Target.Name
		Crew.ShouldScan = true
	end,
	OnUnlink = function(Crew, Target) -- Called when a crew member unlinks from an entity
		if Target:GetClass() ~= "acf_gun" then return end
		if table.Count(Crew.TargetsByType["acf_gun"]) == 0 then
			Crew.GunName = nil
			Crew.ShouldScan = false
		end
	end,
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		Crew.TotalEff = math.Clamp(MyEff, ACF.CrewFallbackCoef, 1)
	end,
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
	GForceInfo = {
		Efficiencies = {
			Min = 0,	-- Best efficiency before this (Gs)
			Max = 3,	-- Worst efficiency after this (Gs)
		},
		Damages = {
			Min = 6,	-- Damage starts being applied after this (Gs)
			Max = 9,	-- Instant death after this (Gs)
		}
	},
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		Crew.TotalEff = math.Clamp(MyEff, ACF.CrewFallbackCoef, 1)
	end,
	UpdateFocus = function(Crew) return 1 end
})