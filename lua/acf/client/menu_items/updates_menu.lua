local ACF = ACF
local Repository, MenuBase

local function LoadCommit(Base, Commit)
	local Date = Commit.Date

	Base:AddTitle(Commit.Title or "No Title")
	Base:AddLabel("Author: " .. (Commit.Author or "Unknown"))
	Base:AddLabel("Date: " .. (Date and os.date("%D", Date) or "Unknown"))
	Base:AddLabel("Time: " .. (Date and os.date("%T", Date) or "Unknown"))
	Base:AddLabel(Commit.Body or "No commit message.")

	local View = Base:AddButton("View this commit")
	function View:DoClickInternal()
		gui.OpenURL(Commit.Link)
	end
end

local function AddStatus(Name, Branches)
	local Data   = Repository[Name]
	local Branch = Branches[Data.Head] or Branches.master
	local Base   = MenuBase:AddCollapsible(Name .. " Status")

	Base:SetTooltip("Left-click to copy the " .. Name .. " version to your clipboard!")

	function Base:OnMousePressed(Code)
		if Code ~= MOUSE_LEFT then return end

		SetClipboardText(Data.Code or "Unknown")
	end

	Base:AddTitle("Status: " .. (Data.Status or "Unknown"))
	Base:AddLabel("Version: " .. (Data.Code or "Unknown"))

	if Branch and Data.Status ~= "Up to date" then
		Base:AddLabel("Latest: " .. Branch.Code)
	end

	Base:AddLabel("Branch: " .. (Data.Head or "Unknown"))

	if Branch then
		local Commit, Header = Base:AddCollapsible("Latest Commit", false)

		function Header:OnToggle(Expanded)
			if not Expanded then return end
			if self.Loaded then return end

			LoadCommit(Commit, Branch)

			self.Loaded = true
		end
	else
		Base:AddTitle("Unable to retrieve the latest commit.")
	end

	MenuBase:AddLabel("") -- Empty space
end

local function UpdateMenu()
	if not IsValid(MenuBase) then return end
	if not Repository then return end

	local Branches = Repository.Branches

	MenuBase:ClearTemporal()
	MenuBase:StartTemporal()

	AddStatus("Server", Branches)
	AddStatus("Client", Branches)

	MenuBase:EndTemporal()
end

local function CreateMenu(Menu)
	Menu:AddTitle("ACF Version Status")

	MenuBase = Menu:AddPanel("ACF_Panel")

	UpdateMenu()
end

ACF.AddMenuItem(1, "About the Addon", "Updates", "newspaper", CreateMenu)

hook.Add("ACF_UpdatedRepository", "ACF Updates Menu", function(Name, Repo)
	if Name ~= "ACF-3" then return end

	Repository = Repo

	UpdateMenu()
end)
