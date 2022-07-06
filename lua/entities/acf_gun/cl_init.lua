local ACF   = ACF
local Clock = ACF.Utilities.Clock

DEFINE_BASECLASS("acf_base_scalable") -- Required to get the local BaseClass

include("shared.lua")

language.Add("Cleanup_acf_gun", "ACF Weapons")
language.Add("Cleaned_acf_gun", "Cleaned up all ACF Weapons")
language.Add("Cleanup_acf_smokelauncher", "ACF Smoke Launchers")
language.Add("SBoxLimit__acf_gun", "You've reached the ACF Weapons limit!")
language.Add("Cleaned_acf_smokelauncher", "Cleaned up all ACF Smoke Launchers")
language.Add("SBoxLimit__acf_smokelauncher", "You've reached the ACF Smoke Launcher limit!")

killicon.Add("acf_gun", "HUD/killicons/acf_gun", ACF.KillIconColor)

function ENT:Initialize(...)
	self.LastFire 	= 0
	self.Reload 	= 0
	self.CloseTime 	= 0
	self.Rate 		= 0
	self.RateScale 	= 0
	self.FireAnim 	= self:LookupSequence("shoot")
	self.CloseAnim 	= self:LookupSequence("load")

	BaseClass.Initialize(self, ...)
end

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel(), self:GetScale())
end

function ENT:OnResized(_, Scale)
	self.HitBoxes = ACF.GetHitboxes(self:GetModel(), Scale)
end

function ENT:Think()
	BaseClass.Think(self)

	local SinceFire = Clock.CurTime - self.LastFire

	self:SetCycle(SinceFire * self.Rate / self.RateScale)

	if Clock.CurTime > self.LastFire + self.CloseTime and self.CloseAnim then
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
	self.LastFire = Clock.CurTime
	self.Reload = ReloadTime
end
