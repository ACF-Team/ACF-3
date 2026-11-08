local ACF           = ACF
local Classes       = ACF.Classes
local Serialization = Classes.Serialization

-- Applies a change to the user vars and everything that depends on the mix of rounds
local function SetMix(Entity, AmmoList, Counts)
	Entity:ACF_SetUserVar("Rounds", AmmoList)
	Entity:ACF_SetUserVar("RoundCounts", Counts)

	Entity:BuildRounds()
	Entity:UnloadWeapons() -- Loaded rounds keep the profile they left with, which may now be another kind's
	Entity:QueueAmmoData()
	Entity:UpdateMass(true)
	Entity:UpdateOverlay(true)
	Entity:UpdateLoading()
end

do -- MARK: Copying
	local function CoerceUserVar(Entity, Name, Value)
		local Field = Classes.GetTypeFieldByName(Entity.ACF_ClassDef, Name)

		Entity:ACF_SetUserVar(Name, Serialization.CoerceField(Field, Value))
	end

	--- Takes the mix the update data carries. The copy tool sends one, the menu doesn't and so empties it
	function ENT:SetRoundsFromData(Data)
		CoerceUserVar(self, "Rounds", Data.Rounds)
		CoerceUserVar(self, "RoundCounts", Data.RoundCounts)
	end
end

do -- MARK: Adding a round
	-- Two ammo instances are the same round if they share a type and every menu input
	local function SameAmmo(A, B)
		local Type = A:GetType()

		if Type ~= B:GetType() then return false end

		for _, Field in ipairs(Classes.GetTypeFields(Type)) do
			if Field.Menu and A[Field.Name] ~= B[Field.Name] then return false end
		end

		return true
	end

	-- Builds the round serialized crate data describes, false and a reason if the crate can't hold it
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

	-- Where a round goes in the list: with the same round if it's listed, otherwise at the bottom
	local function FindSlot(AmmoList, Ammo)
		for Index, Listed in ipairs(AmmoList) do
			if SameAmmo(Ammo, Listed) then return Index end
		end

		return #AmmoList + 1
	end

	-- The kind with the most rounds other than the one at Slot that can spare one
	local function FindDonor(Counts, Slot)
		local Donor

		for Index, Count in ipairs(Counts) do
			if Index ~= Slot and Count > 1 and (not Donor or Count > Counts[Donor]) then Donor = Index end
		end

		return Donor
	end

	local function NoDonorReason(Counts, Slot, Name)
		if #Counts == 1 and Slot == 1 then
			return "The crate already holds only " .. Name .. ", there is no other round to replace."
		elseif Slot <= #Counts then
			return "The crate already holds " .. Name .. ", and every other round in it is the last of its kind."
		end

		return "The crate has no room for another round, every round in it is the last of its kind."
	end

	--- Adds one round of serialized crate data (as the menu sends it) to the crate.
	--- It takes the place of one from the kind with the most rounds. Returns success and a message
	function ENT:ACF_AddRound(_, Data)
		if not self:CanMixRounds() then return false, "Missile crates can't mix rounds." end

		local Ammo, Reason = ParseRound(self, Data)

		if not Ammo then return false, Reason end

		local AmmoList, Counts = self:GetMix()
		local Slot             = FindSlot(AmmoList, Ammo)

		if Slot > ACF.MaxRoundKinds then
			return false, "A crate can't hold more than " .. ACF.MaxRoundKinds .. " kinds of rounds."
		end

		local Donor = FindDonor(Counts, Slot)
		local Name  = ACF.GetLegacyStyleClassName(Classes.GetTypeName(Ammo:GetType()))

		if not Donor then return false, NoDonorReason(Counts, Slot, Name) end

		AmmoList[Slot], Counts[Slot] = AmmoList[Slot] or Ammo, (Counts[Slot] or 0) + 1
		Counts[Donor] = Counts[Donor] - 1

		SetMix(self, AmmoList, Counts)

		return true, "The crate now holds " .. Counts[Slot] .. " " .. Name .. "."
	end
end

do -- MARK: Reordering
	--- Orders and counts the crate's kinds of rounds. Order lists current kind indices top first,
	--- Counts their counts. A kind left out is removed
	function ENT:ACF_SetRoundCounts(_, Order, Counts)
		local Kinds = self.RoundKinds
		local AmmoList, Stored, Seen = {}, {}, {}

		for Position, Index in ipairs(Order) do
			local Kind = Kinds[Index]

			if Kind and not Seen[Index] then
				Seen[Index] = true

				AmmoList[#AmmoList + 1] = Kind.Ammo
				Stored[#Stored + 1]     = Counts[Position]
			end
		end

		if not AmmoList[1] then return end

		SetMix(self, AmmoList, Stored)
	end
end
