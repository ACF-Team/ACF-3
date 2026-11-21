local Classes  = ACF.Classes
local Entities = ACF.Entities

-- Legacy turret components stored their selection as a flat item-id string on a
-- dupe key (e.g. "Turret"/"Motor", or "Id" on much older dupes), with any tunables
-- as sibling flat keys. V2 stores a nested class instance under ACF_UserData[Field]
-- plus the tunables as sibling fields, so we translate the old id to the new FQN.

local IDMap -- legacy item id -> new class FQN, built lazily once the classes exist

local function BuildIDMap()
	local Map = {}

	for _, Class in pairs(Classes.GetSubtypes("ACF.Turrets.Component")) do
		-- Only leaf items are selectable; the group/base classes also carry an ID.
		if Class.ID and not next(Classes.GetChildren(Class)) then
			Map[Class.ID] = Classes.GetTypeName(Class)
		end
	end

	return Map
end

-- Finds the first present value among Keys, checking ACF_UserData, then the dupe
-- table top level, then the legacy nested Data table.
local function ResolveOld(Data, Keys)
	local UD = Data.ACF_UserData

	if UD then
		for _, Key in ipairs(Keys) do
			if UD[Key] ~= nil then return UD[Key] end
		end
	end

	for _, Key in ipairs(Keys) do
		if Data[Key] ~= nil then return Data[Key] end
	end
end

local function MakeConverter(Field, DefaultFQN, NumberFields)
	return function(Data)
		local UD = Data.ACF_UserData
		if UD and type(UD[Field]) == "table" and UD[Field].Type then return end -- Already V2

		if not IDMap then IDMap = BuildIDMap() end

		local Old = ResolveOld(Data, {Field, "Id", "ID"})
		local FQN = (isstring(Old) and IDMap[Old]) or DefaultFQN

		UD = UD or {}
		UD[Field] = { Type = FQN, Data = {} }

		for _, Key in ipairs(NumberFields) do
			local Value = ResolveOld(Data, {Key})
			if Value ~= nil then UD[Key] = Value end
		end

		Data.ACF_UserData = UD
	end
end

Entities.RegisterCompatPatch("acf_turret",          2026061701, MakeConverter("Turret",   "ACF.Turrets.Drive.Horizontal", {"RingSize", "MinDeg", "MaxDeg", "MaxSpeed"}))
Entities.RegisterCompatPatch("acf_turret_motor",    2026061701, MakeConverter("Motor",    "ACF.Turrets.Motor.Electric",   {"CompSize", "Teeth"}))
Entities.RegisterCompatPatch("acf_turret_gyro",     2026061701, MakeConverter("Gyro",     "ACF.Turrets.Gyro.Single",      {}))
Entities.RegisterCompatPatch("acf_turret_computer", 2026061701, MakeConverter("Computer", "ACF.Turrets.Computer.Direct",   {}))

Entities.RegisterCompatPatch("acf_turret", 2026111801, function(Data)
	Entities.MoveLinkModToUserData(Data, "ACFMotor", "Motor", true)
	Entities.MoveLinkModToUserData(Data, "ACFGyro", "Gyro", true)
	Entities.MoveLinkModToUserData(Data, "ACFRadar", "Radar", true)
	Entities.MoveLinkModToUserData(Data, "ACFLightweightControllers", "LightweightControllers")
end)

Entities.RegisterCompatPatch("acf_turret_computer", 2026111801, function(Data)
	Entities.MoveLinkModToUserData(Data, "ACFGun", "Gun", true)
end)

Entities.RegisterCompatPatch("acf_turret_controller", 2026111801, function(Data)
	Entities.MoveLinkModToUserData(Data, "ACFCrew", "Crew", true)
end)
