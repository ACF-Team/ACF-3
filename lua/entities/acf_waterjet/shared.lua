DEFINE_BASECLASS "acf_base_scalable"

ENT.PrintName      = "ACF Waterjet"
ENT.WireDebugName  = "ACF Waterjet"
ENT.PluralName     = "ACF Waterjets"
ENT.ACF_Limit      = 4
ENT.ACF_PreventArmoring = true

-- Maps user var name to its type, whether it is client data and type specific arguments (all support defaults?)
ENT.ACF_UserVars = {
    ["WaterjetSize"]           = {Type = "Number", Min = 0.5,  Max = 2, Default = 1, Decimals = 2, ClientData = true},
}

ENT.ACF_WireInputs = {
    "Pitch (Horizontal Steer Angle)",
    "Yaw (Vertical Steer Angle)",
}

cleanup.Register("acf_waterjet")