local ACF           = ACF
local Classes       = ACF.Classes
local Serialization = Classes.Serialization
local Empty         = {}

do -- MARK: Round access
	--- Returns the bullet data and ammo instance of the round in a slot, overridden or not
	function ENT:GetRound(Slot)
		local Round = self.SlotRounds[Slot]

		if Round then return Round.BulletData, Round.Ammo end

		return self.BulletData, self.RoundData
	end

	--- Returns the round that will leave the crate next, rounds come off the top of the stack
	function ENT:PeekRound()
		return self:GetRound(self.Amount)
	end

	--- Short name of the ammo type that will leave the crate next
	function ENT:GetNextAmmoType()
		return ACF.GetLegacyStyleClassName(self:PeekRound().AmmoType)
	end

	--- Removes the next round from the crate and returns it
	function ENT:TakeRound()
		local BulletData, Ammo = self:PeekRound()

		self:Consume(1)

		return BulletData, Ammo
	end

	--- Sums a bullet data value over the first Count rounds, overrides included
	function ENT:SumRounds(Key, Count)
		local Base  = self.BulletData[Key] or 0
		local Total = Base * Count

		for Slot, Round in pairs(self.SlotRounds) do
			if Slot <= Count then Total = Total + (Round.BulletData[Key] or 0) - Base end
		end

		return Total
	end

	function ENT:GetUnitMass()
		local Amount = self.Amount

		if not next(self.SlotRounds) or Amount <= 0 then return self.BaseClass.GetUnitMass(self) end

		return self:SumRounds("CartMass", Amount) / Amount
	end
end

