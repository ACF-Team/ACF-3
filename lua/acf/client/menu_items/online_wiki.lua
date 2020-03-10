local function CreateMenu(Menu)
	Menu:AddTitle("A Reference Guide")
	Menu:AddLabel("From now on, the ACF wiki will have a greater focus on references about the addon's multiple mechanics.")
	Menu:AddLabel("We'll also leave some content aimed for developers so they can take advatange of everything we leave at their disposal.")

	local Wiki = Menu:AddButton("Open the Wiki")

	function Wiki:DoClickInternal()
		gui.OpenURL("https://github.com/Stooberton/ACF-3/wiki")
	end

	Menu:AddLabel("Note: The wiki is still a work in progress, it'll get poblated as time passes.")
end

ACF.AddOptionItem("About the Addon", "Online Wiki", "book_open", CreateMenu)
