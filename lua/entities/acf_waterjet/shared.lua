DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Waterjet"
ENT.WireDebugName  = "ACF Waterjet"
ENT.PluralName     = "ACF Waterjets"
ENT.ACF_Limit      = 4
ENT.ACF_PreventArmoring = true

-- Maps user var name to its type, whether it is client data and type specific arguments (all support defaults?)
ENT.ACF_UserVars = {
    ["WaterjetSize"] = {Type = "Number", Min = 0.5, Max = 2, Default = 1, Decimals = 2, ClientData = true},
    ["SoundPath"] = {Type = "String", Default = "ambient/machines/spin_loop.wav"},
    ["SoundPitch"] = {Type = "Number", Min = 0.1, Max = 2, Default = 1, Decimals = 2},
    ["SoundVolume"] = {Type = "Number", Min = 0.1, Max = 1, Default = 0.2, Decimals = 2},
}

ENT.ACF_WireInputs = {
    "Pitch (Horizontal Steer Angle, -1 to 1)",
    "Yaw (Vertical Steer Angle, -1 to 1)",
}

cleanup.Register("acf_waterjet")