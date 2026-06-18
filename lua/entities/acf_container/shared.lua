DEFINE_BASECLASS("acf_base_scalable")

ACF.AutoRegisterV2(function()
    local MinSize, MaxSize = ACF.ContainerMinSize, ACF.ContainerMaxSize
    MENU_FIELD("Vector", "Size", { Min = MinSize, Max = MaxSize, Default = 24, Decimals = 0 })
    MENU_FIELD("ACF.ContainerShapes.BaseContainerShape", "Shape", { OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.ContainerShapes.Box" })
end, "Container")