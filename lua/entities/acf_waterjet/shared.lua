DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Waterjet"
ENT.WireDebugName  = "ACF Waterjet"
ENT.PluralName     = "ACF Waterjets"
ENT.ACF_Limit      = 4
ENT.ACF_PreventArmoring = true

ACF.Entities.AutoRegisterV2(function()
    MENU_FIELD("Number",  					  	"WaterjetSize", 				{Min = 0.5, Max = 2, Default = 1, Decimals = 2})
    MENU_FIELD("String",  					  	"SoundPath", 					{Default = "ambient/machines/spin_loop.wav"})
    MENU_FIELD("Number",  					  	"SoundPitch", 					{Min = 0.1, Max = 2, Default = 1, Decimals = 2})
    MENU_FIELD("Number",  					  	"SoundVolume", 					{Min = 0.1, Max = 1, Default = 0.2, Decimals = 2})
end)

ENT.ACF_StaticWireInputs = {
    "Pitch (Horizontal Steer Angle, -1 to 1)",
    "Yaw (Vertical Steer Angle, -1 to 1)",
}