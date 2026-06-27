local ACF        = ACF
local Classes   = ACF.Classes

local GroundLoaderText = "Mass : %s kg\n"

function ACF.CreateGroundLoaderMenu(Data, Menu)
    Menu:AddLabel(GroundLoaderText:format(Data.Mass))

    ACF.SetClientData("PrimaryClass", "acf_groundloader")

    if Menu.ComponentPreview then
        local Settings = {
            GhostAngOffset = Angle(0, -90, 0)
        }

        Menu.ComponentPreview:UpdateSettings(Settings)
        Menu.ComponentPreview:SetModelScale(1, true)
    end
end

Classes.DefineClass("ACF.Components.GroundLoader", "ACF.Components.BaseComponent", function()
    CLASS.Name        = "Ground Loader"
    CLASS.Description = "An entity capable of linking to ammo crates and loading racks within line of sight and range. Must be stationary to function."
    CLASS.Model       = "models/props_vehicles/generatortrailer01.mdl"
    CLASS.Mass        = 200
    CLASS.Entity = "acf_groundloader"
    CLASS.CreateMenu = ACF.CreateGroundLoaderMenu
end)