local ACF = ACF

-- Whether weapons may take the kind at Index: RoundSelect above 0 picks one, otherwise the round filter decides
local function IsSelected(Entity, Index, Kind)
	local Select = Entity.RoundSelect

	if Select > 0 then return Index == Select end

	local Filter = Entity.RoundFilter

	return not Filter or Filter(Kind.BulletData, Kind.Ammo, Index)
end

-- Index of the first kind from the cycle's place, wrapping around, with rounds left that is selected or AnyKind allows
local function FindKind(Entity, AnyKind)
	local Kinds = Entity.RoundKinds
	local Count = #Kinds

	for Step = 0, Count - 1 do
		local Index = (Entity.CycleKind - 1 + Step) % Count + 1
		local Kind  = Kinds[Index]

		if Kind.Count > 0 and (AnyKind or IsSelected(Entity, Index, Kind)) then return Index end
	end
end

-- The kind of the next round to leave, any with rounds left if the selection allows none
local function GetNextKind(Entity)
	return FindKind(Entity) or FindKind(Entity, true)
end

local function UpdateSelection(Entity)
	Entity:UpdateLoading()

	Entity:UpdateOverlay()
end

do -- MARK: Selection
	--- Limits which rounds leave the crate to those Filter(BulletData, Ammo, Position) accepts, nil allows all of them
	function ENT:SetRoundFilter(Filter)
		self.RoundFilter = Filter

		UpdateSelection(self)
	end

	--- Limits the crate to the kind at this position in its list, 0 allows all of them
	function ENT:SetPositionFilter(Position)
		Position = math.max(math.floor(Position), 0)

		if Position == 0 then return self:SetRoundFilter(nil) end

		self:SetRoundFilter(function(_, _, Index) return Index == Position end)
	end

	--- Feeds only the kind at this position in the crate's list, 0 feeds them in turn in list order.
	--- Above 0 it overrides the round filter
	function ENT:SetRoundSelect(Position)
		self.RoundSelect = math.max(math.floor(Position), 0)

		UpdateSelection(self)
	end

	--- The index of the kind the next round leaves from, nil if the selection allows none
	function ENT:FindNextKind()
		return FindKind(self)
	end

	--- Rounds left that the selection lets weapons take
	function ENT:CountSelectedRounds()
		local Total = 0

		for Index, Kind in ipairs(self.RoundKinds) do
			if IsSelected(self, Index, Kind) then Total = Total + Kind.Count end
		end

		return Total
	end
end

do -- MARK: Round access
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
			Kind.Count     = Kind.Count - 1
			self.CycleKind = Index % #self.RoundKinds + 1
		end

		self:Consume(1)

		return Kind.BulletData, Kind.Ammo
	end

	-- The kind a round goes back into, one equal to it that is short of its count
	local function FindReturnKind(Entity, BulletData)
		for Index, Kind in ipairs(Entity.RoundKinds) do
			local Own = Kind.BulletData

			if Kind.Count < Kind.Target and Own.AmmoType == BulletData.AmmoType and ACF.BulletEquality(Own, BulletData) then return Index, Kind end
		end
	end

	--- True if a round like this one can be put back into the crate
	function ENT:CanReturnRound(BulletData)
		return FindReturnKind(self, BulletData) ~= nil
	end

	--- Puts a round back into the crate, among the rounds of its kind
	function ENT:ReturnRound(BulletData)
		local Index, Kind = FindReturnKind(self, BulletData)

		if not Index then return end

		Kind.Count     = Kind.Count + 1
		self.CycleKind = Index -- An unloaded round is loaded again before the cycle moves on

		self:Consume(-1)
	end

	--- Matches the kind counts to an amount of rounds: rounds in fill from the bottom, rounds out go from the top
	function ENT:SyncRoundCounts(Amount)
		local Kinds = self.RoundKinds

		if not Kinds then return end

		local Change = Amount
		local Last   = #Kinds

		for _, Kind in ipairs(Kinds) do Change = Change - Kind.Count end

		for Step = 1, Last do
			local Index = Change > 0 and Last + 1 - Step or Step
			local Kind  = Kinds[Index]
			local Moved = math.Clamp(Change, -Kind.Count, Kind.Target - Kind.Count)

			Kind.Count, Change = Kind.Count + Moved, Change - Moved

			self:SetNW2Int("RoundCount" .. ACF.GetCrateNWSuffix(Index - 1), Kind.Count) -- Drawn by clients
		end
	end
end

do -- MARK: Queries
	--- Every kind of round the crate is loaded with top first and how many of each are left,
	--- as a list of { BulletData, Ammo, Count, Target, Name }
	function ENT:GetRoundCounts()
		return self.RoundKinds
	end

	--- The round at this position in the crate's list, nothing past its end
	function ENT:GetRoundAt(Position)
		local Kind = self.RoundKinds[Position]

		if not Kind then return end

		return Kind.BulletData, Kind.Ammo
	end

	--- Rounds left of each kind, by position in the crate's list
	function ENT:GetPositionCounts()
		local Counts = {}

		for Index, Kind in ipairs(self:GetRoundCounts()) do
			Counts[Index] = Kind.Count
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
