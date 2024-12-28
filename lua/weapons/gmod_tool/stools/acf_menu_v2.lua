TOOL.Category = "Construction"
TOOL.Name = "Armored Combat Framework"
if CLIENT then
    TOOL.Information = {}
    language.Add("tool.acf_menu_v2.name", "Armored Combat Framework")
    language.Add("tool.acf_menu_v2.desc", "A multi-tool for ACF entities & tools")
end

ACF.Tool:Setup(TOOL)

-- this later gets injected into