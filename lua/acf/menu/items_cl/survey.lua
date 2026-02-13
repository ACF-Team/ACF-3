-- This is a page intended to be used only when an ACF survey is active.
-- Just disable it when it's no longer needed so that we can easily reuse it again for future surveys.
--[[
local function CreateMenu(Menu)
	Menu:AddTitle("ACF 2025 Survey")

	Menu:AddLabel("It's time for another community-wide ACF survey!")
	Menu:AddLabel("Please take a few minutes to share your thoughts on ACF with us to help guide development in the best direction for everyone.")

	local Wiki = Menu:AddButton("Open Survey")

	function Wiki:DoClickInternal()
		gui.OpenURL("https://forms.gle/wDsQbVTt9oDk1MN28")
	end

	Menu:AddHelp("This survey will close on February 8th, so please give us your feedback soon!")
end

ACF.AddMenuItem(1, "#acf.menu.about", "Survey", "book_open", CreateMenu)
]]