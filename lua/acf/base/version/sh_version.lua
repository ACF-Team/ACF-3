
local sub = string.sub
local format = string.format
local Exists = file.Exists
local Read = file.Read
local Time = file.Time

if not ACF.Version then
	ACF.Version = {
		Code = false,
		Date = false,
	}
end

ACF.RepoInfo = {
	Owner = "Stooberton",
	Name  = "ACF-3",
	API   = "https://api.github.com/repos/%s/%s/commits?per_page=5",
}

function ACF.GetVersion()
	local Version = ACF.Version

	if Version.Code then return Version end

	local DataPath = "addons/ACF"

	if not Exists(DataPath, "GAME") then
		local _, Folders = file.Find("addons/*", "GAME")

		for _, v in ipairs(Folders) do
			if Exists("addons/" .. v .. "/lua/autorun/acf_loader.lua", "GAME") then
				DataPath = "addons/" .. v

				break
			end
		end
	end

	if Exists(DataPath .. "/.git/refs/heads/master", "GAME") then
		DataPath = DataPath .. "/.git/refs/heads/master"

		Version.Code = "Git-" .. sub(Read(DataPath, "GAME"), 1, 8)
		Version.Date = Time(DataPath, "GAME")

	elseif Exists(DataPath .. "/.svn/wc.db", "GAME") then
		local Repo = ACF.RepoInfo
		local Database = Read(DataPath .. "/.svn/wc.db", "GAME")
		local Start = Database:find(format("/%s/%s/!svn/ver/", Repo.Owner, Repo.Name))
		local Offset = (Start or 0) + #Repo.Owner + #Repo.Name + 12

		Version.Code = "SVN-" .. Start and sub(Database, Offset, Offset + 3) or "Unknown"
		Version.Date = Time(DataPath .. "/.svn/wc.db", "GAME")

	elseif Exists(DataPath .. "/LICENSE", "GAME") then
		Version.Code = "ZIP-Unknown"
		Version.Date = Time(DataPath .. "/LICENSE", "GAME")

	else
		Version.Code = "Not Installed"
		Version.Date = os.time()
	end

	return Version
end
