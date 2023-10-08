-- This file defines damage permission with all ACF weaponry
local ACF = ACF
ACF.Permissions = ACF.Permissions or {}
local this = ACF.Permissions
local Messages = ACF.Utilities.Messages
--TODO: make player-customizable
this.Selfkill = true
this.Safezones = false
this.Player = this.Player or {}
this.Modes = this.Modes or {}
this.ModeDescs = this.ModeDescs or {}
this.ModeThinks = this.ModeThinks or {}
this.ModeDefaultAction = this.ModeDefaultAction or {}
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
	//]]
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

	--PrintTable(safetable)
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
	this.Safezones = safezones

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
	if not this.Safezones then return end

	for _, ply in ipairs(player.GetAll()) do
		local sid = ply:SteamID()
		local pos = ply:GetPos()
		local oldzone = plyzones[sid]
		local zone = this.IsInSafezone(pos) or nil
		plyzones[sid] = zone

		if oldzone ~= zone then
			hook.Run("ACF_PlayerChangedZone", ply, zone, oldzone)
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

		if not this.Safezones then
			this.Safezones = {}
		end

		if this.Safezones[szname] and this.Safezones[szname].default then
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
		this.Safezones[szname] = {mins, maxs}

		if default then
			this.Safezones[szname].default = true
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

		if not (this.Safezones and this.Safezones[szname]) then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: could not find a safezone called " .. szname .. ".")

			return false
		end

		if this.Safezones[szname].default then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: an unmodifiable safezone called " .. szname .. " already exists!")

			return false
		end

		this.Safezones[szname] = nil
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
		if not this.Safezones then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: There are no safezones on the map which can be saved.")

			return false
		end

		local szjson = util.TableToJSON(this.Safezones)
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

		for k in pairs(this.Modes) do
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

		if not this.Modes[mode] then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: " .. mode .. " is not a valid permission mode!" .. "\nUse this command without arguments to see all available modes.")

			return false
		end

		local oldmode = table.KeyFromValue(this.Modes, this.DamagePermission)
		this.DefaultCanDamage = this.ModeDefaultAction[mode]
		this.DamagePermission = this.Modes[mode]
		printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: Current damage permission policy is now " .. mode .. "!")
		hook.Run("ACF_ProtectionModeChanged", mode, oldmode)

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

		for k in pairs(this.Modes) do
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

		if not this.Modes[mode] then
			printmsg(HUD_PRINTCONSOLE, "Command unsuccessful: " .. mode .. " is not a valid permission mode!" .. "\nUse this command without arguments to see all available modes.")

			return false
		end

		if this.DefaultPermission == mode then return false end
		SaveMapDPM(mode)
		this.DefaultPermission = mode
		printmsg(HUD_PRINTCONSOLE, "Command SUCCESSFUL: Default permission mode for " .. curMap .. " set to: " .. mode)

		for _, v in ipairs(player.GetAll()) do
			if v:IsAdmin() then
				Messages.SendChat(v, "Info", "Default permission mode for " .. curMap .. " has been set to " .. mode .. "!")
			end
		end

		this.ResendPermissionsOnChanged()

		return true
	end
end)

local function tellPlysAboutDPMode(mode, oldmode)
	if mode == oldmode then return end

	Messages.SendChat(_, "Info", "Damage protection has been changed to " .. mode .. " mode!")
end

hook.Add("ACF_ProtectionModeChanged", "ACF_TellPlysAboutDPMode", tellPlysAboutDPMode)

function this.IsInSafezone(pos)
	if not this.Safezones then return false end
	local szmin, szmax

	for szname, szpts in pairs(this.Safezones) do
		szmin = szpts[1]
		szmax = szpts[2]
		if (pos.x > szmin.x and pos.y > szmin.y and pos.z > szmin.z) and (pos.x < szmax.x and pos.y < szmax.y and pos.z < szmax.z) then return szname end
	end

	return false
end

function this.RegisterMode(mode, name, desc, default, think, defaultaction)
	this.Modes[name] = mode
	this.ModeDescs[name] = desc
	this.ModeThinks[name] = think or function() end
	this.ModeDefaultAction[name] = Either(defaultaction, nil, defaultaction)
	local DPM = LoadMapDPM()

	if DPM then
		if DPM == name then
			this.DamagePermission = this.Modes[name]
			this.DefaultCanDamage = this.ModeDefaultAction[name]
			this.DefaultPermission = name

			timer.Simple(1, function()
				print("ACF: Found default permission mode: " .. DPM)
				print("ACF: Setting permission mode to: " .. name)
			end)
		end
	elseif default then
		this.DamagePermission = this.Modes[name]
		this.DefaultCanDamage = this.ModeDefaultAction[name]
		this.DefaultPermission = name

		timer.Simple(1, function()
			print("ACF: Map does not have default permission set, using default")
			print("ACF: Setting permission mode to: " .. name)
		end)
	end
	--Old method - can break on rare occasions!
	--if LoadMapDPM() == name or default then 
	--	print("ACF: Setting permission mode to: "..name)
	--	this.DamagePermission = this.Modes[name]
	--	this.DefaultPermission = name
	--end
