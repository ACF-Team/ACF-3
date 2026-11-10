
--	Used for figuring costs for gamemode related activities

-- Cost of one round of a kind the crate holds. Per-round so a big crate can't dilute the seeker's cost away.
local function GetRoundCost(Entity, Kind)
	local Cost = Kind.Ammo:GetCost(Kind.BulletData)

	if Entity.IsMissileAmmo then
		if Entity.GuidanceData then
			Cost = Cost + Entity.GuidanceData:GetCost()
		end

		if Entity.FuzeData then
			Cost = Cost + Entity.FuzeData:GetCost()
		end
	end

	return Cost
end

function ENT:GetCost()
	local Cost = 0

	for _, Kind in ipairs(self.RoundKinds) do
		Cost = Cost + Kind.Target * GetRoundCost(self, Kind)
	end

	return Cost
end
