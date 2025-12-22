DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Autoloader"
ENT.WireDebugName  = "ACF Autoloader"
ENT.PluralName     = "ACF Autoloaders"
ENT.ACF_Limit      = 2
ENT.ACF_PreventArmoring = true

-- Maps user var name to its type, whether it is client data and type specific arguments (all support defaults?)
ENT.ACF_UserVars = {
    ["AutoloaderCaliber"] = {Type = "Number", Min = ACF.MinAutoloaderCaliber, Max = ACF.MaxAutoloaderCaliber, Default = 1, Decimals = 2, ClientData = true},
    ["AutoloaderLength"] = {Type = "Number", Min = ACF.MinAutoloaderLength, Max = ACF.MaxAutoloaderLength, Default = 1, Decimals = 2, ClientData = true},
}

cleanup.Register("acf_autoloader")