local Classes = ACF.Classes

--- Adds an sbox limit for this class
--- @param Data {Name:string, Amount:number, Text:string}
function Classes.AddSboxLimit(Data)
	if CLIENT then return end

	local ConVarName = "sbox_max" .. Data.Name

	if ConVarExists(ConVarName) then return end

	CreateConVar(ConVarName,
				Data.Amount,
				FCVAR_ARCHIVE + FCVAR_NOTIFY,
				Data.Text or "")
end

--- Gets or creates an entries table.
--- Requires that the class-type defines GetStored
function Classes.GetOrCreateEntries(Namespace)
	if Namespace.GetStored then
		return Namespace.GetStored() or {}
	end

	return {}
end