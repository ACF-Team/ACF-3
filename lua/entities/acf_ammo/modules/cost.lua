
--	Used for figuring costs for gamemode related activities
function ENT:GetCost()
	local selftbl	= self:GetTable()

	--PrintTable(selftbl.BulletData)

	--print(selftbl.Capacity, selftbl.BulletData.AmmoType)

	if selftbl.IsMissileAmmo then
		local Cost	= selftbl.Capacity * selftbl.RoundData:GetCost(selftbl.BulletData)

		if selftbl.GuidanceData then
			Cost = Cost + selftbl.GuidanceData:GetCost()
		end

		if selftbl.FuzeData then
			Cost = Cost + selftbl.FuzeData:GetCost()
		end

		return Cost
	else
		return selftbl.Capacity * selftbl.RoundData:GetCost(selftbl.BulletData)
	end
end