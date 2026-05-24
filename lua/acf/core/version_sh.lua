local ACF = ACF
local Realm = SERVER and "Server" or "Client"

--- Converts a local time to UTC for comparison
local function LocalToUTC(time)
	return os.time(os.date("!*t", time)) or 0 -- WHY WOULD IT EVER BE NIL :(
end

--- Returns the current git branch name
local function GetGitHead(Path)
	local HeadFile = Path .. "/.git/HEAD"
	if not file.Exists(HeadFile, "GAME") then return end

	local content = file.Read(HeadFile, "GAME")
	if not content then return end

	local _, _, head = content:find("refs/heads/(.+)$")  -- Extract the branch name from the content, e.g. "master" from "ref: refs/heads/master"
	if not head then return end

	return head:Trim()
end

--- Returns the current git commit SHA and date for a given branch
local function GetGitCommit(Path, Head)
	if not Head then return end

	local RefPath = Path .. "/.git/refs/heads/" .. Head

	if not file.Exists(RefPath, "GAME") then return end

	local sha = file.Read(RefPath, "GAME")
	if not sha then return end

	local BranchSha = string.GetFileFromFilename(Head) .. "-" .. sha:Trim():sub(1, 7)
	local Time = file.Time(RefPath, "GAME")
	return BranchSha, Time
end

--- Returns the git owner from the URL of the remote repository
local function GetGitOwner(Path)
	local FetchPath = Path .. "/.git/FETCH_HEAD"
	if not file.Exists(FetchPath, "GAME") then return end

	local Fetch = file.Read(FetchPath, "GAME")
	if not Fetch then return end

	local Start, End = Fetch:find("github.com[/]?[:]?[%w_-]+/") -- Extract the owner name from the URL, e.g. "ACF-3" from "github.com/ACF-3/ACF-3"
	if not Start then return end

	return Fetch:sub(Start + 11, End - 1)
end

--- Returns a table with information about the most recent commit on the current branch.
--- Handles git, workshop and zip installations.
function ACF.CheckLocalVersion(Owner, Name, Path)
	local Result = {
		realm = Realm,
		path  = Path,
		head  = "master",
		code  = "Not Installed",
		date  = 0,
		owner = Owner
	}

	-- Default result if no installation found
	if not Path then return Result end

	-- Git installation
	if file.Exists(Path .. "/.git/HEAD", "GAME") then
		local Head = GetGitHead(Path)
		local Code, Date = GetGitCommit(Path, Head)

		Result.head  = Head or "master"
		Result.owner = GetGitOwner(Path) -- Makes sure the owner of the repo is correct, deals with forks

		if Code and Date then
			Result.code = "Git-" .. Code
			Result.date = LocalToUTC(Date)
		end

		return Result
	end

	-- Workshop install
	local WorkshopPath = "data_static/acf/" .. string.lower(Name) .. "-version.txt"
	if file.Exists(WorkshopPath, "GAME") then
		local FileData = file.Read(WorkshopPath, "GAME"):Trim()
		local Code = FileData:sub(1, 7)
		local Date = file.Time(WorkshopPath, "GAME")

		Result.code = "Git-master-" .. Code
		Result.date = LocalToUTC(Date)

		return Result
	end

	-- ZIP install
	if file.Exists(Path .. "/LICENSE", "GAME") then
		Result.code = "ZIP-Unknown"
		Result.date = LocalToUTC(file.Time(Path .. "/LICENSE", "GAME"))

		return Result
	end

	return Result
end

--- Convert GitHub date string to epoch
local function GitDateToEpoch(dateStr)
	local year, month, day, hour, min, sec = dateStr:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
	return os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec)
	})
end

