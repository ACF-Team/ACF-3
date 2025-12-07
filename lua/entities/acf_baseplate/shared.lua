DEFINE_BASECLASS "acf_base_scalable"

ENT.PrintName      = "ACF Baseplate"
ENT.WireDebugName  = "ACF Baseplate"
ENT.PluralName     = "ACF Baseplates"
ENT.IsACFBaseplate = true
ENT.ACF_Limit      = 2
ENT.ACF_PreventArmoring = false

-- Maps user var name to its type, whether it is client data and type specific arguments (all support defaults?)
ENT.ACF_UserVars = {
    ["BaseplateType"]  = {Type = "SimpleClass",  ClassName = "BaseplateTypes", Default = "GroundVehicle", ClientData = true},
    ["Width"]          = {Type = "Number",       Min = 36,  Max = 120, Default = 36, Decimals = 2, ClientData = true},
    ["Length"]         = {Type = "Number",       Min = 36,  Max = 480, Default = 36, Decimals = 2, ClientData = true},
    ["Thickness"]      = {Type = "Number",       Min = 0.5, Max = 3,   Default = 3,  Decimals = 2, ClientData = true},
    ["DisableAltE"]    = {Type = "Boolean",      Default = false, ClientData = true},
    ["Seat"]           = {Type = "LinkedEntity", Classes = {prop_vehicle_prisoner_pod = true}},
    ["AlreadyHasSeat"] = {Type = "Boolean",      Default = false},
    ["GForceTicks"]    = {Type = "Number",       Min = 1,   Max = 7,   Default = 1,  Decimals = 0, ClientData = true},
}

ENT.ACF_WireOutputs = {
    "Entity (The entity itself) [ENTITY]",
    "Vehicles (Seat for this entity, compatible with wire) [ARRAY]",
}

cleanup.Register("acf_baseplate")