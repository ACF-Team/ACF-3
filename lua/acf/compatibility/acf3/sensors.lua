local Classes  = ACF.Classes
local Entities = Classes.Entities

local Defaults = {
	acf_radar    = "ACF.Sensors.Radar.Targeting.SmallDirectional",
	acf_receiver = "ACF.Sensors.Receiver.Warning.Laser",
}

local IDMap

local function BuildIDMap()
	local Map = {}

	for _, Class in pairs(Classes.GetSubtypes("ACF.Sensors.Sensor")) do
		if Class.ID and not next(Classes.GetChildren(Class)) then
			Map[Class.ID] = Classes.GetTypeName(Class)
		end
	end

	return Map
end

local function Convert(Data, ClassName, DefaultOverride)
	local UD = Data.ACF_UserData
	if type(UD) == "table" and type(UD.Sensor) == "table" and UD.Sensor.Type then return end -- Already V2

	if not IDMap then IDMap = BuildIDMap() end

	local Old =
		(UD and (UD.Radar or UD.Receiver or UD.Sensor or UD.Id)) or
		Data.Radar or Data.Receiver or Data.Sensor or Data.Id

	if not Old and type(Data.Data) == "table" then
		local D = Data.Data
		Old = D.Radar or D.Receiver or D.Sensor or D.Id
	end

	local FQN = (isstring(Old) and IDMap[Old]) or DefaultOverride or Defaults[ClassName]

	UD = UD or {}
	UD.Sensor = { Type = FQN, Data = {} }
	UD.Radar, UD.Receiver, UD.Id = nil, nil, nil

	Data.ACF_UserData = UD
end

Entities.RegisterCompatPatch("acf_radar",    2026061601, function(Data) Convert(Data, "acf_radar") end)
Entities.RegisterCompatPatch("acf_receiver", 2026061601, function(Data) Convert(Data, "acf_receiver") end)

Entities.RegisterCompatPatch("acf_missileradar", 2026061601, function(Data)
	Data.Class = "acf_radar"
	Convert(Data, "acf_radar", "ACF.Sensors.Radar.Missile.SmallDirectional")
end)
