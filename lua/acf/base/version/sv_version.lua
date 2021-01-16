local ACF = ACF
local Repos = ACF.Repositories

do -- Github data conversion
	local string = string
	local os = os

	local DateData = { year = true, month = true, day = true, hour = true, min = true, sec = true }

	function ACF.GetDateEpoch(GitDate)
		local Date, Time = unpack(string.Explode("T", GitDate))
		local Year, Month, Day = unpack(string.Explode("-", Date))
		local Hour, Min, Sec = unpack(string.Explode(":", Time))

		DateData.year  = Year
		DateData.month = Month
		DateData.day   = Day
		DateData.hour  = Hour
		DateData.min   = Min
		DateData.sec   = Sec:sub(1, 2)

		return os.time(DateData)
	end

	function ACF.GetCommitMessage(Message)
		if not Message then return end

		local Start = Message:find("\n\n")

		Message = Message:Replace("\n\n", "\n"):gsub("[\r]*[\n]+[%s]+", "\n- ")

		local Title = Start and Message:sub(1, Start - 1) or Message
		local Body  = Start and Message:sub(Start + 1, #Message) or "No Commit Message"

		return Title, Body
	end
end

do -- Branch version retrieval and version printing
	local BranchLink = "https://api.github.com/repos/%s/%s/branches"
	local Commits = "https://api.github.com/repos/%s/%s/commits?per_page=1&sha=%s"

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

	local function PrintStatus(Data)
		local Branch  = ACF.GetBranch(Data.Name, Data.Head)
		local Lapse   = ACF.GetTimeLapse(Branch.Date)
		local LogData = Messages[Data.Status]

		ACF.PrintLog(LogData.Type, LogData.Message:format(Data.Name, Data.Code, Lapse))
	end

	local function GetBranchData(Data, Branch, Commit)
		local Title, Body = ACF.GetCommitMessage(Commit.commit.message)
		local Date = ACF.GetDateEpoch(Commit.commit.author.date)

		Branch.Title  = Title
		Branch.Body   = Body
		Branch.Date   = Date
		Branch.Author = Commit.commit.author.name
		Branch.Link   = Commit.html_url

		if Branch.Name == Data.Head then
			ACF.CheckLocalStatus(Data.Name)

			PrintStatus(Data)
		end
	end

	local function LoadBranches(Data, Branches, List)
		for _, Branch in ipairs(List) do
			local SHA = Branch.commit.sha
			local Current = {
				Name = Branch.name,
				Code = "Git-" .. Branch.name .. "-" .. SHA:sub(1, 7),
			}

			Branches[Branch.name] = Current

			ACF.StartRequest(
				Commits:format(Data.Owner, Data.Name, SHA),
				function(_, Commit)
					GetBranchData(Data, Current, unpack(Commit))
				end
			)
		end
	end

	hook.Add("Initialize", "ACF Request Git Data", function()
		for Name, Repo in pairs(Repos) do
			local Data = Repo.Server

			ACF.StartRequest(
				BranchLink:format(Data.Owner, Name),
				function(_, List)
					LoadBranches(Data, Repo.Branches, List)
				end)
		end

		hook.Remove("Initialize", "ACF Request Git Data")
	end)

	ACF.AddLogType("Update_Ok", "Updates")
	ACF.AddLogType("Update_Old", "Updates", Color(255, 160, 0))
	ACF.AddLogType("Update_Error", "Updates", Color(241, 80, 47))
end

do -- Client syncronization
	util.AddNetworkString("ACF_VersionSync")

	hook.Add("ACF_OnPlayerLoaded", "ACF_VersionSync", function(Player)
		local JSON = util.TableToJSON(Repos)

		net.Start("ACF_VersionSync")
			net.WriteString(JSON)
		net.Send(Player)
	end)
end
