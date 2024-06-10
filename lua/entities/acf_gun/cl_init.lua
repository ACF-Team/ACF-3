local ACF   = ACF
local Clock = ACF.Utilities.Clock
local Queued	= {}

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

	local SelfTbl = self:GetTable()
	local SinceFire = Clock.CurTime - SelfTbl.LastFire

	self:SetCycle(SinceFire * SelfTbl.Rate / SelfTbl.RateScale)

	if Clock.CurTime > SelfTbl.LastFire + SelfTbl.CloseTime and SelfTbl.CloseAnim then
		self:ResetSequence(SelfTbl.CloseAnim)
		self:SetCycle((SinceFire - SelfTbl.CloseTime) * SelfTbl.Rate / SelfTbl.RateScale)
		SelfTbl.Rate = 1 / (SelfTbl.Reload - SelfTbl.CloseTime) -- Base anim time is 1s, rate is in 1/10 of a second
		self:SetPlaybackRate(SelfTbl.Rate)
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

do	-- Overlay/networking for that

	function ENT:RequestGunInfo()
		if Queued[self] then return end

		Queued[self] = true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF.RequestGunInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end

	net.Receive("ACF.RequestGunInfo",function()
		local Gun = net.ReadEntity()
		if not IsValid(Gun) then return end

		Queued[Gun] = nil

		local Crates = util.JSONToTable(net.ReadString())
		local CrateEnts = {}

		for _,E in ipairs(Crates) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				local Col = ColorAlpha(Ent:GetColor(),25)
				CrateEnts[#CrateEnts + 1] = {Ent = Ent, Col = Col}
			end
		end

		Gun.Crates	= CrateEnts
		Gun.Age	= Clock.CurTime + 5
		Gun.HasData	= true
	end)

	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestGunInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestGunInfo()
		end

		render.SetColorMaterial()

		if next(SelfTbl.Crates) then
			for _,T in ipairs(SelfTbl.Crates) do
				local E = T.Ent
				if IsValid(E) then
					render.DrawWireframeBox(E:GetPos(),E:GetAngles(),E:OBBMins(),E:OBBMaxs(),T.Col,true)
					render.DrawBox(E:GetPos(),E:GetAngles(),E:OBBMins(),E:OBBMaxs(),T.Col)
				end
			end
		end
	end
end