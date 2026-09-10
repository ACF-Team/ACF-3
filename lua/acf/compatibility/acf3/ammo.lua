local GetType = ACF.Classes.GetTypeByName

local function ShapeFQN(ID)
	local FQN = "ACF.ContainerShapes." .. tostring(ID)
	return GetType(FQN) and FQN or "ACF.ContainerShapes.Box"
end

local function AmmoFQN(ID)
	if GetType(ID) then return ID end -- already an FQN
	local FQN = "ACF.Ammunition." .. tostring(ID)
	return GetType(FQN) and FQN or "ACF.Ammunition.AP"
end

local WeaponFQNTable = {
	["AC"] = "ACF.Guns.Autocannon",
	["C"] = "ACF.Guns.Cannon",
	["FGL"] = "ACF.Guns.FlareLauncher",
	["GL"] = "ACF.Guns.GrenadeLauncher",
	["HW"] = "ACF.Guns.Howitzer",
	["LAC"] = "ACF.Guns.LightAutocannon",
	["MG"] = "ACF.Guns.Machinegun",
	["MO"] = "ACF.Guns.Mortar",
	["RAC"] = "ACF.Guns.RotaryAutocannon",
	["SA"] = "ACF.Guns.SemiautomaticCannon",
	["SC"] = "ACF.Guns.ShortBarrelledCannon",
	["SL"] = "ACF.Guns.SmokeLauncher",

	["AIM-9 AAM"] = "ACF.Missiles.AirToAir.AIM-9",
	["AIM-120 AAM"] = "ACF.Missiles.AirToAir.AIM-120",
	["AIM-7 AAM"] = "ACF.Missiles.AirToAir.AIM-7",
	["AIM-54 AAM"] = "ACF.Missiles.AirToAir.AIM-54",

	["AGM-122 ASM"] = "ACF.Missiles.AntiRadiation.AGM-122",
	["AGM-45 ASM"] = "ACF.Missiles.AntiRadiation.AGM-45",

	["Type 63 RA"] = "ACF.Missiles.Artillery.Type63",
	["SAKR-10 RA"] = "ACF.Missiles.Artillery.SAKR-10",
	["SS-40 RA"] = "ACF.Missiles.Artillery.SS-40",

	["AT-3 ASM"] = "ACF.Missiles.AntiTankGuided.AT-3",
	["BGM-71E ASM"] = "ACF.Missiles.AntiTankGuided.BGM-71E",
	["AGM-114 ASM"] = "ACF.Missiles.AntiTankGuided.AGM-114",
	["Ataka ASM"] = "ACF.Missiles.AntiTankGuided.Ataka",
	["9M133 ASM"] = "ACF.Missiles.AntiTankGuided.9M133",
	["AT-2 ASM"] = "ACF.Missiles.AntiTankGuided.AT-2",

	["50kgBOMB"] = "ACF.Missiles.FreeFallingBomb.50kgBOMB",
	["100kgBOMB"] = "ACF.Missiles.FreeFallingBomb.100kgBOMB",
	["250kgBOMB"] = "ACF.Missiles.FreeFallingBomb.250kgBOMB",
	["500kgBOMB"] = "ACF.Missiles.FreeFallingBomb.500kgBOMB",
	["1000kgBOMB"] = "ACF.Missiles.FreeFallingBomb.1000kgBOMB",

	["40mmFFAR"] = "ACF.Missiles.FoldingFinRocket.40mmFFAR",
	["57mmFFAR"] = "ACF.Missiles.FoldingFinRocket.57mmFFAR",
	["70mmFFAR"] = "ACF.Missiles.FoldingFinRocket.70mmFFAR",
	["80mmFFAR"] = "ACF.Missiles.FoldingFinRocket.80mmFFAR",
	["Zuni ASR"] = "ACF.Missiles.FoldingFinRocket.Zuni",

	["100kgGBOMB"] = "ACF.Missiles.GlidingBomb.100kgGBOMB",
	["250kgGBOMB"] = "ACF.Missiles.GlidingBomb.250kgGBOMB",

	["WalleyeGBU"] = "ACF.Missiles.GuidedBomb.WalleyeGBU",
	["227kgGBU"] = "ACF.Missiles.GuidedBomb.227kgGBU",
	["454kgGBU"] = "ACF.Missiles.GuidedBomb.454kgGBU",
	["909kgGBU"] = "ACF.Missiles.GuidedBomb.909kgGBU",

	["FIM-92 SAM"] = "ACF.Missiles.SurfaceToAir.FIM-92",
	["Strela-1 SAM"] = "ACF.Missiles.SurfaceToAir.Strela-1",

	["RS82 ASR"] = "ACF.Missiles.UnguidedRocket.RS82",
	["HVAR ASR"] = "ACF.Missiles.UnguidedRocket.HVAR",
	["SPG-9 ASR"] = "ACF.Missiles.UnguidedRocket.SPG-9",
	["S-24 ASR"] = "ACF.Missiles.UnguidedRocket.S-24",
	["RW61 ASR"] = "ACF.Missiles.UnguidedRocket.RW61",
}

