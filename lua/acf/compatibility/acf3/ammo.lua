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
	["H"] = "ACF.Guns.Howitzer",
	["LAC"] = "ACF.Guns.LightAutocannon",
	["MG"] = "ACF.Guns.Machinegun",
	["MO"] = "ACF.Guns.Mortar",
	["RAC"] = "ACF.Guns.RotaryAutocannon",
	["SAC"] = "ACF.Guns.SemiautomaticCannon",
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
	["AGM-114 ASM"] = "ACF.Missiles.AntiTankGuided.AGM-114",
	["Ataka ASM"] = "ACF.Missiles.AntiTankGuided.Ataka",
	["9M133 ASM"] = "ACF.Missiles.AntiTankGuided.9M133",
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
	["227kgGBU"] = "ACF.Missiles.GuidedBomb.227kgGBU",
	["454kgGBU"] = "ACF.Missiles.GuidedBomb.454kgGBU",
	["454kgGBU"] = "ACF.Missiles.GuidedBomb.454kgGBU",
	["909kgGBU"] = "ACF.Missiles.GuidedBomb.909kgGBU",
	["909kgGBU"] = "ACF.Missiles.GuidedBomb.909kgGBU",

	["FIM-92 SAM"] = "ACF.Missiles.SurfaceToAir.FIM-92",
	["Strela-1 SAM"] = "ACF.Missiles.SurfaceToAir.Strela-1",

	["RS82 ASR"] = "ACF.Missiles.UnguidedRocket.RS82",
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

ACF.Entities.RegisterCompatPatch("acf_ammo", 2026062101, function(Data)
	if Data.ACF_UserData then return end

	local Weapon  = Data.Weapon
	local Caliber = Data.Caliber

	-- Resolve pre-scalable weapon aliases (old short IDs/names) to their FQN.
	if not ACF.Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", Weapon) then
		Weapon = WeaponFQNTable[Weapon] or Weapon
	end

	-- Migrate the legacy flat round inputs onto the ammo type instance's serialized field set.
	local AmmoData = { Tracer = tobool(Data.Tracer) }
	for _, K in ipairs(RoundFields) do AmmoData[K] = Data[K] end

	Data.ACF_UserData = {
		-- If worried about potential exploits here, Caliber will only be passed to the
		-- weapon instance if the weapon supports Caliber as a field. So it'll all be 
		-- deserialized appropriately (+ compat patches run before the entity even gets
		-- a chance to exist in the first place)
		Weapon            = {Type = Weapon, Data = {Caliber = Caliber}},
		Caliber           = Caliber,
		AmmoType          = {Type = AmmoFQN(Data.AmmoType), Data = AmmoData},
		AmmoStage         = Data.AmmoStage,
		Shape             = ShapeFQN(Data.AmmoShape or "Box"),
		CrateProjectilesX = Data.CrateProjectilesX,
		CrateProjectilesY = Data.CrateProjectilesY,
		CrateProjectilesZ = Data.CrateProjectilesZ,
	}
end)
