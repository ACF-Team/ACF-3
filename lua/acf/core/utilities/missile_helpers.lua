local ACF      = ACF
local Classes  = ACF.Classes

-- Missiles/racks are V2 classes addressed by short id (FQN suffix, or CLASS.ID for missile groups).
local function GetMissileClass(ID)
	local Direct = Classes.GetSubtypeByName("ACF.Missiles.BaseMissile", ID)
	if Direct then return Direct end

	for _, Class in ipairs(Classes.GetSubtypesAsList("ACF.Missiles.BaseMissile")) do
		if Class.ID == ID or Classes.GetTypeName(Class):match("[^.]+$") == ID then return Class end
	end
end

function ACF.GetGunValue(BulletData, Value)
	BulletData = istable(BulletData) and BulletData.WeaponType or BulletData

	-- The missile item class inherits its group's values, so a single lookup covers both.
	local Data = GetMissileClass(BulletData)

	if Data then
		local Result = Data.Round and Data.Round[Value] or Data[Value]

		if Result ~= nil then return Result end
	end
end

local function CanLoadCaliber(RackData, WeaponData)
	local RackCaliber = RackData.Caliber
	local Caliber     = WeaponData.Caliber
	local RackName    = RackData.Name

	if RackCaliber then
		if RackCaliber == Caliber then return true end

		return false, "Only " .. RackCaliber .. "mm rounds can be loaded on " .. RackName
	end

	local MinCaliber = RackData.MinCaliber

	if MinCaliber and Caliber < MinCaliber then
		return false, "Rounds must be at least " .. MinCaliber .. "mm to be loaded into " .. RackName
	end

	local MaxCaliber = RackData.MaxCaliber

	if MaxCaliber and Caliber > MaxCaliber then
		return false, "Rounds cannot be more than " .. MaxCaliber .. "mm to be loaded into " .. RackName
	end

	return true
end

function ACF.CanLinkRack(RackData, WeaponData)
	-- A non-missile crate (e.g. a gun ammo crate) has no missile weapon data here.
	if not WeaponData then
		return false, "This crate doesn't hold missiles compatible with " .. RackData.Name .. "!"
	end

	local Allowed = WeaponData.Racks
	PrintTable(Allowed)
	if not (Allowed and Allowed[Classes.GetTypeName(RackData:GetType())]) then
		return false, (WeaponData.ID or "These") .. " rounds are not compatible with " .. RackData.Name .. "!"
	end

	local Bool, Message = CanLoadCaliber(RackData, WeaponData)

	if not Bool then
		return Bool, Message
	end

	return true
end
