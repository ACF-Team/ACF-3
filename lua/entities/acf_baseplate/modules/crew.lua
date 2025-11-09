local ACF      		= ACF

function ENT:UpdateAccuracyMod()
    self.CrewsByType = self.CrewsByType or {}
    local Sum1, Count1 = ACF.WeightedLinkSum(self.CrewsByType.Gunner or {}, function(Crew) return Crew.TotalEff end)
    local Sum2, Count2 = ACF.WeightedLinkSum(self.CrewsByType.Commander or {}, function(Crew) return Crew.TotalEff end)
    local Sum3, Count3 = ACF.WeightedLinkSum(self.CrewsByType.Pilot or {}, function(Crew) return Crew.TotalEff end)
    local Sum, Count = Sum1 + Sum2 + Sum3, Count1 + Count2 + Count3
    local Val = (Count > 0) and (Sum / Count) or 0
    self.AccuracyCrewMod = math.Clamp(Val, ACF.CrewFallbackCoef, 1)
    return self.AccuracyCrewMod
end

function ENT:UpdateFuelMod()
    self.CrewsByType = self.CrewsByType or {}
    local Sum1, Count1 = ACF.WeightedLinkSum(self.CrewsByType.Driver or {}, function(Crew) return Crew.TotalEff end)
    local Sum2, Count2 = ACF.WeightedLinkSum(self.CrewsByType.Pilot or {}, function(Crew) return Crew.TotalEff end)
    local Sum, Count = Sum1 + Sum2, Count1 + Count2
    local Val = (Count > 0) and (Sum / Count) or 0
    self.FuelCrewMod = math.Clamp(Val, ACF.CrewFallbackCoef, 1)
    if self:ACF_GetUserVar("BaseplateType").Name == "Recreational" then
        self.FuelCrewMod = 1 -- Recreational baseplates have no fuel consumption
    end
    return self.FuelCrewMod
end

function ENT:EnforceLooped()
    local BaseplateClass = self:ACF_GetUserVar("BaseplateType")
    if BaseplateClass.EnforceLooped then BaseplateClass.EnforceLooped(self) end
end