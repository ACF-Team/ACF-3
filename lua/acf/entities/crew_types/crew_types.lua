--[[
Most of the crew type specific properties and logic is specified here.

Must be specified:
Name, Description, LimitConVar, LinkHandlers, Mass, UpdateFocus, UpdateEfficiency
]]--


local ACF		= ACF
local CrewTypes	= ACF.Classes.CrewTypes

local table_empty = {}

--- Checks if the number of targets of the class for the crew exceeds the count
--- Default count is 1
local function CheckCount(Crew, Class, Count)
	if not Class then
		return table.Count(Crew.Targets) >= (Count or 1)
	end
	local Targets = Crew.TargetsByType[Class]
	return (Targets and table.Count(Targets) or 0) >= (Count or 1)
end

--- Finds the longest bullet of any gun connected to this crew and adjusts the box accordingly
local function FindLongestBullet(Crew)
	-- Go through every bullet linked to the gun, and find the longest shell
	local LongestLength = 0
	local LongestBullet = nil
	for Gun in pairs(Crew.TargetsByType["acf_gun"] or Crew.TargetsByType["acf_rack"] or table_empty) do
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

	-- If we find such a bullet and it's longer than we've seen before, set the scan box and hull to match it
	if LongestLength > 0 and Crew.LongestLength ~= LongestLength then
		local Length = LongestLength / ACF.InchToCm
		local Caliber = LongestBullet.Caliber / ACF.InchToCm
		Crew.ScanBox = Vector(Length * ACF.CrewSpaceLengthMod, Length * ACF.CrewSpaceLengthMod, Caliber * ACF.CrewSpaceCaliberMod)
		Crew.ScanHull = Vector(Caliber, Caliber, Caliber)
		Crew.LongestLength = LongestLength

		-- Network the scan box to clients
		net.Start("ACF_Crew_Space")
		net.WriteEntity(Crew)
		net.WriteVector(Crew.ScanBox)
		net.WriteVector(Crew.CrewModel.ScanOffsetL)
		net.Broadcast()
	end
end

CrewTypes.Register("Loader", {
	Name        = "Loader",
	Description = "Loaders affect the reload rate of your guns. Link them to gun(s). They prefer standing.",
	ExtraNotes 	= "Loaders can be linked to any gun, but their focus is split between each. Viewing loaders with the acf menu tool will visualize the space they need for peak performance in purple.",
	LimitConVar	= {			-- ConVar to limit the number of crew members of this type a player can have
		Name	= "_acf_crew_loader",
		Amount	= 4,
		Text	= "Maximum number of loaders a player can have."
	},
	Mass = 80,				-- Mass (kg) of a single crew member
	LeanInfo = {			-- Specifying this table enables leaning efficiency calculations (deviation from world up)
		Min = 15,			-- Best efficiency before this angle (Degs)
		Max = 90,			-- Worst efficiency after this angle (Degs)
	},
	GForceInfo = {
		Efficiencies = {	-- Specifying this table enables G force efficiency calculations
			Min = 0,		-- Best efficiency before this (Gs)
			Max = 3,		-- Worst efficiency after this (Gs)
		},
		Damages = {			-- Specifying this table enables G force damage calculations
			Min = 5,		-- Damage starts being applied after this (Gs)
			Max = 9,		-- Instant death after this (Gs)
		}
	},
	SpaceInfo = {			-- Specifying this table enables spatial scans (if linked to a gun)
		ScanStep = 3,		-- How many parts of a scan to update each time
	},
	LinkHandlers = {		-- Custom link handlers for this crew type
		acf_gun = {			-- Specify a target class for it to be included in the whitelist
			OnLink = function(Crew)	Crew.ShouldScan = CheckCount(Crew, "acf_gun") end,
			OnUnlink = function(Crew) Crew.ShouldScan = CheckCount(Crew, "acf_gun") end,
		},
		acf_rack = {
			OnLink = function(Crew)	Crew.ShouldScan = CheckCount(Crew, "acf_rack") end,
			OnUnlink = function(Crew) Crew.ShouldScan = CheckCount(Crew, "acf_rack") end,
		},
	},
	UpdateLowFreq = FindLongestBullet,
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		local CommanderEff = Commander and Commander.TotalEff or 0
		Crew.TotalEff = math.Clamp(CommanderEff * ACF.CrewCommanderCoef + MyEff * ACF.CrewSelfCoef, ACF.CrewFallbackCoef, 1)
	end,
	UpdateFocus = function(Crew) -- Represents the fraction of efficiency a crew can give to its linked entities
		local Count = table.Count(Crew.Targets)
		Crew.Focus = (Count > 0) and (1 / Count) or 1
	end
})

