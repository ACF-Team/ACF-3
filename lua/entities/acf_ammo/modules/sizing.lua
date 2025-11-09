local ACF       = ACF
local Clamp     = math.Clamp
local Floor     = math.floor
local Classes   = ACF.Classes
local Crates    = Classes.Crates
local AmmoTypes = Classes.AmmoTypes
local Weapons   = Classes.Weapons

function VerifyData(Data)
	if not isvector(Data.Size) then
		local X = ACF.CheckNumber(Data.AmmoSizeX or Data.CrateSizeX, 24)
		local Y = ACF.CheckNumber(Data.AmmoSizeY or Data.CrateSizeY, 24)
		local Z = ACF.CheckNumber(Data.AmmoSizeZ or Data.CrateSizeZ, 24)

		Data.Size = Vector(X, Y, Z)
	end

	do
		local Min  = ACF.AmmoMinSize
		local Size = Data.Size

		Size.x = Clamp(Size.x, Min, ACF.AmmoMaxLength)
		Size.y = Clamp(Size.y, Min, ACF.AmmoMaxWidth)
		Size.z = Clamp(Size.z, Min, ACF.AmmoMaxWidth)

		if not isstring(Data.Destiny) then
			Data.Destiny = ACF.FindWeaponrySource(Data.Weapon) or "Weapons"
		end

		local Source = Classes[Data.Destiny]
		local Class  = Classes.GetGroup(Source, Data.Weapon)

		if not Class then
			Class = Weapons.Get("C")

			Data.Destiny = "Weapons"
			Data.Weapon  = "C"
			Data.Caliber = Data.caliber or 50
		elseif Source.IsAlias(Data.Weapon) then
			Data.Weapon = Class.ID
		end

		do
			local Weapon = Source.GetItem(Class.ID, Data.Weapon)

			if Weapon then
				if Class.IsScalable then
					local Bounds  = Class.Caliber
					local Caliber = ACF.CheckNumber(Weapon.Caliber, Bounds.Base)

					Data.Weapon  = Class.ID
					Data.Caliber = Clamp(Caliber, Bounds.Min, Bounds.Max)
				else
					Data.Caliber = ACF.CheckNumber(Weapon.Caliber, 50)
				end
			end
		end

		local Ammo = AmmoTypes.Get(Data.AmmoType)

		if not Ammo or Ammo.Blacklist[Class.ID] then
			Data.AmmoType = Class.DefaultAmmo or "AP"

			Ammo = AmmoTypes.Get(Data.AmmoType)
		end

		if not isnumber(Data.AmmoStage) then
			Data.AmmoStage = 1
		end
		Data.AmmoStage = Clamp(Data.AmmoStage, ACF.AmmoStageMin, ACF.AmmoStageMax)

		do
			Ammo:VerifyData(Data, Class)

			if Class.VerifyData then
				Class.VerifyData(Data, Class, Ammo)
			end

			hook.Run("ACF_OnVerifyData", "acf_ammo", Data, Class, Ammo)
		end
	end
end

function UpdateCrateSize(Entity, Data, Class, Weapon, Ammo)
	-- Convert current tool data once to get projectile geometry
	local Bullet = Ammo:ServerConvert(Data)

	-- Normalize requested projectile counts (accept nil, coerce to integers >= 1)
	local cx = tonumber(Data.CrateProjectilesX)
	local cy = tonumber(Data.CrateProjectilesY)
	local cz = tonumber(Data.CrateProjectilesZ)

	if not (cx and cy and cz) then
		cx, cy, cz = ACF.GetProjectileCountsFromCrateSize(Data.Size, Class, Data, Bullet)
	end

	cx = math.max(1, Floor(cx or 3))
	cy = math.max(1, Floor(cy or 3))
	cz = math.max(1, Floor(cz or 3))

	-- Persist counts on both Data and Entity
	Data.CrateProjectilesX, Data.CrateProjectilesY, Data.CrateProjectilesZ = cx, cy, cz


	-- Recompute and apply consistent crate size from final counts
	Data.Size = ACF.GetCrateSizeFromProjectileCounts(cx, cy, cz, Class, Data, Bullet)
	Entity:SetSize(Data.Size)

	return cx * cy * cz
end

function CalculateExtraData(Entity, Data, Class, Weapon)
	local Rounds = Entity.Capacity
	local ExtraData = {}

	if Rounds > 0 then
		local BulletData = Entity.BulletData
		local Caliber = Entity.Caliber
		local BeltFed = ACF.GetWeaponValue("IsBelted", Caliber, Class, Weapon) or false
		local Round = Weapon and Weapon.Round or Class.Round
		local RoundLength, RoundDiameter, RoundModel, RoundOffset = ACF.GetModelDimensions(Round)

		if not RoundLength then
			RoundDiameter = Caliber * ACF.AmmoCaseScale * 0.1
			RoundLength = BulletData.PropLength + BulletData.ProjLength
			RoundLength = RoundLength / ACF.InchToCm
			RoundDiameter = RoundDiameter / ACF.InchToCm
		end

		Entity.IsBelted = BeltFed
		ExtraData.AmmoStage = Data.AmmoStage or 0
		ExtraData.IsRound = true
		ExtraData.Capacity = Entity.Capacity or 0
		ExtraData.Enabled = true
		ExtraData.RoundSize = Vector(RoundLength, RoundDiameter, RoundDiameter)
		ExtraData.LocalAng = Angle(0, 0, 0)
		ExtraData.Spacing = 0
		ExtraData.MagSize = Entity.MagSize or 0
		ExtraData.IsBelted = BeltFed or false
		ExtraData.RoundModel = RoundModel
		ExtraData.RoundOffset = RoundOffset
	else
		ExtraData = { Enabled = false }
	end

	return ExtraData
end

function ENT:OnResized(Size)
	local A = ACF.ContainerArmor * ACF.MmToInch
	local ExteriorVolume = Size.x * Size.y * Size.z
	local InteriorVolume = math.max(0, (Size.x - 2 * A) * (Size.y - 2 * A) * (Size.z - 2 * A))

	local Volume = ExteriorVolume - InteriorVolume
	local Mass   = Volume * 0.13

	self.EmptyMass = Mass
end