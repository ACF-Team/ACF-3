DEFINE_BASECLASS("acf_base_simple")

ACF.Entities.AutoRegister(2026091001, function(CLASS)
	MENU_FIELD("String",  "CrewTypeID",                {Title = "#acf.menu.fields.acf_crew.crew_type_id", Default = "Commander"})
	MENU_FIELD("String",  "CrewModelID",               {Title = "#acf.menu.fields.acf_crew.crew_model_id", Default = "Sitting"})
	MENU_FIELD("String",  "CrewPoseID",                {Title = "#acf.menu.fields.acf_crew.crew_pose_id", Default = ""})
	MENU_FIELD("Boolean", "ReplaceOthers",             {Title = "#acf.menu.fields.acf_crew.replace_others", Default = true})
	MENU_FIELD("Boolean", "ReplaceSelf",               {Title = "#acf.menu.fields.acf_crew.replace_self", Default = true})
	MENU_FIELD("Boolean", "ReplacedOnlyLower",         {Title = "#acf.menu.fields.acf_crew.replaced_only_lower", Default = false})
	MENU_FIELD("Boolean", "UseAnimation",              {Title = "#acf.menu.fields.acf_crew.use_animation", Default = false})
	MENU_FIELD("Number",  "CrewPriority",              {Title = "#acf.menu.fields.acf_crew.crew_priority", Min = ACF.CrewRepPrioMin, Max = ACF.CrewRepPrioMax, Default = 1, Decimals = 0})
	MENU_FIELD("String",  "CrewPlayerModel",           {Title = "#acf.menu.fields.acf_crew.crew_player_model", Default = "models/player/dod_german.mdl"})
	MENU_FIELD("String",  "CrewPlayerModelBodygroups", {Title = "#acf.menu.fields.acf_crew.crew_player_model_bodygroups", Default = ""})
	MENU_FIELD("Number",  "CrewPlayerModelSkin",       {Title = "#acf.menu.fields.acf_crew.crew_player_model_skin", Min = 0, Max = 63, Default = 0, Decimals = 0})
	LINKED_ENTITY_ARRAY_FIELD("Targets",               {WarnOnLinkFail = true})

	function CLASS:VerifyData()
	end
end, "Crew", "Crews")

ENT.ConvexMaterial = "Flesh"
ENT.ACF_DestroyedLabel = "Dead"
ENT.ACF_RequiresParentChain = true

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
