ACF.Entities.RegisterCompatPatch("acf_opticalcomputer", 2020060801, function(Data)
	Data.Class = "acf_computer"
end)

local Classes = ACF.Classes

local Lookup = {
	["CPR-Joystick"] = "ACF.Components.Joystick",
	["CPR-OPT"] = "ACF.Components.OpticalGuidanceComputer",
	["CPR-LSR"] = "ACF.Components.LaserGuidanceComputer",
	["CPR-GPS"] = "ACF.Components.GPSTransmitter",
}

local function ComponentFQN(ID)
	if Classes.GetSubtypeByName("ACF.Components.GuidanceComputer", ID) then return ID end -- already an FQN
	return Lookup[ID] or "ACF.Components.LaserGuidanceComputer"
end

ACF.Entities.RegisterCompatPatch("acf_computer", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	local ID  = Data.Computer or Data.Component or Data.Id

	Data.ACF_UserData = {
		Computer = {Type = ComponentFQN(ID), Data = {}},
	}
end)
