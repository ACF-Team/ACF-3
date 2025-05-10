local ACF = ACF
local Repository, MenuBase

local function LoadCommit(Base, Commit)
	local Date = Commit.Date
	local DefaultText = language.GetPhrase("acf.menu.updates.unknown")

	Base:AddTitle(Commit.Title or "#acf.menu.updates.commit_title_default")
	Base:AddLabel(language.GetPhrase("acf.menu.updates.commit_author"):format(Commit.Author or DefaultText))
	Base:AddLabel(language.GetPhrase("acf.menu.updates.commit_date"):format(Date and os.date("%D", Date) or DefaultText))
	Base:AddLabel(language.GetPhrase("acf.menu.updates.commit_time"):format(Date and os.date("%T", Date) or DefaultText))
	Base:AddLabel(Commit.Body or "#acf.menu.updates.commit_message_default")

	local View = Base:AddButton("#acf.menu.updates.commit_view")
	function View:DoClickInternal()
		gui.OpenURL(Commit.Link)
	end
end

local function AddStatus(Name, Branches)
	local Data        = Repository[Name]
	local Branch      = Branches[Data.Head] or Branches.master
	local Base        = MenuBase:AddCollapsible(language.GetPhrase("acf.menu.updates.realm_status"):format(Name))
	local DefaultText = language.GetPhrase("acf.menu.updates.unknown")

	Base:SetTooltip(language.GetPhrase("acf.menu.updates.realm_tooltip"):format(Name))

	function Base:OnMousePressed(Code)
		if Code ~= MOUSE_LEFT then return end

		SetClipboardText(Data.Code or DefaultText)
	end

	Base:AddTitle(language.GetPhrase("acf.menu.updates.current_status"):format(Data.Status or DefaultText))
	Base:AddLabel(language.GetPhrase("acf.menu.updates.current_version"):format(Data.Code or DefaultText))

	if Branch and Data.Status ~= "Up to date" then
		Base:AddLabel(language.GetPhrase("acf.menu.updates.latest_version"):format(Branch.Code))
	end

	Base:AddLabel(language.GetPhrase("acf.menu.updates.current_branch"):format(Data.Head or DefaultText))

	if Branch then
		local Commit, Header = Base:AddCollapsible("#acf.menu.updates.latest_commit", false)

		function Header:OnToggle(Expanded)
			if not Expanded then return end
			if self.Loaded then return end

			LoadCommit(Commit, Branch)

			self.Loaded = true
		end
	else
		Base:AddTitle("#acf.menu.updates.invalid_branch")
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
	Menu:AddTitle("#acf.menu.updates.version_status")

	MenuBase = Menu:AddPanel("ACF_Panel")

	UpdateMenu()
end

ACF.AddMenuItem(1, "#acf.menu.about", "#acf.menu.updates", "newspaper", CreateMenu)

hook.Add("ACF_OnFetchRepository", "ACF Updates Menu", function(Name, Repo)
	if Name ~= "ACF-3" then return end

	Repository = Repo

	UpdateMenu()
end)