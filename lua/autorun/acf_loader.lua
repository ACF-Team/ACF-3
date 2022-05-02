local addonFolder = "ACF" -- This is the name of the folder that gets loaded eg. addons\addonFolder\lua\addonFolder\
local addonGlobal = "ACF" -- This is the name of the global table for the addon ( _G.addonGlobal )

--[[
	This script automatically loads all files under garrysmod/garrysmod/addons/addonFolder/lua/addonFolder/
	All files and folders in this directory are loaded in alphabetical order EXCEPT for a "core" directory, which is loaded before the other directories


	To reload the addon, run the concmd 'addonGlobalTableName_reload'.

	Files and folders can have their realms specified by adding a suffix to the filename.
		_cl marks files and folders for CLIENTS
		_sh marks files and folders for SHARED
		_sv marks files and folders for SERVERS

	Folder structure:

	addons\
		addonFolder\
			lua\
				autorun\
					loader.lua
				addonFolder\
					core\		<--- FILES in this directory are loaded FIRST
						example_sv.lua
					damage\	  <--- ALL other DIRECTORIES are loaded AFTER in ALPHABETICAL ORDER
						exampleFolder_cl\
							thisFileIsSentToClients.lua
					ballistics\  <--- All directories under addonFolder have a table created for them, eg. addonGlobal.ballistics
]]--

local table   = table
local pattern = "_([cs][lvh])[.lua]*$"

local realms = {
	cl = "client",
	sv = "server",
	sh = "shared",
	client = function(path)
		if CLIENT then
			include(path)
		else
			AddCSLuaFile(path)
		end

		return true
	end,
	server = function(path)
		if CLIENT then return false end

		include(path)

		return true
	end,
	shared = function(path)
		AddCSLuaFile(path)
		include(path)

		return true
	end,
}

local function getRealm(path)
	local realm = path:match(pattern)

	return realm and realms[realm]
end

local function getLibraryName(name)
	local finish = name:find(pattern)

	return name:sub(1, 1):upper() .. name:sub(2, finish and finish - 1)
end

local function prepareFiles(current, context, folders, files, realm)
	local newFiles, newFolders = file.Find(current .. "/*", "LUA")

	for i, path in ipairs(newFiles) do
		local fileRealm = realm or getRealm(path) or "shared"

		files[i] = {
			path = current .. "/" .. path,
			load = realms[fileRealm],
		}
	end

	for _, name in ipairs(newFolders) do
		local libName  = getLibraryName(name)
		local libRealm = realm or getRealm(name)

		if isfunction(context) then
			print("fucked up", libName)

			continue
		end

		local libTable = context[libName] or {}

		local data = {
			name    = libName,
			realm   = libRealm,
			context = libTable,
			folders = {},
			files   = {},
		}

		if name == "core" then
			table.insert(folders, 1, data)
		else
			folders[#folders + 1] = data
		end

		context[libName] = libTable

		prepareFiles(current .. "/" .. name, libTable, data.folders, data.files, libRealm)
	end
end

local function loadLibrary(library, context, realm)
	local libRealm = library.realm

	if libRealm and libRealm ~= "shared" and libRealm ~= realm then return 0, 0 end

	local fileCount = 0
	local libCount  = 0

	LIBRARY = context

	for _, data in pairs(library.files) do
		if not data.load(data.path) then continue end

		fileCount = fileCount + 1
	end

	LIBRARY = nil

	for _, data in pairs(library.folders) do
		local addedFiles, addedLibs = loadLibrary(data, data.context, realm)

		fileCount = fileCount + addedFiles
		libCount  = libCount  + addedLibs + 1
	end

	return fileCount, libCount
end

local function loadAddon()
	local addonRoot = _G[addonGlobal] or {}
	local libraries = {
		folders = {},
		files   = {},
	}

	_G[addonGlobal] = addonRoot

	print("Preparing files....")
	prepareFiles(addonFolder, addonRoot, libraries.folders, libraries.files)

	print("Loading files....")
	local files, libs = loadLibrary(libraries, addonRoot, SERVER and "server" or "client")

	print("Loaded " .. files .. " files and " .. libs .. " folders.")
end

concommand.Add(addonGlobal:lower() .. "_reload", function()
	loadAddon()
end)

--loadAddon()
