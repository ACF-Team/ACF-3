DEFINE_BASECLASS "acf_base_scalable"

ENT.PrintName      		= "ACF Baseplate"
ENT.WireDebugName  		= "ACF Baseplate"
ENT.PluralName     		= "ACF Baseplates"
ENT.IsACFBaseplate 		= true
ENT.ACF_Limit      		= 2
ENT.ACF_PreventArmoring = false

ACF.AutoRegisterV2(function()
	MENU_FIELD("ACF.Baseplates.BaseplateType", "BaseplateType", 			{InstantiateTypeForDefault = "ACF.Baseplates.GroundVehicle"})
	MENU_FIELD("Number",  					  	"Width", 					{Min = 36,  Max = 240, Default = 36, Decimals = 2})
	MENU_FIELD("Number",  					  	"Width", 					{Min = 36,  Max = 480, Default = 36, Decimals = 2})
	MENU_FIELD("Number",  					  	"Thickness",				{Min = 0.5,  Max = 3, Default = 3, Decimals = 2})
	MENU_FIELD("Boolean", 					  	"DisableAltE",    			{Default = false})
	MENU_FIELD("Boolean", 					  	"ExplodeOnCollisions",    	{Default = false})
		 FIELD("Seat", 					  		"Entity",    				{AcceptableClasses = {prop_vehicle_prisoner_pod = true}})
		 FIELD("Boolean", 					  	"AlreadyHasSeat",    		{Default = false})
	MENU_FIELD("Number",  					  	"GForceTicks",				{Min = 1,  Max = 7, Default = 1, Decimals = 0})
end)

ENT.ACF_StaticWireInputs = {
	"Unflip (Triggers an unflip on the baseplate)",
}

ENT.ACF_StaticWireOutputs = {
	"Entity (The entity itself) [ENTITY]",
	"Vehicles (Seat for this entity, compatible with wire) [ARRAY]",
}

AddCSLuaFile("modules/autotest.lua")
include("modules/autotest.lua")()

cleanup.Register("acf_baseplate")
