local ACF = ACF

do -- ACF global vars
	ACF.AmmoCrates         = ACF.AmmoCrates or {}
	ACF.FuelTanks          = ACF.FuelTanks or {}
	ACF.Repositories       = ACF.Repositories or {}
	ACF.ClientData         = ACF.ClientData or {}
	ACF.ServerData         = ACF.ServerData or {}
	ACF.ModelData          = ACF.ModelData or { Models = {} }

	-- General Settings
	ACF.LegalChecks        = true -- Whether or not IsLegal checks should be run on ACF entities
	ACF.NameAndShame       = false -- Whether or not IsLegal checks should message everyone* about ACF entities getting disabled
	ACF.VehicleLegalChecks = true -- Whether or not IsLegal checks should be run on vehicle entities
	ACF.Year               = 1945
	ACF.IllegalDisableTime = 30 -- Time in seconds for an entity to be disabled when it fails ACF.IsLegal
	ACF.RestrictInfo       = true -- If enabled, players will be only allowed to get info from entities they're allowed to mess with.
	ACF.AllowAdminData     = false -- Allows admins to mess with a few server settings and data variables
	ACF.HEPush             = true -- Whether or not HE pushes on entities
	ACF.KEPush             = true -- Whether or not kinetic force pushes on entities
	ACF.RecoilPush         = true -- Whether or not ACF guns apply recoil
	ACF.Volume             = 1 -- Global volume for ACF sounds
	ACF.AllowFunEnts       = true -- Allows entities listed under the Fun Stuff option to be used
	ACF.AllowProcArmor     = false --Allows procedural armor entities to be used.
	ACF.WorkshopContent    = true -- Enable workshop content download for clients
	ACF.WorkshopExtras     = false -- Enable extra workshop content download for clients
	ACF.SmokeWind          = 5 + math.random() * 35 --affects the ability of smoke to be used for screening effect
	ACF.LinkDistance       = 650 -- Maximum distance, on inches, at which components will remain linked with each other
	ACF.MinimumArmor       = 1 -- Minimum possible armor that can be given to an entity
	ACF.MaximumArmor       = 5000 -- Maximum possible armor that can be given to an entity
	ACF.KillIconColor      = Color(200, 200, 48)

	ACF.GunsCanFire        = true
	ACF.GunsCanSmoke       = true
	ACF.RacksCanFire       = true

	-- Unit Conversion
	ACF.MeterToInch        = 39.3701 -- Meters to inches
	ACF.gCmToKgIn          = 0.016387064 -- g/cm³ to kg/in³ :face_vomiting: :face_vomiting: :face_vomiting:
	ACF.MmToInch		   = 0.0393701 -- Millimeters to inches
	ACF.InchToMm           = 25.4 -- Inches to millimeters

	-- Fuzes
	ACF.MinFuzeCaliber     = 20 -- Minimum caliber in millimeters that can be fuzed

	-- Reload Mechanics
	ACF.BaseReload         = 1 -- Minimum reload time. Time it takes to move around a weightless projectile
	ACF.MassToTime         = 0.2 -- Conversion of projectile mass to time be moved around
	ACF.LengthToTime       = 0.1 -- Conversion of projectile length to time -- Emulating the added difficulty of manipulating a longer projectile

	-- External and Terminal Ballistics
	ACF.DragDiv            = 80 --Drag fudge factor
	ACF.Scale              = 1 --Scale factor for ACF in the game world
	ACF.HealthFactor       = 1
	ACF.Threshold          = 264.7 -- Health Divisor, directly tied to ACF.HealthFactor
	ACF.ArmorMod           = 1
	ACF.ArmorFactor        = 1 -- Multiplier for ACF.ArmorMod
	ACF.Gravity            = Vector(0, 0, -GetConVar("sv_gravity"):GetInt())
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
	}

	-- Ammo
	ACF.AmmoArmor          = 5 -- How many millimeters of armor ammo crates have
	ACF.AmmoPadding        = 0.3 -- Ratio of wasted space to projectile case diameter
	ACF.AmmoCaseScale      = 1 -- How much larger the diameter of the case is versus the projectile (necked cartridges, M829 is 1.4, .50 BMG is 1.6)
	ACF.AmmoMinSize        = 6 -- Defines the shortest possible length of ammo crates for all their axises, in gmu
	ACF.AmmoMaxSize        = 96 -- Defines the highest possible length of ammo crates for all their axises, in gmu
	ACF.PropImpetus        = 1075 -- Energy in KJ produced by 1kg of propellant, based off M30A1 propellant
	ACF.PDensity           = 0.95 -- Propellant loading density (Density of propellant + volume lost due to packing density)

	-- HE
	ACF.HEPower            = 8000 --HE Filler power per KG in KJ
	ACF.HEDensity          = 1.65e-3 -- Density of TNT in kg/cm3
	ACF.HEFrag             = 1000 --Mean fragment number for equal weight TNT and casing

	-- HEAT
	ACF.TNTPower           = 4184    -- J/g
	ACF.CompBDensity       = 1.72e-3 -- kg/cm^3
	ACF.CompBEquivalent    = 1.33    -- Relative to TNT
	ACF.OctolDensity       = 1.83e-3 -- kg/cm^3
	ACF.OctolEquivalent    = 1.54    -- Relative to TNT
	ACF.HEATEfficiency     = 0.5     -- Efficiency of converting explosive energy to velocity
	ACF.LinerThicknessMult = 0.04   -- Metal liner thickness multiplier
	ACF.MaxChargeHeadLen   = 1.2     -- Maximum shaped charge head length (in charge diameters), lengths above will incur diminishing returns
	ACF.HEATPenMul         = 0.85    -- Linear jet penetration multiplier
	ACF.HEATMinPenVel      = 1000    -- m/s, minimum velocity of the copper jet that contributes to penetration
	ACF.HEATCavityMul      = 1.2     -- Size of the penetration cavity in penetrator volume expended
	ACF.HEATSpallingArc    = 0.5     -- Cossine of the HEAT spalling angle
	ACF.HEATBoomConvert    = 1 / 3   -- Percentage of filler that creates HE damage at detonation

	-- Material densities
	ACF.SteelDensity       = 7.9e-3  -- kg/cm^3
	ACF.RHADensity         = 7.84e-3 -- kg/cm^3
	ACF.AluminumDensity    = 2.7e-3  -- kg/cm^3
	ACF.CopperDensity      = 8.96e-3 -- kg/cm^3

	-- Debris
	ACF.ChildDebris        = 50 -- Higher is more debris props; Chance = ACF.ChildDebris / num_children; Only applies to children of acf-killed parent props
	ACF.DebrisIgniteChance = 0.25
	ACF.ValidDebris        = { -- Whitelist for things that can be turned into debris
		acf_ammo = true,
		acf_gun = true,
		acf_gearbox = true,
		acf_fueltank = true,
		acf_engine = true,
		prop_physics = true,
		prop_vehicle_prisoner_pod = true
	}

	-- Weapon Accuracy
	ACF.SpreadScale        = 4 -- The maximum amount that damage can decrease a gun"s accuracy. Default 4x
	ACF.GunInaccuracyScale = 0.5 -- A multiplier for gun accuracy. Must be between 0.5 and 4
	ACF.GunInaccuracyBias  = 2 -- Higher numbers make shots more likely to be inaccurate. Choose between 0.5 to 4. Default is 2 (unbiased).

	-- Fuel
	ACF.RequireFuel        = true -- Whether or not fuel usage should be required for engines
	ACF.FuelRate           = 15 -- Multiplier for fuel usage, 1.0 is approx real world
	ACF.FuelFactor         = 1 -- Multiplier for ACF.FuelRate
	ACF.FuelMinSize        = 6 -- Defines the shortest possible length of fuel tanks for all their axises, in gmu
	ACF.FuelMaxSize        = 96 -- Defines the highest possible length of fuel tanks for all their axises, in gmu
	ACF.FuelArmor          = 5 -- How many millimeters of armor fuel tanks have
	ACF.TankVolumeMul      = 1 -- Multiplier for fuel tank capacity, 1.0 is approx real world
	ACF.LiIonED            = 0.458 -- li-ion energy density: kw hours / liter
	ACF.RefillDistance     = 300 -- Distance in which ammo crate starts refilling.
	ACF.RefillSpeed        = 700 -- (ACF.RefillSpeed / RoundMass) / Distance
	ACF.RefuelSpeed        = 20 -- Liters per second * ACF.FuelRate
