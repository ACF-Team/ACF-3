local Classes     = ACF.Classes
local CrewTypes   = Classes.CrewTypes
local Entries     = Classes.GetOrCreateEntries(CrewTypes)

function CrewTypes.Register(ID, Data)
	local Simple = Classes.AddSimple(ID, Entries, Data)
	if Simple.LimitConVar then Classes.AddSboxLimit(Simple.LimitConVar) end
	return Simple
end

Classes.AddSimpleFunctions(CrewTypes, Entries)
Classes.AddSboxLimit({
	Name   = "_acf_crew",
	Amount = 8,
	Text   = "Maximum amount of ACF crew members a player can create."
})