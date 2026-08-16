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

	State:AddKeyValue("Network Optimization", self:ACF_GetUserVar("NetworkOptimization") and "Enabled" or "Disabled")
	State:AddKeyValue("Unfreeze On Entry", self:ACF_GetUserVar("UnfreezeOnEntry") and "Enabled" or "Disabled")

	if BaseplateType.ID == "Recreational" then
		State:AddKeyValue("Recreational Explosions", self:ACF_GetUserVar("ExplodeOnCollisions") and "Enabled" or "Disabled")
	end
end