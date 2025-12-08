
--	Used for figuring costs for gamemode related activities
function ENT:GetCost()
	local selftbl	= self:GetTable()

	--PrintTable(selftbl.BulletData)

	--print(selftbl.Capacity, selftbl.BulletData.Type)

	return selftbl.Capacity * selftbl.RoundData:GetCost(selftbl.BulletData)
end