-- This file defines damage permission with all ACF weaponry
local ACF = ACF
ACF.Permissions = ACF.Permissions or {}
local Permissions = ACF.Permissions
local Messages = ACF.Utilities.Messages
--TODO: make player-customizable
Permissions.Selfkill = true
Permissions.Safezones = false
Permissions.Player = Permissions.Player or {}
Permissions.Modes = Permissions.Modes or {}
Permissions.ModeDescs = Permissions.ModeDescs or {}
Permissions.ModeThinks = Permissions.ModeThinks or {}
Permissions.ModeDefaultAction = Permissions.ModeDefaultAction or {}
--TODO: convar this
local mapSZDir = "acf/safezones/"
local mapDPMDir = "acf/permissions/"
file.CreateDir(mapDPMDir)
local curMap = game.GetMap()

local function msgtoconsole(_, msg)
	print(msg)
end

local function resolveAABBs(mins, maxs)
	--[[
	for xyz, val in pairs(mins) do	// ensuring points conform to AABB mins/maxs
		if val > maxs.xyz then
			local store = maxs.xyz
			maxs.xyz = val
			mins.xyz = store
		end
	end
	]]
	local store

	if mins.x > maxs.x then
		store = maxs.x
		maxs.x = mins.x
		mins.x = store
	end

	if mins.y > maxs.y then
		store = maxs.y
		maxs.y = mins.y
		mins.y = store
	end

	if mins.z > maxs.z then
		store = maxs.z
		maxs.z = mins.z
		mins.z = store
	end

	return mins, maxs
end

