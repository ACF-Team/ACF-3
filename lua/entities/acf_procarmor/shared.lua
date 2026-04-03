DEFINE_BASECLASS "acf_base_scalable"

ENT.PrintName     = "ACF Procedural Armor"
ENT.WireDebugName = "ACF Proc Armor"
ENT.PluralName    = "ACF Procedural Armor"
ENT.IsACFProcArmor = true
ENT.IsACFEntity = true
ENT.ACF_Limit     = 16

-- User variables
ENT.ACF_UserVars = {
    ["ArmorType"]  = { Type = "SimpleClass", ClassName = "ProcArmorTypes", Default = "RHA" },
    ["ProcLength"] = { Type = "Number", Min = 1, Max = 480, Default = 36, Decimals = 2 },
    ["ProcWidth"]  = { Type = "Number", Min = 1, Max = 480, Default = 36, Decimals = 2 },
    ["ProcHeight"] = { Type = "Number", Min = 1, Max = 480, Default = 36, Decimals = 2 },
}

ENT.ACF_WireOutputs = {
    "Entity (The entity itself) [ENTITY]",
}

cleanup.Register("acf_procarmor")