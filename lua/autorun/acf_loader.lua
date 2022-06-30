--[[
	This script automatically loads all files under garrysmod/garrysmod/addons/AddonFolder/lua/AddonFolder/
	All files and folders in this directory are loaded in alphabetical order EXCEPT for a "core" directory, which is loaded before the other directories


	To reload the addon, run the concmd 'AddonGlobal_reload'.

	Files and folders can have their realms specified by adding a suffix to the filename.
		_cl marks files and folders for CLIENTS
		_sh marks files and folders for SHARED
		_sv marks files and folders for SERVERS

	Folder structure:

	addons\
		AddonFolder\
			lua\
				autorun\
					loader.lua
				AddonFolder\
					core\		<--- FILES in this directory are loaded FIRST
						example_sv.lua
					damage\	  <--- ALL other DIRECTORIES are loaded AFTER in ALPHABETICAL ORDER
						exampleFolder_cl\
							thisFileIsSentToClients.lua
					ballistics\  <--- All directories under AddonFolder have a table created for them, eg. AddonGlobal.Ballistics
]]--

local AddonFolder = "ACF" -- This is the name of the folder that gets loaded eg. addons\AddonFolder\lua\AddonFolder\
local AddonGlobal = "ACF" -- This is the name of the global table for the addon (_G.AddonGlobal)
local Suffix      = "_([cs][lvh])[.lua]*$"
local table       = table
local Realms = {
	cl = "Client",
	sv = "Server",
	sh = "Shared",
	Client = function(Filepath)
		if CLIENT then
			include(Filepath)
		else
			AddCSLuaFile(Filepath)
		end
	end,
	Server = function(Filepath)
		if CLIENT then return end

		include(Filepath)
	end,
	Shared = function(Filepath)
		AddCSLuaFile(Filepath)
		include(Filepath)
	end,
}

local function CanLoad(Realm, SessionRealm)
	if SERVER then return true end -- We need to add clientside files
	if not Realm then return true end
	if Realm == "Shared" then return true end

	return Realm == SessionRealm
end

local function GetRealm(Filename)
	local Realm = Filename:match(Suffix)

	return Realm and Realms[Realm]
end

local function GetLibraryName(Filename)
	local Finish = Filename:find(Suffix)

	if Finish then
		Filename = Filename:sub(1, Finish - 1)
	end

	local Words = {}

	for Word in Filename:gmatch("%a+") do
		Words[#Words + 1] = Word:sub(1, 1):upper() .. Word:sub(2)
	end

	return table.concat(Words)
end

local function PrepareFiles(Path, Context, Library, Realm, Forced)
	if not CanLoad(Context.Realm, Realm) then return end

	local NewFiles, NewFolders = file.Find(Path .. "/*", "LUA")
	local Files   = Library.Files
	local Folders = Library.Folders

	for _, Filename in ipairs(NewFiles) do
		local FileRealm = Forced or GetRealm(Filename)

		if not CanLoad(FileRealm, Realm) then continue end

		Files[#Files + 1] = {
			Path = Path .. "/" .. Filename,
			Load = Realms[FileRealm or "Shared"],
		}
	end

	for _, Folder in ipairs(NewFolders) do
		local LibRealm = Forced or GetRealm(Folder)

		if not CanLoad(LibRealm, Realm) then continue end

		local LibName  = GetLibraryName(Folder)
		local IsCore   = LibName == "Core"
		local LibTable = IsCore and Context or (Context[LibName] or {})
		local NewLib = {
			Name    = LibName,
			Realm   = LibRealm,
			Context = LibTable,
			Folders = {},
			Files   = {},
		}

		if IsCore then
			table.insert(Folders, 1, NewLib)
		else
			Folders[#Folders + 1] = NewLib

			Context[LibName] = LibTable
		end

		PrepareFiles(Path .. "/" .. Folder, LibTable, NewLib, Realm, LibRealm)
	end
end

local function ShouldClear(Context, Name, Table)
	if Name == "Core" then return false end
	if Context[Name] ~= Table then return false end

	return next(Table) == nil
end

local function LoadLibrary(Library, Context)
	local FileCount = #Library.Files
	local LibCount  = 1

	for _, File in ipairs(Library.Files) do
		File.Load(File.Path)
	end

	for _, Folder in ipairs(Library.Folders) do
		local LibContext = Folder.Context
		local LibName    = Folder.Name
		local AddedFiles, AddedLibs = LoadLibrary(Folder, LibContext)

		FileCount = FileCount + AddedFiles
		LibCount  = LibCount  + AddedLibs

		if ShouldClear(Context, LibName, LibContext) then
			--print("Removing " ..  LibName ..  " folder from " .. (Library.Name or AddonGlobal))

			Context[LibName] = nil
		--else
			--print("Keeping " ..  LibName ..  " folder from " .. (Library.Name or AddonGlobal))
		end
	end

	return FileCount, LibCount
end

local function LoadAddon()
	local Realm = SERVER and "Server" or "Client"
	local Root  = _G[AddonGlobal] or {}
	local Libraries = {
		Folders = {},
		Files   = {},
	}

	print("\nInitializing " .. AddonGlobal .. " loader.")
	print("> Creating global " .. AddonGlobal .. " table...")
	_G[AddonGlobal] = Root

	print("> Preparing files....")
	PrepareFiles(AddonFolder, Root, Libraries, Realm)

	print("> Loading files....")
	local TotalFiles, TotalLibs = LoadLibrary(Libraries, Root)

	print("> Loaded " .. TotalFiles .. " files and " .. TotalLibs .. " folders.")
	print(AddonGlobal .. " has finished loading.\n")

	hook.Run(AddonGlobal .. "_OnAddonLoaded")
end

concommand.Add(AddonGlobal:lower() .. "_reload", function()
	LoadAddon()
end)

LoadAddon()
