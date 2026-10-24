do
	local GearboxEndMap = {
		[1] = "One Final, Dual Clutch",
		[2] = "Two Final, Dual Clutch"
	}

	function ENT:ACF_UpdateOverlayState(State)
		State:AddKeyValue("Predicted Drivetrain", GearboxEndMap[self.GearboxEndCount] or "All Wheel Drive")
	end

	function ENT:UpdateParentHint()
		local Contraption = self:CFW_GetContraption()

		ACF.Hints.Set(self, "controller_parent", Contraption == nil or Contraption.ACF_Baseplate ~= self.Baseplate)
	end
end