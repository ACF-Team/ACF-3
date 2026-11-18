-- Controllers saved before 2026-11-17 steered cars with the brake strength when SteerLow and SteerTop were both 0.
ACF.Entities.RegisterCompatPatch("acf_controller", 2026111701, function(Data)
	local DT = Data.DT
	if not DT or (Data.ACF_Version or 0) >= 2026111701 then return end
	if (DT.SteerLow or 0) ~= 0 or (DT.SteerTop or 0) ~= 0 then return end

	DT.SteerLow = DT.BrakeStrength
	DT.SteerTop = DT.BrakeStrengthTop
end)
