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
					ballistics\  <--- All directories under addonFolder have a table created for them, eg. addonGlobal.Ballistics
]]--

local table   = table
local pattern = "_([cs][lvh])[.lua]*$"

local realms = {
	cl = "Client",
	sv = "Server",
	sh = "Shared",
	Client = function(path)
		if CLIENT then
			include(path)
		else
			AddCSLuaFile(path)
		end
	end,
	Server = function(path)
		if CLIENT then return end

		include(path)
	end,
	Shared = function(path)
		AddCSLuaFile(path)
		include(path)
	end,
}

local function canLoad(realm, sessionRealm)
	if not realm then return true end
	if realm == "Shared" then return true end

	return realm == sessionRealm
end

local function getRealm(path)
	local realm = path:match(pattern)

	return realm and realms[realm]
end

local function getLibraryName(name)
	local finish = name:find(pattern)

	return name:sub(1, 1):upper() .. name:sub(2, finish and finish - 1)
end

local function prepareFiles(current, context, folders, files, realm, forced)
	local contextRealm = context.Realm

	if not canLoad(contextRealm, realm) then return end

	local newFiles, newFolders = file.Find(current .. "/*", "LUA")

	for _, path in ipairs(newFiles) do
		local fileRealm = forced or getRealm(path)

		if not canLoad(fileRealm, realm) then continue end

		files[#files + 1] = {
			Path = current .. "/" .. path,
			Load = realms[fileRealm or "Shared"],
		}
	end

	for _, name in ipairs(newFolders) do
		local libRealm = forced or getRealm(name)

		if not canLoad(libRealm, realm) then continue end

		local libName  = getLibraryName(name)
		local isCore   = libName == "Core"
		local libTable = isCore and context or (context[libName] or {})

		local data = {
			Name    = libName,
			Realm   = libRealm,
			Context = libTable,
			Folders = {},
			Files   = {},
		}

		if isCore then
			table.insert(folders, 1, data)
		else
			folders[#folders + 1] = data

			context[libName] = libTable
		end

		prepareFiles(current .. "/" .. name, libTable, data.Folders, data.Files, realm, libRealm)
	end
end

local function loadLibrary(library, context)
	local fileCount = #library.Files
	local libCount  = 1

	for _, data in ipairs(library.Files) do
		data.Load(data.Path)
	end

	for _, data in ipairs(library.Folders) do
		local libContext = data.Context
		local libName    = data.Name
		local addedFiles, addedLibs = loadLibrary(data, libContext)

		fileCount = fileCount + addedFiles
		libCount  = libCount  + addedLibs

		if libName ~= "Core" and not next(libContext) then
			--print("Removing " ..  data.name ..  " folder from " .. (library.name or addonGlobal))

			context[libName] = nil
		--else
			--print("Keeping " ..  libName ..  " folder from " .. (library.Name or addonGlobal))
		end
	end

	return fileCount, libCount
end

local function loadAddon()
	local realm     = SERVER and "Server" or "Client"
	local addonRoot = _G[addonGlobal] or {}
	local libraries = {
		Folders = {},
		Files   = {},
	}

	print("\nInitializing " .. addonGlobal .. " loader.")
	print("> Creating global " .. addonGlobal .. " table...")
	_G[addonGlobal] = addonRoot

	print("> Preparing files....")
	prepareFiles(addonFolder, addonRoot, libraries.Folders, libraries.Files, realm)

	print("> Loading files....")
	local files, libs = loadLibrary(libraries, addonRoot, realm)

	print("> Loaded " .. files .. " files and " .. libs .. " folders.")
	print(addonGlobal .. " has finished loading.\n")
end

concommand.Add(addonGlobal:lower() .. "_reload", function()
	loadAddon()
end)

loadAddon()
