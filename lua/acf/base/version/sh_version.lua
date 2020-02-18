local Repos = ACF.Repositories

local function LocalToUTC(Time)
	return os.time(os.date("!*t", Time))
end

local function SetRealOwner(Path, Version)
	local Fetch = file.Read(Path .. "/.git/FETCH_HEAD", "GAME")
	local Start, End = Fetch:find("github.com[/]?[:]?[%w_-]+/")

	Version.Owner = Fetch:sub(Start + 11, End - 1)
end

local function GetGitData(Path, Version)
	local _, _, Head = file.Read(Path .. "/.git/HEAD", "GAME"):find("heads/(.+)$")
	local Heads = Path .. "/.git/refs/heads/"
	local Files = file.Find(Heads .. "*", "GAME")
	local Code, Date

	SetRealOwner(Path, Version)

	Version.Head = Head:Trim()

	for _, Name in ipairs(Files) do
		if Name == Version.Head then
			local SHA = file.Read(Heads .. Name, "GAME"):Trim()

			Code = Name .. "-" .. SHA:sub(1, 7)
			Date = file.Time(Heads .. Name, "GAME")

			break
		end
	end

	return Code, Date
end

function ACF.GetVersion(Name)
	local Version = Repos[Name]

	if not Version then return end
	if Version.Code then return Version end

	local _, Folders = file.Find("addons/*", "GAME")
	local Pattern = Version.Path
	local Path, Code, Date

	for _, Folder in ipairs(Folders) do
		if file.Exists(Pattern:format(Folder), "GAME") then
			Path = "addons/" .. Folder
			break
		end
	end

	if not Path then
		Version.Code = "Not Installed"
		Version.Date = 0
	elseif file.Exists(Path .. "/.git/HEAD", "GAME") then
		Code, Date = GetGitData(Path, Version)

		Version.Code = "Git-" .. Code
		Version.Date = LocalToUTC(Date)
	elseif file.Exists(Path .. "/LICENSE", "GAME") then
		Date = file.Time(Path .. "/LICENSE", "GAME")

		Version.Code = "ZIP-Unknown"
		Version.Date = LocalToUTC(Date)
	end

	if not Version.Head then
		Version.Head = "master"
	end

	return Version
end

function ACF.GetBranch(Name, Branch)
	local Version = Repos[Name]

	if not Version then return end
	if not Version.Branches then return end

	Branch = Branch or Version.Head

	-- Just in case both server and client are using different forks with different branches
	return Version.Branches[Branch] or Version.Branches.master
end

function ACF.GetVersionStatus(Name)
	local Version = Repos[Name]

	if not Version then return end
	if Version.Status then return Version.Status end

	local Branch = ACF.GetBranch(Name)
	local Status

	if not Branch or Version.Code == "Not Installed" then
		Status = "Unable to check"
	elseif Version.Code == Branch.Code
	or Version.Date
	>= Branch.Date then
		Status = "Up to date"
	else
		Status = "Out of date"
	end

	Version.Status = Status

	return Status
end
