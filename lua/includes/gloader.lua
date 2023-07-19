AddCSLuaFile()

module("gloader", package.seeall)

--[[
The MIT License (MIT)

Copyright (c) 2023 TwistedTail

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local session = SERVER and "server" or "client"
local suffix  = "_([cs][lvh])[.lua]*$"
local realms  = { cl = "client", sv = "server", sh = "shared", }
local loaders = {
	client = function(path)
		if CLIENT then
			include(path)
		else
			AddCSLuaFile(path)
		end
	end,
	server = function(path)
		if CLIENT then return end

		include(path)
	end,
	shared = function(path)
		AddCSLuaFile(path)
		include(path)
	end,
}

local function canLoad(realm)
	if SERVER then return true end -- We need to add clientside files
	if not realm then return true end
	if realm == "shared" then return true end

	return realm == session
end

local function getRealm(path)
	local realm = path:match(suffix)

	return realm and realms[realm]
end

local function getLibraryName(path)
	local final = path:find(suffix)

	if final then
		path = path:sub(1, final - 1)
	end

	local words = {}

	for word in path:gmatch("%a+") do
		words[#words + 1] = word:sub(1, 1):upper() .. word:sub(2)
	end

	return table.concat(words)
end

local function prepareFiles(path, context, library, forced)
	if not canLoad(library.realm) then return end

	local newFiles, newFolders = file.Find(path .. "/*", "LUA")
	local files     = library.files
	local folders   = library.folders
	local coreCount = 0

	for _, filename in ipairs(newFiles) do
		local realm = forced or getRealm(filename)

		if not canLoad(realm) then continue end

		files[#files + 1] = {
			path = path .. "/" .. filename,
			load = loaders[realm or "shared"],
		}
	end

	for _, folder in ipairs(newFolders) do
		local realm = forced or getRealm(folder)

		if not canLoad(realm) then continue end

		local name       = getLibraryName(folder)
		local isCore     = name == "Core"
		local newContext = isCore and context or (context[name] or {})
		local newLibrary = {
			name    = name,
			realm   = realm,
			context = newContext,
			folders = {},
			files   = {},
		}

		if isCore then
			coreCount = coreCount + 1

			table.insert(folders, coreCount, newLibrary)
		else
			folders[#folders + 1] = newLibrary

			context[name] = newContext
		end

		prepareFiles(path .. "/" .. folder, newContext, newLibrary, realm)
	end
end

local function shouldClear(context, name, current)
	if name == "Core" then return false end
	if context[name] ~= current then return false end
	if not istable(current) then return false end

	return next(current) == nil
end

local function loadFiles(library, context)
	local fileCount   = #library.files
	local folderCount = 1

	for _, fileInfo in ipairs(library.files) do
		fileInfo.load(fileInfo.path)
	end

	for _, folderInfo in ipairs(library.folders) do
		local current = folderInfo.context
		local name    = folderInfo.name
		local files, folders = loadFiles(folderInfo, current)

		fileCount   = fileCount + files
		folderCount = folderCount + folders

		if shouldClear(context, name, current) then
			context[name] = nil
		end
	end

	return fileCount, folderCount
end

local function loadAddon(name, folder)
	local context = _G[name] or {}
	local library = { folders = {}, files = {}, }

	print("\nInitializing " .. name .. " loader.")
	print("> Creating global " .. name .. " table...")
	_G[name] = context

	print("> Preparing files....")
	prepareFiles(folder, context, library)

	print("> Loading files....")
	local files, folders = loadFiles(library, context)

	print("> Loaded " .. files .. " files and " .. folders .. " folders.")
	print(name .. " has finished loading.\n")

	hook.Run(name .. "_OnLoadAddon", context)
end

function Load(name, folder)
	if not isstring(name) then return end
	if not isstring(folder) then return end

	loadAddon(name, folder)

	concommand.Add(name:lower() .. "_reload", function()
		loadAddon(name, folder)
	end)
end
