local function CreateMenu(Menu)
	Menu:AddTitle("A Reference Guide")
	Menu:AddLabel("The new ACF wiki will have a greater focus on references about the addon's multiple mechanics.")
	Menu:AddLabel("There's also gonna be more content aimed towards extension developers, allowing them to take advantage of all the features ACF has to offer.")

	local Wiki = Menu:AddButton("Open the Wiki")

	function Wiki:DoClickInternal()
		gui.OpenURL("https://github.com/Stooberton/ACF-3/wiki")
	end

	Menu:AddHelp("The wiki is still a work in progress, it'll get populated as time passes.")
end

ACF.AddOptionItem("About the Addon", "Online Wiki", "book_open", CreateMenu)
