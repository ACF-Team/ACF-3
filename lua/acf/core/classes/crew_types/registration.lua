local Classes = ACF.Classes
local CrewTypes   = Classes.CrewTypes
local Entries = {}

CreateConVar(
	"sbox_max_acf_crew",
	8,
	FCVAR_ARCHIVE + FCVAR_NOTIFY,
	"Maximum amount of ACF crew members a player can create."
)

function CrewTypes.Register(ID, Data)
	local Simple = Classes.AddSimple(ID, Entries, Data)
	if Simple.LimitConVar then Classes.AddSboxLimit(Simple.LimitConVar) end
	return Simple
end

Classes.AddSimpleFunctions(CrewTypes, Entries)