CrewTypes.Register("Gunner", {
	Name        = "Gunner",
	Description = "Gunners affect the accuracy of your gun. Link them to acf turret rings or baseplates. They prefer sitting.",
	ExtraNotes	= "Gunners can only be linked to one type of gun and their focus does not change.",
	LimitConVar	= {
		Name	= "_acf_crew_gunner",
		Amount	= 4,
		Text	= "Maximum number of gunners a player can have."
	},
	Mass = 80,
	LeanInfo = {			-- Specifying this table enables leaning efficiency calculations (deviation from world up)
		Min = 15,			-- Best efficiency before this angle (Degs)
		Max = 90,			-- Worst efficiency after this angle (Degs)
	},
	GForceInfo = {
		Efficiencies = {
			Min = 0,	-- Best efficiency before this (Gs)
			Max = 3,	-- Worst efficiency after this (Gs)
		},
		Damages = {
			Min = 5,	-- Damage starts being applied after this (Gs)
			Max = 9,	-- Instant death after this (Gs)
		}
	},
	LinkHandlers = {
		acf_turret = {
			CanLink = function(Crew, Target) -- Called when a crew member tries to link to an entity
				if CheckCount(Crew) then return false, "Gunners can only link to one entity." end
				if Target.Turret == "Turret-V" then return false, "Gunners cannot link to vertical drives." end
				return true, "Crew linked."
			end
		},
		acf_baseplate = {
			CanLink = function(Crew) -- Called when a crew member tries to link to an entity
				if CheckCount(Crew, "acf_baseplate") then return false, "Gunners can only link to one acf_baseplate." end
				return true, "Crew linked."
			end
		}
	},
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		local CommanderEff = Commander and Commander.TotalEff or 0
		Crew.TotalEff = math.Clamp(CommanderEff * ACF.CrewCommanderCoef + MyEff * ACF.CrewSelfCoef, ACF.CrewFallbackCoef, 1)
	end,
	UpdateFocus = function(Crew)
		Crew.Focus = 1
	end
})

CrewTypes.Register("Driver", {
	Name        = "Driver",
	Description = "Drivers affect the fuel efficiency of your engines. Link them to acf baseplates. They prefer sitting.",
	ExtraNotes	= "Drivers can be linked to any engine and their focus does not change.",
	LimitConVar	= {
		Name	= "_acf_crew_driver",
		Amount	= 2,
		Text	= "Maximum number of drivers a player can have."
	},
	Mass = 80,
	LeanInfo = {			-- Specifying this table enables leaning efficiency calculations (deviation from world up)
		Min = 60,			-- Best efficiency before this angle (Degs)
		Max = 90,			-- Worst efficiency after this angle (Degs)
	},
	GForceInfo = {
		Efficiencies = {
			Min = 0,	-- Best efficiency before this (Gs)
			Max = 3,	-- Worst efficiency after this (Gs)
		},
		Damages = {
			Min = 5,	-- Damage starts being applied after this (Gs)
			Max = 9,	-- Instant death after this (Gs)
		}
	},
	LinkHandlers = {
		acf_baseplate = {
			CanLink = function(Crew) -- Called when a crew member tries to link to an entity
				if CheckCount(Crew) then return false, "Drivers can only link to one entity." end
				return true, "Crew linked."
			end
		}
	},
	UpdateEfficiency = function(Crew, Commander)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		local CommanderEff = Commander and Commander.TotalEff or 0
		Crew.TotalEff = math.Clamp(CommanderEff * ACF.CrewCommanderCoef + MyEff * ACF.CrewSelfCoef, ACF.CrewFallbackCoef, 1)
	end,
	UpdateFocus = function(Crew)
		Crew.Focus = 1
	end
})

