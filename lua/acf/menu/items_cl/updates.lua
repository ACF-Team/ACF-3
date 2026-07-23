local function DrawGitCommit(Menu, Commit)
	local Base = Menu:AddCollapsible("#acf.menu.updates.latest_commit", false, "icon16/clock.png")
	if not Commit then
		Base:AddLabel("#acf.menu.updates.invalid_branch")
		return
	end

	Base:AddTitle(Commit.title or "#acf.menu.updates.commit_title_default")
	Base:AddLabel(Commit.body or "#acf.menu.updates.commit_message_default")
	Base:AddLabel(language.GetPhrase("acf.menu.updates.commit_author"):format(Commit.author))
	Base:AddLabel(language.GetPhrase("acf.menu.updates.commit_date"):format(
		os.date("%Y-%m-%d %H:%M:%S", Commit.date) .. " (" .. string.FormattedTime(os.time() - Commit.date, "%dh") .. " ago)"
	))
	Base:AddLabel(language.GetPhrase("acf.menu.updates.commit_code"):format(Commit.Code or Commit.code or "#acf.menu.updates.unknown"))
	local Button = Base:AddButton("#acf.menu.updates.commit_view")
	function Button:DoClickInternal()
		gui.OpenURL(Commit.url)
	end
end

local function DrawGitStatus(Menu, ExtensionName, Version, MostRecentCommit)
	local BaseText     = language.GetPhrase("acf.menu.updates.realm_status"):format(ExtensionName, Version.realm)
	local Outdated     = (MostRecentCommit and Version.code ~= MostRecentCommit.code) or false
	local IconSuffix   = Outdated and "_error.png" or ".png"
	local BaseIcon     = Version.realm == "Server" and "icon16/server" .. IconSuffix or "icon16/computer" .. IconSuffix
	local Base         = Menu:AddCollapsible(BaseText, true, BaseIcon)

	local Status       = Base:AddLabel("")
	local StatusPrefix = language.GetPhrase("acf.menu.updates.current_status")

	-- Note, since we're using the latest commit on the server's branch, the following is possible:
	-- Server up to date with main, client out of date with dev, but dev is ahead of main.
	if MostRecentCommit then
		local StatusValue = language.GetPhrase(Outdated and "acf.menu.updates.outdated" or "acf.menu.updates.up_to_date")
		if Outdated and Version.date and Version.date > 0 then
			local Diff      = MostRecentCommit.date - Version.date
			local Direction = Diff >= 0 and "behind" or "ahead"
			StatusValue     = StatusValue .. " (" .. string.FormattedTime(math.abs(Diff), "%dh") .. " " .. Direction .. ")"
		end
		Status:SetText(StatusPrefix:format(StatusValue))
	else
		Status:SetText(StatusPrefix:format("#acf.menu.updates.unknown"))
	end

	Base:AddLabel(language.GetPhrase("acf.menu.updates.current_branch"):format(Version.head))
	Base:AddLabel(language.GetPhrase("acf.menu.updates.current_version"):format(Version.code))

	Base:SetTooltip(language.GetPhrase("acf.menu.updates.realm_tooltip"):format(Version.realm))
	function Base:OnMousePressed(Enum)
		if Enum ~= MOUSE_LEFT then return end
		SetClipboardText(Version.code)
	end
end

local function CreateMenu(Menu)
	Menu:AddTitle("#acf.menu.updates.version_status")

	for _, ExtensionName in ipairs(ACF.ExtensionOrders) do
		ClientExtension = ACF.Extensions[ExtensionName]
		ServerExtension = ACF.ServerExtensions[ExtensionName]
		local Base = Menu:AddCollapsible(ExtensionName, true, "icon16/package.png")
		DrawGitCommit(Base, ServerExtension.Commit)
		DrawGitStatus(Base, ExtensionName, ClientExtension.Version, ServerExtension.Commit)
		DrawGitStatus(Base, ExtensionName, ServerExtension.Version, ServerExtension.Commit)
	end
end

ACF.AddMenuItem(1, "#acf.menu.about", "#acf.menu.updates", "newspaper", CreateMenu)