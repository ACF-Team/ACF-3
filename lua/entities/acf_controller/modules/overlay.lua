do
	local GearboxEndMap = {
		[1] = "One Final, Dual Clutch",
		[2] = "Two Final, Dual Clutch"
	}

	function ENT:ACF_UpdateOverlayState(State)
		State:AddKeyValue("Predicted Drivetrain", GearboxEndMap[self.GearboxEndCount] or "All Wheel Drive")

		local Contraption = self:GetContraption()
		if Contraption == nil or Contraption.ACF_Baseplate ~= self.Baseplate then
			State:AddWarning("Must be parented to baseplate or its contraption")
		end
	end
end