do -- MARK: Storage
	-- Two ammo instances are the same round if they share a type and every menu input
	local function SameAmmo(A, B)
		local Type = A:GetType()

		if Type ~= B:GetType() then return false end

		for _, Field in ipairs(Classes.GetTypeFields(Type)) do
			if Field.Menu and A[Field.Name] ~= B[Field.Name] then return false end
		end

		return true
	end

	-- Distinct ammo instances in a slot to ammo instance map
	local function CountTypes(Map)
		local Types = {}

		for _, Ammo in pairs(Map) do Types[Ammo] = true end

		return table.Count(Types)
	end

	-- Reads the user vars into a slot to ammo instance map
	local function ReadOverrides(Entity)
		local Profiles = Entity:ACF_GetUserVar("OverrideAmmo") or Empty
		local Indices  = Entity:ACF_GetUserVar("OverrideProfiles") or Empty
		local Map      = {}

		for I, Slot in ipairs(Entity:ACF_GetUserVar("OverrideSlots") or Empty) do
			Map[Slot] = Profiles[Indices[I]]
		end

		return Map
	end

	-- Writes a slot to ammo instance map back into the user vars, numbering profiles by first use
	local function StoreOverrides(Entity, Map)
		local Profiles, Slots, Indices, Lookup = {}, {}, {}, {}

		for Slot = 1, ACF.MaxRoundsDrawn do
			local Ammo = Map[Slot]

			if Ammo then
				if not Lookup[Ammo] then
					Profiles[#Profiles + 1] = Ammo
					Lookup[Ammo]            = #Profiles
				end

				Slots[#Slots + 1]     = Slot
				Indices[#Indices + 1] = Lookup[Ammo]
			end
		end

		Entity:ACF_SetUserVar("OverrideAmmo", Profiles)
		Entity:ACF_SetUserVar("OverrideSlots", Slots)
		Entity:ACF_SetUserVar("OverrideProfiles", Indices)

		return Profiles, Lookup
	end

	-- Ammo types write their client data with SetNW2*, this redirects it to keys suffixed with the profile
	local function NetworkProfile(Entity, Ammo, BulletData, Profile)
		local Suffix = "#" .. Profile
		local Proxy  = {
			SetNW2String = function(_, Key, Value) Entity:SetNW2String(Key .. Suffix, Value) end,
			SetNW2Float  = function(_, Key, Value) Entity:SetNW2Float(Key .. Suffix, Value) end,
			SetNW2Int    = function(_, Key, Value) Entity:SetNW2Int(Key .. Suffix, Value) end,
		}

		Ammo:Network(Proxy, BulletData)
	end

	local function GetCrateModel(Entity, Ammo, BulletData)
		local Weapon = not Entity.ClassData.IsScalable and Entity.WeaponData or nil

		return Ammo:ResolveModel("Crate", Entity.ClassData, Weapon, BulletData.TwoPiece)
	end

	--- Checks a round can take a slot sized for the crate's own round, returns false and a reason if not
	function ENT:CanHoldRound(Ammo, BulletData)
		local Base = self.BulletData

		if Ammo.Blacklist and Ammo.Blacklist[Classes.GetTypeName(self:GetWeapon():GetType())] then
			return false, "This ammo type can't be used with this weapon."
		end

		if (BulletData.TwoPiece or false) ~= (Base.TwoPiece or false) then
			return false, "Two piece setting must match the crate's."
		end

		if GetCrateModel(self, Ammo, BulletData).Model ~= GetCrateModel(self, self.RoundData, Base).Model then
			return false, "This round uses a different model than the crate's."
		end

		local Data = { Caliber = self.Caliber }
		local Size = ACF.GetRoundProperties(self.ClassData, Data, BulletData)
		local Slot = ACF.GetRoundProperties(self.ClassData, Data, Base)

		if Size.x > Slot.x + 1e-3 or Size.y > Slot.y + 1e-3 then
			return false, "This round doesn't fit in the crate's slots."
		end

		return true
	end

	--- The highest slot a round override can target, none on missile crates
	function ENT:GetOverridableSlots()
		return self.IsMissileAmmo and 0 or math.min(self.Capacity, ACF.MaxRoundsDrawn)
	end

	--- Rebuilds the overridden rounds from a slot to ammo map, the user vars by default, dropping any that no longer fit the crate
	function ENT:BuildOverrides(Overrides)
		local Limit     = self:GetOverridableSlots()
		local Map       = {}
		local Converted = {}

		for Slot, Ammo in pairs(Overrides or ReadOverrides(self)) do
			if Slot <= Limit then
				if Converted[Ammo] == nil then
					self:PrepareAmmo(Ammo, Empty)

					local BulletData = Ammo:ServerConvert()

					Converted[Ammo] = self:CanHoldRound(Ammo, BulletData) and BulletData or false
				end

				if Converted[Ammo] then Map[Slot] = Ammo end
			end
		end

		-- Only a hand edited dupe can get past the type limit
		if CountTypes(Map) > ACF.MaxOverrideTypes then Map = {} end

		local Profiles, Lookup = StoreOverrides(self, Map)
		local Rounds = {}

		for Profile, Ammo in ipairs(Profiles) do
			local BulletData = Converted[Ammo]

			BulletData.Crate        = self:EntIndex()
			BulletData.CrateProfile = Profile

			NetworkProfile(self, Ammo, BulletData, Profile)

			Rounds[Profile] = {
				Ammo       = Ammo,
				BulletData = BulletData,
				Bodygroup  = GetCrateModel(self, Ammo, BulletData).Bodygroup or 0,
			}
		end

		self.SlotRounds = {}

		for Slot, Ammo in pairs(Map) do
			self.SlotRounds[Slot] = Rounds[Lookup[Ammo]]
		end
	end

	function ENT:ClearOverrides()
		StoreOverrides(self, Empty)
	end

	-- Builds the ammo instance serialized crate data describes, returns false and a reason if the crate can't hold it
	local function ParseRound(Entity, Data)
		local ClassDef = Entity.ACF_ClassDef

		Serialization.SanitizeClassFields(ClassDef, Data)

		local Config  = Serialization.DeserializePartial(ClassDef, Data)
		local Weapon  = Config.Weapon
		local Ammo    = Config.AmmoType
		local Current = Entity:GetWeapon()

		if not Weapon or not Ammo then return false, "Invalid ammo data." end
		if Weapon:GetType() ~= Current:GetType() then return false, "The selected weapon doesn't match the crate's." end

		if Weapon.Caliber ~= nil then
			Weapon.Caliber = tonumber(Data.Caliber) or Weapon.Caliber
			if Weapon.VerifyData then Weapon:VerifyData() end

			if math.abs(Weapon.Caliber - Current.Caliber) > 1e-3 then return false, "The selected caliber doesn't match the crate's." end
		end

		Entity:PrepareAmmo(Ammo, Data)

		local CanHold, Reason = Entity:CanHoldRound(Ammo, Ammo:ServerConvert())

		if not CanHold then return false, Reason end

		return Ammo
	end

	--- Sets the round in a slot from serialized crate data (as the menu sends it), returns success and a message
	function ENT:ACF_OverrideSlot(_, Slot, Data)
		if self.IsMissileAmmo then return false, "Missile crates can't override rounds." end
		if Slot < 1 or Slot > self:GetOverridableSlots() then return false, "That slot can't be overridden." end

		local Ammo, Reason = ParseRound(self, Data)

		if not Ammo then return false, Reason end

		local Map = ReadOverrides(self)

		-- Reuse a matching override so equal rounds share one profile, the crate's own round needs no override
		if SameAmmo(Ammo, self.RoundData) then
			Ammo = nil
		else
			for _, Other in pairs(Map) do
				if SameAmmo(Ammo, Other) then Ammo = Other break end
			end
		end

		Map[Slot] = Ammo

		if CountTypes(Map) > ACF.MaxOverrideTypes then
			return false, "A crate can't hold more than " .. ACF.MaxOverrideTypes .. " other round types."
		end

		self:BuildOverrides(Map)
		self:NetworkAmmoData()
		self:UpdateMass(true)
		self:UpdateOverlay(true)

		return true, "Slot " .. Slot .. " now holds " .. ACF.GetLegacyStyleClassName(self:GetRound(Slot).AmmoType) .. "."
	end
end
