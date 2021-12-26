
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

if not ACF then ACF = {} end

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

hook.Run("ACF_OnAddonLoaded")
