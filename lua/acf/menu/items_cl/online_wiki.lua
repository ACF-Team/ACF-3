local function CreateMenu(Menu)
	Menu:AddTitle("#acf.menu.wiki")

	Menu:AddLabel("#acf.menu.wiki.desc1")
	Menu:AddLabel("#acf.menu.wiki.desc2")

	local Wiki = Menu:AddButton("#acf.menu.wiki.open")

	function Wiki:DoClickInternal()
		gui.OpenURL("https://github.com/ACF-Team/ACF-3/wiki")
	end

	Menu:AddHelp("#acf.menu.wiki.wip_notice")
end

ACF.AddMenuItem(101, "#acf.menu.about", "#acf.menu.wiki", "book_open", CreateMenu)