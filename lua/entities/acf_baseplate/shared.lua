DEFINE_BASECLASS "acf_base_scalable"

ENT.ACF_Limit      		= 2
ENT.ACF_PreventArmoring = false

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("ACF.Baseplates.BaseplateType", 	"BaseplateType", 			{Title = "#acf.menu.fields.acf_baseplate.baseplate_type", OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Baseplates.GroundVehicle"})
	MENU_FIELD("Number",  					  	"Width", 					{Title = "#acf.menu.fields.acf_baseplate.width", Min = 36,  Max = 240, Default = 36, Decimals = 2})
	MENU_FIELD("Number",  					  	"Length", 					{Title = "#acf.menu.fields.acf_baseplate.length", Min = 36,  Max = 480, Default = 36, Decimals = 2})
	MENU_FIELD("Number",  					  	"Thickness",				{Title = "#acf.menu.fields.acf_baseplate.thickness", Min = 0.5,  Max = 3, Default = 1.5, Decimals = 2})
	MENU_FIELD("Boolean", 					  	"DisableAltE",    			{Title = "#acf.menu.fields.acf_baseplate.disable_alt_e", Default = false})
	MENU_FIELD("Boolean", 					  	"NetworkOptimization",		{Title = "#acf.menu.fields.acf_baseplate.network_optimization", Default = true})
	MENU_FIELD("Boolean", 					  	"UnfreezeOnEntry",    		{Title = "#acf.menu.fields.acf_baseplate.unfreeze_on_entry", Default = false})
		 FIELD("Entity", 						"Seat",    					{AcceptableClasses = {prop_vehicle_prisoner_pod = true}})
		 FIELD("Boolean", 					  	"AlreadyHasSeat",    		{Default = false})
		 FIELD("String", 					  	"SuppressedPasteTests",		{Default = ""}) -- Comma separated autotest IDs to skip on paste
end, "Baseplate")

ENT.ACF_StaticWireInputs = {
	"Unflip (Triggers an unflip on the baseplate)",
}

ENT.ACF_StaticWireOutputs = {
	"Entity (The entity itself) [ENTITY]",
	"Vehicles (Seat for this entity, compatible with wire) [ARRAY]",
	"Seat (The seat/pod of this baseplate) [ENTITY]",
	"Driver (The player currently seated in this baseplate's seat) [ENTITY]",
}
AddCSLuaFile("modules/autotest.lua")
include("modules/autotest.lua")()