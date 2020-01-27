
local format = string.format
local Explode = string.Explode
local PrintLog = ACF.PrintLog

local Repo = ACF.RepoInfo

if not ACF.GitVersion then
	ACF.GitVersion = {
		Code = false,
		Date = false,
		Commits = {},
	}
end

local function GetTimezoneDiff()
	local Time = os.time()
	local Local = os.date("*t", Time)
	local LocalTime = os.time(Local)
	local GlobalTime = os.time(os.date("!*t", Time))
	local Difference = os.difftime(GlobalTime, LocalTime)

	if Local.isdst then
		if Difference > 0 then
			Difference = Difference - 3600
		else
			Difference = Difference + 3600
		end
	end

	return Difference
end

local function GetDateEpoch(GitDate)
	local Date, Time = unpack(Explode("T", GitDate))
	local Year, Month, Day = unpack(Explode("-", Date))
	local Hour, Min, Sec = unpack(Explode(":", Time))

	return os.time({
		year = Year,
		month = Month,
		day = Day,
		hour = Hour,
		min = Min,
		sec = string.sub(Sec, 1, 2),
	}) - GetTimezoneDiff()
end

local function GetCommitMessage(Message)
	if not Message then return end

	local Start = Message:find("\n\n")

	Message = Message:Replace("\n\n", "\n"):gsub("[\r]*[\n]+[%s]+", "\n- ")

	local Title = Start and Message:sub(1, Start - 1) or Message
	local Body =  Start and Message:sub(Start + 1, #Message) or "No Commit Message"

	return Title, Body
end

util.AddNetworkString("ACF_GithubVersion")
util.AddNetworkString("ACF_ServerVersion")

local Players = {}
local function SendGithubData()
	if not next(Players) then return end

	local Git = ACF.GitVersion

	net.Start("ACF_GithubVersion")
		net.WriteString(Git.Code)
		net.WriteUInt(Git.Date, 32)
		net.WriteTable(Git.Commits)
	net.Send(Players)

	Players = {}
end

local function SendServerData(Player)
	local Version = ACF.Version

	net.Start("ACF_ServerVersion")
		net.WriteString(Version.Code)
		net.WriteUInt(Version.Date, 32)
	net.Send(Player)
end

local function PrintVersionStatus()
	local Version = ACF.Version
	local Git = ACF.GitVersion

	PrintLog("Version", "Loaded version " .. Version.Code)

	if not Git.Code then
		PrintLog("Update", "Unable to retrieve Github updates.")
		return
	end

	if Version.Code == Git.Code or Version.Date >= Git.Date then
		PrintLog("Version", "No updates available.")
	else
		local Date = os.date("%B %d, %Y", Git.Date)

		PrintLog("Update", "Update available: Version ", Git.Code, ", updated on ", Date, ".")
	end
end

local function OnSuccess(JSON, _, _, Code)
	if not JSON then
		PrintVersionStatus()
		PrintLog("Error", "No data found on request.")
		return
	end

	local Data = util.JSONToTable(JSON)

	if Code == 200 then -- Success
		if next(Data) then
			local Git = ACF.GitVersion

			for K, V in ipairs(Data) do
				local Date = GetDateEpoch(V.commit.author.date)
				local Title, Body = GetCommitMessage(V.commit.message)

				Git.Commits[K] = {
					ID = V.sha,
					Date = Date,
					Author = V.commit.author.name,
					Title = Title,
					Message = Body,
					URL = V.html_url,
				}
			end

			local First = unpack(Git.Commits)

			Git.Code = "Git-" .. First.ID:sub(1, 8)
			Git.Date = First.Date

			SendGithubData()
		end
	else
		PrintLog("Error", Code, " - ", Data.message,
				"\n\tFor more info: \t", Data.documentation_url)
	end

	PrintVersionStatus()
end

local function OnFailure(Error)
	PrintVersionStatus()
	PrintLog("Error", Error)
end

ACF.AddLogType("Version", "Version")
ACF.AddLogType("Update", "Version", Color(241, 80, 47))

hook.Add("Initialize", "ACF_GetVersionData", function()
	ACF.GetVersion()

	timer.Simple(10, function()
		http.Fetch(format(Repo.API, Repo.Owner, Repo.Name), OnSuccess, OnFailure)
	end)

	hook.Remove("Initialize", "ACF_GetVersionData")
end)

hook.Add("PlayerInitialSpawn", "ACF_SendVersionData", function(Player)
	SendServerData(Player)

	Players[#Players + 1] = Player

	if ACF.GitVersion.Code then
		SendGithubData()
	end
end)
