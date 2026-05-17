DEFINE_BASECLASS "acf_base_simple"

ENT.PrintName     = "ACF Ground Loader"
ENT.WireDebugName = "ACF Ground Loader"
ENT.PluralName    = "ACF Ground Loaders"
ENT.IsACFEntity = true
ENT.IsACFBaseplate = true

ENT.ACF_UserVars = {
    ["LinkedAmmoCrates"] = {Type = "LinkedEntities", Classes = {acf_ammo = true}},
}

local LoadingRadius, ReceivingRadius = 256, 128
return LoadingRadius, ReceivingRadius