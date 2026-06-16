DEFINE_BASECLASS "acf_base_simple"

ENT.PrintName     = "ACF Ground Loader"
ENT.WireDebugName = "ACF Ground Loader"
ENT.PluralName    = "ACF Ground Loaders"
ENT.IsACFGroundloader = true
ENT.ACF_Limit     = 2

ACF.AutoRegisterV2(function()
	LINKED_ENTITY_ARRAY_FIELD("LinkedAmmoCrates", { AcceptableClasses = { acf_ammo = true } })
end)

local LoadingRadius, ReceivingRadius = 256, 128
return LoadingRadius, ReceivingRadius