local function CreateMenu(Menu)
	Menu:AddTitle("#acf.menu.contact.desc1")
	Menu:AddLabel("#acf.menu.contact.desc2")

	do -- Official Discord Server
		local Base = Menu:AddCollapsible("#acf.menu.contact.discord", false, "icon16/server.png")

		Base:AddLabel("#acf.menu.contact.discord_desc")

		local Link = Base:AddButton("#acf.menu.contact.discord_join")

		function Link:DoClickInternal()
			gui.OpenURL("https://discordapp.com/invite/jgdzysxjST")
		end
	end

	do -- Official Steam Group
		local Base = Menu:AddCollapsible("#acf.menu.contact.steam", false, "vgui/resource/icon_steam")

		Base:AddLabel("#acf.menu.contact.steam_desc")

		local Link = Base:AddButton("#acf.menu.contact.steam_join")

		function Link:DoClickInternal()
			gui.OpenURL("https://steamcommunity.com/groups/officialacf")
		end
	end

	do -- "Github Issues & Suggestions"
		local Base = Menu:AddCollapsible("#acf.menu.contact.github", false, "icon16/arrow_branch.png")

		Base:AddLabel("#acf.menu.contact.github_desc1")
		Base:AddLabel("#acf.menu.contact.github_desc2")

		local Link = Base:AddButton("#acf.menu.contact.github_report")

		function Link:DoClickInternal()
			gui.OpenURL("https://github.com/ACF-Team/ACF-3/issues/new/choose")
		end
	end

	do -- How to Contribute
		local Base = Menu:AddCollapsible("#acf.menu.contact.contributing", false, "icon16/page_code.png")

		Base:AddLabel("#acf.menu.contact.contributing_desc")

		local Link = Base:AddButton("#acf.menu.contact.contributing_link")

		function Link:DoClickInternal()
			gui.OpenURL("https://github.com/ACF-Team/ACF-3/blob/master/CONTRIBUTING.md")
		end
	end
end

ACF.AddMenuItem(301, "#acf.menu.about", "#acf.menu.contact", "feed", CreateMenu)