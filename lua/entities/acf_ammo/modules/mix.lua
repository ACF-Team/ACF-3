local ACF     = ACF
local Classes = ACF.Classes
local Empty   = {}

local NW_DEFAULTS = { SetNW2String = "", SetNW2Float = 0, SetNW2Int = 0 } -- What clients read when a key was never set

-- Ammo types write their client data with SetNW2*, this redirects it to keys suffixed with the profile.
-- Keys an earlier round on the profile wrote and this one doesn't are reset, or clients would read them as this round's
local function NetworkProfile(Entity, Ammo, BulletData, Profile)
	local Suffix  = ACF.GetCrateNWSuffix(Profile)
	local Earlier = Entity.ProfileKeys[Profile] or Empty
	local Written = {}
	local Proxy   = {}

	for Setter in pairs(NW_DEFAULTS) do
		Proxy[Setter] = function(_, Key, Value)
			Entity[Setter](Entity, Key .. Suffix, Value)

			Written[Key] = Setter
		end
	end

	Ammo:Network(Proxy, BulletData)

	for Key, Setter in pairs(Earlier) do
		if not Written[Key] then Entity[Setter](Entity, Key .. Suffix, NW_DEFAULTS[Setter]) end
	end

	Entity.ProfileKeys[Profile] = Written
end

local function GetCrateModel(Entity, Ammo, BulletData)
	local Weapon = not Entity.ClassData.IsScalable and Entity.WeaponData or nil

	return Ammo:ResolveModel("Crate", Entity.ClassData, Weapon, BulletData.TwoPiece)
end

do -- MARK: Validation
	--- Missile crates hold only the round they were spawned with
	function ENT:CanMixRounds()
		return not self.IsMissileAmmo
	end

	--- Checks a round fits the crate's slots, sized for its spawn round. Returns false and a reason if not
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
end

do -- MARK: Building
	local function RoundName(BulletData)
		local Tracer = (BulletData.Tracer or 0) > 0 and "-T" or ""

		return ACF.GetLegacyStyleClassName(BulletData.AmmoType) .. Tracer
	end

	-- The kinds the user vars list that the crate can hold, their counts as targets.
	-- A crate left with none holds only the round it was spawned with
	local function ReadKinds(Entity)
		local AmmoList = Entity:ACF_GetUserVar("Rounds") or Empty
		local Counts   = Entity:ACF_GetUserVar("RoundCounts") or Empty
		local Kinds    = {}

		for Index, Ammo in ipairs(Entity:CanMixRounds() and AmmoList or Empty) do
			local Count = math.floor(tonumber(Counts[Index]) or 0)

			if Count > 0 and #Kinds < ACF.MaxRoundKinds then
				Entity:PrepareAmmo(Ammo, Empty)

				local BulletData = Ammo:ServerConvert()

				if Entity:CanHoldRound(Ammo, BulletData) then
					Kinds[#Kinds + 1] = { Ammo = Ammo, BulletData = BulletData, Target = Count }
				end
			end
		end

		if not Kinds[1] then
			Kinds[1] = { Ammo = Entity.RoundData, BulletData = Entity.BulletData, Target = Entity.Capacity or 0 }
		end

		return Kinds
	end

	-- Scales the counts to fill the crate exactly, a mix copied from another crate size keeps its proportions
	local function FitCounts(Kinds, Capacity)
		local Total = 0

		for _, Kind in ipairs(Kinds) do Total = Total + Kind.Target end

		if Total > 0 and Total ~= Capacity then
			local Left = Capacity

			for Index, Kind in ipairs(Kinds) do
				local Scaled = math.min(Left, math.Round(Kind.Target * Capacity / Total))

				Kind.Target = Index == #Kinds and Left or Scaled
				Left        = Left - Kind.Target
			end
		end

		-- A crate always keeps one kind, even with no room for it
		for Index = #Kinds, 1, -1 do
			if Kinds[Index].Target == 0 and #Kinds > 1 then table.remove(Kinds, Index) end
		end
	end

	-- Fills in what the rest of the crate reads off each kind and networks its round data
	local function PrepareKinds(Entity, Kinds)
		for Index, Kind in ipairs(Kinds) do
			local BulletData = Kind.BulletData

			BulletData.Crate        = Entity:EntIndex()
			BulletData.CrateProfile = Index - 1

			Kind.Name      = RoundName(BulletData)
			Kind.Bodygroup = GetCrateModel(Entity, Kind.Ammo, BulletData).Bodygroup or 0
			Kind.Count     = 0 -- The rounds are dealt out again, so a new mix applies straight away

			NetworkProfile(Entity, Kind.Ammo, BulletData, Index - 1)
		end
	end

	--- The crate's kinds of rounds as two lists top first: the ammo of each and how many it holds
	function ENT:GetMix()
		local AmmoList, Counts = {}, {}

		for Index, Kind in ipairs(self.RoundKinds) do
			AmmoList[Index], Counts[Index] = Kind.Ammo, Kind.Target
		end

		return AmmoList, Counts
	end

	--- Rebuilds the kinds of rounds from the user vars, dropping the ones that no longer fit
	function ENT:BuildRounds()
		local Kinds = ReadKinds(self)

		FitCounts(Kinds, self.Capacity or 0)
		PrepareKinds(self, Kinds)

		self.RoundKinds      = Kinds
		self.CycleKind       = 1
		self.RoundMixVersion = (self.RoundMixVersion + 1) % 2 ^ self.MixVersionBits

		local AmmoList, Counts = self:GetMix() -- Stored back so the user vars match what the crate holds

		self:ACF_SetUserVar("Rounds", AmmoList)
		self:ACF_SetUserVar("RoundCounts", Counts)
		self:SyncRoundCounts(self.Amount or 0)
	end
end
