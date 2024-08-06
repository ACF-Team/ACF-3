ACF.LoadToolFunctions(TOOL)

TOOL.Name = "#tool.acfcopy.name"

if CLIENT then
	TOOL.BuildCPanel = ACF.CreateCopyMenu

	concommand.Add("acf_reload_copy_menu", function()
		if not IsValid(ACF.CopyMenu) then return end

		ACF.CreateCopyMenu(ACF.CopyMenu.Panel)
	end)
end
