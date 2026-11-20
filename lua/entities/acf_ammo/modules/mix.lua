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

	--- Checks the crate can hold a round. The slots grow to fit the biggest one, so only the weapon and two piece matter
	function ENT:CanHoldRound(Ammo, BulletData)
		if Ammo.Blacklist and Ammo.Blacklist[Classes.GetTypeName(self:GetWeapon():GetType())] then
			return false, "This ammo type can't be used with this weapon."
		end

		if (BulletData.TwoPiece or false) ~= (self.BulletData.TwoPiece or false) then
			return false, "Two piece setting must match the crate's."
		end

		return true
	end
end

do -- MARK: Building
	local function RoundName(BulletData)
		local Tracer = (BulletData.Tracer or 0) > 0 and "-T" or ""

		return ACF.GetLegacyStyleClassName(BulletData.AmmoType) .. Tracer
	end

	--- The kinds the user vars list that the crate can hold, their counts as targets.
	--- A crate left with none holds only the round it was spawned with.
	--- Every kind takes the spawn round's two piece setting, it's one setting for the whole crate
	function ENT:ReadKinds()
		local AmmoList = self:ACF_GetUserVar("Rounds") or Empty
		local Counts   = self:ACF_GetUserVar("RoundCounts") or Empty
		local TwoPiece = self.RoundData.TwoPiece
		local Kinds    = {}

		for Index, Ammo in ipairs(self:CanMixRounds() and AmmoList or Empty) do
			local Count = math.floor(tonumber(Counts[Index]) or 0)

			if Count > 0 and #Kinds < ACF.MaxRoundKinds then
				self:PrepareAmmo(Ammo, Empty)

				if TwoPiece ~= nil and Classes.GetTypeFieldByName(Ammo:GetType(), "TwoPiece") then
					Ammo.TwoPiece = TwoPiece
				end

				local BulletData = Ammo:ServerConvert()

				if self:CanHoldRound(Ammo, BulletData) then
					Kinds[#Kinds + 1] = { Ammo = Ammo, BulletData = BulletData, Target = Count }
				end
			end
		end

		-- Targets are weights, FitCounts scales this to the whole crate
		if not Kinds[1] then
			Kinds[1] = { Ammo = self.RoundData, BulletData = self.BulletData, Target = 1 }
		end

		return Kinds
	end

	-- Scales the counts to fill the crate exactly, a mix copied from another crate size keeps its proportions
	local function FitCounts(Kinds, Capacity)
		local Targets = {}

		for Index, Kind in ipairs(Kinds) do Targets[Index] = Kind.Target end

		for Index, Count in ipairs(ACF.FitRoundCounts(Targets, Capacity)) do Kinds[Index].Target = Count end

		-- A crate always keeps one kind, even with no room for it
		for Index = #Kinds, 1, -1 do
			if Kinds[Index].Target == 0 and #Kinds > 1 then table.remove(Kinds, Index) end
		end
	end

	-- Custom names stay as they are, the same auto name twice gets a number
	local function NameKinds(Kinds)
		local Seen = {}

		for _, Kind in ipairs(Kinds) do
			local Custom = string.Trim(Kind.Ammo.KindName or "")

			if Custom ~= "" then
				Kind.Name = Custom
			else
				local Name  = RoundName(Kind.BulletData)
				local Count = (Seen[Name] or 0) + 1

				Seen[Name] = Count
				Kind.Name  = Count > 1 and Name .. " (" .. Count .. ")" or Name
			end
		end
	end

	-- Read by ACF.GetKindColor, -1 follows the crate's color
	local function NetworkKindColor(Entity, Index, Ammo)
		Entity:SetNW2Int("KindColor" .. ACF.GetCrateNWSuffix(Index - 1), Ammo.OverrideColor and Ammo.KindColor or -1)
	end

	--- Sets the tracer color of a kind of round, Override false makes it the crate's color again.
	--- Packed is 0xRRGGBB, left out it keeps the color it had
	function ENT:SetKindColor(Index, Override, Packed)
		local Kind = self.RoundKinds and self.RoundKinds[Index]

		if not Kind then return false end

		local Ammo = Kind.Ammo -- The same instance as in the Rounds user var, dupes keep it

		Ammo.OverrideColor = Override

		if Packed then Ammo.KindColor = math.Clamp(math.floor(Packed), 0, 0xFFFFFF) end

		NetworkKindColor(self, Index, Ammo)

		return true
	end

	-- Fills in what the rest of the crate reads off each kind and networks its round data
	local function PrepareKinds(Entity, Kinds)
		NameKinds(Kinds)

		for Index, Kind in ipairs(Kinds) do
			local BulletData = Kind.BulletData
			local Ammo       = Kind.Ammo

			BulletData.Crate        = Entity:EntIndex()
			BulletData.CrateProfile = Index - 1

			Kind.Bodygroup = GetCrateModel(Entity, Ammo, BulletData).Bodygroup or 0
			Kind.Count     = 0 -- The rounds are dealt out again, so a new mix applies straight away

			NetworkProfile(Entity, Ammo, BulletData, Index - 1)
			NetworkKindColor(Entity, Index, Ammo)
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

	--- Rebuilds the kinds of rounds from the user vars, or from kinds ReadKinds already made
	function ENT:BuildRounds(Kinds)
		Kinds = Kinds or self:ReadKinds()

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
