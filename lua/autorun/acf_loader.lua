local addonName  = "ACF" -- This is the name of the folder that gets loaded
local globalName = "ACF" -- This is the name of the global table for the addon

--[[
    This script automatically loads all files under the <addonName> folder
    A global variable is created for the addon named <globalName>
    The first folders under addonName\ are given tables under globalName, eg. globalName.core, globalName.damage, globalName.fred

    To reload the addon, run the concmd 'globalName_reload'.

    Files and folders can have their realms specified by adding a suffix to the filename.
        _cl marks files and folders for CLIENTS
        _sh marks files and folders for SHARED
        _sv marks files and folders for SERVERS

    Folder structure:

    addons\
        addonName\
            lua\
                autorun\
                    loader.lua
                addonName\
                    core\
                        example_sv.lua
                    damage\
                        exampleFolder_cl\
                            thisFileIsSentToClients.lua
                    ballistics\
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
	Msg("\n> " .. addonName .. "/\n")

    local addonGlobal = {}; _G[addonName] = addonGlobal
    local  _, dirs    = file.Find(addonName .. "/*", "LUA")
    local rootFolders = {}

    -- Create a table underneath <addonName> for each folder under the root directory, eg. addonName.core, addonName.damage, addonName.ballistics
    for _, folderName in ipairs(dirs) do
        addonGlobal[folderName] = {}

        if folderName == "core" then -- if there is a "core" folder load it first
            MsgN(" ├──" .. folderName .. "/")
            load(addonName .. "/" .. folderName)
        else
            rootFolders[#rootFolders + 1] = folderName
        end
    end

    -- Load all of the root folders except "core" (already loaded)
    for i, dirName in ipairs(rootFolders) do
        MsgN((i == #rootFolders and " └──" or  " ├──") .. dirName .. "/")

        local dirSnip  = string.sub(dirName, 1, 6)
        local dirRealm = realms[dirSnip] or realm or "_sh"

        load(addonName .. "/" .. dirName, dirRealm)
    end
end

concommand.Add(string.lower(globalName .. "_reload"), function()
	loadAddon()
end)

loadAddon()