-- Round inputs ammo types used to store flat on the dupe/tool data. They now live on the AmmoType
-- instance; the serializer keeps only the fields the chosen ammo type actually declares.
local RoundFields = {
	"Projectile", "Propellant", "FillerRatio", "Flechettes",
	"HollowRatio", "LinerAngle", "SmokeWPRatio", "Spread", "StandoffRatio",
}

local WeaponFields = {}

local FuzeLookup = {
	["Altitude"] 	= {Type = "ACF.Missiles.Fuze.Altitude", CopyFields = {"ArmingDelay"}},
	["Contact"] 	= {Type = "ACF.Missiles.Fuze.Contact", 	CopyFields = {"ArmingDelay"}},
	["Optical"] 	= {Type = "ACF.Missiles.Fuze.Optical", 	CopyFields = {"ArmingDelay", "FuzeDistance"}},
	["Radio"] 		= {Type = "ACF.Missiles.Fuze.Radio", 	CopyFields = {"ArmingDelay"}},
	["Timed"] 		= {Type = "ACF.Missiles.Fuze.Timed", 	CopyFields = {"ArmingDelay", "FuzeTimer"}},
}

function WeaponFields.Fuze(Fuze, Data)
	local TypeData = FuzeLookup[Fuze] or FuzeLookup["Contact"]
	local CopyData = {}
	for _, Field in ipairs(TypeData.CopyFields) do
		CopyData[Field] = Data[Field]
	end
	return {
		Type = TypeData.Type,
		Data = CopyData
	}
end

local GuidanceLookup = {
	["Active Radar"] 		= {Type = "ACF.Missiles.Guidance.ActiveRadar", 		CopyFields = {}},
	["Anti-missile"] 		= {Type = "ACF.Missiles.Guidance.AntiMissile", 		CopyFields = {}},
	["Anti-radiation"] 		= {Type = "ACF.Missiles.Guidance.AntiRadiation", 	CopyFields = {}},
	["Dumb"] 				= {Type = "ACF.Missiles.Guidance.Dumb", 			CopyFields = {}},
	["GPS Guided"] 			= {Type = "ACF.Missiles.Guidance.GPSGuided", 		CopyFields = {}},
	["Infrared"] 			= {Type = "ACF.Missiles.Guidance.Infrared", 		CopyFields = {}},
	["Laser"] 				= {Type = "ACF.Missiles.Guidance.Laser", 			CopyFields = {}},
	["Radio (MCLOS)"] 		= {Type = "ACF.Missiles.Guidance.RadioMCLOS", 		CopyFields = {}},
	["Radio (SACLOS)"] 		= {Type = "ACF.Missiles.Guidance.RadioSACLOS", 		CopyFields = {}},
	["Semi-active Radar"] 	= {Type = "ACF.Missiles.Guidance.SemiActiveRadar", 	CopyFields = {}},
	["Wire (MCLOS)"] 		= {Type = "ACF.Missiles.Guidance.WireMCLOS", 		CopyFields = {}},
	["Wire (SACLOS)"] 		= {Type = "ACF.Missiles.Guidance.WireSACLOS", 		CopyFields = {}},
}

function WeaponFields.Guidance(Guidance, Data)
	local TypeData = GuidanceLookup[Guidance] or GuidanceLookup["Dumb"]
	local CopyData = {}
	for _, Field in ipairs(TypeData.CopyFields) do
		CopyData[Field] = Data[Field]
	end
	return {
		Type = TypeData.Type,
		Data = CopyData
	}
end

