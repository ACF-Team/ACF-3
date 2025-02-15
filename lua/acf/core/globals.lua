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

	function ACF.StringDataCallback()
		local SettingData = ACF.GetWorkingSetting()
		SettingData.Type = "String"

		return function(_, Value)
			return tostring(Value)
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
	ACF.DefineSetting("SelectedLimitset",   "none", "The current limitset has been set to %s.", ACF.StringDataCallback())

	ACF.DefineSetting("AllowAdminData",     false,  "Admin server data access has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RestrictInfo",       true,   "Entity information restrictions have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("LegalChecks",        true,   "Legality checks for ACF entities has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("NameAndShame",       false,  "Console messages for failed legality checks have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("VehicleLegalChecks", true,   "Legality checks for vehicles has been %s.", ACF.BooleanDataCallback())

	ACF.DefineSetting("GunsCanFire",        true,   "Gunfire has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("GunsCanSmoke",       true,   "Gun sounds and particles have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RacksCanFire",       true,   "Missile racks have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RequireFuel",        true,   "Engine fuel requirements have been %s.", ACF.BooleanDataCallback())

	ACF.Threshold = 264.7
	ACF.DefineSetting("HealthFactor",       1,      "Health multiplier has been set to a factor of %.2f.", ACF.FactorDataCallback("Threshold", 0.01, 2, 2))

	ACF.ArmorMod = 1
	ACF.DefineSetting("ArmorFactor",        1,      "Armor multiplier has been set to a factor of %.2f.", ACF.FactorDataCallback("ArmorMod", 0.01, 2, 2))

	ACF.FuelRate = 15
	ACF.DefineSetting("FuelFactor",         1,      "Fuel rate multiplier has been set to a factor of %.2f.", ACF.FactorDataCallback("FuelRate", 0.01, 2, 2))

	ACF.MinimumArmor         = 1 -- Minimum possible armor that can be given to an entity
	ACF.MaximumArmor         = 5000 -- Maximum possible armor that can be given to an entity
	ACF.DefineSetting("MaxThickness",       300,    nil, ACF.FloatDataCallback(ACF.MinimumArmor, ACF.MaximumArmor, 0))

	ACF.DefineSetting("SmokeWind",          20,     "Wind smoke multiplier has been set to a factor of %.2f.", ACF.FloatDataCallback(0, 1000, 2))

	ACF.DefineSetting("HEPush",             true,   "Explosive energy entity pushing has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("KEPush",             true,   "Kinetic energy entity pushing has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("RecoilPush",         true,   "Recoil entity pushing has been %s.", ACF.BooleanDataCallback())

	ACF.DefineSetting("AllowFunEnts",       true,   "Fun Entities have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("ShowFunMenu",        true,   "The Fun Entities menu option has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("AllowProcArmor",     false,  "Procedural armor has been %s.", ACF.BooleanDataCallback(function(Value)
		ACF.GlobalFilter["acf_armor"] = not Value
		return Value
	end))

	ACF.DefineSetting("WorkshopContent",    true,   "Workshop content downloading has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("WorkshopExtras",     false,  "Extra Workshop content downloading has been %s.", ACF.BooleanDataCallback())

	ACF.DefineSetting("CreateDebris",       true,   "Networking debris has been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("CreateFireballs",    false,  "Debris fireballs have been %s.", ACF.BooleanDataCallback())
	ACF.DefineSetting("FireballMult",       1,      nil, ACF.FloatDataCallback(0.01, 1, 2))

	ACF.Year                 = 1945
	ACF.IllegalDisableTime   = 30 -- Time in seconds for an entity to be disabled when it fails ACF.IsLegal
	ACF.Volume               = 1 -- Global volume for ACF sounds
	ACF.MobilityLinkDistance = 650 -- Maximum distance, in inches, at which mobility-related components will remain linked with each other
	ACF.LinkDistance         = 650 -- Maximum distance, in inches, at which components will remain linked with each other
	ACF.KillIconColor        = Color(200, 200, 48)

	-- Unit Conversion
	ACF.MeterToInch          = 39.3701 -- Meters to inches
	ACF.gCmToKgIn            = 0.016387064 -- g/cm³ to kg/in³ :face_vomiting: :face_vomiting: :face_vomiting:
	ACF.MmToInch             = 0.0393701 -- Millimeters to inches
	ACF.InchToMm             = 25.4 -- Inches to millimeters
	ACF.InchToCmSq           = 6.45 -- in² to cm²

	-- Fuzes
	ACF.MinFuzeCaliber       = 20 -- Minimum caliber in millimeters that can be fuzed

	-- Reload Mechanics
	ACF.BaseReload           = 1 -- Minimum reload time. Time it takes to move around a weightless projectile
	ACF.MassToTime           = 0.2 -- Conversion of projectile mass to time be moved around
	ACF.LengthToTime         = 0.1 -- Conversion of projectile length to time -- Emulating the added difficulty of manipulating a longer projectile

	-- External and Terminal Ballistics
	ACF.DragDiv              = 80 -- Drag fudge factor
	ACF.Scale                = 1 -- Scale factor for ACF in the game world
	ACF.Gravity              = Vector(0, 0, -GetConVar("sv_gravity"):GetInt())
	ACF.GlobalFilter = { -- Global ACF filter
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
		acf_armor = not ACF.AllowProcArmor, -- Procedural armor filter
		starfall_prop = true
	}

	-- Ammo
	ACF.AmmoArmor            = 5 -- How many millimeters of armor ammo crates have
	ACF.AmmoPadding          = 0.3 -- Ratio of wasted space to projectile case diameter
	ACF.AmmoCaseScale        = 1 -- How much larger the diameter of the case is versus the projectile (necked cartridges, M829 is 1.4, .50 BMG is 1.6)
	ACF.AmmoMinSize          = 6 -- Defines the shortest possible length of ammo crates for all their axises, in gmu
	ACF.AmmoMaxSize          = 96 -- Defines the highest possible length of ammo crates for all their axises, in gmu
	ACF.AmmoRefillColor      = Color(255, 255, 0, 10) -- The color to use for the ammo refill effect
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
	ACF.SteelDensity         = 7.9e-3  -- kg/cm^3
	ACF.RHADensity           = 7.84e-3 -- kg/cm^3
	ACF.AluminumDensity      = 2.7e-3  -- kg/cm^3
	ACF.CopperDensity        = 8.96e-3 -- kg/cm^3

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
		acf_armor = true,
		acf_baseplate = true,
		acf_turret_computer = true,
		acf_turret_gyro = true,
		acf_turret_motor = true,
		acf_computer = true,
		acf_radar = true,
		acf_receiver = true,
		prop_physics = true,
		prop_vehicle_prisoner_pod = true
	}

	-- Weapon Accuracy
	ACF.SpreadScale          = 4 -- The maximum amount that damage can decrease a gun's accuracy. Default 4x
	ACF.GunInaccuracyScale   = 0.5 -- A multiplier for gun accuracy. Must be between 0.5 and 4
	ACF.GunInaccuracyBias    = 2 -- Higher numbers make shots more likely to be inaccurate. Choose between 0.5 to 4. Default is 2 (unbiased).

	-- Fuel
	ACF.FuelMinSize          = 6 -- Defines the shortest possible length of fuel tanks for all their axises, in gmu
	ACF.FuelMaxSize          = 96 -- Defines the highest possible length of fuel tanks for all their axises, in gmu
	ACF.FuelArmor            = 1 -- How many millimeters of armor fuel tanks have
	ACF.FuelRefillColor      = Color(76, 201, 250, 10) -- The color to use for the fuel refill effect
	ACF.TankVolumeMul        = 1 -- Multiplier for fuel tank capacity, 1.0 is approx real world
	ACF.LiIonED              = 0.458 -- li-ion energy density: kw hours / liter
	ACF.RefillDistance       = 300 -- Distance in which ammo crate starts refilling.
	ACF.RefillSpeed          = 700 -- (ACF.RefillSpeed / RoundMass) / Distance
	ACF.RefuelSpeed          = 20 -- Liters per second * ACF.FuelRate
end

do -- ACF Convars & Particles
	CreateConVar("sbox_max_acf_ammo", 32, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum amount of ACF ammo crates a player can create.")

	game.AddParticles("particles/acf_muzzleflashes.pcf")
	game.AddParticles("particles/explosion1.pcf")
	game.AddParticles("particles/rocket_motor.pcf")
end

if SERVER then
	util.AddNetworkString("ACF_UpdateEntity")

	hook.Add("ACF_OnLoadPersistedData", "ACF Workshop Content", function()
		if ACF.WorkshopContent then
			resource.AddWorkshop("2183798463") -- Playermodel Seats
			resource.AddWorkshop("3248769144") -- ACF-3 Base
			resource.AddWorkshop("3248769787") -- ACF-3 Missiles
		end

		if ACF.WorkshopExtras then
			resource.AddWorkshop("2099387099") -- ACF-3 Removed Sounds
			resource.AddWorkshop("2782407502") -- ACF-3 Removed Models
		end
	end)
elseif CLIENT then
	CreateClientConVar("acf_show_entity_info", 1, true, false, "Defines under what conditions the info bubble on ACF entities will be shown. 0 = Never, 1 = When not seated, 2 = Always", 0, 2)
	CreateClientConVar("acf_cl_particlemul", 1, true, true, "Multiplier for the density of ACF effects.", 0.1, 1)
	CreateClientConVar("acf_mobilityropelinks", 1, true, true)
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

	function ACF.HideInfoBubble()
		local Value = ShowInfo:GetInt()

		if Value == 0 then return true end
		if Value == 2 then return false end

		return LocalPlayer():InVehicle()
	end
	---------------------------------------------

	-- Custom Tool Category ---------------------
	ACF.CustomToolCategory = CreateClientConVar("acf_tool_category", 0, true, false, "If enabled, ACF tools will be put inside their own category.", 0, 1)

	if ACF.CustomToolCategory:GetBool() then
		language.Add("spawnmenu.tools.acf", "ACF")

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