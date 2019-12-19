ACF = {}
ACF.AmmoTypes = {}
ACF.AmmoCrates = {}
ACF.FuelTanks = {}
ACF.MenuFunc = {}
ACF.AmmoBlacklist = {}
ACF.IllegalDisableTime = 30 -- Time in seconds for an entity to be disabled when it fails ACF_IsLegal
ACF.Version = 660 -- REMEMBER TO CHANGE THIS FOR GODS SAKE, OMFG!!!!!!! -wrex   Update the changelog too! -Ferv
ACF.CurrentVersion = 0 -- just defining a variable, do not change
ACF.Year = 1945
ACF.Threshold = 264.7 --Health Divisor (don"t forget to update cvar function down below)
ACF.PartialPenPenalty = 5 --Exponent for the damage penalty for partial penetration
ACF.PenAreaMod = 0.85
ACF.KinFudgeFactor = 2.1 --True kinetic would be 2, over that it"s speed biaised, below it"s mass biaised
ACF.KEtoRHA = 0.25 --Empirical conversion from (kinetic energy in KJ)/(Area in Cm2) to RHA penetration
ACF.GroundtoRHA = 0.15 --How much mm of steel is a mm of ground worth (Real soil is about 0.15)
ACF.KEtoSpall = 1
ACF.AmmoMod = 1.05 -- Ammo modifier. 1 is 1x the amount of ammo. 0.6 default
ACF.CrateVolEff = 0.1576 -- magic number that adjusts the efficiency of crate model volume to ammo capacity
ACF.ArmorMod = 1
ACF.SlopeEffectFactor = 1.1 -- Sloped armor effectiveness: armor / cos(angle)^factor
ACF.Spalling = 0
ACF.GunfireEnabled = true
ACF.MeshCalcEnabled = false
ACF.HEPower = 8000 --HE Filler power per KG in KJ
ACF.HEDensity = 1.65 --HE Filler density (That"s TNT density)
ACF.HEFrag = 1000 --Mean fragment number for equal weight TNT and casing
ACF.HEBlastPen = 0.4 --Blast penetration exponent based of HE power
ACF.HEFeatherExp = 0.5 --exponent applied to HE dist/maxdist feathering, <1 will increasingly bias toward max damage until sharp falloff at outer edge of range
ACF.HEATMVScale = 0.75 --Filler KE to HEAT slug KE conversion expotential
ACF.HEATMulAmmo = 30 --HEAT slug damage multiplier; 13.2x roughly equal to AP damage
ACF.HEATMulFuel = 4 --needs less multiplier, much less health than ammo
ACF.HEATMulEngine = 10 --likewise
ACF.HEATPenLayerMul = 0.75 --HEAT base energy multiplier
ACF.HEATBoomConvert = 1 / 3 -- percentage of filler that creates HE damage at detonation
ACF.HEATMinCrush = 800 -- vel where crush starts, progressively converting round to raw HE
ACF.HEATMaxCrush = 1200 -- vel where fully crushed
ACF.DragDiv = 40 --Drag fudge factor
ACF.VelScale = 1 --Scale factor for the shell velocities in the game world
ACF.PhysMaxVel = 4000
ACF.SmokeWind = 5 + math.random() * 35 --affects the ability of smoke to be used for screening effect
ACF.PBase = 1050 --1KG of propellant produces this much KE at the muzzle, in kj
ACF.PScale = 1 --Gun Propellant power expotential
ACF.MVScale = 0.5 --Propellant to MV convertion expotential
ACF.PDensity = 1.6 --Gun propellant density (Real powders go from 0.7 to 1.6, i"m using higher densities to simulate case bottlenecking)
ACF.TorqueBoost = 1.25 --torque multiplier from using fuel
ACF.FuelRate = 5 --multiplier for fuel usage, 1.0 is approx real world
ACF.ElecRate = 1.5 --multiplier for electrics
ACF.TankVolumeMul = 0.5 -- multiplier for fuel tank capacity, 1.0 is approx real world

--kg/liter
ACF.FuelDensity = {
	Diesel = 0.832,
	Petrol = 0.745,
	Electric = 3.89 -- li-ion
}

--how efficient various engine types are, higher is worse
ACF.Efficiency = {
	GenericPetrol = 0.304, --kg per kw hr
	GenericDiesel = 0.243, --up to 0.274
	Turbine = 0.375, -- previously 0.231
	Wankel = 0.335,
	Radial = 0.4, -- 0.38 to 0.53
	Electric = 0.85 --percent efficiency converting chemical kw into mechanical kw
}

--how fast damage drops torque, lower loses more % torque
ACF.TorqueScale = {
	GenericPetrol = 0.25,
	GenericDiesel = 0.35,
	Turbine = 0.2,
	Wankel = 0.2,
	Radial = 0.3,
	Electric = 0.5
}

--health multiplier for engines
ACF.EngineHPMult = {
	GenericPetrol = 0.2,
	GenericDiesel = 0.5,
	Turbine = 0.125,
	Wankel = 0.125,
	Radial = 0.3,
	Electric = 0.75
}

ACF.LiIonED = 0.458 -- li-ion energy density: kw hours / liter
ACF.CuIToLiter = 0.0163871 -- cubic inches to liters
ACF.RefillDistance = 300 --Distance in which ammo crate starts refilling.
ACF.RefillSpeed = 700 -- (ACF.RefillSpeed / RoundMass) / Distance 
ACF.ChildDebris = 50 -- higher is more debris props;  Chance =  ACF.ChildDebris / num_children;  Only applies to children of acf-killed parent props
ACF.DebrisIgniteChance = 0.25
ACF.DebrisScale = 20 -- Ignore debris that is less than this bounding radius.
ACF.SpreadScale = 4 -- The maximum amount that damage can decrease a gun"s accuracy.  Default 4x
ACF.GunInaccuracyScale = 1 -- A multiplier for gun accuracy. Must be between 0.5 and 4
ACF.GunInaccuracyBias = 2 -- Higher numbers make shots more likely to be inaccurate.  Choose between 0.5 to 4. Default is 2 (unbiased).
ACF.EnableDefaultDP = false -- Enable the inbuilt damage protection system.
ACF.EnableKillicons = true -- Enable killicons overwriting.

if file.Exists("acf/shared/acf_userconfig.lua", "LUA") then
	include("acf/shared/acf_userconfig.lua")
end

CreateConVar("sbox_max_acf_gun", 16)
CreateConVar("sbox_max_acf_smokelauncher", 10)
CreateConVar("sbox_max_acf_ammo", 32)
CreateConVar("sbox_max_acf_misc", 32)
CreateConVar("acf_meshvalue", 1)
CreateConVar("sbox_acf_restrictinfo", 1) -- 0=any, 1=owned
AddCSLuaFile()
AddCSLuaFile("acf/client/cl_acfballistics.lua")
AddCSLuaFile("acf/client/cl_acfmenu_gui.lua")
AddCSLuaFile("acf/client/cl_acfrender.lua")

if SERVER and ACF.EnableDefaultDP then
	AddCSLuaFile("acf/client/cl_acfpermission.lua")
	AddCSLuaFile("acf/client/gui/cl_acfsetpermission.lua")
end

if SERVER then
	util.AddNetworkString("ACF_KilledByACF")
	util.AddNetworkString("ACF_RenderDamage")
	util.AddNetworkString("ACF_Notify")
	include("acf/server/sv_acfbase.lua")
	include("acf/server/sv_acfdamage.lua")
	include("acf/server/sv_acfballistics.lua")

	if ACF.EnableDefaultDP then
		include("acf/server/sv_acfpermission.lua")
	end
elseif CLIENT then
	include("acf/client/cl_acfballistics.lua")
	include("acf/client/cl_acfrender.lua")

	if ACF.EnableDefaultDP then
		include("acf/client/cl_acfpermission.lua")
		include("acf/client/gui/cl_acfsetpermission.lua")
	end

	CreateConVar("acf_cl_particlemul", 1)
	CreateClientConVar("ACF_MobilityRopeLinks", "1", true, true)
	-- Cache results so we don"t need to do expensive filesystem checks every time
	local IsValidCache = {}

	-- Returns whether or not a sound actually exists, fixes client timeout issues
	function IsValidSound(path)
		if IsValidCache[path] == nil then
			IsValidCache[path] = file.Exists(string.format("sound/%s", tostring(path)), "GAME") and true or false
		end

		return IsValidCache[path]
	end
end

include("acf/shared/acfloader.lua")
include("acf/shared/acfcratelist.lua")
--include("acf/shared/acfmissilelist.lua")
ACF.Weapons = list.Get("ACFEnts")
ACF.Classes = list.Get("ACFClasses")
ACF.RoundTypes = list.Get("ACFRoundTypes")
ACF.IdRounds = list.Get("ACFIdRounds") --Lookup tables so i can get rounds classes from clientside with just an integer
game.AddParticles("particles/acf_muzzleflashes.pcf")
game.AddParticles("particles/explosion1.pcf")
game.AddParticles("particles/rocket_motor.pcf")
game.AddDecal("GunShot1", "decals/METAL/shot5")

-- Add the ACF tool category
if CLIENT then
	ACF.CustomToolCategory = CreateClientConVar("acf_tool_category", 0, true, false)

	if (ACF.CustomToolCategory:GetBool()) then
		language.Add("spawnmenu.tools.acf", "ACF")

		-- We use this hook so that the ACF category is always at the top
		hook.Add("AddToolMenuTabs", "CreateACFCategory", function()
			spawnmenu.AddToolCategory("Main", "ACF", "#spawnmenu.tools.acf")
		end)
	end
end

timer.Simple(0, function()
	for _, Table in pairs(ACF.Classes["GunClass"]) do
		PrecacheParticleSystem(Table["muzzleflash"])
	end
end)

--Stupid workaround red added to precache timescaling.
hook.Add("Think", "Update ACF Internal Clock", function()
	ACF.CurTime = CurTime()
	ACF.SysTime = SysTime()
end)

-- changes here will be automatically reflected in the armor properties tool
function ACF_CalcArmor(Area, Ductility, Mass)
	return (Mass * 1000 / Area / 0.78) / (1 + Ductility) ^ 0.5 * ACF.ArmorMod
end

function ACF_MuzzleVelocity(Propellant, Mass)
	local PEnergy = ACF.PBase * ((1 + Propellant) ^ ACF.PScale - 1)
	local Speed = ((PEnergy * 2000 / Mass) ^ ACF.MVScale)
	local Final = Speed -- - Speed * math.Clamp(Speed/2000,0,0.5)

	return Final
end

function ACF_Kinetic(Speed, Mass, LimitVel)
	LimitVel = LimitVel or 99999
	Speed = Speed / 39.37
	local Energy = {}
	Energy.Kinetic = (Mass * (Speed ^ 2)) / 2000 --Energy in KiloJoules
	Energy.Momentum = (Speed * Mass)
	local KE = (Mass * (Speed ^ ACF.KinFudgeFactor)) / 2000 + Energy.Momentum
	Energy.Penetration = math.max(KE - (math.max(Speed - LimitVel, 0) ^ 2) / (LimitVel * 5) * (KE / 200) ^ 0.95, KE * 0.1)
	--Energy.Penetration = math.max( KE - (math.max(Speed-LimitVel,0)^2)/(LimitVel*5) * (KE/200)^0.95 , KE*0.1 )
	--Energy.Penetration = math.max(Energy.Momentum^ACF.KinFudgeFactor - math.max(Speed-LimitVel,0)/(LimitVel*5) * Energy.Momentum , Energy.Momentum*0.1)

	return Energy
end

-- returns any wheels linked to this or child gearboxes
function ACF_GetLinkedWheels(MobilityEnt)
	if not IsValid(MobilityEnt) then return {} end
	local ToCheck = {}
	local Wheels = {}
	local links = MobilityEnt.GearLink or MobilityEnt.WheelLink -- handling for usage on engine or gearbox

	for _, link in pairs(links) do
		table.insert(ToCheck, link.Ent)
	end

	-- use a stack to traverse the link tree looking for wheels at the end
	while #ToCheck > 0 do
		local Ent = table.remove(ToCheck, #ToCheck)

		if IsValid(Ent) then
			if Ent:GetClass() == "acf_gearbox" then
				for _, v in pairs(Ent.WheelLink) do
					table.insert(ToCheck, v.Ent)
				end
			else
				Wheels[Ent] = Ent -- indexing it same as ACF_GetAllPhysicalEntities, for easy merge.  whoever indexed by entity in that function, uuuuuuggghhhhh
			end
		end
	end

	return Wheels
end


-- Global Ratio Setting Function
function ACF_CalcMassRatio(Ent, Pwr)
	if not IsValid(Ent) then return end

	local TotMass  = 0
	local PhysMass = 0
	local Power    = 0
	local Fuel     = 0
	local Time     = CurTime()

	local Physical, Parented = ACF_GetEnts(Ent)

	for K in pairs(Physical) do
		if Pwr then
			if K:GetClass() == "acf_engine" then
				Power = Power + (K.peakkw * 1.34)
				Fuel = K.RequiresFuel and 2 or Fuel
			elseif K:GetClass() == "acf_fueltank" then
				Fuel = math.max(Fuel, 1)
			end
		end

		local Phys = K:GetPhysicsObject() -- This should always exist, but just in case

		if IsValid(Phys) then
			local Mass = Phys:GetMass()

			TotMass  = TotMass + Mass
			PhysMass = PhysMass + Mass
		end
	end

	for K in pairs(Parented) do
		if Physical[K] then continue end -- Skip overlaps

		if Pwr then
			if K:GetClass() == "acf_engine" then
				Power = Power + (K.peakkw * 1.34)
				Fuel = K.RequiresFuel and 2 or Fuel
			elseif K:GetClass() == "acf_fueltank" then
				Fuel = math.max(Fuel, 1)
			end
		end

		local Phys = K:GetPhysicsObject()

		if IsValid(Phys) then
			TotMass = TotMass + Phys:GetMass()
		end
	end

	for K in pairs(Physical) do
		K.acfphystotal      = PhysMass
		K.acftotal          = TotMass
		K.acflastupdatemass = Time
	end

	for K in pairs(Parented) do
		if Physical[K] then continue end -- Skip overlaps

		K.acfphystotal      = PhysMass
		K.acftotal          = TotMass
		K.acflastupdatemass = Time
	end

	if Pwr then
		return {
			Power = Power,
			Fuel = Fuel
		}
	end
end

-- Cvars for recoil/he push
CreateConVar("acf_hepush", 1)
CreateConVar("acf_recoilpush", 1)
-- New healthmod/armormod/ammomod cvars
CreateConVar("acf_healthmod", 1)
CreateConVar("acf_armormod", 1)
CreateConVar("acf_ammomod", 1)
CreateConVar("acf_spalling", 0)
CreateConVar("acf_gunfire", 1)
CreateConVar("acf_modelswap_legal", 0)

function ACF_CVarChangeCallback(CVar, _, New)
	if (CVar == "acf_healthmod") then
		ACF.Threshold = 264.7 / math.max(New, 0.01)
		print("Health Mod changed to a factor of " .. New)
	elseif (CVar == "acf_armormod") then
		ACF.ArmorMod = 1 * math.max(New, 0)
		print("Armor Mod changed to a factor of " .. New)
	elseif (CVar == "acf_ammomod") then
		ACF.AmmoMod = 1 * math.max(New, 0.01)
		print("Ammo Mod changed to a factor of " .. New)
	elseif (CVar == "acf_spalling") then
		ACF.Spalling = math.floor(math.Clamp(New, 0, 1))
		local text = "off"

		if (ACF.Spalling > 0) then
			text = "on"
		end

		print("ACF Spalling is now " .. text)
	elseif (CVar == "acf_gunfire") then
		ACF.GunfireEnabled = tobool(New)
		local text = "disabled"

		if ACF.GunfireEnabled then
			text = "enabled"
		end

		print("ACF Gunfire has been " .. text)
	elseif CVar == "acf_modelswap_legal" then
		ACF.LegalSettings.CanModelSwap = tobool(New)
		print("ACF model swapping is set to " .. (ACF.LegalSettings.CanModelSwap and "legal" or "not legal"))
	end
end

if SERVER then
	function ACF_SendNotify(ply, success, msg)
		net.Start("ACF_Notify")
		net.WriteBit(success)
		net.WriteString(msg or "")
		net.Send(ply)
	end
else
	local function ACF_Notify()
		local Type = NOTIFY_ERROR

		if tobool(net.ReadBit()) then
			Type = NOTIFY_GENERIC
		end

		GAMEMODE:AddNotify(net.ReadString(), Type, 7)
	end

	net.Receive("ACF_Notify", ACF_Notify)
end

function ACF_UpdateChecking()
	http.Fetch("https://github.com/nrlulz/ACF", function(contents, _)
		local rev = tonumber(string.match(contents, "%s*(%d+)\n%s*</span>\n%s*commits")) or 0 --"history\"></span>\n%s*(%d+)\n%s*</span>"

		if rev and ACF.Version >= rev then
			print("[ACF] ACF Is Up To Date, Latest Version: " .. rev)
		elseif not rev then
			print("[ACF] No Internet Connection Detected! ACF Update Check Failed")
		else
			print("[ACF] A newer version of ACF is available! Version: " .. rev .. ", You have Version: " .. ACF.Version)

			if CLIENT then
				chat.AddText(Color(255, 0, 0), "A newer version of ACF is available!")
			end
		end

		ACF.CurrentVersion = rev
	end, function() end)
end

ACF_UpdateChecking()

local function OnInitialSpawn(ply)
	local Table = {}

	for _, v in pairs(ents.GetAll()) do
		if v.ACF and v.ACF.PrHealth then
			table.insert(Table, {
				ID = v:EntIndex(),
				Health = v.ACF.Health,
v.ACF.MaxHealth
			})
		end
	end

	if Table ~= {} then
		net.Start("ACF_RenderDamage")
		net.WriteTable(Table)
		net.Send(ply)
	end
end

hook.Add("PlayerInitialSpawn", "renderdamage", OnInitialSpawn)
cvars.AddChangeCallback("acf_healthmod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_armormod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_ammomod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_spalling", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_gunfire", ACF_CVarChangeCallback)

-- smoke-wind cvar handling
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

	local function sendSmokeWind(ply)
		net.Start("acf_smokewind")
		net.WriteFloat(ACF.SmokeWind)
		net.Send(ply)
	end

	hook.Add("PlayerInitialSpawn", "ACF_SendSmokeWind", sendSmokeWind)
else
	local function recvSmokeWind()
		ACF.SmokeWind = net.ReadFloat()
	end

	net.Receive("acf_smokewind", recvSmokeWind)
end