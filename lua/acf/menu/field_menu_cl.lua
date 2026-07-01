function ACF.Classes.CreateTypeSelector(Menu, ClassDef, FieldName)
    local FieldDef = ACF.Classes.GetTypeFieldByName(ClassDef, FieldName)
    if not FieldDef then return end

    local SubTypes = ACF.Classes.GetSubtypes(FieldDef.Type)
    local Handle   = { ComboBox = nil, OnTypeChanged = nil }

    local NestedData     = {}
    local SelectedTypeID = nil

    local ComboBox = Menu:AddComboBox()
    Handle.ComboBox = ComboBox

    local SubPanel = Menu:AddPanel("ACF_Panel")

    local function PushClientData()
        if not SelectedTypeID then return end
        ACF.SetClientData(FieldName, { Type = SelectedTypeID, Data = NestedData })
    end

    function ComboBox:OnSelect(_, _, TypeObj)
        if self.Selected == TypeObj then return end
        self.Selected = TypeObj

        SubPanel:ClearAll()

        SelectedTypeID = TypeObj.ID

        local OldData = NestedData
        NestedData    = {}
        for _, Field in ipairs(ACF.Classes.GetTypeFields(TypeObj)) do
            local Val = OldData[Field.Name]
            if Val == nil then Val = Field.Options.Default end
            if Val ~= nil then NestedData[Field.Name] = Val end
        end

        if TypeObj.CreateMenu then
            TypeObj.CreateMenu(SubPanel, NestedData, PushClientData)
        end

        PushClientData()
        SubPanel:InvalidateParent()

        if Handle.OnTypeChanged then
            Handle.OnTypeChanged(TypeObj)
        end

        self:GetParent():InvalidateLayout()
    end

    ACF.LoadSortedList(ComboBox, SubTypes, "Name", "Icon")

    local Saved         = ACF.ClientData[FieldName]
    local InitialTypeID = FieldDef.Options.InstantiateTypeForDefault

    if type(Saved) == "table" and Saved.Type then
        InitialTypeID = Saved.Type
        NestedData    = type(Saved.Data) == "table" and table.Copy(Saved.Data) or {}
    end

    if ComboBox.ListData then
        local SelectIdx = 1
        for I, TypeObj in ipairs(ComboBox.ListData.Choices) do
            if TypeObj.ID == InitialTypeID then
                SelectIdx = I
                break
            end
        end
        ComboBox:ChooseOptionID(SelectIdx)
    end

    return Handle
end
