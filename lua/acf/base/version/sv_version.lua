local Repos = ACF.Repositories
local PrintLog = ACF.PrintLog

do -- Repository tracking
	local RepoLink = "https://github.com/%s/%s/"

	function ACF.AddRepository(Owner, Name, Path)
		if not Owner then return end
		if not Name then return end
		if not Path then return end
		if Repos[Owner .. "/" .. Name] then return end

		Repos[Owner .. "/" .. Name] = {
			Owner = Owner,
			Name = Name,
			Path = "addons/%s/" .. Path,
			Link = RepoLink:format(Owner, Name),
			Code = false,
			Date = false,
		}
	end

	ACF.AddRepository("Stooberton", "ACF-3", "lua/autorun/acf_loader.lua")
end

do -- HTTP Request
	local function SuccessfulRequest(Code, Body, OnSuccess, OnFailure)
		local Data = Body and util.JSONToTable(Body)
		local Error

		if not Body then
			Error = "No data found on request."
		elseif Code ~= 200 then
			Error = "Request unsuccessful (Code " .. Code .. ")."
		elseif not (Data and next(Data)) then
			Error = "Empty request result."
		end

		if Error then
			PrintLog("Error", Error)

			return OnFailure(Error)
		end

		OnSuccess(Body, Data)
	end

	function ACF.StartRequest(Link, OnSuccess, OnFailure)
		OnSuccess = OnSuccess or function() end
		OnFailure = OnFailure or function() end

		http.Fetch(
			Link,
			function(Body, _, _, Code)
				SuccessfulRequest(Code, Body, OnSuccess, OnFailure)
			end,
			function(Error)
				PrintLog("Error", Error)

				OnFailure(Error)
			end)
	end
end

do -- Github data conversion
	function ACF.GetDateEpoch(GitDate)
		local Date, Time = unpack(string.Explode("T", GitDate))
		local Year, Month, Day = unpack(string.Explode("-", Date))
		local Hour, Min, Sec = unpack(string.Explode(":", Time))

		return os.time({
			year = Year,
			month = Month,
			day = Day,
			hour = Hour,
			min = Min,
			sec = Sec:sub(1, 2),
		})
	end

	function ACF.GetCommitMessage(Message)
		if not Message then return end

		local Start = Message:find("\n\n")

		Message = Message:Replace("\n\n", "\n"):gsub("[\r]*[\n]+[%s]+", "\n- ")

		local Title = Start and Message:sub(1, Start - 1) or Message
		local Body =  Start and Message:sub(Start + 1, #Message) or "No Commit Message"

		return Title, Body
	end
end

do -- Branch version retrieval and version printing
	local Branches = "https://api.github.com/repos/%s/branches"
	local Commits = "https://api.github.com/repos/%s/commits?per_page=1%s"

	local Messages = {
		["Unable to check"] = {
			Type = "Update_Error",
			Message = "%s: Running on version %s. Unable to check for updates.",
		},
		["Out of date"] = {
			Type = "Update_Old",
			Message = "%s: Running on version %s. There's an update available, pushed %s.",
		},
		["Up to date"] = {
			Type = "Update_Ok",
			Message = "%s: Running on version %s. No updates available, running on the latest version."
		},
	}

	local function PrintStatus(Version)
		local Branch = ACF.GetBranch(Version.Owner, Version.Name)
		local Lapse = ACF.GetTimeLapse(Branch.Date)

		local Data = Messages[Version.Status]
		local Message = Data.Message

		PrintLog(Data.Type, Message:format(Version.Name, Version.Code, Lapse))
	end

	local function GetBranchData(Data, Branch, Commit)
		local Title, Body = ACF.GetCommitMessage(Commit.commit.message)
		local Date = ACF.GetDateEpoch(Commit.commit.author.date)

		Branch.Title = Title
		Branch.Body = Body
		Branch.Date = Date
		Branch.Link = Commit.html_url

		if Data.Head == Branch.Name then
			ACF.GetVersionStatus(Data.Owner, Data.Name)

			PrintStatus(Data)
		end
	end

	local function GetBranches(Name, Data, List)
		local Request = ACF.StartRequest

		Data.Branches = {}

		for _, Branch in ipairs(List) do
			local SHA = Branch.commit.sha

			Data.Branches[Branch.name] = {
				Name = Branch.name,
				Code = "Git-" .. Branch.name .. "-" .. SHA:sub(1, 7),
				Title = false,
				Body = false,
				Date = false,
				Link = false,
			}

			local Current = Data.Branches[Branch.name]

			Request(
				Commits:format(Name, "&sha=" .. SHA),
				function(_, Commit)
					GetBranchData(Data, Current, unpack(Commit))
				end)
		end
	end

	local function CheckAllRepos()
		local Request = ACF.StartRequest

		for Name, Data in pairs(Repos) do
			ACF.GetVersion(Data.Owner, Data.Name)

			Request(
				Branches:format(Name),
				function(_, List)
					GetBranches(Name, Data, List)
				end)
		end
	end

	hook.Add("Initialize", "ACF Request Git Data", function()
		timer.Simple(0, CheckAllRepos)

		hook.Add("Initialize", "ACF Request Git Data")
	end)

	ACF.AddLogType("Update_Ok", "Updates")
	ACF.AddLogType("Update_Old", "Updates", Color(255, 160, 0))
	ACF.AddLogType("Update_Error", "Updates", Color(241, 80, 47))
end

do -- Client syncronization
	util.AddNetworkString("ACF_VersionSync")

	local function SyncInformation(Player)
		if not IsValid(Player) then return end

		net.Start("ACF_VersionSync")
			net.WriteTable(Repos)
		net.Send(Player)
	end

	hook.Add("PlayerInitialSpawn", "ACF_VersionSync", function(Player)
		timer.Simple(5, function()
			SyncInformation(Player)
		end)
	end)
end
