DEFINE_BASECLASS "acf_base_scalable"

ENT.ACF_Limit      		= 2
ENT.ACF_PreventArmoring = false

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("ACF.Baseplates.BaseplateType", 	"BaseplateType", 			{OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Baseplates.GroundVehicle"})
	MENU_FIELD("Number",  					  	"Width", 					{Min = 36,  Max = 240, Default = 36, Decimals = 2})
	MENU_FIELD("Number",  					  	"Length", 					{Min = 36,  Max = 480, Default = 36, Decimals = 2})
	MENU_FIELD("Number",  					  	"Thickness",				{Min = 0.5,  Max = 3, Default = 1.5, Decimals = 2})
	MENU_FIELD("Boolean", 					  	"DisableAltE",    			{Default = false})
		 FIELD("Entity", 						"Seat",    					{AcceptableClasses = {prop_vehicle_prisoner_pod = true}})
		 FIELD("Boolean", 					  	"AlreadyHasSeat",    		{Default = false})
end, "Baseplate")

ENT.ACF_StaticWireInputs = {
	"Unflip (Triggers an unflip on the baseplate)",
}

ENT.ACF_StaticWireOutputs = {
	"Entity (The entity itself) [ENTITY]",
	"Vehicles (Seat for this entity, compatible with wire) [ARRAY]",
}
AddCSLuaFile("modules/autotest.lua")
include("modules/autotest.lua")()