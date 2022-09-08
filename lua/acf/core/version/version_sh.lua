local ACF   = ACF
local Repos = ACF.Repositories
local Realm = SERVER and "Server" or "Client"


do -- Local repository version checking
	local file = file
	local os   = os

	local function LocalToUTC(Time)
		return os.time(os.date("!*t", Time))
	end

	-- Makes sure the owner of the repo is correct, deals with forks
	local function UpdateOwner(Path, Data)
		if not file.Exists(Path .. "/.git/FETCH_HEAD", "GAME") then return end

		local Fetch = file.Read(Path .. "/.git/FETCH_HEAD", "GAME")
		local Start, End = Fetch:find("github.com[/]?[:]?[%w_-]+/")

		if not Start then return end -- File is empty

		Data.Owner = Fetch:sub(Start + 11, End - 1)
	end

	local function GetHeadsPath(Path, Data)
		local _, _, Head = file.Read(Path .. "/.git/HEAD", "GAME"):find("heads/(.+)$")
		local HeadPrefix = string.Split(Head, "/")
		Head = HeadPrefix[#HeadPrefix]
		HeadPrefix = table.concat(HeadPrefix, "/", 1, #HeadPrefix - 1)
		if #HeadPrefix > 0 then HeadPrefix = HeadPrefix .. "/" end

		Data.Head = Head:Trim()

		local Heads = Path .. "/.git/refs/heads/" .. HeadPrefix .. "/"
		return Heads
	end

	local function GetGitData(Path, Data)
		local Heads = GetHeadsPath(Path, Data)
		local Files = file.Find(Heads .. "*", "GAME")
		local Code, Date

		for _, Name in ipairs(Files) do
			if Name == Data.Head then
				local SHA = file.Read(Heads .. Name, "GAME"):Trim()

				Code = Name .. "-" .. SHA:sub(1, 7)
				Date = file.Time(Heads .. Name, "GAME")

				break
			end
		end

		return Code, Date
	end

	-------------------------------------------------------------------

	function ACF.CheckLocalVersion(Name)
		if not isstring(Name) then return end

		local Data = ACF.GetLocalRepo(Name)

		if not Data then return end

		local Path = Data.Path

		if not Path then
			Data.Code    = "Not Installed"
			Data.Date    = 0
			Data.NoFiles = true
		elseif file.Exists(Path .. "/.git/HEAD", "GAME") then
			local Code, Date = GetGitData(Path, Data)

			UpdateOwner(Path, Data)

			Data.Code = "Git-" .. Code
			Data.Date = LocalToUTC(Date)
		elseif file.Exists(Path .. "/LICENSE", "GAME") then
			local Date = file.Time(Path .. "/LICENSE", "GAME")

			Data.Code = "ZIP-Unknown"
			Data.Date = LocalToUTC(Date)
		end

		if not Data.Head then
			Data.Head = "master"
		end
	end
end

do -- Local repository status checking
	local function IsUpdated(Data, Branch)
		if not isnumber(Data.Date) then return false end

		return Data.Date >= Branch.Date
	end

	function ACF.CheckLocalStatus(Name)
		if not isstring(Name) then return end

		local Repo = ACF.GetRepository(Name)

		if not Repo then return end

		local Data     = Repo[Realm]
		local Branches = Repo.Branches
		local Branch   = Branches[Data.Head] or Branches.master

		if not (Branch and Branch.Date) or Data.NoFiles then
			Data.Status = "Unable to check"
		elseif Data.Code == Branch.Code or IsUpdated(Data, Branch) then
			Data.Status = "Up to date"
		else
			Data.Status = "Out of date"
		end
	end
end

do -- Repository functions
	function ACF.AddRepository(Owner, Name, File)
		if not isstring(Owner) then return end
		if not isstring(Name) then return end
		if not isstring(File) then return end
		if Repos[Name] then return end

		local DebugInfo = debug.getinfo( 2, "S" )
		local AddonFolder = string.Split( DebugInfo.short_src, "/lua/" )[1]

		Repos[Name] = {
			[Realm] = {
				Path = AddonFolder,
				Owner = Owner,
				Name = Name,
			},
			Branches = {},
		}

		if CLIENT then
			Repos[Name].Server = {}
		end

		ACF.CheckLocalVersion(Name)
	end

	function ACF.GetRepository(Name)
		if not isstring(Name) then return end

		return Repos[Name]
	end

	function ACF.GetLocalRepo(Name)
		if not isstring(Name) then return end

		local Data = Repos[Name]

		return Data and Data[Realm]
	end

	ACF.AddRepository("Stooberton", "ACF-3", "lua/autorun/acf_loader.lua")
end

do -- Branch functions
	function ACF.GetBranches(Name)
		if not isstring(Name) then return end

		local Data = Repos[Name]

		return Data and Data.Branches
	end

	function ACF.GetBranch(Name, Branch)
		if not isstring(Name) then return end
		if not isstring(Branch) then return end

		local Data = Repos[Name]

		if not Data then return end

		return Data.Branches[Branch]
	end
end
