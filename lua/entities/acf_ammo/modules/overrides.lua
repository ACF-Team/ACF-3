local ACF           = ACF
local Classes       = ACF.Classes
local Serialization = Classes.Serialization
local Empty         = {}

do -- MARK: Round access
	-- Index of the kind at a depth in the stack, 0 is the top: the crate's own round, then the other kinds last added first
	local function StackIndex(Kinds, Depth) return Depth == 0 and 1 or #Kinds + 1 - Depth end

	-- Index of the top kind with rounds left that the filter accepts
	local function FindKind(Entity, Filter)
		local Kinds = Entity.RoundKinds

		for Depth = 0, #Kinds - 1 do
			local Index = StackIndex(Kinds, Depth)
			local Kind  = Kinds[Index]

			if Kind.Count > 0 and (not Filter or Filter(Kind.BulletData, Kind.Ammo)) then return Index end
		end
	end

	-- The kind of the next round to leave, the next one with any rounds left if the filter accepts none
	local function GetNextKind(Entity)
		return FindKind(Entity, Entity.RoundFilter) or FindKind(Entity)
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

	--- The index of the kind the next round leaves from, nil if the filter accepts none
	function ENT:FindNextKind()
		return FindKind(self, self.RoundFilter)
	end

	--- Returns the round that will leave the crate next
	function ENT:PeekRound()
		local Kind = self.RoundKinds[GetNextKind(self) or 1]

		return Kind.BulletData, Kind.Ammo
	end

	--- Short name of the ammo type that will leave the crate next
	function ENT:GetNextAmmoType()
		return ACF.GetLegacyStyleClassName(self:PeekRound().AmmoType)
	end

	--- Removes the next round from the crate and returns it
	function ENT:TakeRound()
		local Index = GetNextKind(self)
		local Kind  = self.RoundKinds[Index or 1]

		if Index then
			Kind.Count = Kind.Count - 1
		end

		self:Consume(1)

		return Kind.BulletData, Kind.Ammo
	end

	-- The kind a round goes back into, one equal to it that is short of its count
	local function FindReturnKind(Entity, BulletData)
		for _, Kind in ipairs(Entity.RoundKinds) do
			local Own = Kind.BulletData

			if Kind.Count < Kind.Target and Own.AmmoType == BulletData.AmmoType and ACF.BulletEquality(Own, BulletData) then return Kind end
		end
	end

	--- True if a round like this one can be put back into the crate
	function ENT:CanReturnRound(BulletData)
		return FindReturnKind(self, BulletData) ~= nil
	end

	--- Puts a round back into the crate, among the rounds of its kind
	function ENT:ReturnRound(BulletData)
		local Kind = FindReturnKind(self, BulletData)

		if not Kind then return end

		Kind.Count = Kind.Count + 1

		self:Consume(-1)
	end

	--- Matches the kind counts to the amount again: rounds that came in fill from the bottom, rounds that left go from the top
	function ENT:SyncRoundCounts()
		local Kinds = self.RoundKinds

		if not Kinds then return end

		local Change = self.Amount or 0

		for _, Kind in ipairs(Kinds) do Change = Change - Kind.Count end

		for Depth = 0, #Kinds - 1 do
			local Kind = Kinds[StackIndex(Kinds, Change > 0 and #Kinds - 1 - Depth or Depth)]
			local Step = math.Clamp(Change, -Kind.Count, Kind.Target - Kind.Count)

			Kind.Count, Change = Kind.Count + Step, Change - Step
		end

		-- Clients draw each other kind from its count, the crate's own round fills the rest
		for Index = 2, #Kinds do
			self:SetNW2Int("RoundCount" .. ACF.GetCrateNWSuffix(Index - 1), Kinds[Index].Count)
		end
	end

	--- Every kind of round the crate is loaded with and how many of each are left, as a list of { BulletData, Ammo, Count }
	function ENT:GetRoundCounts()
		return self.RoundKinds
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

		if Amount <= 0 then return self.BaseClass.GetUnitMass(self) end

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

	-- Ammo types write their client data with SetNW2*, this redirects it to keys suffixed with the profile
	local function NetworkProfile(Entity, Ammo, BulletData, Profile)
		local Suffix = ACF.GetCrateNWSuffix(Profile)
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

	--- Rebuilds the kinds of rounds from the user vars, dropping the ones that no longer fit the crate
	function ENT:BuildOverrides()
		local AmmoList = self:ACF_GetUserVar("OverrideAmmo") or Empty
		local Counts   = self:ACF_GetUserVar("OverrideCounts") or Empty
		local Own     = self.RoundData
		local Kinds    = { { Ammo = Own, BulletData = self.BulletData, Bodygroup = GetCrateModel(self, Own, self.BulletData).Bodygroup or 0 } }

		for Index, Ammo in ipairs(AmmoList) do
			local Count = math.floor(tonumber(Counts[Index]) or 0)

			-- Missile crates and hand edited dupes past the type limit hold only their own round
			if Count > 0 and not self.IsMissileAmmo and #Kinds <= ACF.MaxOverrideTypes then
				self:PrepareAmmo(Ammo, Empty)

				local BulletData = Ammo:ServerConvert()

				if self:CanHoldRound(Ammo, BulletData) then
					Kinds[#Kinds + 1] = { Ammo = Ammo, BulletData = BulletData, Bodygroup = GetCrateModel(self, Ammo, BulletData).Bodygroup or 0, Target = Count }
				end
			end
		end

		local StoredAmmo, StoredCounts = {}, {}
		local Room = self.Capacity or 0

		-- Each other kind takes its count out of the crate's own, as far as there is room
		for Index = 2, #Kinds do
			local Kind = Kinds[Index]

			StoredAmmo[Index - 1], StoredCounts[Index - 1] = Kind.Ammo, Kind.Target

			Kind.Target = math.min(Kind.Target, Room)
			Room        = Room - Kind.Target

			Kind.BulletData.Crate        = self:EntIndex()
			Kind.BulletData.CrateProfile = Index - 1

			NetworkProfile(self, Kind.Ammo, Kind.BulletData, Index - 1)
		end

		Kinds[1].Target = Room

		-- The rounds in the crate are dealt out again, so a new mix applies straight away
		for _, Kind in ipairs(Kinds) do Kind.Count = 0 end

		self:ACF_SetUserVar("OverrideAmmo", StoredAmmo)
		self:ACF_SetUserVar("OverrideCounts", StoredCounts)

		self.RoundKinds = Kinds

		self:SyncRoundCounts()
	end

	function ENT:ClearOverrides()
		self:ACF_SetUserVar("OverrideAmmo", {})
		self:ACF_SetUserVar("OverrideCounts", {})
	end

	-- Applies a change to the user vars and everything that depends on the mix of rounds
	local function UpdateOverrides(Entity)
		Entity:BuildOverrides()
		Entity:QueueAmmoData()
		Entity:UpdateMass(true)
		Entity:UpdateOverlay(true)
	end

	-- Builds the round serialized crate data describes for the crate's own weapon, returns false and a reason if it can't hold it
	local function ParseRound(Entity, Data)
		local ClassDef = Entity.ACF_ClassDef

		Serialization.SanitizeClassFields(ClassDef, Data)

		local Ammo = Serialization.DeserializePartial(ClassDef, Data).AmmoType

		if not Ammo then return false, "Invalid ammo data." end

		Entity:PrepareAmmo(Ammo, Data)

		local CanHold, Reason = Entity:CanHoldRound(Ammo, Ammo:ServerConvert())

		if not CanHold then return false, Reason end

		return Ammo
	end

	--- Adds one round of serialized crate data (as the menu sends it) to the crate's mix, returns success and a message
	function ENT:ACF_AddRound(_, Data)
		if self.IsMissileAmmo then return false, "Missile crates can't mix rounds." end

		local Ammo, Reason = ParseRound(self, Data)

		if not Ammo then return false, Reason end
		if SameAmmo(Ammo, self.RoundData) then return false, "This is already the crate's own round." end

		local AmmoList = table.Copy(self:ACF_GetUserVar("OverrideAmmo") or Empty)
		local Counts   = table.Copy(self:ACF_GetUserVar("OverrideCounts") or Empty)
		local Index    = #AmmoList + 1

		for Other, Listed in ipairs(AmmoList) do
			if SameAmmo(Ammo, Listed) then Index = Other break end
		end

		if Index > ACF.MaxOverrideTypes then
			return false, "A crate can't hold more than " .. ACF.MaxOverrideTypes .. " other round types."
		end

		AmmoList[Index], Counts[Index] = AmmoList[Index] or Ammo, (Counts[Index] or 0) + 1

		self:ACF_SetUserVar("OverrideAmmo", AmmoList)
		self:ACF_SetUserVar("OverrideCounts", Counts)

		UpdateOverrides(self)

		return true, "The crate now holds " .. Counts[Index] .. " " .. ACF.GetLegacyStyleClassName(Classes.GetTypeName(Ammo:GetType())) .. "."
	end

	--- Sets how many rounds of each other kind the crate holds, in the order they were added, 0 removes a kind
	function ENT:ACF_SetRoundCounts(_, Counts)
		self:ACF_SetUserVar("OverrideCounts", Counts)

		UpdateOverrides(self)
	end
end