--- Retrieves the title and body from a git commit message
local function GitTitleBody(Message)
	if not Message then return end

	local Start = Message:find("\n\n")

	Message = Message:Replace("\n\n", "\n"):gsub("[\r]*[\n]+[%s]+", "\n- ")

	local Title = Start and Message:sub(1, Start - 1) or Message
	local Body  = Start and Message:sub(Start + 1, #Message) or "No Commit Message"

	return Title, Body
end

--- Fetches the (latest) commit given a url and runs the callback with the commit information
local function FetchCommit(url, callback)
	ACF.StartRequest(url,
	function(body, _, _, _)
		local data = util.JSONToTable(body)
		if not data then ACF.PrintLog("HTTP_Error", "Failed to fetch commit information") return end

		local raw = data[1] or data
		if not raw or not raw.commit then ACF.PrintLog("HTTP_Error", "Failed to fetch commit information") return end

		local Title, Body = GitTitleBody(raw.commit.message)

		callback({
			short_sha = raw.sha:sub(1, 7),
			title     = Title,
			body      = Body,
			author    = raw.commit.author.name,
			date      = GitDateToEpoch(raw.commit.author.date),
			url       = raw.html_url
		})
	end,
	function(_)
		ACF.PrintLog("HTTP_Error", "Failed to fetch commit information")
	end
	)
end

--- Get information about the latest commit for a given repo and branch
--- Example usage: lua_run ACF.GetLatestCommit("ACF-Team", "ACF-3", "master", function(commit) PrintTable(commit) end)
function ACF.GetLatestCommit(owner, repo, branch, callback)
	FetchCommit(("https://api.github.com/repos/%s/%s/commits?per_page=1&sha=%s"):format(owner, repo, branch), callback)
end

--- Get information about a specific commit by SHA
--- Example usage: lua_run ACF.GetCommit("ACF-Team", "ACF-3", "abc1234", function(commit) PrintTable(commit) end)
function ACF.GetCommit(owner, repo, sha, callback)
	FetchCommit(("https://api.github.com/repos/%s/%s/commits/%s"):format(owner, repo, sha), callback)
end

ACF.Extensions = ACF.Extensions or {}
ACF.ExtensionOrders = ACF.ExtensionOrders or {}
function ACF.AddRepository(Owner, Name)
	if ACF.Extensions[Name] then return end
	local info = debug.getinfo(2, "S")
	local Path = string.Split(info.short_src, "/lua/")[1]

	local Version = ACF.CheckLocalVersion(Owner, Name, Path)
	ACF.Extensions[Name] = ACF.Extensions[Name] or {}
	ACF.Extensions[Name].Version = Version -- Version info for this repository
	table.insert(ACF.ExtensionOrders, Name)
end

ACF.AddRepository("ACF-Team", "ACF-3")

-- Realm specific stuff (so small it probably doesn't need to be in separate files)
if SERVER then
	hook.Add("Initialize", "ACF_GetLatestCommit", function()
		print("[ACF] Fetching latest commit information for all repositories...")
		for ExtensionName, Extension in pairs(ACF.Extensions) do
			if not Extension.Version or not Extension.Version.owner then continue end

			ACF.GetLatestCommit(Extension.Version.owner, ExtensionName, Extension.Version.head, function(Commit)
				Extension.Commit = Commit
				Extension.Retrieved = true
				Extension.Commit.code = "Git-" .. Extension.Version.head .. "-" .. Commit.short_sha
			end)
		end
		hook.Remove("Initialize", "ACF_GetLatestCommit")
	end)

	-- Retrieve most recent commit and current server commit and network to all clients
	util.AddNetworkString("ACF_VersionInfo")
	hook.Add("ACF_OnLoadPlayer", "ACF_SendVersionInfo", function(ply)
		net.Start("ACF_VersionInfo")
		net.WriteString(util.TableToJSON(ACF.Extensions or {}))
		net.Send(ply)
	end)
elseif CLIENT then
	-- Receive version info from server
	net.Receive("ACF_VersionInfo", function()
		ACF.ServerExtensions = util.JSONToTable(net.ReadString())

		hook.Add("CreateMove", "ACF Outdated Notice", function(Move)
			if Move:GetButtons() ~= 0 then
				-- Determine if client or server versions are out of date with most recent commit and notify.
				local Messages = ACF.Utilities.Messages
				for _, ExtensionName in ipairs(ACF.ExtensionOrders) do
					ClientExtension = ACF.Extensions[ExtensionName]
					ServerExtension = ACF.ServerExtensions[ExtensionName]
					if not ClientExtension or not ServerExtension or not ClientExtension.Version or not ServerExtension.Commit then continue end -- Why would this happen :(
					if ClientExtension.Version.code ~= ServerExtension.Commit.code then
						Messages.PrintChat("Error", "Your version of " .. ExtensionName .. " is out of date with the latest commit on the server's branch.\nPlease update to avoid potential compatibility issues.")
					end
					if ServerExtension.Version.code ~= ServerExtension.Commit.code then
						Messages.PrintChat("Error", "The server's version of " .. ExtensionName .. " is out of date with the latest commit on its branch.\nPlease notify the server administrator to update to avoid potential compatibility issues.")
					end
				end

				hook.Remove("CreateMove", "ACF Outdated Notice")
			end
		end)
	end)
end