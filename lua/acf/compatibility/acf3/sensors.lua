local Classes  = ACF.Classes
local Entities = ACF.Entities

local Defaults = {
	acf_radar    = "ACF.Sensors.Radar.Standard.SmallDirectional",
	acf_receiver = "ACF.Sensors.Receiver.Warning.Laser",
}

-- Missile and targeting radars were merged into one Radar class set on August 17th, 2026.
-- Old antimissile radars only saw missiles and old targeting radars only saw contraptions, so each
-- old ID maps to its merged item plus the detection flags that keep an old dupe behaving as it did.
local AntimissileDetect = { DetectContraptions = false, DetectMissiles = true }
local TargetingDetect   = { DetectContraptions = true,  DetectMissiles = false }

local PreMergeRadars = {
	["SmallDIR-AM"]   = { ID = "SmallDIR",   Detect = AntimissileDetect },
	["SmallDIR-TGT"]  = { ID = "SmallDIR",   Detect = TargetingDetect },
	["MediumDIR-AM"]  = { ID = "MediumDIR",  Detect = AntimissileDetect },
	["MediumDIR-TGT"] = { ID = "MediumDIR",  Detect = TargetingDetect },
	["LargeDIR-AM"]   = { ID = "LargeDIR",   Detect = AntimissileDetect },
	["LargeDIR-TGT"]  = { ID = "LargeDIR",   Detect = TargetingDetect },

	["SmallOMNI-AM"]   = { ID = "SmallOMNI",  Detect = AntimissileDetect },
	["SmallOMNI-TGT"]  = { ID = "SmallOMNI",  Detect = TargetingDetect },
	["MediumOMNI-AM"]  = { ID = "MediumOMNI", Detect = AntimissileDetect },
	["MediumOMNI-TGT"] = { ID = "MediumOMNI", Detect = TargetingDetect },
	["LargeOMNI-AM"]   = { ID = "LargeOMNI",  Detect = AntimissileDetect },
	["LargeOMNI-TGT"]  = { ID = "LargeOMNI",  Detect = TargetingDetect },
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

local function Convert(Data, ClassName, DefaultOverride, DefaultDetect)
	local UD = Data.ACF_UserData
	if type(UD) == "table" and type(UD.Sensor) == "table" and UD.Sensor.Type then return end -- Already V2

	if not IDMap then IDMap = BuildIDMap() end

	local Old =
		(UD and (UD.Radar or UD.Receiver or UD.Sensor or UD.Id)) or
		Data.Radar or Data.Receiver or Data.Sensor or Data.Id

	-- Pre-merge radar IDs resolve to their merged item and carry their old detection capability
	local Detect = DefaultDetect
	local PreMerge = isstring(Old) and PreMergeRadars[Old]

	if PreMerge then
		Old = PreMerge.ID
		Detect = PreMerge.Detect
	end

	local FQN = (isstring(Old) and IDMap[Old]) or DefaultOverride or Defaults[ClassName]

	UD = UD or {}
	UD.Sensor = { Type = FQN, Data = {} }
	UD.Radar, UD.Receiver, UD.Id = nil, nil, nil

	if Detect then
		UD.DetectContraptions = Detect.DetectContraptions
		UD.DetectMissiles     = Detect.DetectMissiles
	end

	Data.ACF_UserData = UD
end

Entities.RegisterCompatPatch("acf_radar",    2026061601, function(Data) Convert(Data, "acf_radar") end)
Entities.RegisterCompatPatch("acf_receiver", 2026061601, function(Data) Convert(Data, "acf_receiver") end)

Entities.RegisterCompatPatch("acf_missileradar", 2026061601, function(Data)
	Data.Class = "acf_radar"
	Convert(Data, "acf_radar", Defaults.acf_radar, AntimissileDetect)
end)
