local ACF        = ACF
local Classes    = ACF.Classes

function ACF.CreateWaterjetMenu(_, Menu)
    ACF.SetClientData("PrimaryClass", "acf_waterjet")
    ACF.SetClientData("SecondaryClass", "N/A")

    local SizeX = Menu:AddSlider("Size", 0.5, 1, 2)
    SizeX:SetClientData("WaterjetSize", "OnValueChanged")
    SizeX:DefineSetter(function(Panel, _, _, Value)
        local X = math.Round(Value, 2)

        Panel:SetValue(X)

        if Menu.ComponentPreview then
            Menu.ComponentPreview:SetModelScale(X, true)
        end
    end)
end

Classes.DefineClass("ACF.Components.Waterjet", "ACF.Components.BaseComponent", function()
    CLASS.Name        = "Water Jet"
    CLASS.Description  = "Entity capable of aiding with movement in water."
    CLASS.Model        = "models/maxofs2d/hover_propeller.mdl"
    CLASS.Entity       = "acf_waterjet"
    CLASS.TutorialURL  = "docs/acf_tutorials/waterjets.html"
    CLASS.CreateMenu   = ACF.CreateWaterjetMenu
end)
