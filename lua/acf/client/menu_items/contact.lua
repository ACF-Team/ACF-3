local function CreateMenu(Menu)
	Menu:AddTitle("Your feedback is important.")
	Menu:AddLabel("For this reason, we've setup a variety of methods to generate discussion among the members of the ACF community.")

	Menu:AddTitle("How to Contribute")
	Menu:AddLabel("To make it easier for first time contributors, we've left a guide about how to contribute to the addon.")

	local Contribute = Menu:AddButton("Contributing to ACF")

	function Contribute:DoClickInternal()
		gui.OpenURL("https://github.com/Stooberton/ACF-3/blob/master/CONTRIBUTING.md")
	end

	Menu:AddTitle("Official Discord Server")
	Menu:AddLabel("We have a Discord server! You can discuss the addon's development or just hang around on one of the off-topic channels.")

	local Discord = Menu:AddButton("Join the Discord Server")

	function Discord:DoClickInternal()
		gui.OpenURL("https://discordapp.com/invite/shk5sc5")
	end

	Menu:AddTitle("Official Steam Group")
	Menu:AddLabel("There's also a Steam group, you'll find all important announcements about the addon's development there.")

	local Steam = Menu:AddButton("Join the Steam Group")

	function Steam:DoClickInternal()
		gui.OpenURL("https://steamcommunity.com/groups/officialacf")
	end

	Menu:AddTitle("Github Issues & Suggestions")
	Menu:AddLabel("The recommended method for bug reporting and suggestion posting is the Issues tab on the Github repository.")
	Menu:AddLabel("By using this method, you'll be able to easily track your issue and the discussion related to it.")

	local Issue = Menu:AddButton("Report an Issue")

	function Issue:DoClickInternal()
		gui.OpenURL("https://github.com/Stooberton/ACF-3/issues/new/choose")
	end
end

ACF.AddOptionItem("About the Addon", "Contact Us", "feed", CreateMenu)
