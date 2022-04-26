local addonFolderName      = "ACF" -- This is the name of the folder that gets loaded eg. addons\addonFolderName\lua\addonFolderName\
local addonGlobalTableName = "ACF" -- This is the name of the global table for the addon ( _G.addonGlobalTableName )

--[[
    This script automatically loads all files under garrysmod/garrysmod/addons/addonFolderName/lua/addonFolderName/
    All files and folders in this directory are loaded in alphabetical order EXCEPT for a "core" directory, which is loaded before the other directories


    To reload the addon, run the concmd 'addonGlobalTableName_reload'.

    Files and folders can have their realms specified by adding a suffix to the filename.
        _cl marks files and folders for CLIENTS
        _sh marks files and folders for SHARED
        _sv marks files and folders for SERVERS

    Folder structure:

    addons\
        addonFolderName\
            lua\
                autorun\
                    loader.lua
                addonFolderName\ <--- FILES in this directory are NOT LOADED, only DIRECTORIES
                    core\        <--- FILES in this directory are loaded FIRST
                        example_sv.lua
                    damage\      <--- ALL other DIRECTORIES are loaded AFTER in ALPHABETICAL ORDER
                        exampleFolder_cl\
                            thisFileIsSentToClients.lua
                    ballistics\  <--- All directories under addonFolderName have a table created for them, eg. addonGlobalTableName.ballistics
]]--

local realms = {
    client = "_cl",
    server = "_sv",
    shared = "_sh",
    _sv = include,
    _cl = AddCSLuaFile,
    _sh = function(path)
		include(path)
		AddCSLuaFile(path)
	end
}

setmetatable(realms, realms)

local function load(path, realm)
    local files, dirs = file.Find(path .. "/*", "LUA")

    for _, fileName in ipairs(files) do
        local filePath  = path .. "/" .. fileName
        local fileSnip  = string.sub(fileName, fileName:len() - 6, fileName:len() - 4)
        local fileRealm = CLIENT and "_sv" or realms[fileSnip] and fileSnip or realm or "_sh"

        realms[fileRealm](filePath)
    end

    for _, directory in ipairs(dirs) do
        local dirSnip  = string.sub(directory, 1, 6)
        local dirRealm = realms[dirSnip] or realm or "_sh"

        load(path .. "/" .. directory, dirRealm)
    end
end

local function loadAddon()
	Msg("\n> " .. addonFolderName .. "/\n")

    local addonGlobal = {}; _G[addonFolderName] = addonGlobal
    local _, dirs    = file.Find(addonFolderName .. "/*", "LUA")
    local rootFolders = {}

    -- Create a "library" named by each folder under the addon's root directory ( _G.addonGlobalName.core, _G.addonGlobalName.menu, etc )
    -- If there is a "core" folder load it first
    for _, folderName in ipairs(dirs) do
        addonGlobal[folderName] = {}

        if folderName == "core" then
            MsgN(" ├──" .. folderName .. "/")
            load(addonFolderName .. "/" .. folderName)
        else
            rootFolders[#rootFolders + 1] = folderName
        end
    end

    -- Load all of the root folders except "core" (already loaded)
    for i, dirName in ipairs(rootFolders) do
        MsgN((i == #rootFolders and " └──" or  " ├──") .. dirName .. "/")

        local dirSnip  = string.sub(dirName, 1, 6)
        local dirRealm = realms[dirSnip] or realm or "_sh"

        load(addonFolderName .. "/" .. dirName, dirRealm)
    end

    -- Remove any libraries that weren't populated
    for addonGlobalTableName in pairs(addonGlobal) do
        if not next(addonGlobal[addonGlobalTableName]) then
            addonGlobal[addonGlobalTableName] = nil
        end
    end
end

concommand.Add(string.lower(addonGlobalTableName .. "_reload"), function()
	loadAddon()
end)

loadAddon()