end

do -- ACF Convars & Particles
	CreateConVar("sbox_max_acf_ammo", 32, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum amount of ACF ammo crates a player can create.")

	game.AddParticles("particles/acf_muzzleflashes.pcf")
	game.AddParticles("particles/explosion1.pcf")
	game.AddParticles("particles/rocket_motor.pcf")
end

if SERVER then
	util.AddNetworkString("ACF_UpdateEntity")

	hook.Add("PlayerConnect", "ACF Workshop Content", function()
		if ACF.WorkshopContent then
			resource.AddWorkshop("2183798463") -- Playermodel seats
			resource.AddWorkshop("2782411885") -- ACF-3 Content for Players
		end

		if ACF.WorkshopExtras then
			resource.AddWorkshop("2099387099") -- ACF-3 Removed Sounds
			resource.AddWorkshop("2782407502") -- ACF-3 Removed Models
		end

		hook.Remove("PlayerConnect", "ACF Workshop Content")
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
			hook.Run("ACF_OnPlayerLoaded", Player)
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

do -- Smoke/Wind -----------------------------------
	if SERVER then
		local function msgtoconsole(_, msg)
			print(msg)
		end

		util.AddNetworkString("acf_smokewind")

		concommand.Add("acf_smokewind", function(ply, _, args, _)
			local validply = IsValid(ply)

			local printmsg = validply and function(hud, msg)
				ply:PrintMessage(hud, msg)
			end or msgtoconsole

			if not args[1] then
				printmsg(HUD_PRINTCONSOLE, "Set the wind intensity upon all smoke munitions." .. "\n   This affects the ability of smoke to be used for screening effect." .. "\n   Example; acf_smokewind 300")

				return false
			end

			if validply and not ply:IsAdmin() then
				printmsg(HUD_PRINTCONSOLE, "You can't use this because you are not an admin.")

				return false
			else
				local wind = tonumber(args[1])

				if not wind then
					printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: that wind value could not be interpreted as a number!")

					return false
				end

				ACF.SmokeWind = wind
				net.Start("acf_smokewind")
				net.WriteFloat(wind)
				net.Broadcast()
				printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: set smoke-wind to " .. wind .. "!")

				return true
			end
		end)

		hook.Add("ACF_OnPlayerLoaded", "ACF Send Smoke Wind", function(Player)
			net.Start("acf_smokewind")
				net.WriteFloat(ACF.SmokeWind)
			net.Send(Player)
		end)
	else
		net.Receive("acf_smokewind", function()
			ACF.SmokeWind = net.ReadFloat()
		end)
	end
end ------------------------------------------------