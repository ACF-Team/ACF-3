DEFINE_BASECLASS "acf_base_scalable"

ENT.PrintName     = "ACF Baseplate"
ENT.WireDebugName = "ACF Baseplate"
ENT.PluralName    = "ACF Baseplates"
ENT.IsACFEntity = true
ENT.IsACFBaseplate = true

ENT.ACF_DataKeys = {
    ["Width"]     = {Type = "Number", Min = 36, Max = 96,  Default = 36, Decimals = 2},
    ["Length"]    = {Type = "Number", Min = 36, Max = 480, Default = 36, Decimals = 2},
    ["Thickness"] = {Type = "Number", Min = 0.5,  Max = 3,   Default = 3,  Decimals = 2}
}