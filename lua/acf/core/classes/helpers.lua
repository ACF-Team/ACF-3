local Classes = ACF.Classes
Classes.SboxLimits = Classes.SboxLimits or {}

--- Adds an sbox limit for this class
--- @param Data {Name:string, Amount:number, Text:string}
function Classes.AddSboxLimit(Data)
	-- Add the limit to a list to be used in the settings menu
	if CLIENT then
		Classes.SboxLimits[Data.Name] = Data

		return
	end

	local ConVarName = "sbox_max" .. Data.Name

	if ConVarExists(ConVarName) then return end

	CreateConVar(ConVarName,
				Data.Amount,
				FCVAR_ARCHIVE + FCVAR_NOTIFY,
				Data.Text or "",
				Data.Min or 0,
				Data.Max)
end

--- Gets or creates an entries table.
--- Requires that the class-type defines GetStored
function Classes.GetOrCreateEntries(Namespace)
	if not Namespace then ErrorNoHaltWithStack("ACF.Classes.GetOrCreateEntries: Got nil Namespace!") return end

	if Namespace.GetStored then
		return Namespace.GetStored() or {}
	end

	return {}
end