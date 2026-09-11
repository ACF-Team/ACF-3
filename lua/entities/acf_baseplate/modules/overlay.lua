function ENT:ACF_UpdateOverlayState(State)
	local BaseplateType = self:ACF_GetUserVar("BaseplateType")
	local TypeName = ACF.Classes.GetTypeName(BaseplateType:GetType())

	State:AddKeyValue("Type", BaseplateType.Name)
	State:AddSize("Size", self.BaseplateSize[2], self.BaseplateSize[1], self.BaseplateSize[3])
	State:AddHealth("Health", self.ACF.Health, self.ACF.MaxHealth)

	if TypeName == "ACF.Baseplates.Aircraft" then
		State:AddNumber("G-Force Ticks", BaseplateType.GForceTicks)
	end

	if self:ACF_GetUserVar("DisableAltE") then
		State:AddLabel("Alt + E Entry Disabled")
	end

	State:AddKeyValue("Network Optimization", self:ACF_GetUserVar("NetworkOptimization") and "Enabled" or "Disabled")
	State:AddKeyValue("Unfreeze On Entry", self:ACF_GetUserVar("UnfreezeOnEntry") and "Enabled" or "Disabled")

	if TypeName == "ACF.Baseplates.Recreational" then
		State:AddKeyValue("Recreational Explosions", BaseplateType.ExplodeOnCollisions and "Enabled" or "Disabled")
	end
end
