DEFINE_BASECLASS("base_wire_entity")
ACF.SetupENT(ENT)

ENT.PrintName     = "Simple ACF Base Entity"
ENT.WireDebugName = "Simple ACF Base Entity"
ENT.PluralName    = "Simple ACF Base Entities"
ENT.IsACFEntity   = true
ENT.ACF_PreventArmoring = true

MsgC(SERVER and Color(255, 0, 255) or Color(0, 255, 255), "[ACF] Loaded simple base entity: " .. ENT.ACF_Class .. "\n")
