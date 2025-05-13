ACF.LoadToolFunctions(TOOL)

TOOL.Name = "#tool.acfcopy.name"

if CLIENT then
	TOOL.BuildCPanel = ACF.CreateCopyMenu
end