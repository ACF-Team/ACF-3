-- V1 -> V2 migration for acf_piledriver
ACF.Classes.Entities.RegisterCompatPatch("acf_piledriver", 2026061501, function(Data)
	local UD = Data.ACF_UserData
	if not UD then return end
	if type(UD.Weapon) == "table" and UD.Weapon.Type then return end -- Already V2

	-- Resolve caliber from old flat data: explicit Caliber, else an old item Id
	-- ("75mmPD"/"100mmPD"/"150mmPD" or top-level Data.Id), else the 100mm default.
	-- Serialization re-clamps to the field's 50-300 range, so no clamping here.
	local Caliber = tonumber(UD.Caliber)
		or tonumber(string.match(tostring(UD.Id or Data.Id or ""), "%d+"))
		or 100

	UD.Weapon  = { Type = "ACF.Piledrivers.Piledriver", Data = { Caliber = Caliber } }
	UD.Caliber = nil
	UD.Id      = nil
end)
