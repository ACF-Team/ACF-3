local Repos = ACF.Repositories

local function LocalToUTC(Time)
	return os.time(os.date("!*t", Time))
end

local function GetGitData(Path, Version)
	local _, _, Head = file.Read(Path .. "/.git/HEAD", "GAME"):find("heads/(.+)$")
	local Heads = Path .. "/.git/refs/heads/"
	local Files = file.Find(Heads .. "*", "GAME")
	local Code, Date

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

function ACF.GetVersion(Owner, Name)
	local Version = Repos[Owner .. "/" .. Name]

	if not Version then return end
	if Version.Code then return Version.Code end

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

function ACF.GetBranch(Owner, Name, Branch)
	local Version = Repos[Owner .. "/" .. Name]

	if not Version then return end
	if not Version.Branches then return end

	return Version.Branches[Branch or Version.Head]
end

function ACF.GetVersionStatus(Owner, Name)
	local Version = Repos[Owner .. "/" .. Name]

	if not Version then return end
	if Version.Status then return Version.Status end

	local Branch = ACF.GetBranch(Owner, Name)
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