local Floor = math.floor
local Max   = math.max
local Min   = math.min
local DeserializePartial = ACF.Classes.Serialization.DeserializePartial

local function LegacySize(Data)
	if isvector(Data.Size) then return Data.Size end

	local X = tonumber(Data.AmmoSizeX or Data.CrateSizeX)
	local Y = tonumber(Data.AmmoSizeY or Data.CrateSizeY)
	local Z = tonumber(Data.AmmoSizeZ or Data.CrateSizeZ)

	if X or Y or Z then return Vector(X or 24, Y or 24, Z or 24) end
end

local function DeriveCountsFromSize(WeaponFQN, AmmoTypeFQN, AmmoData, Caliber, Size)
	local WeaponClass = GetType(WeaponFQN)
	local AmmoClass   = GetType(AmmoTypeFQN)
	if not (WeaponClass and AmmoClass) then return end

	local ok, cx, cy, cz = pcall(function()
		local Weapon = DeserializePartial(WeaponClass, {Caliber = Caliber})
		if Weapon.VerifyData then Weapon:VerifyData() end

		local Ammo  = DeserializePartial(AmmoClass, AmmoData)
		Ammo.Weapon = Weapon

		local Bullet   = Ammo:ServerConvert()
		local ToolData = {Caliber = Caliber}

		local x, y, z = ACF.GetProjectileCountsFromCrateSize(Size, WeaponClass, ToolData, Bullet)
		x = Max(1, Floor(x or 3))
		y = Max(1, Floor(y or 3))
		z = Max(1, Floor(z or 3))

		-- Clamp to the maximum counts the round geometry allows, same as UpdateCrateSize.
		local RoundSize        = ACF.GetRoundProperties(WeaponClass, ToolData, Bullet)
		local MaxX, MaxY, MaxZ = ACF.GetMaxCounts(RoundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, y, z)

		return Min(x, MaxX), Min(y, MaxY), Min(z, MaxZ)
	end)

	if ok and cx then return cx, cy, cz end
end

ACF.Entities.RegisterCompatPatch("acf_ammo", 2026062101, function(Data)
	if Data.ACF_UserData then return end

	local Weapon  = Data.Weapon
	local Caliber = Data.Caliber or Data.caliber
	if not ACF.Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", Weapon) then
		local Mapped = WeaponFQNTable[Weapon]
		if Mapped then
			Weapon = Mapped
		elseif ACF.Entities.ResolveLegacyWeapon then
			local FQN, LegacyCaliber = ACF.Entities.ResolveLegacyWeapon(Weapon, Caliber)
			if FQN then
				Weapon  = FQN
				Caliber = LegacyCaliber or Caliber
			end
		end
	end

	-- Migrate the legacy flat round inputs onto the ammo type instance's serialized field set.
	local AmmoData = { Tracer = tobool(Data.Tracer) }
	for _, K in ipairs(RoundFields) do AmmoData[K] = Data[K] end

	local WeaponData = { Caliber = Caliber }
	for K, V in pairs(WeaponFields) do WeaponData[K] = V(Data[K], Data) end

	local AmmoTypeFQN = AmmoFQN(Data.AmmoType)

	local CrateX, CrateY, CrateZ = Data.CrateProjectilesX, Data.CrateProjectilesY, Data.CrateProjectilesZ
	if CrateX == nil and Data.AmmoShape ~= "Cylinder" then
		local Size = LegacySize(Data)
		if Size then
			CrateX, CrateY, CrateZ = DeriveCountsFromSize(Weapon, AmmoTypeFQN, AmmoData, Caliber, Size)
		end
	end

	Data.ACF_UserData = {
		-- If worried about potential exploits here, Caliber will only be passed to the
		-- weapon instance if the weapon supports Caliber as a field. So it'll all be 
		-- deserialized appropriately (+ compat patches run before the entity even gets
		-- a chance to exist in the first place)
		Weapon            = {Type = Weapon, Data = WeaponData },
		Caliber           = Caliber,
		AmmoType          = {Type = AmmoTypeFQN, Data = AmmoData},
		AmmoStage         = Data.AmmoStage,
		Shape             = ShapeFQN(Data.AmmoShape or "Box"),
		CrateProjectilesX = CrateX,
		CrateProjectilesY = CrateY,
		CrateProjectilesZ = CrateZ,
	}
end)
