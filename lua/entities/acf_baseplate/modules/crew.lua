local ACF      		= ACF

function ENT:UpdateDriverMod()
    self.CrewsByType = self.CrewsByType or {}
    local Sum1, Count1 = ACF.WeightedLinkSum(self.CrewsByType.Driver or {}, function(Crew) return Crew.TotalEff end)
    local Sum2, Count2 = ACF.WeightedLinkSum(self.CrewsByType.Pilot or {}, function(Crew) return Crew.TotalEff end)
    local Sum, Count = Sum1 + Sum2, Count1 + Count2
    local Val = (Count > 0) and (Sum / Count) or 0
    self.DriverCrewMod = (Val >= ACF.DriverEfficiencyThreshold) and 1 or ACF.CrewFallbackCoef
    if self:ACF_GetUserVar("BaseplateType").Name == "Recreational" then
        self.DriverCrewMod = 1 -- Recreational baseplates are meant to not require crew
    end
    return self.DriverCrewMod
end

function ENT:EnforceLooped()
    local BaseplateClass = self:ACF_GetUserVar("BaseplateType")
    if BaseplateClass.EnforceLooped then BaseplateClass.EnforceLooped(self) end
end