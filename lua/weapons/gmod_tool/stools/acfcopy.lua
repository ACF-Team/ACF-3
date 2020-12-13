ACF.LoadToolFunctions(TOOL)

TOOL.Name = "ACF Copy Tool"

if CLIENT then
	language.Add("Tool.acfcopy.name", "Armored Combat Framework")
	language.Add("Tool.acfcopy.desc", "Copy information from one ACF entity to another")

	TOOL.BuildCPanel = ACF.CreateCopyMenu

	concommand.Add("acf_reload_copy_menu", function()
		if not IsValid(ACF.CopyMenu) then return end

		ACF.CreateCopyMenu(ACF.CopyMenu.Panel)
	end)
end
