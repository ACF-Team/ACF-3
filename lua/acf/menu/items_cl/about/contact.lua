local function CreateMenu(Menu)
	Menu:AddTitle("Your feedback is important.")
	Menu:AddLabel("For this reason, we've setup a variety of methods to generate discussion among the members of the ACF community")

	do -- Official Discord Server
		local Base = Menu:AddCollapsible("Official Discord Server", true, "icon16/server.png")

		Base:AddLabel("We have a Discord server! You can discuss the addon's development or just hang around on one of the off-topic channels.")

		local Link = Base:AddButton("Join the Discord Server")

		function Link:DoClickInternal()
			gui.OpenURL("https://discordapp.com/invite/jgdzysxjST")
		end
	end

	do -- Official Steam Group
		local Base = Menu:AddCollapsible("Official Steam Group", true, "vgui/resource/icon_steam")

		Base:AddLabel("We have a Steam group! You can discuss the addon's development or just hang around on one of the off-topic channels.")

		local Link = Base:AddButton("Join the Steam Group")

		function Link:DoClickInternal()
			gui.OpenURL("https://steamcommunity.com/groups/officialacf")
		end
	end
end

ACF.AddMenuItem(1, "Contact", "icon16/feed.png", CreateMenu, "About")