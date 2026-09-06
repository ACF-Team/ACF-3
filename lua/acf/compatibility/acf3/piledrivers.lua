ACF.Entities.RegisterCompatPatch("acf_piledriver", 2026061501, function(Data)
	local UD = Data.ACF_UserData
	if not UD then return end
	if type(UD.Weapon) == "table" and UD.Weapon.Type then return end -- Already V2

	local OldId   = UD.Id or Data.Id or (isstring(UD.Weapon) and UD.Weapon) or ""
	local Caliber = tonumber(UD.Caliber)
		or tonumber(string.match(tostring(OldId), "%d+"))
		or 100

	UD.Weapon  = { Type = "ACF.Piledrivers.Piledriver", Data = { Caliber = Caliber } }
	UD.Caliber = nil
	UD.Id      = nil
end)
