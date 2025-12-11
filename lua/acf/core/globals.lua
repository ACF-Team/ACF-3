local ACF = ACF

do
	-- MARCH:
	-- Until things load, theres no way to register settings, so all the settings stuff gets created here.
	-- Data callbacks later creates ACF.__OnDefinedSetting (and also goes through everything defined here).
	-- Both combined should ensure that no matter where ACF.DefineSetting is called, it will be registered
	-- (but for official addon stuff, we should just define it here)

	-- It would be ideal if we could put this stuff somewhere else for organization's sake, but for that I
	-- think we'd need to modify gloader, since iirc load order starts with Addon/core/[A-Z order] and
	-- globals is the first file that would load...

	ACF.__DefinedSettings = ACF.__DefinedSettings or {}

	-- This is kind of a weird API, but it allows DataCallback functions to set setting data as long as the key
	-- isn't the default values (Key, Default, TextWhenChanged, Callback). Just call ACF.GetWorkingSetting() in
	-- a data callback
	local SettingData = {}

	-- Defines a single setting.
	-- Internally sets up the global, then registers the setting data.

	-- A callback function can be provided. This callback should be a function that takes in a string Key and a
	-- arbitrary type Value, and returns Value back. You can use a function that returns a function to create a
	-- standard for a specific type; see ACF.BooleanDataCallback, FloatDataCallback, etc for examples of how that
	-- behavior works.

	function ACF.DefineSetting(Key, Default, TextWhenChanged, Callback)
		ACF[Key] = Default

		SettingData.Key             = Key
		SettingData.Default         = Default
		SettingData.TextWhenChanged = TextWhenChanged
		SettingData.Callback        = Callback

		ACF.__DefinedSettings[Key]  = SettingData
		SettingData                 = {}

		if ACF.__OnDefinedSetting then
			ACF.__OnDefinedSetting(Key, Default, TextWhenChanged, Callback)
		end
	end

	-- Returns the current value for the setting (ACF[Key]), along with the settings data.
	function ACF.GetSetting(Key)
		if not ACF[Key] then return end

		return ACF[Key], ACF.__DefinedSettings[Key]
	end

	-- Returns the current settings table. Note that immediately upon the execution of ACF.DefineSetting(),
	-- SettingData is set to a new table; this is meant to be used in a data callback context (to write things
	-- like minimum and maximum values for the panel, for example)
	function ACF.GetWorkingSetting()
		return SettingData
	end

	function ACF.BooleanDataCallback(Callback)
		local SettingData = ACF.GetWorkingSetting()
		SettingData.Type = "Boolean"

		return function(_, Value)
			Value = tobool(Value)

			if Callback then
				Callback(Value)
			end

			return Value
		end
	end

	function ACF.FactorDataCallback(ThreshKey, Min, Max, Decimals)
		local SettingData = ACF.GetWorkingSetting()
		SettingData.Type     = "Factor"
		SettingData.ThreshKey = ThreshKey
		SettingData.Min       = Min
		SettingData.Max       = Max
		SettingData.Decimals  = Decimals

		return function(Key, Value)
			local Factor = math.Round(tonumber(Value) or 1, Decimals or 2)
			if Min then Factor = math.max(Factor, Min) end
			if Max then Factor = math.min(Factor, Max) end

			local Old = ACF[Key]
			ACF[ThreshKey] = ACF[ThreshKey] / Old * Factor

			return Factor
		end
	end

	function ACF.FloatDataCallback(Min, Max, Decimals)
		local SettingData = ACF.GetWorkingSetting()
		SettingData.Type     = "Float"
		SettingData.Min       = Min
		SettingData.Max       = Max
		SettingData.Decimals  = Decimals

		return function(_, Value)
			local Float = math.Round(tonumber(Value) or 1, Decimals or 2)
			if Min then Float = math.max(Float, Min) end
			if Max then Float = math.min(Float, Max) end

			return Float
		end
	end
end

