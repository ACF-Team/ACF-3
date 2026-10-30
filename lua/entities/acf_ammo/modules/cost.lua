
--	Used for figuring costs for gamemode related activities

--- Cost of one round. Per-round so a big crate can't dilute the seeker's cost away.
function ENT:GetRoundCost()
	local selftbl = self:GetTable()
	local Cost    = selftbl.RoundData:GetCost(selftbl.BulletData)

	if selftbl.IsMissileAmmo then
		if selftbl.GuidanceData then
			Cost = Cost + selftbl.GuidanceData:GetCost()
		end

		if selftbl.FuzeData then
			Cost = Cost + selftbl.FuzeData:GetCost()
		end
	end

	return Cost
end

function ENT:GetCost()
	local Cost = self.Capacity * self:GetRoundCost()

	-- Overridden slots swap the crate's round for their own
	for _, Round in pairs(self.SlotRounds) do
		Cost = Cost + Round.Ammo:GetCost(Round.BulletData) - self.RoundData:GetCost(self.BulletData)
	end

	return Cost
end