--TODO: sanitize safetable instead of marking it all as bad
local function validateSZs(safetable)
	if type(safetable) ~= "table" then return false end

	for k, v in pairs(safetable) do
		if type(k) ~= "string" then return false end
		if not (#v == 2 and v[1] and v[2]) then return false end

		for _, b in ipairs(v) do
			if not (b.x and b.y and b.z) then return false end
		end

		local mins = v[1]
		local maxs = v[2]
		mins, maxs = resolveAABBs(mins, maxs)
	end

	return true
end

local function getMapFilename()
	local mapname = string.gsub(curMap, "[^%a%d-_]", "_")

	return mapSZDir .. mapname .. ".txt"
end

local function getMapSZs()
	local mapname = getMapFilename()
	local mapSZFile = file.Read(mapname, "DATA") or ""
	local safezones = util.JSONToTable(mapSZFile)
	if not validateSZs(safezones) then return false end -- TODO: generate default safezones around spawnpoints.
	Permissions.Safezones = safezones

	return true
end

local function SaveMapDPM(mode)
	local mapname = string.gsub(curMap, "[^%a%d-_]", "_")
	file.Write(mapDPMDir .. mapname .. ".txt", mode)
end

-- Unix adds an extra newline character at the end of the files
-- So we have to get rid of it, and everything after it
local function ReadFile(Path)
	local Contents = file.Read(Path, "DATA")

	if Contents then
		return string.gsub(Contents, "(\n.*)", "")
	end
end

local function LoadMapDPM()
	local mapname = string.gsub(curMap, "[^%a%d-_]", "_")
	local mapmode = ReadFile(mapDPMDir .. mapname .. ".txt")

	if mapmode then return mapmode end

	return ReadFile(mapDPMDir .. "default.txt")
end

hook.Add("Initialize", "ACF_LoadSafesForMap", function()
	if not getMapSZs() then
		print("Safezone file " .. getMapFilename() .. " is missing, invalid or corrupt! Safezones will not be restored this time.")
	end
end)

local plyzones = {}

hook.Add("Think", "ACF_DetectSZTransition", function()
	if not Permissions.Safezones then return end

	for _, ply in player.Iterator() do
		local sid = ply:SteamID()
		local pos = ply:GetPos()
		local oldzone = plyzones[sid]
		local zone = Permissions.IsInSafezone(pos) or nil
		plyzones[sid] = zone

		if oldzone ~= zone then
			hook.Run("ACF_OnPlayerChangeZone", ply, zone, oldzone)
		end
	end
end)

concommand.Add("ACF_AddSafeZone", function(ply, _, args)
	local validply = IsValid(ply)

	local printmsg = validply and function(hud, msg)
		ply:PrintMessage(hud, msg)
	end or msgtoconsole

	if not args[1] then
		printmsg(HUD_PRINTCONSOLE, " - Add a safezone as an AABB box." .. "\n   Input a name and six numbers. First three numbers are minimum co-ords, last three are maxs." .. "\n   Example; ACF_addsafezone airbase -500 -500 0 500 500 1000")

		return false
	end

	if validply and not ply:IsAdmin() then
		printmsg(HUD_PRINTCONSOLE, "You can't use this because you are not an admin.")

		return false
	else
		local szname = tostring(args[1])
		args[1] = nil
		local default = tostring(args[8])

		if default ~= "default" then
			default = nil
		end

		if not Permissions.Safezones then
			Permissions.Safezones = {}
		end

		if Permissions.Safezones[szname] and Permissions.Safezones[szname].default then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: an unmodifiable safezone called " .. szname .. " already exists!")

			return false
		end

		for k, v in ipairs(args) do
			args[k] = tonumber(v)

			if args[k] == nil then
				printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: argument " .. k .. " could not be interpreted as a number (" .. v .. ")")

				return false
			end
		end

		local mins = Vector(args[2], args[3], args[4])
		local maxs = Vector(args[5], args[6], args[7])
		mins, maxs = resolveAABBs(mins, maxs)
		Permissions.Safezones[szname] = {mins, maxs}

		if default then
			Permissions.Safezones[szname].default = true
		end

		printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: added a safezone called " .. szname .. " between " .. tostring(mins) .. " and " .. tostring(maxs) .. "!")

		return true
	end
end)

concommand.Add("ACF_RemoveSafeZone", function(ply, _, args)
	local validply = IsValid(ply)

	local printmsg = validply and function(hud, msg)
		ply:PrintMessage(hud, msg)
	end or msgtoconsole

	if not args[1] then
		printmsg(HUD_PRINTCONSOLE, " - Delete a safezone using its name." .. "\n   Input a safezone name. If it exists, it will be removed." .. "\n   Deletion is not permanent until safezones are saved.")

		return false
	end

	if validply and not ply:IsAdmin() then
		printmsg(HUD_PRINTCONSOLE, "You can't use this because you are not an admin.")

		return false
	else
		local szname = tostring(args[1])

		if not szname then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: could not interpret your input as a string.")

			return false
		end

		if not (Permissions.Safezones and Permissions.Safezones[szname]) then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: could not find a safezone called " .. szname .. ".")

			return false
		end

		if Permissions.Safezones[szname].default then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: an unmodifiable safezone called " .. szname .. " already exists!")

			return false
		end

		Permissions.Safezones[szname] = nil
		printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: removed the safezone called " .. szname .. "!")

		return true
	end
end)

concommand.Add("ACF_SaveSafeZones", function(ply)
	local validply = IsValid(ply)

	local printmsg = validply and function(hud, msg)
		ply:PrintMessage(hud, msg)
	end or msgtoconsole

	if validply and not ply:IsAdmin() then
		printmsg(HUD_PRINTCONSOLE, "You can't use this because you are not an admin.")

		return false
	else
		if not Permissions.Safezones then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: There are no safezones on the map which can be saved.")

			return false
		end

		local szjson = util.TableToJSON(Permissions.Safezones)
		local mapname = getMapFilename()
		file.CreateDir(mapSZDir)
		file.Write(mapname, szjson)
		printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: All safezones on the map have been made restorable.")

		return true
	end
end)

concommand.Add("ACF_ReloadSafeZones", function(ply)
	local validply = IsValid(ply)

	local printmsg = validply and function(hud, msg)
		ply:PrintMessage(hud, msg)
	end or msgtoconsole

	if validply and not ply:IsAdmin() then
		printmsg(HUD_PRINTCONSOLE, "You can't use this because you are not an admin.")

		return false
	else
		local ret = getMapSZs()

		if ret then
			printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: All safezones on the map have been restored.")
		else
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: Safezone file for this map is missing, invalid or corrupt.")
		end

		return ret
	end
end)

concommand.Add("ACF_SetPermissionMode", function(ply, _, args)
	local validply = IsValid(ply)

	local printmsg = validply and function(hud, msg)
		ply:PrintMessage(hud, msg)
	end or msgtoconsole

	if not args[1] then
		local modes = ""

		for k in pairs(Permissions.Modes) do
			modes = modes .. k .. " "
		end

		printmsg(HUD_PRINTCONSOLE, " - Set damage permission behaviour mode." .. "\n   Available modes: " .. modes)

		return false
	end

	if validply and not ply:IsAdmin() then
		printmsg(HUD_PRINTCONSOLE, "You can't use this because you are not an admin.")

		return false
	else
		local mode = tostring(args[1])

		if not Permissions.Modes[mode] then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: " .. mode .. " is not a valid permission mode!" .. "\nUse this command without arguments to see all available modes.")

			return false
		end

		local oldmode = table.KeyFromValue(Permissions.Modes, Permissions.DamagePermission)
		Permissions.DefaultCanDamage = Permissions.ModeDefaultAction[mode]
		Permissions.DamagePermission = Permissions.Modes[mode]
		printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: Current damage permission policy is now " .. mode .. "!")
		hook.Run("ACF_OnChangeProtectionMode", mode, oldmode)

		return true
	end
end)

concommand.Add("ACF_SetDefaultPermissionMode", function(ply, _, args)
	local validply = IsValid(ply)

	local printmsg = validply and function(hud, msg)
		ply:PrintMessage(hud, msg)
	end or msgtoconsole

	if not args[1] then
		local modes = ""

		for k in pairs(Permissions.Modes) do
			modes = modes .. k .. " "
		end

		printmsg(HUD_PRINTCONSOLE, " - Set damage permission behaviour mode." .. "\n   Available modes: " .. modes)

		return false
	end

	if validply and not ply:IsAdmin() then
		printmsg(HUD_PRINTCONSOLE, "You can't use this because you are not an admin.")

		return false
	else
		local mode = tostring(args[1])

		if not Permissions.Modes[mode] then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: " .. mode .. " is not a valid permission mode!" .. "\nUse this command without arguments to see all available modes.")

			return false
		end

		if Permissions.DefaultPermission == mode then return false end
		SaveMapDPM(mode)
		Permissions.DefaultPermission = mode
		printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: Default permission mode for " .. curMap .. " set to: " .. mode)

		for _, v in ipairs(player.GetAll()) do
			if v:IsAdmin() then
				Messages.SendChat(v, "Info", "Default permission mode for " .. curMap .. " has been set to " .. mode .. "!")
			end
		end

		Permissions.ResendPermissionsOnChanged()

		return true
	end
end)

local function tellPlysAboutDPMode(mode, oldmode)
	if mode == oldmode then return end

	Messages.SendChat(nil, "Info", "Damage protection has been changed to " .. mode .. " mode!")
end

hook.Add("ACF_OnChangeProtectionMode", "ACF_TellPlysAboutDPMode", tellPlysAboutDPMode)

function Permissions.IsInSafezone(pos)
	if not Permissions.Safezones then return false end
	local szmin, szmax

	for szname, szpts in pairs(Permissions.Safezones) do
		szmin = szpts[1]
		szmax = szpts[2]
		if (pos.x > szmin.x and pos.y > szmin.y and pos.z > szmin.z) and (pos.x < szmax.x and pos.y < szmax.y and pos.z < szmax.z) then return szname end
	end

	return false
end

function Permissions.RegisterMode(mode, name, desc, default, think, defaultaction)
	Permissions.Modes[name] = mode
	Permissions.ModeDescs[name] = desc
	Permissions.ModeThinks[name] = think or function() end
	Permissions.ModeDefaultAction[name] = Either(defaultaction, nil, defaultaction)
	local DPM = LoadMapDPM()

	if DPM and DPM == name then
		Permissions.DamagePermission = Permissions.Modes[name]
		Permissions.DefaultCanDamage = Permissions.ModeDefaultAction[name]
		Permissions.DefaultPermission = name

		timer.Simple(1, function()
			print("ACF: Found default permission mode: " .. DPM)
			print("ACF: Setting permission mode to: " .. name)
		end)
	elseif default then
		Permissions.DamagePermission = Permissions.Modes[name]
		Permissions.DefaultCanDamage = Permissions.ModeDefaultAction[name]
		Permissions.DefaultPermission = name

		timer.Simple(1, function()
			print("ACF: Map does not have default permission set, using default")
			print("ACF: Setting permission mode to: " .. name)
		end)
	end
	--Old method - can break on rare occasions!
	--if LoadMapDPM() == name or default then 
	--	print("ACF: Setting permission mode to: "..name)
	--	Permissions.DamagePermission = Permissions.Modes[name]
	--	Permissions.DefaultPermission = name
	--end
end

function Permissions.CanDamage(Entity, _, DmgInfo)
	local Attacker = DmgInfo:GetAttacker()
	local Owner    = IsValid(Entity) and Entity:CPPIGetOwner()

	if not (IsValid(Owner) and Owner:IsPlayer()) then
		if IsValid(Entity) and Entity:IsPlayer() then
			Owner = Entity
		else
			return Permissions.DefaultCanDamage
		end
	end

	if not (IsValid(Attacker) and Attacker:IsPlayer()) then
		return Permissions.DefaultCanDamage
	end

	return Permissions.DamagePermission(Owner, Attacker, Entity)
end

hook.Add("ACF_PreDamageEntity", "ACF_DamagePermissionCore", Permissions.CanDamage)

Permissions.thinkWrapper = function()
	local curmode = table.KeyFromValue(Permissions.Modes, Permissions.DamagePermission)
	local think = Permissions.ModeThinks[curmode]
	local nextthink

	if think then
		nextthink = think()
	end

	timer.Simple(nextthink or 0.01, Permissions.thinkWrapper)
end

timer.Simple(0.01, Permissions.thinkWrapper)

function Permissions.GetDamagePermissions(ownerid)
	if not Permissions.Player[ownerid] then
		Permissions.Player[ownerid] = {
			[ownerid] = true
		}
	end

	return Permissions.Player[ownerid]
end

function Permissions.AddDamagePermission(owner, attacker)
	local ownerid = owner:SteamID()
	local attackerid = attacker:SteamID()
	local ownerprefs = Permissions.GetDamagePermissions(ownerid)
	ownerprefs[attackerid] = true
end

function Permissions.RemoveDamagePermission(owner, attacker)
	local ownerid = owner:SteamID()
	if not Permissions.Player[ownerid] then return end
	local attackerid = attacker:SteamID()
	Permissions.Player[ownerid][attackerid] = nil
end

function Permissions.ClearDamagePermissions(owner)
	local ownerid = owner:SteamID()
	if not Permissions.Player[ownerid] then return end
	Permissions.Player[ownerid] = nil
end

function Permissions.PermissionsRaw(ownerid, attackerid, value)
	if not ownerid then return end
	local ownerprefs = Permissions.GetDamagePermissions(ownerid)

	if attackerid then
		local old = ownerprefs[attackerid] and true or nil
		local new = value and true or nil
		ownerprefs[attackerid] = new

		return old ~= new
	end

	return false
end

local function onDisconnect(ply)
	local plyid = ply:SteamID()

	if Permissions.Player[plyid] then
		Permissions.Player[plyid] = nil
	end

	plyzones[plyid] = nil
end

hook.Add("PlayerDisconnected", "ACF_PermissionDisconnect", onDisconnect)

local function plyBySID(steamid)
	for _, v in ipairs(player.GetAll()) do
		if v:SteamID() == steamid then return v end
	end

	return false
end

-- -- -- -- -- Client sync -- -- -- -- --
-- All code below modified from the NADMOD client permissions menu, by Nebual
-- http://www.facepunch.com/showthread.php?t=1221183
util.AddNetworkString("ACF_dmgfriends")

net.Receive("ACF_dmgfriends", function(_, ply)
	if not ply:IsValid() then return end
	local perms = net.ReadTable()
	local ownerid = ply:SteamID()
	local changed
	local Success = true

	for k, v in pairs(perms) do
		changed = Permissions.PermissionsRaw(ownerid, k, v)

		if changed then
			local targ = plyBySID(k)

			if targ then
				local note = v and "given you" or "removed your"
				local nick = string.Trim(string.format("%q", ply:Nick()), "\"") -- Ensuring that the name is Lua safe

				ACF.SendNotify(targ, true, nick .. " has " .. note .. " permission to damage their objects with ACF!")
			end
		end
	end

	local FeedbackMessage = Success and "Successfully updated your ACF damage permissions!" or "Failed to update your ACF damage permissions."
	ACF.SendNotify(ply, Success, FeedbackMessage)
end)

function Permissions.RefreshPlyDPFriends(ply)
	if not ply:IsValid() then return end
	local perms = Permissions.GetDamagePermissions(ply:SteamID())
	net.Start("ACF_refreshfriends")
	net.WriteTable(perms)
	net.Send(ply)
end

util.AddNetworkString("ACF_refreshfriends")

net.Receive("ACF_refreshfriends", function(_, ply)
	Permissions.RefreshPlyDPFriends(ply)
end)

function Permissions.SendPermissionsState(ply)
	local modes = Permissions.ModeDescs
	local current = table.KeyFromValue(Permissions.Modes, Permissions.DamagePermission)
	net.Start("ACF_refreshpermissions")
	net.WriteTable(modes)
	net.WriteString(current or Permissions.DefaultPermission)
	net.WriteString(Permissions.DefaultPermission or "")
	net.Send(ply)
end

util.AddNetworkString("ACF_refreshpermissions")

net.Receive("ACF_refreshpermissions", function(_, ply)
	Permissions.SendPermissionsState(ply)
end)

function Permissions.ResendPermissionsOnChanged()
	for _, ply in ipairs(player.GetAll()) do
		Permissions.SendPermissionsState(ply)
	end
end

hook.Add("ACF_OnChangeProtectionMode", "ACF_ResendPermissionsOnChanged", Permissions.ResendPermissionsOnChanged)

-- -- -- -- -- Initial DP mode load -- -- -- -- --
local m = table.KeyFromValue(Permissions.Modes, Permissions.DamagePermission)

if not m then
	Permissions.DamagePermission = function() end
	hook.Run("ACF_OnChangeProtectionMode", "default", nil)
end