end

function this.CanDamage(Entity, _, DmgInfo)
	local Attacker = DmgInfo:GetAttacker()
	local Owner    = IsValid(Entity) and Entity:CPPIGetOwner()

	if not (IsValid(Owner) and Owner:IsPlayer()) then
		if IsValid(Entity) and Entity:IsPlayer() then
			Owner = Entity
		else
			return this.DefaultCanDamage
		end
	end

	if not (IsValid(Attacker) and Attacker:IsPlayer()) then
		return this.DefaultCanDamage
	end

	return this.DamagePermission(Owner, Attacker, Entity)
end

hook.Add("ACF_PreDamageEntity", "ACF_DamagePermissionCore", this.CanDamage)

this.thinkWrapper = function()
	local curmode = table.KeyFromValue(this.Modes, this.DamagePermission)
	--print(curmode)
	local think = this.ModeThinks[curmode]
	local nextthink

	if think then
		nextthink = think()
	end

	timer.Simple(nextthink or 0.01, this.thinkWrapper)
end

timer.Simple(0.01, this.thinkWrapper)

function this.GetDamagePermissions(ownerid)
	if not this.Player[ownerid] then
		this.Player[ownerid] = {
			[ownerid] = true
		}
	end

	return this.Player[ownerid]
end

function this.AddDamagePermission(owner, attacker)
	local ownerid = owner:SteamID()
	local attackerid = attacker:SteamID()
	local ownerprefs = this.GetDamagePermissions(ownerid)
	ownerprefs[attackerid] = true
end

function this.RemoveDamagePermission(owner, attacker)
	local ownerid = owner:SteamID()
	if not this.Player[ownerid] then return end
	local attackerid = attacker:SteamID()
	this.Player[ownerid][attackerid] = nil
end

function this.ClearDamagePermissions(owner)
	local ownerid = owner:SteamID()
	if not this.Player[ownerid] then return end
	this.Player[ownerid] = nil
end

function this.PermissionsRaw(ownerid, attackerid, value)
	if not ownerid then return end
	local ownerprefs = this.GetDamagePermissions(ownerid)

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

	if this.Player[plyid] then
		this.Player[plyid] = nil
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
util.AddNetworkString("ACF_refreshfeedback")

net.Receive("ACF_dmgfriends", function(_, ply)
	--Msg("\nsv dmgfriends\n")
	if not ply:IsValid() then return end
	local perms = net.ReadTable()
	local ownerid = ply:SteamID()
	--Msg("ownerid = ", ownerid)
	--PrintTable(perms)
	local changed

	for k, v in pairs(perms) do
		changed = this.PermissionsRaw(ownerid, k, v)

		--Msg(k, " has ", changed and "changed\n" or "not changed\n")
		if changed then
			local targ = plyBySID(k)

			if targ then
				local note = v and "given you" or "removed your"
				local nick = string.Trim(string.format("%q", ply:Nick()), "\"") -- Ensuring that the name is Lua safe
				--Msg("Sending", targ, " ", note, "\n")
				ACF.SendNotify(targ, true, nick .. " has " .. note .. " permission to damage their objects with ACF!")
			end
		end
	end

	net.Start("ACF_refreshfeedback")
	net.WriteBit(true)
	net.Send(ply)
end)

function this.RefreshPlyDPFriends(ply)
	--Msg("\nsv refreshfriends\n")
	if not ply:IsValid() then return end
	local perms = this.GetDamagePermissions(ply:SteamID())
	net.Start("ACF_refreshfriends")
	net.WriteTable(perms)
	net.Send(ply)
end

util.AddNetworkString("ACF_refreshfriends")

net.Receive("ACF_refreshfriends", function(_, ply)
	this.RefreshPlyDPFriends(ply)
end)

function this.SendPermissionsState(ply)
	local modes = this.ModeDescs
	local current = table.KeyFromValue(this.Modes, this.DamagePermission)
	net.Start("ACF_refreshpermissions")
	net.WriteTable(modes)
	net.WriteString(current or this.DefaultPermission)
	net.WriteString(this.DefaultPermission or "")
	net.Send(ply)
end

util.AddNetworkString("ACF_refreshpermissions")

net.Receive("ACF_refreshpermissions", function(_, ply)
	this.SendPermissionsState(ply)
end)

function this.ResendPermissionsOnChanged()
	for _, ply in ipairs(player.GetAll()) do
		this.SendPermissionsState(ply)
	end
end

hook.Add("ACF_ProtectionModeChanged", "ACF_ResendPermissionsOnChanged", this.ResendPermissionsOnChanged)

-- -- -- -- -- Initial DP mode load -- -- -- -- --
local m = table.KeyFromValue(this.Modes, this.DamagePermission)

if not m then
	this.DamagePermission = function() end
	hook.Run("ACF_ProtectionModeChanged", "default", nil)
end