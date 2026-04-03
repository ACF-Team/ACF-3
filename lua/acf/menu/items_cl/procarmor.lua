local ACF = ACF
-- local ProcArmorTypes = ACF.Classes.ProcArmorTypes

local function CreateMenu(Menu)
    ACF.SetToolMode("acf_menu", "Spawner", "ProcArmor")
    ACF.SetClientData("PrimaryClass", "acf_procarmor")
    ACF.SetClientData("SecondaryClass", "N/A")

    local VerificationCtx = ACF.Classes.Entities.VerificationContext("acf_procarmor")
    VerificationCtx:StartClientData(ACF.GetAllClientData(true))

    Menu:AddTitle("Procedural Armor")

    Menu:AddLabel("Configure size and material of the armor block.")

    Menu:AddSimpleClassUserVar(VerificationCtx, "", "ArmorType", "Name", "Icon")

    local Length = Menu:AddNumberUserVar(VerificationCtx, "ProcLength", "ProcLength")
    local Width  = Menu:AddNumberUserVar(VerificationCtx, "ProcWidth",  "ProcWidth")
    local Height = Menu:AddNumberUserVar(VerificationCtx, "ProcHeight", "ProcHeight")

    -- Preview
    local Preview = Menu:AddModelPreview("models/holograms/cube.mdl", true, "Primary")

    Preview:UpdateSettings({
        FOV = 120,
        Height = 120,
        AngOffset = Angle(0, -90, 0),
    })

    Preview:UpdateModel("models/holograms/cube.mdl", "hunter/myplastic")

    local function UpdatePreview()
        local L = Length:GetValue()
        local W = Width:GetValue()
        local H = Height:GetValue()

        Preview:SetModelScale(Vector(L, W, H))
    end

    local function OnUpdate(self, _, producer)
        if self == producer then
            UpdatePreview()
        end
    end

    Length.ACF_OnUpdate = OnUpdate
    Width.ACF_OnUpdate  = OnUpdate
    Height.ACF_OnUpdate = OnUpdate

    UpdatePreview()
end

ACF.AddMenuItem(60, "#acf.menu.entities", "Procedural Armor", "brick", CreateMenu)