DEFINE_BASECLASS("acf_base_scalable")

ACF.Entities.AutoRegisterV2(function()
	-- Shape is shared by all containers. Size is NOT stored here: each child declares its own size
	-- fields (ammo = projectile counts, supply/fuel = absolute dimensions).
	MENU_FIELD("ACF.ContainerShapes.BaseContainerShape", "Shape", {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.ContainerShapes.Box"})
end, "Container")
