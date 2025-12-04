local Text = "%s Baseplate\n\nBaseplate Size: %.1f x %.1f x %.1f\nBaseplate Health: %.1f%%\nTick Interval: %s"
function ENT:UpdateOverlayText()
	local h, mh = self.ACF.Health, self.ACF.MaxHealth
	local AltEDisabled = self:ACF_GetUserVar("DisableAltE") and "\n(Alt + E Entry Disabled)" or ""
	return Text:format(self:ACF_GetUserVar("BaseplateType").Name, self.Size[2], self.Size[1], self.Size[3], (h / mh) * 100, self:ACF_GetUserVar("GForceTicks")) .. AltEDisabled
end