do -- ACF global vars
	ACF.AmmoCrates           = ACF.AmmoCrates or {}
	ACF.FuelTanks            = ACF.FuelTanks or {}
	ACF.Repositories         = ACF.Repositories or {}
	ACF.ClientData           = ACF.ClientData or {}
	ACF.ServerData           = ACF.ServerData or {}
	ACF.ModelData            = ACF.ModelData or { Models = {} }

	-- General Settings
	ACF.DefineSetting("AllowAdminData",       false,  "Admin server data access has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RestrictInfo",         true,   "Entity information restrictions have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("LegalChecks",          true,   "Legality checks for ACF entities has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("NameAndShame",         false,  "Console messages for failed legality checks have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("VehicleLegalChecks",   true,   "Legality checks for vehicles has been %s.", ACF.BooleanDataCallback())

	ACF.DefineSetting("GunsCanFire",          true,   "Gunfire has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("GunsCanSmoke",         true,   "Gun sounds and particles have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RacksCanFire",         true,   "Missile racks have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RequireFuel",          true,   "Engine fuel requirements have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("AllowBaseplateDamage", false,  "Non-ACF damage while driving baseplates has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("SquishyDamageMult",    1,      "Player/NPC damage multiplier has been set to a factor of %.2f.", ACF.FloatDataCallback(0.1, 2, 2))

	ACF.Threshold = 264.7
	ACF.DefineSetting("HealthFactor",         1,      "Health multiplier has been set to a factor of %.2f.", ACF.FactorDataCallback("Threshold", 0.01, 2, 2))

	ACF.ArmorMod = 1
	ACF.DefineSetting("ArmorFactor",          1,      "Armor multiplier has been set to a factor of %.2f.", ACF.FactorDataCallback("ArmorMod", 0.01, 2, 2))

	ACF.FuelRate = 15 -- Multiplier for fuel usage, 1.0 is approx real world
	ACF.DefineSetting("FuelFactor",           1,      "Fuel rate multiplier has been set to a factor of %.2f.", ACF.FactorDataCallback("FuelRate", 0.01, 2, 2))

	ACF.MinimumArmor         = 1     -- Minimum possible armor that can be given to an entity
	ACF.MaximumArmor         = 5000  -- Maximum possible armor that can be given to an entity
	ACF.MinDuctility         = -80   -- The minimum amount of ductility that can be set on an entity
	ACF.MaxDuctility         = 80    -- The maximum amount of ductility that can be set on an entity
	ACF.MinimumMass          = 0.1   -- The minimum amount of mass that can be set on an entity
	ACF.MaximumMass          = 50000 -- The maximum amount of mass that can be set on an entity
	ACF.DefineSetting("MaxThickness",         300,    nil, ACF.FloatDataCallback(ACF.MinimumArmor, ACF.MaximumArmor, 0))

	ACF.DefineSetting("SmokeWind",            20,     "Wind smoke multiplier has been set to a factor of %.2f.", ACF.FloatDataCallback(0, 1000, 2))

	ACF.DefineSetting("HEPush",               true,   "Explosive energy entity pushing has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("KEPush",               true,   "Kinetic energy entity pushing has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RecoilPush",           true,   "Recoil entity pushing has been %s.", ACF.BooleanDataCallback())

	ACF.DefineSetting("AllowFunEnts",              true,     "Fun Entities have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("AllowArbitraryParents",     false,    "Arbitrary parenting has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("AllowSpecialEngines",       true,     "Special engines have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("AllowDynamicLinking",       false,    "Dynamic ACF linking has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("LethalEntityPlayerChecks",  true,     "Lethal entity player checks have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("ShowFunMenu",               true,     "The Fun Entities menu option has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("DetachedPhysmassRatio",     false,    "Detached entities affecting mass ratio has been %s.", ACF.BooleanDataCallback())

	ACF.DefineSetting("WorkshopContent",      true,   "Workshop content downloading has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("WorkshopExtras",       false,  "Extra Workshop content downloading has been %s.", ACF.BooleanDataCallback())

	ACF.DefineSetting("CreateDebris",         true,   "Networking debris has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("CreateFireballs",      false,  "Debris fireballs have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("FireballMult",         1,      nil, ACF.FloatDataCallback(0.01, 1, 2))

	ACF.DefineSetting("EnableSafezones",      true,   "Safezones have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("NoclipOutsideZones",   true,   "Noclipping outside safezones has been %s.", ACF.BooleanDataCallback())

	-- The deviation of the input direction from the shaft + the output direction from the shaft cannot exceed this
	ACF.DefineSetting("MaxDriveshaftAngle",   85,    nil, ACF.FloatDataCallback(85, 180, 0))
	ACF.Year                 = 1945
	ACF.IllegalDisableTime   = 30 -- Time in seconds for an entity to be disabled when it fails ACF.IsLegal
	ACF.Volume               = 1 -- Global volume for ACF sounds
	ACF.MobilityLinkDistance = 650 -- Maximum distance, in inches, at which mobility-related components will remain linked with each other
	ACF.LinkDistance         = 650 -- Maximum distance, in inches, at which components will remain linked with each other
	ACF.KillIconColor        = Color(200, 200, 48)
	ACF.NetMessageSizeLimit  = 13	-- Maximum size of a net message in bytes (IF SET TOO LOW, CERTAIN MODELS MAY NOT BE NETWORKED PROPERLY)

	-- Unit Conversion
	ACF.MeterToInch          = 39.3701 -- Meters to inches
	ACF.InchToMeter          = 0.0254 -- Inches to meters
	ACF.gCmToKgIn            = 0.016387064 -- g/cm³ to kg/in³ :face_vomiting: :face_vomiting: :face_vomiting:
	ACF.MmToInch             = 0.0393701 -- Millimeters to inches
	ACF.InchToMm             = 25.4 -- Inches to millimeters
	ACF.InchToCm             = 2.54 -- Inches to centimeters
	ACF.InchToCmSq           = 6.45 -- in² to cm²
	ACF.InchToCmCu           = 16.387 -- in³ to cm³
	ACF.NmToFtLb             = 0.73756 -- Newton meters to foot-pounds
	ACF.KwToHp               = 1.341 -- Kilowatts to horsepower
	ACF.LToGal               = 0.264172 -- Liters to gallons

	-- Fuzes
	ACF.MinFuzeCaliber       = 20 -- Minimum caliber in millimeters that can be fuzed

	-- Reload Mechanics
	ACF.BaseReload         = 1 -- Minimum reload time. Time it takes to move around a weightless projectile
	ACF.MassToTime         = 0.25 -- Conversion of projectile mass to time be moved around
	ACF.LengthToTime       = 0.025 -- Conversion of projectile length to time -- Emulating the added difficulty of manipulating a longer projectile

	-- External and Terminal Ballistics
	ACF.DragDiv              = 80 -- Drag fudge factor
	ACF.Scale                = 1 -- Scale factor for ACF in the game world
	ACF.Gravity              = Vector(0, 0, -GetConVar("sv_gravity"):GetInt())

	-- WE WANT NO INTERACTION WITH THESE ENTITIES
	ACF.GlobalFilter = {
		gmod_ghost = true,
		acf_debris = true,
		prop_ragdoll = true,
		gmod_wire_hologram = true,
		starfall_hologram = true,
		prop_vehicle_crane = true,
		prop_dynamic = true,
		npc_strider = true,
		npc_dog = true,
		phys_bone_follower = true,
		gmod_wire_expression2 = true,
		starfall_processor = true,
		sent_prop2mesh = true,
	}

	-- THESE ENTITIES ARE FILTERED BUT CAN STILL BE ARMORED, FOR BACKWARDS COMPATIBILITY
	ACF.ArmorableGlobalFilterExceptions = {
		sent_prop2mesh = true,
	}

	ACF.AmbientTemperature   = 288.15 -- Ambient temperature in kelvin (15°C @ sea level) from google search

	-- Containers (Ammo, Fuel, Supply)
	ACF.ContainerArmor       = 5 -- How many millimeters of armor all containers have
	ACF.AmmoArmor            = ACF.ContainerArmor -- Backwards compatibility
	ACF.FuelArmor            = ACF.ContainerArmor -- Backwards compatibility

	-- Ammo
	ACF.AmmoPadding          = 0.3 -- Ratio of wasted space to projectile case diameter
	ACF.AmmoCaseScale        = 1 -- How much larger the diameter of the case is versus the projectile (necked cartridges, M829 is 1.4, .50 BMG is 1.6)
	ACF.AmmoMinSize          = 6 -- Defines the shortest possible length of ammo crates for all their axises, in gmu
	ACF.AmmoMaxLength        = 192 -- Defines the highest possible length of ammo crates for the X axis (length), in gmu
	ACF.AmmoMaxWidth         = 96 -- Defines the highest possible width of ammo crates for the Y and Z axes (width/height), in gmu
	ACF.AmmoSupplyColor      = Color(255, 255, 0, 10) -- The color to use for the ammo supply effect
	ACF.PropImpetus          = 1075 -- Energy in KJ produced by 1kg of propellant, based off M30A1 propellant
	ACF.PDensity             = 0.95 -- Propellant loading density (Density of propellant + volume lost due to packing density)

	-- HE
	ACF.HEPower              = 8000 -- HE Filler power per KG in KJ
	ACF.HEDensity            = 1.65e-3 -- Density of TNT in kg/cm3
	ACF.HEFrag               = 1000 --Mean fragment number for equal weight TNT and casing

	-- HEAT
	ACF.TNTPower             = 4184    -- J/g
	ACF.CompBDensity         = 1.72e-3 -- kg/cm^3
	ACF.CompBEquivalent      = 1.33    -- Relative to TNT
	ACF.OctolDensity         = 1.83e-3 -- kg/cm^3
	ACF.OctolEquivalent      = 1.54    -- Relative to TNT
	ACF.HEATEfficiency       = 0.5     -- Efficiency of converting explosive energy to velocity
	ACF.LinerThicknessMult   = 0.04   -- Metal liner thickness multiplier
	ACF.MaxChargeHeadLen     = 1.2     -- Maximum shaped charge head length (in charge diameters), lengths above will incur diminishing returns
	ACF.HEATPenMul           = 0.85 * 8    -- Linear jet penetration multiplier
	ACF.HEATMinPenVel        = 1000    -- m/s, minimum velocity of the copper jet that contributes to penetration
	ACF.HEATCavityMul        = 1.2     -- Size of the penetration cavity in penetrator volume expended
	ACF.HEATSpallingArc      = 0.5     -- Cossine of the HEAT spalling angle
	ACF.HEATBoomConvert      = 1 / 3   -- Percentage of filler that creates HE damage at detonation
	ACF.HEATStandOffMul      = 0.11 -- Percentage of standoff to use in penetration calculation (Original was too hig)
	ACF.HEATBreakUpMul       = 0.15 -- Percentage of breakup time to use in penetration calculation (Original was too high)

	-- Material densities
	ACF.SteelDensity         = 7.9e-3 	-- kg/cm^3
	ACF.RHADensity           = 7.84e-3	-- kg/cm^3
	ACF.AluminumDensity      = 2.7e-3 	-- kg/cm^3
	ACF.CopperDensity        = 8.96e-3	-- kg/cm^3
	ACF.TungstenDensity		 = 19.25e-3	-- kg/cm^3

	-- Material conversion to points, kg * modifier
	ACF.PointConversion		 = {
		Steel		= 0.04,	-- Projectile steel
		Aluminum	= 0.25,	-- Sabot material
		Copper		= 0.15,	-- Liner for HEAT cones
		Tungsten	= 0.3,	-- Expensive
		CompB		= 0.1,	-- Normal explosives
		Octol		= 0.7,	-- Snowflakium, needs to be expensive as a balancing measure

		WP			= 0.01,	-- White phosphorus
		SF			= 0.02,	-- Smoke filler

		FlareMix	= 0.025,	-- Just some generic mix of hot flammable garbage

		Propellant	= 0.025,	-- Propellant powder
	}

	-- Debris
	ACF.ChildDebris          = 50 -- Higher is more debris props; Chance = ACF.ChildDebris / num_children; Only applies to children of acf-killed parent props
	ACF.DebrisIgniteChance   = 0.25
	ACF.ValidDebris          = { -- Whitelist for things that can be turned into debris
		acf_ammo = true,
		acf_gun = true,
		acf_gearbox = true,
		acf_fueltank = true,
		acf_engine = true,
		acf_piledriver = true,
		acf_rack = true,
		acf_baseplate = true,
		acf_turret_computer = true,
		acf_turret_gyro = true,
		acf_turret_motor = true,
		acf_computer = true,
		acf_radar = true,
		acf_receiver = true,
		acf_groundloader = true,
		acf_supply = true,
		acf_waterjet = true,
		prop_physics = true,
		prop_vehicle_prisoner_pod = true
	}

	-- Weapon Accuracy
	ACF.SpreadScale          = 4 -- The maximum amount that damage can decrease a gun's accuracy. Default 4x
	ACF.GunInaccuracyScale   = 0.5 -- A multiplier for gun accuracy. Must be between 0.5 and 4
	ACF.GunInaccuracyBias    = 2 -- Higher numbers make shots more likely to be inaccurate. Choose between 0.5 to 4. Default is 2 (unbiased).

	-- Containers (Fuel/Supply)
	ACF.ContainerMinSize   = 6 -- Defines the shortest possible length of containers (fuel tanks, supply crates) for all their axises, in gmu
	ACF.ContainerMaxSize   = 96 -- Defines the highest possible length of containers (fuel tanks, supply crates) for all their axises, in gmu
	ACF.FuelSupplyColor    = Color(76, 201, 250, 10) -- The color to use for the fuel supply effect
	ACF.LiIonED            = 0.458 -- li-ion energy density: kw hours / liter
	ACF.SupplyDistance     = 300 -- Distance in which supply units distribute mass to containers.
	ACF.SupplyMassRate     = 0.00009417 -- kg per second per cubic inch of supply unit volume (no distance attenuation)
	ACF.RefuelSpeed        = 700 -- Refueling speed for fuel tanks

	-- Crew
	-- Total efficiency = clamp(CommanderEff * CommanderCoef + SelfEff * SelfCoef, FallBackCoef, 1)
	ACF.DefineSetting("CrewFallbackCoef", 0.1, nil, ACF.FloatDataCallback(0.1, 1, 2)) -- Minimum possible efficiency
	ACF.CrewCommanderCoef 	= 0.3	-- Portion of a crew's efficiency the commander provides
	ACF.CrewSelfCoef 		= 1.0	-- Portion of a crew's efficiency they provide

	ACF.CrewRepTimeBase 	= 3		-- Base time to replace a crew member
	ACF.CrewRepDistToTime 	= 0.05 	-- Time it takes for crew to move one inch during replacement
	ACF.CrewRepPrioMin 		= 1		-- Minimum priority for crew replacement
	ACF.CrewRepPrioMax 		= 10	-- Maximum priority for crew replacement

	ACF.CrewSpaceLengthMod 	= 0.425	-- Changes contribution of shell length to ideal crew space
	ACF.CrewSpaceCaliberMod = 1.0	-- Changes contribution of shell caliber to ideal crew space

	ACF.CrewArmor 			= 5		-- How many millimeters of armor crew members have
	ACF.CrewHealth 			= 4		-- How much health crew members have

	ACF.CrewOxygen 			= 10	-- How many seconds can crew hold their breath for
	ACF.CrewOxygenLossRate 	= 1		-- Multiplier for how fast crew regain their breath
	ACF.CrewOxygenGainRate 	= 2		-- Multiplier for how fast crew regain their breath

	ACF.AmmoStageMin 		= 1		-- Minimum stage index for ammo stowages
	ACF.AmmoStageMax 		= 5		-- Maximum stage index for ammo stowages

	ACF.LoaderBestDist 		= 100	-- Distance before which loaders are most effective
	ACF.LoaderWorstDist 	= 300	-- Distance after which loaders are least effective
	ACF.LoaderMaxBonus 		= 2		-- Maximum bonus loaders can give to reload time

	ACF.InitReloadDelay		= 10		-- Delay after spawning that belt feds are loaded

	ACF.CommanderCapacity 	= 3		-- The number of crew members a commander can handle before focus reduces

	-- Gearboxes
	ACF.GearboxMinSize     = 0.75 -- Defines the smallest possible multiplier for the scale of a gearbox
	ACF.GearboxMaxSize     = 3 -- Defines the largest possible multiplier for the scale of a gearbox
	ACF.GearEfficiency     = 0.95 -- The percentage of RPM efficiency kept when increasing the gear count
	ACF.GearboxMassScale   = 3 -- The exponent to determine the gearbox's mass in proportion to its scale
	ACF.GearboxTorqueScale = 3 -- The exponent to determine the gearbox's torque in proportion to its scale
	-- The arbitrary multiplier for the final amount of torque; TODO: we should probably implement this in a better way
	ACF.DefineSetting("TorqueMult", 5, "The arbitrary multiplier for the final amount of torque. Stopgap measure until a future engine update.", ACF.FloatDataCallback(0, 10, 2))
	ACF.MinGearRatio       = -10 -- The minimum value that a gear's ratio can be set to
	ACF.MaxGearRatio       = 10 -- The maximum value that a gear's ratio can be set to
	ACF.MinCVTRatio        = 1 -- The minimum value that a CVT's ratio can be set to
	ACF.MaxCVTRatio        = 100 -- The maximum value that a CVT's ratio can be set to
	ACF.MinGearRatioLegacy = -1 -- The minimum value that a gear's ratio can be set to (legacy)
	ACF.MaxGearRatioLegacy = 1 -- The maximum value that a gear's ratio can be set to (legacy)
end

do -- ACF Particles
	game.AddParticles("particles/acf_muzzleflashes.pcf")
	game.AddParticles("particles/explosion1.pcf")
	game.AddParticles("particles/rocket_motor.pcf")
end

if SERVER then
	util.AddNetworkString("ACF_UpdateEntity")

	hook.Add("ACF_OnLoadPersistedData", "ACF Workshop Content", function()
		if ACF.ServerData.WorkshopContent then
			resource.AddWorkshop("2183798463") -- Playermodel Seats
			resource.AddWorkshop("3248769144") -- ACF-3 Base
		end

		if ACF.ServerData.WorkshopExtras then
			resource.AddWorkshop("2099387099") -- ACF-3 Removed Sounds
			resource.AddWorkshop("2782407502") -- ACF-3 Removed Models
		end
	end)
elseif CLIENT then
	CreateClientConVar("acf_show_entity_info", 1, true, false, "Defines under what conditions the info bubble on ACF entities will be shown. 0 = Never, 1 = When not seated, 2 = Always", 0, 2)
	CreateClientConVar("acf_cl_particlemul", 1, true, true, "Multiplier for the density of ACF effects.", 0.1, 1)
	CreateClientConVar("acf_mobilityropelinks", 0, true, true, "Toggles the visibility of the links connecting mobility components.")
	-- CreateClientConVar("acf_advancedmobilityropelinks", 0, true, true, "Uses generated models to represent mobility links.")
	CreateClientConVar("acf_maxroundsdisplay", 16, true, false, "Maximum rounds to display before using bulk display (0 to only display bulk)", 0, 5000)
	CreateClientConVar("acf_drawboxes", 1, true, false, "Whether or not to draw hitboxes on ACF entities", 0, 1)
	CreateClientConVar("acf_legalhints", 1, true, true, "If enabled, ACF will throw a warning hint whenever an entity gets disabled.", 0, 1)
	CreateClientConVar("acf_legalshame", 0, true, true, "If enabled, you will get a message in console from the server if someone else has an ACF entity get disabled, but only when the server has that logging enabled.", 0, 1)
	CreateClientConVar("acf_debris", 1, true, false, "Toggles ACF Debris.", 0, 1)
	CreateClientConVar("acf_debris_autolod", 1, true, false, "Automatically disables some effects on debris if FPS is low.", 0, 1)
	CreateClientConVar("acf_debris_collision", 0, true, false, "Toggles debris collisions with other entities.", 0, 1)
	CreateClientConVar("acf_debris_gibmultiplier", 1, true, false, "The amount of gibs spawned when created by ACF debris.", 0, 1)
	CreateClientConVar("acf_debris_giblifetime", 60, true, false, "Defines lifetime in seconds of each debris gib.", 1, 300)
	CreateClientConVar("acf_debris_lifetime", 60, true, false, "Defines lifetime in seconds of each debris entity.", 1, 300)

	-- Display Info Bubble ----------------------
	local ShowInfo = GetConVar("acf_show_entity_info")

	-- We cache these in upvalues rather than performing C calls a ton.
	-- The HideInfoBubble function gets called a LOT!!!!
	-- I have no idea if this will actually imrpove performance yet... we'll see
	local ShowInfo_Value, LocalPlayer_InVehicle = 0, false
	timer.Create("ACF_HideInfo_ResyncCData", 0.1, 0, function()
		ShowInfo_Value = ShowInfo:GetInt()
		local Player = LocalPlayer()
		LocalPlayer_InVehicle = IsValid(Player) and Player:InVehicle() or false
	end)
	function ACF.HideInfoBubble()
		if ShowInfo_Value == 0 then return true end
		if ShowInfo_Value == 2 then return false end

		return LocalPlayer_InVehicle
	end
	---------------------------------------------

	-- Custom Tool Category ---------------------
	ACF.CustomToolCategory = CreateClientConVar("acf_tool_category", 0, true, false, "If enabled, ACF tools will be put inside their own category.", 0, 1)

	if ACF.CustomToolCategory:GetBool() then
		-- We use this hook so that the ACF category is always at the top
		hook.Add("AddToolMenuTabs", "CreateACFCategory", function()
			spawnmenu.AddToolCategory("Main", "ACF", "#spawnmenu.tools.acf")
		end)
	end
	---------------------------------------------

	-- Clientside Updating --------------------------
	net.Receive("ACF_UpdateEntity", function()
		local Entity = net.ReadEntity()

		timer.Simple(0.5, function()
			if not IsValid(Entity) then return end
			if not isfunction(Entity.Update) then return end

			Entity:Update()
		end)
	end)
	---------------------------------------------
end

do -- Player loaded hook
	-- PlayerInitialSpawn isn't reliable when it comes to network messages
	-- So we'll ask the clientside to tell us when it's actually ready to send and receive net messages
	-- For more info, see: https://wiki.facepunch.com/gmod/GM:PlayerInitialSpawn
	if SERVER then
		util.AddNetworkString("ACF_PlayerLoaded")

		net.Receive("ACF_PlayerLoaded", function(_, Player)
			hook.Run("ACF_OnLoadPlayer", Player)
		end)
	else
		hook.Add("InitPostEntity", "ACF Player Loaded", function()
			net.Start("ACF_PlayerLoaded")
			net.SendToServer()

			hook.Remove("InitPostEntity", "ACF Player Loaded")
		end)
	end
end

cvars.AddChangeCallback("sv_gravity", function(_, _, Value)
	ACF.Gravity.z = -Value
end, "ACF Bullet Gravity")
