DEFINE_BASECLASS("acf_base_scalable")
ACF.SetupENT(ENT)

ENT.PrintName      = "ACF baseplate"
ENT.WireDebugName  = "ACF baseplate"

ENT.ACF_Menu_Model = "models/hunter/blocks/cube075x075x075.mdl"
ENT.ACF_Menu_Description = "Base of all ACF contraptions. Build your vehicle off of this."
ENT.ACF_Limit = 2

ACFDefineEntVar("Type",         "EnumeratedString",     "ACF.Baseplates.GroundVehicleBaseplate", {MustBeAssignableTo = "ACF.Baseplates.BaseplateType"})
ACFDefineEntVar("Size",         "Vector",               Vector(144, 72, 1.5),                    {Min = Vector(36, 36, 0.5), Max = Vector(480, 120, 3)})
ACFDefineEntVar("DisableAltE",  "Bool",                 false,                                   {})
ACFDefineEntVar("LuaSeat",      "StoredEntity",         nil,                                     {Hidden = true})

MsgC(SERVER and Color(255, 0, 255) or Color(0, 255, 255), "[ACF] Loaded baseplate entity: " .. ENT.ACF_Class .. "\n")

print(ACF.GetDataVar("Type", ENT.ACF_Class))