CrewTypes.Register("Commander", {
	Name        = "Commander",
	Description = "Commanders coordinate the crew. Works without linking. They prefer sitting.",
	ExtraNotes 	= "You can link them to work like gunners/loaders to operate a RWS for example. However, this reduces their focus and their ability to command the other crew.",
	LimitConVar	= {
		Name	= "_acf_crew_commander",
		Amount	= 1,
		Text	= "Maximum number of commanders a player can have."
	},
	Mass = 80,
	LeanInfo = {			-- Specifying this table enables leaning efficiency calculations (deviation from world up)
		Min = 15,			-- Best efficiency before this angle (Degs)
		Max = 90,			-- Worst efficiency after this angle (Degs)
	},
	GForceInfo = {
		Efficiencies = {
			Min = 0,		-- Best efficiency before this (Gs)
			Max = 3,		-- Worst efficiency after this (Gs)
		},
		Damages = {
			Min = 5,		-- Damage starts being applied after this (Gs)
			Max = 9,		-- Instant death after this (Gs)
		}
	},
	SpaceInfo = {			-- Specifying this table enables spatial scans (if linked to a gun)
		ScanStep = 3,		-- How many parts of a scan to update each time
	},
	LinkHandlers = {
		acf_gun = {
			OnLink = function(Crew)	Crew.ShouldScan = CheckCount(Crew, "acf_gun") end,
			OnUnlink = function(Crew) Crew.ShouldScan = CheckCount(Crew, "acf_gun") end,
		},
		acf_rack = {
			OnLink = function(Crew)	Crew.ShouldScan = CheckCount(Crew, "acf_rack") end,
			OnUnlink = function(Crew) Crew.ShouldScan = CheckCount(Crew, "acf_rack") end,
		},
		acf_turret = {
			CanLink = function(Crew, Target) -- Called when a crew member tries to link to an entity
				if CheckCount(Crew) then return false, "Commanders can only link to one entity." end
				if Target.Turret == "Turret-V" then return false, "Commanders cannot link to vertical drives." end
				return true, "Crew linked."
			end
		},
		acf_baseplate = {
			CanLink = function(Crew) -- Called when a crew member tries to link to an entity
				if CheckCount(Crew, "acf_baseplate") then return false, "Commanders can only link to one acf_baseplate." end
				return true, "Crew linked."
			end
		}
	},
	UpdateLowFreq = FindLongestBullet,
	UpdateEfficiency = function(Crew)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		Crew.TotalEff = math.Clamp(MyEff, ACF.CrewFallbackCoef, 1)
	end,
	UpdateFocus = function(Crew) -- Represents the fraction of efficiency a crew can give to its linked entities
		local Contraption = Crew:GetContraption() or {}
		local CrewCount = (Contraption.Crews and table.Count(Contraption.Crews) or 0) - 1 -- Excluding the commander
		local Count = table.Count(Crew.Targets) + (CrewCount * 1 / ACF.CommanderCapacity) -- 1/3rd focus to each crew, 1 to each other target
		Crew.Focus = (Count > 0) and math.min(1 / Count, 1) or 1
	end
})

CrewTypes.Register("Pilot", {
	Name        = "Pilot",
	Description = "Pilots can sustain higher G tolerances but weigh more (life support systems and G suits). You should only use these on aircraft.",
	ExtraNotes 	= "Pilots do not affect anything at the moment.",
	LimitConVar	= {
		Name	= "_acf_crew_pilot",
		Amount	= 2,
		Text	= "Maximum number of pilots a player can have."
	},
	Mass = 200,			-- Pilots weigh more due to life support systems and G suits
	GForceInfo = {
		Damages = {
			Min = 6,	-- Damage starts being applied after this (Gs)
			Max = 9,	-- Instant death after this (Gs)
		}
	},
	LinkHandlers = {
		acf_gun = {
			OnLink = function(Crew)	Crew.ShouldScan = CheckCount(Crew, "acf_gun") or CheckCount(Crew, "acf_rack") end,
			OnUnlink = function(Crew) Crew.ShouldScan = CheckCount(Crew, "acf_gun") or CheckCount(Crew, "acf_rack") end,
		},
		acf_rack = {
			OnLink = function(Crew)	Crew.ShouldScan = CheckCount(Crew, "acf_gun") or CheckCount(Crew, "acf_rack") end,
			OnUnlink = function(Crew) Crew.ShouldScan = CheckCount(Crew, "acf_gun") or CheckCount(Crew, "acf_rack") end,
		},
		acf_turret = {
			CanLink = function(Crew, Target) -- Called when a crew member tries to link to an entity
				if CheckCount(Crew) then return false, "Pilot can only link to one entity." end
				if Target.Turret == "Turret-V" then return false, "Pilot cannot link to vertical drives." end
				return true, "Crew linked."
			end
		},
		acf_baseplate = {
			CanLink = function(Crew) -- Called when a crew member tries to link to an entity
				if CheckCount(Crew, "acf_baseplate") then return false, "Pilot can only link to one acf_baseplate." end
				return true, "Crew linked."
			end
		}
	},
	UpdateEfficiency = function(Crew)
		local MyEff = Crew.ModelEff * Crew.LeanEff * Crew.SpaceEff * Crew.MoveEff * Crew.HealthEff * Crew.Focus
		Crew.TotalEff = math.Clamp(MyEff, ACF.CrewFallbackCoef, 1)
	end,
	UpdateFocus = function(Crew) -- Represents the fraction of efficiency a crew can give to its linked entities
		local Count = table.Count(Crew.Targets)
		Crew.Focus = (Count > 0) and (1 / Count) or 1
	end,
	EnforceLimits = function(Crew)
		-- Pilots exclude other crew
		local Contraption = Crew:GetContraption() or {}
		local Crews = Contraption.Crews or {}
		for k in pairs(Crews) do
			if k.CrewTypeID ~= "Pilot" then k:Remove() end
		end
	end
})