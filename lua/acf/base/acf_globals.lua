do -- ACF global vars
	ACF.AmmoCrates 			= ACF.AmmoCrates or {}
	ACF.Classes				= ACF.Classes or {}
	ACF.FuelTanks 			= ACF.FuelTanks or {}
	ACF.Repositories		= ACF.Repositories or {}
	ACF.ClientData			= ACF.ClientData or {}
	ACF.ServerData			= ACF.ServerData or {}

	-- Misc
	ACF.Year 				= 1945
	ACF.IllegalDisableTime 	= 30 -- Time in seconds for an entity to be disabled when it fails ACF_IsLegal
	ACF.GunfireEnabled 		= true
	ACF.SmokeWind 			= 5 + math.random() * 35 --affects the ability of smoke to be used for screening effect

	-- Fuzes
	ACF.MinFuzeCaliber		= 20 -- Minimum caliber in millimeters that can be fuzed

	-- Reload Mechanics
	ACF.BaseReload			= 1 -- Minimum reload time. Time it takes to move around a weightless projectile
	ACF.MassToTime			= 0.2 -- Conversion of projectile mass to time be moved around
	ACF.LengthToTime		= 0.1 -- Conversion of projectile length to time -- Emulating the added difficulty of manipulating a longer projectile

	-- External and Terminal Ballistics
	ACF.DragDiv 			= 80 --Drag fudge factor
	ACF.Scale 				= 1 --Scale factor for ACF in the game world
	ACF.Threshold 			= 264.7 --Health Divisor (don"t forget to update cvar function down below)
	ACF.PenAreaMod 			= 0.85
	ACF.KinFudgeFactor 		= 2.1 --True kinetic would be 2, over that it's speed biased, below it's mass biased
	ACF.KEtoRHA 			= 0.25 --Empirical conversion from (kinetic energy in KJ)/(Area in Cm2) to RHA penetration
	ACF.GroundtoRHA 		= 0.15 --How much mm of steel is a mm of ground worth (Real soil is about 0.15)
	ACF.ArmorMod 			= 1
	ACF.SlopeEffectFactor 	= 1.1 -- Sloped armor effectiveness: armor / cos(angle)^factor
	ACF.GlobalFilter = { -- Global ACF filter
		gmod_ghost = true,
		acf_debris = true,
		prop_ragdoll = true,
		gmod_wire_hologram = true,
		starfall_hologram = true,
		prop_vehicle_crane = true,
		prop_dynamic = true,
		npc_strider = true,
		npc_dog = true
	}

	-- Ammo
	ACF.AmmoArmor			= 5 -- How many millimeters of armor ammo crates have
	ACF.AmmoPadding         = 2 -- Millimeters of wasted space between rounds
	ACF.AmmoMod 			= 1.05 -- Ammo modifier. 1 is 1x the amount of ammo. 0.6 default
	ACF.AmmoCaseScale		= 1.4 -- How much larger the diameter of the case is versus the projectile (necked cartridges, M829 is 1.4, .50 BMG is 1.6) 
	ACF.PBase 				= 875 --1KG of propellant produces this much KE at the muzzle, in kj
	ACF.PScale 				= 1 --Gun Propellant power expotential
	ACF.MVScale 			= 0.5 --Propellant to MV convertion expotential
	ACF.PDensity 			= 0.95 -- Propellant loading density (Density of propellant + volume lost due to packing density)

	-- HE
	ACF.HEPower 			= 8000 --HE Filler power per KG in KJ
	ACF.HEDensity 			= 1.65 --HE Filler density (That's TNT density)
	ACF.HEFrag 				= 1000 --Mean fragment number for equal weight TNT and casing
	ACF.HEBlastPen			= 0.4 --Blast penetration exponent based of HE power
	ACF.HEFeatherExp 		= 0.5 --exponent applied to HE dist/maxdist feathering, <1 will increasingly bias toward max damage until sharp falloff at outer edge of range
	ACF.HEATMVScale 		= 0.75 --Filler KE to HEAT slug KE conversion expotential
	ACF.HEATMulAmmo 		= 30 --HEAT slug damage multiplier; 13.2x roughly equal to AP damage
	ACF.HEATMulFuel 		= 4 --needs less multiplier, much less health than ammo
	ACF.HEATMulEngine 		= 10 --likewise
	ACF.HEATPenLayerMul 	= 0.75 --HEAT base energy multiplier
	ACF.HEATBoomConvert 	= 1 / 3 -- percentage of filler that creates HE damage at detonation
	ACF.HEATMinCrush 		= 800 -- vel where crush starts, progressively converting round to raw HE
	ACF.HEATMaxCrush 		= 1200 -- vel where fully crushed

	-- Debris
	ACF.ChildDebris 		= 50 -- higher is more debris props; Chance = ACF.ChildDebris / num_children; Only applies to children of acf-killed parent props
	ACF.DebrisIgniteChance 	= 0.25
	ACF.DebrisScale 		= 999999 -- Ignore debris that is less than this bounding radius.
	ACF.ValidDebris			= { -- Whitelist for things that can be turned into debris
		acf_ammo = true,
		acf_gun = true,
		acf_gearbox = true,
		acf_fueltank = true,
		acf_engine = true,
		prop_physics = true,
		prop_vehicle_prisoner_pod = true
	}

	-- Weapon Accuracy
	ACF.SpreadScale 		= 4 -- The maximum amount that damage can decrease a gun"s accuracy. Default 4x
	ACF.GunInaccuracyScale 	= 0.5 -- A multiplier for gun accuracy. Must be between 0.5 and 4
	ACF.GunInaccuracyBias 	= 2 -- Higher numbers make shots more likely to be inaccurate. Choose between 0.5 to 4. Default is 2 (unbiased).

	-- Fuel
	ACF.FuelRate 			= 1 --multiplier for fuel usage, 1.0 is approx real world
	ACF.CompFuelRate		= 27.8 --Extra multiplier for fuel consumption on servers with acf_gamemode set to 2 (Competitive)
	ACF.TankVolumeMul 		= 1 -- multiplier for fuel tank capacity, 1.0 is approx real world
	ACF.LiIonED 			= 0.458 -- li-ion energy density: kw hours / liter
	ACF.CuIToLiter 			= 0.0163871 -- cubic inches to liters
	ACF.RefillDistance 		= 300 --Distance in which ammo crate starts refilling.
	ACF.RefillSpeed 		= 700 -- (ACF.RefillSpeed / RoundMass) / Distance 
	ACF.RefuelSpeed			= 20 -- Liters per second * ACF.FuelRate
end

do -- ACF Convars/Callbacks ------------------------
	CreateConVar("sbox_max_acf_ammo", 32, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum amount of ACF ammo crates a player can create.")

	function ACF_CVarChangeCallback(CVar, _, New)
		if CVar == "acf_healthmod" then
			ACF.Threshold = 264.7 / math.max(New, 0.01)
			print("Health Mod changed to a factor of " .. New)
		elseif CVar == "acf_armormod" then
			ACF.ArmorMod = 1 * math.max(New, 0)
			print("Armor Mod changed to a factor of " .. New)
		elseif CVar == "acf_ammomod" then
			ACF.AmmoMod = 1 * math.max(New, 0.01)
			print("Ammo Mod changed to a factor of " .. New)
		elseif CVar == "acf_fuelrate" then
			local Value = tonumber(New) or 1

			ACF.FuelRate = math.max(Value, 0.01)

			print("Fuel Rate changed to a factor of " .. Value)
		elseif CVar == "acf_gunfire" then
			ACF.GunfireEnabled = tobool(New)
			local text = "disabled"

			if ACF.GunfireEnabled then
				text = "enabled"
			end

			print("ACF Gunfire has been " .. text)
		end
	end

	-- New healthmod/armormod/ammomod cvars
	CreateConVar("acf_healthmod", 1)
	CreateConVar("acf_armormod", 1)
	CreateConVar("acf_ammomod", 1)
	CreateConVar("acf_fuelrate", 1)
	CreateConVar("acf_spalling", 0)
	CreateConVar("acf_gunfire", 1)

	cvars.AddChangeCallback("acf_healthmod", ACF_CVarChangeCallback)
	cvars.AddChangeCallback("acf_armormod", ACF_CVarChangeCallback)
	cvars.AddChangeCallback("acf_ammomod", ACF_CVarChangeCallback)
	cvars.AddChangeCallback("acf_fuelrate", ACF_CVarChangeCallback)
	cvars.AddChangeCallback("acf_spalling", ACF_CVarChangeCallback)
	cvars.AddChangeCallback("acf_gunfire", ACF_CVarChangeCallback)

	game.AddParticles("particles/acf_muzzleflashes.pcf")
	game.AddParticles("particles/explosion1.pcf")
	game.AddParticles("particles/rocket_motor.pcf")
end

if SERVER then
	util.AddNetworkString("ACF_UpdateEntity")
	util.AddNetworkString("ACF_RenderDamage")
	util.AddNetworkString("ACF_Notify")

	CreateConVar("acf_enable_workshop_content", 1, FCVAR_ARCHIVE, "Enable workshop content download for clients. Requires server restart on change.", 0, 1)
	CreateConVar("acf_enable_workshop_extras", 0, FCVAR_ARCHIVE, "Enable extra workshop content download for clients. Requires server restart on change.", 0, 1)
	CreateConVar("acf_gamemode", 1, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Sets the ACF gamemode of the server. 0 = Sandbox, 1 = Classic, 2 = Competitive", 0, 2)
	CreateConVar("acf_restrict_info", 1, FCVAR_ARCHIVE, "If enabled, players will be only allowed to get info from entities they're allowed to mess with.", 0, 1)
	CreateConVar("acf_hepush", 1, FCVAR_ARCHIVE, "Whether or not HE pushes on entities", 0, 1)
	CreateConVar("acf_kepush", 1, FCVAR_ARCHIVE, "Whether or not kinetic force pushes on entities", 0, 1)
	CreateConVar("acf_recoilpush", 1, FCVAR_ARCHIVE, "Whether or not ACF guns apply recoil", 0, 1)

	-- Addon content ----------------------------
	local Content = GetConVar("acf_enable_workshop_content")

	if Content:GetBool() then
		resource.AddWorkshop("2183798463") -- Playermodel seats
	end
	---------------------------------------------

	-- Extra content ----------------------------
	local Extras = GetConVar("acf_enable_workshop_extras")

	if Extras:GetBool() then
		resource.AddWorkshop("439526795") -- Hide Errors addon
		resource.AddWorkshop("2099387099") -- ACF-3 Removed Extra Sounds
	end
	---------------------------------------------
elseif CLIENT then
	CreateClientConVar("acf_show_entity_info", 1, true, false, "Defines under what conditions the info bubble on ACF entities will be shown. 0 = Never, 1 = When not seated, 2 = Always", 0, 2)
	CreateClientConVar("acf_cl_particlemul", 1, true, true, "Multiplier for the density of ACF effects.", 0.1, 1)
	CreateClientConVar("acf_mobilityropelinks", 1, true, true)
	CreateClientConVar("acf_maxroundsdisplay", 16, true, false, "Maximum rounds to display before using bulk display (0 to only display bulk)", 0, 5000)
	CreateClientConVar("acf_drawboxes", 1, true, false, "Whether or not to draw hitboxes on ACF entities", 0, 1)
	CreateClientConVar("acf_legalhints", 1, true, true, "If enabled, ACF will throw a warning hint whenever an entity gets disabled.", 0, 1)

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

do -- ACF Notify -----------------------------------
	if SERVER then
		function ACF.SendNotify(Player, Success, Message)
			net.Start("ACF_Notify")
				net.WriteBool(Success or true)
				net.WriteString(Message or "")
			net.Send(Player)
		end

		ACF_SendNotify = ACF.SendNotify -- Backwards compatibility
	else
		local notification = notification

		net.Receive("ACF_Notify", function()
			local Type = NOTIFY_ERROR

			if net.ReadBool() then
				Type = NOTIFY_GENERIC
			else
				surface.PlaySound("buttons/button10.wav")
			end

			notification.AddLegacy(net.ReadString(), Type, 7)
		end)
	end
end ------------------------------------------------

do -- Render Damage --------------------------------
	hook.Add("ACF_OnPlayerLoaded", "ACF Render Damage", function(ply)
		local Table = {}

		for _, v in pairs(ents.GetAll()) do
			if v.ACF and v.ACF.PrHealth then
				table.insert(Table, {
					ID = v:EntIndex(),
					Health = v.ACF.Health,
					MaxHealth = v.ACF.MaxHealth
				})
			end
		end

		if next(Table) then
			net.Start("ACF_RenderDamage")
				net.WriteTable(Table)
			net.Send(ply)
		end
	end)
end ------------------------------------------------

--Stupid workaround red added to precache timescaling.
hook.Add("Think", "Update ACF Internal Clock", function()
	ACF.CurTime = CurTime()
end)

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
