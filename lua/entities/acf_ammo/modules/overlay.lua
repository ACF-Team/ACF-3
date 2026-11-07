local ACF     = ACF
local Classes = ACF.Classes

do -- MARK: Overlay
	-- Bullet and ammo info of one kind of round, a page of the crate's ammo info
	local function AddRoundInfo(Entity, State, Kind)
		local BulletData = Kind.BulletData
		local Projectile = math.Round(BulletData.ProjMass, 2)
		local Cartridge  = math.Round(BulletData.CartMass, 2)

		local Caliber       = math.Round(BulletData.Caliber * 10, 2)
		local ShellDiameter = math.Round(BulletData.CaseDiameter * 10, 2)
		local Length        = math.Round(BulletData.RoundLength or (BulletData.ProjLength + BulletData.PropLength), 2)

		if Entity.IsMissileAmmo then
			local MissileClass = Classes.GetSubtypeByName("ACF.Missiles.BaseMissile", BulletData.WeaponType)
			local Round        = MissileClass and MissileClass.Round

			if Round and Round.ActualLength then
				Length = Round.ActualLength * ACF.InchToCm
			end
		end

		State:AddKeyValue("Shell dimensions", ShellDiameter .. "mm x " .. Length .. "cm")

		local HasMag = ACF.GetWeaponValue("MagReload", Caliber, Entity.ClassData, Entity.WeaponData)

		-- Per-round reload only matters without a magazine, and not for belt feds (cyclic RPM is their only timing)
		if not HasMag and not Entity.IsBelted then
			local IdealReloadTime = math.Round(ACF.CalcReloadTime(Caliber, Entity.ClassData, Entity.WeaponData, BulletData, Entity.Override), 2)
			State:AddKeyValue("Ideal Reload Time", IdealReloadTime .. " s")
		end

		if HasMag then
			local IdealMagReloadTime = math.Round(ACF.CalcReloadTimeMag(Entity.Caliber, Entity.ClassData, Entity.WeaponData, BulletData, {MagSize = Entity.Amount}), 2)
			State:AddKeyValue("Ideal Mag Reload Time", IdealMagReloadTime .. " s")
		end

		State:AddNumber("Cartridge Mass", Cartridge, " kg", 2)
		State:AddNumber("Projectile Mass", Projectile, " kg", 2)

		Kind.Ammo:UpdateCrateOverlay(BulletData, State)
	end

	local MIXED_HELP = "Open the context menu and right click this crate, then pick Edit Round Counts "
		.. "to change how many of each round it holds and the order they load in."
	local SINGLE_HELP = "Hold Alt while applying a round from the ACF menu to add it to this crate. "
		.. "How many of each round it holds can then be edited from its context menu."

	-- The contents bar's data: a section per kind in list order, sized by its share and filled by its rounds left
	local function GetContentsBar(Entity, Kinds)
		local Help = not Entity:CanMixRounds() and "" or #Kinds > 1 and MIXED_HELP or SINGLE_HELP
		local Bar  = { "Contents", Entity.Capacity, Help }

		for Index, Kind in ipairs(Kinds) do
			local Last = #Bar

			Bar[Last + 1] = Kind.Ammo.SpawnIcon or ""
			Bar[Last + 2] = Kind.Count
			Bar[Last + 3] = Kind.Target
			Bar[Last + 4] = Entity.GetRoundKindColor(Index)
		end

		return unpack(Bar)
	end

	function ENT:ACF_UpdateOverlayState(State)
		local Kinds = self.RoundKinds

		-- The destroyed line is added by the base overlay
		if not ACF.IsDestroyed(self) and next(self.Weapons) then
			if self:CanConsume() then
				State:AddSuccess("Providing Ammo")
			elseif self.Amount ~= 0 then
				State:AddWarning("Idle")
			else
				State:AddError("Empty")
			end
		end

		local CountX = self.CrateProjectilesX
		local CountY = self.CrateProjectilesY
		local CountZ = self.CrateProjectilesZ

		local Shape = self:ACF_GetUserVar("Shape")

		-- Cassettes store stacks and conveyor size, so expand them to the full grid
		if Shape.IsCassette then
			CountX, CountY, CountZ = ACF.GetCassetteGrid(CountX, CountY, CountZ, self.BulletData.TwoPiece):Unpack()
		end

		State:AddDivider()
		State:AddSize("Storage (in projectiles)", CountX, CountY, CountZ)
		State:AddKeyValue("Two Piece", self.BulletData.TwoPiece and "Yes" or "No")
		State:AddKeyValue("Hex Packing", self:IsHexPacked() and "Yes" or "No")

		local Layout = ACF.GetDrumLayout(Shape)
		if Layout then
			State:AddKeyValue("Layout", Layout.Name)
		elseif Shape.IsCassette then
			State:AddKeyValue("Layout", "Cassette")
			State:AddKeyValue("Stacks", self.CrateProjectilesX)
		end
		State:AddSegmentBar(GetContentsBar(self, Kinds))

		if #Kinds > 1 or self.RoundSelect > 0 then
			local Next = self:FindNextKind()

			State:AddKeyValue("Next Round", Next and Kinds[Next].Name or "None")
		end

		-- One page per kind, each viewer pages through them on their own
		State:AddPageHeader("Ammo Info", #Kinds, 2)

		for Index, Kind in ipairs(Kinds) do
			if Index > 1 then State:AddPageBreak() end
			State:AddKeyValue("Round", Kind.Name)

			AddRoundInfo(self, State, Kind)
		end

		State:AddPageEnd()

		ACF.AddAdditionalOverlays(self, State)
	end
end