local function CreateMenu(Menu)
	Menu:AddTitle("Your feedback is important.")
	Menu:AddLabel("For this reason, we've setup a variety of methods to generate discussion among the members of the ACF community.")

	do -- Official Discord Server
		local Base = Menu:AddCollapsible("Official Discord Server", false)

		Base:AddLabel("We have a Discord server! You can discuss the addon's development or just hang around on one of the off-topic channels.")

		local Link = Base:AddButton("Join the Discord Server")

		function Link:DoClickInternal()
			gui.OpenURL("https://discordapp.com/invite/jgdzysxjST")
		end
	end

	do -- Official Steam Group
		local Base = Menu:AddCollapsible("Official Steam Group", false)

		Base:AddLabel("There's also a Steam group, you'll find all important announcements about the addon's development there.")

		local Link = Base:AddButton("Join the Steam Group")

		function Link:DoClickInternal()
			gui.OpenURL("https://steamcommunity.com/groups/officialacf")
		end
	end

	do -- "Github Issues & Suggestions"
		local Base = Menu:AddCollapsible("Github Issues & Suggestions", false)

		Base:AddLabel("The recommended method for bug reporting and suggestion posting is the Issues tab on the Github repository.")
		Base:AddLabel("By using this method, you'll be able to easily track your issue and the discussion related to it.")

		local Link = Base:AddButton("Report an Issue")

		function Link:DoClickInternal()
			gui.OpenURL("https://github.com/Stooberton/ACF-3/issues/new/choose")
		end
	end

	do -- How to Contribute
		local Base = Menu:AddCollapsible("How to Contribute", false)

		Base:AddLabel("To make it easier for first time contributors, we've left a guide about how to contribute to the addon.")

		local Link = Base:AddButton("Contributing to ACF")

		function Link:DoClickInternal()
			gui.OpenURL("https://github.com/Stooberton/ACF-3/blob/master/CONTRIBUTING.md")
		end
	end
end

ACF.AddMenuItem(301, "About the Addon", "Contact Us", "feed", CreateMenu)
