-- Controllers saved before 2026-11-17 steered cars with the brake strength when SteerLow and SteerTop were both 0.
ACF.Entities.RegisterCompatPatch("acf_controller", 2026111701, function(Data)
	local DT = Data.DT
	if not DT or (Data.ACF_Version or 0) >= 2026111701 then return end
	if (DT.SteerLow or 0) ~= 0 or (DT.SteerTop or 0) ~= 0 then return end

	DT.SteerLow = DT.BrakeStrength
	DT.SteerTop = DT.BrakeStrengthTop
end)

local SingleLinks = {"Seat", "Gearbox", "Baseplate", "TurretComputer", "GuidanceComputer", "Radar"}
local ArrayLinks  = {"SteerPlates", "Turrets", "Guns", "Racks", "Receivers"}

ACF.Entities.RegisterCompatPatch("acf_controller", 2026111801, function(Data)
	local Move = ACF.Entities.MoveLinkModToUserData

	for _, Field in ipairs(SingleLinks) do Move(Data, Field, Field, true) end
	for _, Field in ipairs(ArrayLinks) do Move(Data, Field, Field) end

	local EntityMods = Data.EntityMods
	if not istable(EntityMods) then return end

	local UserData = istable(Data.ACF_UserData) and Data.ACF_UserData or {}
	Data.ACF_UserData = UserData

	local function MoveSlots(ModName, Prefix, Suffix)
		local Slots = EntityMods[ModName]
		EntityMods[ModName] = nil

		if not istable(Slots) then return end

		for Slot = 1, 3 do
			local Field = Prefix .. Slot .. Suffix

			if UserData[Field] == nil and isnumber(Slots[Slot]) then UserData[Field] = Slots[Slot] end
		end
	end

	MoveSlots("CamParents", "Cam", "Parent")
	MoveSlots("Guns123", "Gun", "")
end)
