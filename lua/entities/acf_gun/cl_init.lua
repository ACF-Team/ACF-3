include("shared.lua")

local HideInfo = ACF.HideInfoBubble

language.Add("Cleanup_acf_gun", "ACF Weapons")
language.Add("Undone_acf_gun", "Undone ACF Weapon")
language.Add("Cleaned_acf_gun", "Cleaned up all ACF Weapons")
language.Add("Cleanup_acf_smokelauncher", "ACF Smoke Launchers")
language.Add("SBoxLimit__acf_gun", "You've reached the ACF Weapons limit!")
language.Add("Cleaned_acf_smokelauncher", "Cleaned up all ACF Smoke Launchers")
language.Add("SBoxLimit__acf_smokelauncher", "You've reached the ACF Smoke Launcher limit!")

function ENT:Initialize()
	self.LastFire 	= 0
	self.Reload 	= 0
	self.CloseTime 	= 0
	self.Rate 		= 0
	self.RateScale 	= 0
	self.FireAnim 	= self:LookupSequence("shoot")
	self.CloseAnim 	= self:LookupSequence("load")

	self:Update()

	self.BaseClass.Initialize(self)
end

function ENT:Update()
	self.HitBoxes = ACF.HitBoxes[self:GetModel()]
end

-- copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
function ENT:Draw()
	self:DoNormalDraw(false, HideInfo())

	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	local SinceFire = CurTime() - self.LastFire

	self:SetCycle(SinceFire * self.Rate / self.RateScale)

	if CurTime() > self.LastFire + self.CloseTime and self.CloseAnim then
		self:ResetSequence(self.CloseAnim)
		self:SetCycle((SinceFire - self.CloseTime) * self.Rate / self.RateScale)
		self.Rate = 1 / (self.Reload - self.CloseTime) -- Base anim time is 1s, rate is in 1/10 of a second
		self:SetPlaybackRate(self.Rate)
	end
end

function ENT:Animate(ReloadTime, LoadOnly)
	if self.CloseAnim and self.CloseAnim > 0 then
		self.CloseTime = math.max(ReloadTime - 0.75, ReloadTime * 0.75)
	else
		self.CloseTime = ReloadTime
		self.CloseAnim = nil
	end

	self:ResetSequence(self.FireAnim)
	self:SetCycle(0)
	self.RateScale = self:SequenceDuration()

	if LoadOnly then
		self.Rate = 1000000
	else
		self.Rate = 1 / math.Clamp(self.CloseTime, 0.1, 1.5) --Base anim time is 1s, rate is in 1/10 of a second
	end

	self:SetPlaybackRate(self.Rate)
	self.LastFire = CurTime()
	self.Reload = ReloadTime
end
