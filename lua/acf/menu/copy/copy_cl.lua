local ACF      = ACF
local Messages = ACF.Utilities.Messages
local Copy     = ACF.Menu.Copy

--- Puts an entity's settings into the menu page that makes it, then opens that page.
--- Skip is a set of field paths to leave as the menu had them. False if no page makes the entity
function Copy.ToMenu(ClassName, Data, Skip)
	local Page, Name = ACF.Menu.FindPage(ClassName, Data)
	if not Page then return false end

	local Context = ACF.Menu.GetPageContext(Page, Name)
	local Merged  = Copy.Merge(Context.Class, Context:Serialize(), Data, Skip)

	ACF.Menu.OpenPageWith(Page, Name, Merged)
	ACF.OpenMenuItem(Page.Category, Page.Name)

	return true, Page
end

hook.Add("ACF_OnMenuCopy", "ACF Menu Copy", function(ClassName, Data, Pick)
	if not ACF.Menu.FindPage(ClassName, Data) then
		Messages.PrintChat("Error", "#acf.menu.copy.no_page")
		return
	end

	if Pick then
		Copy.OpenWindow(ClassName, Data)
		return
	end

	local _, Page = Copy.ToMenu(ClassName, Data)
	local PageName = language.GetPhrase((Page.Name:gsub("^#", "")))

	Messages.PrintChat("Info", language.GetPhrase("acf.menu.copy.copied"):format(PageName))
end)
