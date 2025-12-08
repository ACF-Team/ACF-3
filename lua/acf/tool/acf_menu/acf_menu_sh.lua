-- MenuImpl_Hotload hotloads the menu. If TOOL is not provided, then we try to hotload on the stool table if it exists.
-- If that doesn't exist, no action is taken.
function ACF.MenuImpl_Hotload(TOOL)
    if not TOOL then
        -- This allows us to hotload changes from cl/sh
        local gmod_tool = weapons.GetStored("gmod_tool")
        if not gmod_tool then return end

        TOOL = gmod_tool.Tool["acf_menu"]
        if not TOOL then return end
    end

    for K, V in pairs(ACF.MenuImpl) do
        TOOL[K] = V
    end
end

-- Actual functionality down here.

ACF.MenuImpl = ACF.MenuImpl or {}
local MenuImpl = ACF.MenuImpl

MenuImpl.Category = "Construction"
MenuImpl.Name = "ACF-3 Menu"
if CLIENT then
    MenuImpl.Information = {}
    language.Add("tool.acf_menu_v2.name", "Armored Combat Framework")
    language.Add("tool.acf_menu_v2.desc", "A multi-tool for ACF entities & tools")
end

function MenuImpl:Deploy()

end

function MenuImpl:Holster()

end

function MenuImpl:LeftClick(_)

end

function MenuImpl:Reload(_)

end

function MenuImpl:RightClick(_)

end

function MenuImpl:Think()

end

-- Hotload.
ACF.MenuImpl_Hotload()