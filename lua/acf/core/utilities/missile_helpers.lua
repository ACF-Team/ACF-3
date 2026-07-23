local ACF      = ACF
local Classes  = ACF.Classes
local Missiles = Classes.Missiles

function ACF.GetGunValue(BulletData, Value)
	BulletData = istable(BulletData) and BulletData.Id or BulletData

	local Class = Classes.GetGroup(Missiles, BulletData)

	if Class then
		local Data = Class.Lookup[BulletData]
		local Result = Data.Round and Data.Round[Value] or Data[Value]

		if Result ~= nil then return Result end

		return Class and Class[Value]
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
	local Allowed = WeaponData.Racks

	if not (Allowed and Allowed[RackData.ID]) then
		return false, WeaponData.ID .. " rounds are not compatible with " .. RackData.Name .. "!"
	end

	local Bool, Message = CanLoadCaliber(RackData, WeaponData)

	if not Bool then
		return Bool, Message
	end

	return true
end
