DEFINE_BASECLASS("acf_base_simple")

ACF.Entities.AutoRegisterV2(function()
	-- Crew classes (type/model/pose) are V2 DefineClass subtypes addressed by their short id (the FQN
	-- suffix); the entity stores the ids and resolves the classes at runtime (see init.lua).
	MENU_FIELD("String",  "CrewTypeID",                {Default = "Commander"})
	MENU_FIELD("String",  "CrewModelID",               {Default = "Sitting"})
	MENU_FIELD("String",  "CrewPoseID",                {Default = ""})
	MENU_FIELD("Boolean", "ReplaceOthers",             {Default = true})
	MENU_FIELD("Boolean", "ReplaceSelf",               {Default = true})
	MENU_FIELD("Boolean", "UseAnimation",              {Default = false})
	MENU_FIELD("Number",  "CrewPriority",              {Min = ACF.CrewRepPrioMin, Max = ACF.CrewRepPrioMax, Default = 1, Decimals = 0})
	MENU_FIELD("String",  "CrewPlayerModel",           {Default = "models/player/dod_german.mdl"})
	MENU_FIELD("String",  "CrewPlayerModelBodygroups", {Default = ""})
	MENU_FIELD("Number",  "CrewPlayerModelSkin",       {Min = 0, Max = 63, Default = 0, Decimals = 0})

	function CLASS:VerifyData()
	end
end, "Crew", "Crews")

ENT.ACF_StaticWireOutputs = {
	"ModelEff",
	"LeanEff",
	"SpaceEff",
	"HealthEff",
	"MoveEff",
	"TotalEff",
	"Oxygen (Seconds of breath left before drowning)",
	"GForce (The strength of GForce experienced)",
	"Stamina (The stamina of the crew member)",
	"Entity (The crew entity itself) [ENTITY]",
}
