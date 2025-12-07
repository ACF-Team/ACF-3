function ENT:ACF_UpdateOverlayState(State)
	local BaseplateType = self:ACF_GetUserVar("BaseplateType")
	State:AddKeyValue("Type", BaseplateType.Name)
	State:AddSize("Size", self.Size[2], self.Size[1], self.Size[3])
	State:AddHealth("Health", self.ACF.Health, self.ACF.MaxHealth)

	if BaseplateType.ID == "Aircraft" then
		State:AddNumber("G-Force Ticks", self:ACF_GetUserVar("GForceTicks"))
	end
	if self:ACF_GetUserVar("DisableAltE") then
		State:AddLabel("Alt + E Entry Disabled")
	end
end