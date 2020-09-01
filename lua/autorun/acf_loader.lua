
--[[
	Files are sent to client/server/shared realm as determined by folder name (server, client, shared)
	realm destination inherits through sub-folders
	Files are sent by one of the following prefixes if not in a realm-specific folder:
		sv_: server
		cl_: client
		sh_: shared (default if no prefix)
		sk_: skipped/ignored (client only)

	----------------------------------------------------------------------
	--	IMPORTANT NOTE: file.Find returns files in ALPHABETICAL ORDER	--
	--		All FOLDERS and FILES are loaded in ALPHABETICAL ORDER		--
	----------------------------------------------------------------------
]]--
MsgN("\n===========[ Loading ACF ]============\n|")

local GunClasses 	= {}
local GunTable 		= {}
local MobilityTable = {}
local FuelTankTable = {}

if not ACF then ACF = {} end

ACF.RoundTypes = ACF.RoundTypes or {}

ACF.Classes = ACF.Classes or {
	GunClass = GunClasses
}

ACF.Weapons = ACF.Weapons or {
	Guns = GunTable,
	Mobility = MobilityTable,
	FuelTanks = FuelTankTable
}

local gun_base = {
	ent = "acf_gun",
	type = "Guns"
}

local engine_base = {
	ent = "acf_engine",
	type = "Mobility"
}

local gearbox_base = {
	ent = "acf_gearbox",
	type = "Mobility",
	sound = "vehicles/junker/jnk_fourth_cruise_loop2.wav"
}

local fueltank_base = {
	ent = "acf_fueltank",
	type = "Mobility",
	explosive = true
}

do
	function ACF_defineGunClass( id, data )
		data.id = id
		GunClasses[ id ] = data

		PrecacheParticleSystem(data["muzzleflash"])
	end

	function ACF_defineGun( id, data )
		data.id = id
		data.round.id = id
		table.Inherit( data, gun_base )
		GunTable[ id ] = data
	end

	function ACF_DefineEngine( id, data )
		data.id = id
		table.Inherit( data, engine_base )
		MobilityTable[ id ] = data
	end

	function ACF_DefineGearbox( id, data )
		data.id = id
		table.Inherit( data, gearbox_base )
		MobilityTable[ id ] = data
	end

	function ACF_DefineFuelTank( id, data )
		data.id = id
		table.Inherit( data, fueltank_base )
		MobilityTable[ id ] = data
	end

	function ACF_DefineFuelTankSize( id, data )
		data.id = id
		table.Inherit( data, fueltank_base )
		FuelTankTable[ id ] = data
	end
end

if SERVER then
	local Realms = {client = "client", server = "server", shared = "shared"}
	local Text = "| > Loaded %s serverside file(s).\n| > Loaded %s shared file(s).\n| > Loaded %s clientside file(s)."
	local ServerCount, SharedCount, ClientCount = 0, 0, 0

	local function Load(Path, Realm)
		local Files, Directories = file.Find(Path .. "/*", "LUA")

		if Realm then -- If a directory specifies which realm then load in that realm and persist through sub-directories
			for _, File in ipairs(Files) do
				File = Path .. "/" .. File

				if Realm == "client" then
					AddCSLuaFile(File)

					ClientCount = ClientCount + 1
				elseif Realm == "server" then
					include(File)

					ServerCount = ServerCount + 1
				else -- Shared
					include(File)
					AddCSLuaFile(File)

					SharedCount = SharedCount + 1
				end
			end
		else
			for _, File in ipairs(Files) do
				local Sub = string.sub(File, 1, 3)

				File = Path .. "/" .. File

				if Sub == "cl_" then
					AddCSLuaFile(File)

					ClientCount = ClientCount + 1
				elseif Sub == "sv_" then
					include(File)

					ServerCount = ServerCount + 1
				else -- Shared
					include(File)
					AddCSLuaFile(File)

					SharedCount = SharedCount + 1
				end
			end
		end

		for _, Directory in ipairs(Directories) do
			local Sub = string.sub(Directory, 1, 6)

			Realm = Realms[Sub] or Realm or nil

			Load(Path .. "/" .. Directory, Realm)
		end
	end

	Load("acf")

	MsgN(Text:format(ServerCount, SharedCount, ClientCount))

elseif CLIENT then

	gun_base.guicreate 		= function( _, tbl ) ACFGunGUICreate( tbl ) end or nil
	gun_base.guiupdate 		= function() return end
	engine_base.guicreate 	= function( _, tbl ) ACFEngineGUICreate( tbl ) end or nil
	engine_base.guiupdate 	= function() return end
	gearbox_base.guicreate 	= function( _, tbl ) ACFGearboxGUICreate( tbl ) end or nil
	gearbox_base.guiupdate 	= function() return end
	fueltank_base.guicreate = function( _, tbl ) ACFFuelTankGUICreate( tbl ) end or nil
	fueltank_base.guiupdate = function( _, tbl ) ACFFuelTankGUIUpdate( tbl ) end or nil

	local Text = "| > Loaded %s clientside file(s).\n| > Skipped %s clientside file(s)."
	local FileCount, SkipCount = 0, 0

	local function Load(Path)
		local Files, Directories = file.Find(Path .. "/*", "LUA")

		for _, File in ipairs(Files) do
			local Sub = string.sub(File, 1, 3)

			if Sub == "sk_" then
				SkipCount = SkipCount + 1
			else
				File = Path .. "/" .. File

				include(File)

				FileCount = FileCount + 1
			end
		end

		for _, Directory in ipairs(Directories) do
			Load(Path .. "/" .. Directory)
		end
	end

	Load("acf")

	MsgN(Text:format(FileCount, SkipCount))
end

MsgN("|\n=======[ Finished Loading ACF ]=======\n")
