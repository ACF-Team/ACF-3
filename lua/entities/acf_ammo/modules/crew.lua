local ACF = ACF

local function GetReloadEff(Crew, Ammo1, Ammo2)
	local CrewPos = Crew:LocalToWorld(Crew.CrewModel.ScanOffsetL)
	local AmmoPos1 = Ammo1:GetPos()
	local AmmoPos2 = Ammo2:GetPos()
	local D1 = CrewPos:Distance(AmmoPos1)
	local D2 = CrewPos:Distance(AmmoPos2)

	return Crew.TotalEff * ACF.Normalize(D1 + D2, ACF.LoaderWorstDist, ACF.LoaderBestDist)
end

function ENT:UpdateStockMod()
	self.CrewsByType = self.CrewsByType or {}
	local Sum1, Count1 = ACF.WeightedLinkSum(self.CrewsByType.Loader or {}, GetReloadEff, self, self.RestockCrate or self)
	local Sum2, Count2 = ACF.WeightedLinkSum(self.CrewsByType.Commander or {}, GetReloadEff, self, self.RestockCrate or self)
	local Sum, _ = Sum1 + Sum2 * 0.5, Count1 + Count2
	self.StockCrewMod = math.Clamp(Sum, ACF.CrewFallbackCoef, 1)
	return self.StockCrewMod
end

function ENT:Think()
	self.Crews = self.Crews or {}
	self.CrewsByType = self.CrewsByType or {}
	if self.Weapons then for Weapon in pairs(self.Weapons) do
		if Weapon.Crews then for Crew in pairs(Weapon.Crews) do
			self.Crews[Crew] = true
			self.CrewsByType[Crew.CrewTypeID] = self.CrewsByType[Crew.CrewTypeID] or {}
			self.CrewsByType[Crew.CrewTypeID][Crew] = true
		end end
	end end
	self:NextThink(CurTime() + 1)
	return true
end