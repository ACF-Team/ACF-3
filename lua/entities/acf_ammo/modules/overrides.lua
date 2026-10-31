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

	--- The highest slot holding a round. Slots below it can be empty where a filtered take left a hole
	function ENT:GetTopSlot()
		return self.Amount + table.Count(self.Holes)
	end

	function ENT:IsSlotFilled(Slot)
		return Slot >= 1 and Slot <= self:GetTopSlot() and not self.Holes[Slot]
	end

	--- Limits which rounds leave the crate to those Filter(BulletData, Ammo) accepts, nil allows all of them
	function ENT:SetRoundFilter(Filter)
		self.RoundFilter = Filter

		WireLib.TriggerOutput(self, "Loading", self:CanConsume() and 1 or 0)
	end

	--- Limits the crate to rounds of one ammo type, by full or short name ("ACF.Ammunition.HE" or "HE"), "" allows all of them
	function ENT:SetAmmoTypeFilter(AmmoType)
		if not AmmoType or AmmoType == "" then return self:SetRoundFilter(nil) end

		self:SetRoundFilter(function(BulletData)
			return BulletData.AmmoType == AmmoType or ACF.GetLegacyStyleClassName(BulletData.AmmoType) == AmmoType
		end)
	end

	--- The slot of the next round to leave the crate, the highest one the filter accepts, nil if none does
	function ENT:FindNextSlot()
		local Top    = self:GetTopSlot()
		local Filter = self.RoundFilter
		local Holes  = self.Holes

		if Top < 1 then return end
		if not Filter then return Top end

		-- Past the overridable slots every round is the crate's own and none are holes, so only the top one matters
		if Top > ACF.MaxRoundsDrawn then
			if Filter(self.BulletData, self.RoundData) then return Top end

			Top = ACF.MaxRoundsDrawn
		end

		for Slot = Top, 1, -1 do
			if not Holes[Slot] and Filter(self:GetRound(Slot)) then return Slot end
		end
	end

	--- The slot a round put back into the crate goes into, the lowest hole or the one above the top
	function ENT:GetRefillSlot()
		local Holes = self.Holes

		for Slot = 1, math.min(self:GetTopSlot(), ACF.MaxRoundsDrawn) do
			if Holes[Slot] then return Slot end
		end

		return self:GetTopSlot() + 1
	end

	--- Returns the round that will leave the crate next
	function ENT:PeekRound()
		return self:GetRound(self:FindNextSlot() or self:GetTopSlot())
	end

	--- Short name of the ammo type that will leave the crate next
	function ENT:GetNextAmmoType()
		return ACF.GetLegacyStyleClassName(self:PeekRound().AmmoType)
	end

	--- Removes the next round from the crate and returns it
	function ENT:TakeRound()
		local Slot = self:FindNextSlot() or self:GetTopSlot()
		local BulletData, Ammo = self:GetRound(Slot)

		-- A round taken from below the top leaves a hole, so the top stays put as the amount drops
		if Slot < self:GetTopSlot() then
			self.Holes[Slot] = true
			self:QueueAmmoData()
		end

		self:Consume(1)

		return BulletData, Ammo
	end

	--- Keeps the holes in step with a new amount: rounds leave from the top and refills fill the lowest hole first
	function ENT:UpdateHoles(OldAmount)
		local Holes = self.Holes
		local Count = table.Count(Holes)
		local Delta = self.Amount - OldAmount
		local Top   = OldAmount + Count

		if Delta == 0 then return end

		if self.Amount <= 0 then
			self.Holes = {}
		elseif Delta > 0 then
			for Slot = 1, math.min(Top, ACF.MaxRoundsDrawn) do
				if Delta == 0 then break end

				if Holes[Slot] then
					Holes[Slot] = nil
					Delta = Delta - 1
				end
			end
		else
			for _ = 1, -Delta do
				Top = Top - 1

				while Holes[Top] do
					Holes[Top] = nil
					Top = Top - 1
				end
			end
		end

		-- Clients draw holes as gaps, every change to them changes how many there are
		if table.Count(self.Holes) ~= Count then self:QueueAmmoData() end
	end

	--- Every kind of round the crate is loaded with and how many of each are left, as a list of { BulletData, Ammo, Count }
	function ENT:GetRoundCounts()
		local Base   = { BulletData = self.BulletData, Ammo = self.RoundData, Count = self.Amount }
		local Kinds  = { Base }
		local ByAmmo = {}

		for Slot, Round in pairs(self.SlotRounds) do
			local Kind = ByAmmo[Round.Ammo]

			if not Kind then
				Kind = { BulletData = Round.BulletData, Ammo = Round.Ammo, Count = 0 }
				ByAmmo[Round.Ammo]  = Kind
				Kinds[#Kinds + 1]   = Kind
			end

			if self:IsSlotFilled(Slot) then
				Kind.Count = Kind.Count + 1
				Base.Count = Base.Count - 1
			end
		end

		return Kinds
	end

	--- Rounds left in the crate by short ammo type name, rounds of one type with different specs count together
	function ENT:GetAmmoTypeCounts()
		local Counts = {}

		for _, Kind in ipairs(self:GetRoundCounts()) do
			local Name = ACF.GetLegacyStyleClassName(Kind.BulletData.AmmoType)

			Counts[Name] = (Counts[Name] or 0) + Kind.Count
		end

		return Counts
	end

	--- Sums a bullet data value over the rounds in the crate
	function ENT:SumRounds(Key)
		local Total = 0

		for _, Kind in ipairs(self:GetRoundCounts()) do
			Total = Total + (Kind.BulletData[Key] or 0) * Kind.Count
		end

		return Total
	end

	function ENT:GetUnitMass()
		local Amount = self.Amount

		if not next(self.SlotRounds) or Amount <= 0 then return self.BaseClass.GetUnitMass(self) end

		return self:SumRounds("CartMass") / Amount
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
		self:QueueAmmoData()
		self:UpdateMass(true)
		self:UpdateOverlay(true)

		return true, "Slot " .. Slot .. " now holds " .. ACF.GetLegacyStyleClassName(self:GetRound(Slot).AmmoType) .. "."
	end
end
