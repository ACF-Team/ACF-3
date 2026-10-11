local ACF = ACF
local Round = math.Round
local floor = math.floor

-- Overlay Text 
function ENT:ACF_UpdateOverlayState(State)
    local Final  = ACF.ConvertGearRatio(self.FinalDrive, self.GearboxLegacyRatio)
    local Torque = Round(self.MaxTorque * ACF.TorqueMult * ACF.NmToFtLb)
    local Output = Round(self.TorqueOutput * ACF.TorqueMult * ACF.NmToFtLb)

    if not GearsText or GearsText == "" then
        local Gears = self.Gears

        GearsText = ""

        for I = 1, self.MaxGear do
            local Ratio = ACF.ConvertGearRatio(Gears[I], self.GearboxLegacyRatio)
            GearsText = GearsText .. "Gear " .. I .. ": " .. Ratio .. "\n"
        end
    end

    local RatioFormat = self.GearboxLegacyRatio and "Driven/Driver (Legacy)" or "Driver/Driven (Realistic)"
    State:AddNumber("Scale", self.ScaleMult)
    State:AddNumber("Current Gear", self.Gear)
    State:AddDivider()
    if self.ClassData.WriteGearOverlay then
        self.ClassData.WriteGearOverlay(self, State)
    else
        local Gears = self.Gears

        for I = 1, self.MaxGear do
            local Ratio = ACF.ConvertGearRatio(Gears[I], self.GearboxLegacyRatio)
            State:AddGearRatio("Gear " .. I, Ratio, "", self.GearboxLegacyRatio)
        end
    end
    State:AddDivider()
    State:AddNumber("Final Drive", Final)
    State:AddKeyValue("Ratio", RatioFormat)
    State:AddKeyValue("Torque Rating", ("%s Nm / %s ft-lb"):format(Round(self.MaxTorque * ACF.TorqueMult), Torque))
    State:AddKeyValue("Torque Output", ("%s Nm / %s ft-lb"):format(floor(self.TorqueOutput * ACF.TorqueMult), Output))
end
