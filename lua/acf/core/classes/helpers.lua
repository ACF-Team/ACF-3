local Classes = ACF.Classes
Classes.SboxLimits = Classes.SboxLimits or {}

--- Adds an sbox limit for this class
--- @param Data {Name:string, Amount:number, Text:string, LegacyDefault:number}
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

	-- Because this convar is FCVAR_ARCHIVE, servers that ran a previous version can have
	-- the old default baked into their config, which will silently override Data.Amount above.
	-- If the stored value still matches the old (higher) default, assume it was never
	-- deliberately configured and migrate it down to the new default.
	if Data.LegacyDefault then
		local CVar = GetConVar(ConVarName)

		if CVar:GetInt() == Data.LegacyDefault then
			CVar:SetInt(Data.Amount)
		end
	end
end