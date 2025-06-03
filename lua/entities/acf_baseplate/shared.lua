DEFINE_BASECLASS "acf_base_scalable"

ENT.PrintName     = "ACF Baseplate"
ENT.WireDebugName = "ACF Baseplate"
ENT.PluralName    = "ACF Baseplates"
ENT.IsACFEntity = true
ENT.IsACFBaseplate = true

ENT.ACF_UserVars = {
    ["BaseplateType"]  = {Type = "SimpleClass", ClassName = "BaseplateTypes", Default = "GroundVehicle", ClientData = true},
    ["Width"]          = {Type = "Number", Min = 36, Max = 96,  Default = 36, Decimals = 2, ClientData = true},
    ["Length"]         = {Type = "Number", Min = 36, Max = 480, Default = 36, Decimals = 2, ClientData = true},
    ["Thickness"]      = {Type = "Number", Min = 0.5,  Max = 3,   Default = 3,  Decimals = 2, ClientData = true},
    ["Seat"]           = {Type = "LinkedEntity", Classes = {prop_vehicle_prisoner_pod = true}},
    ["AlreadyHasSeat"] = {Type = "Boolean", Default = false}
}