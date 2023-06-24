local function CreateMenu(Menu)
	Menu:AddTitle("Online Wiki")

	Menu:AddLabel("The new ACF wiki will have a greater focus on providing content aimed towards the average builder.")
	Menu:AddLabel("There's also gonna be a section where we'll document anything that could be useful for extension developers.")

	local Wiki = Menu:AddButton("Open the Wiki")

	function Wiki:DoClickInternal()
		gui.OpenURL("https://github.com/Stooberton/ACF-3/wiki")
	end

	Menu:AddHelp("The wiki is still a work in progress, it'll get populated as time passes.")
end

ACF.AddMenuItem(101, "About the Addon", "Online Wiki", "book_open", CreateMenu)
