local ACF   = ACF
local Clock = ACF.Utilities.Clock
local Weapons = ACF.Classes.Weapons
local Queued	= {}

include("shared.lua")

killicon.Add("acf_gun", "HUD/killicons/acf_gun", ACF.KillIconColor)

function ENT:Initialize(...)
	self.LastFire 	= 0
	self.Reload 	= 0
	self.CloseTime 	= 0
	self.Rate 		= 0
	self.RateScale 	= 0
	self.FireAnim 	= self:LookupSequence("shoot")
	self.CloseAnim 	= self:LookupSequence("load")

	self.BaseClass.Initialize(self, ...)
end

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel(), self:GetScale())
end

function ENT:OnResized(_, Scale)
	self.HitBoxes = ACF.GetHitboxes(self:GetModel(), Scale)
end

function ENT:Think()
	self.BaseClass.Think(self)

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
		self.CloseTime = math.max(ReloadTime - 0.75, (ReloadTime / 2) - (LocalPlayer():Ping() / 1000))
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
	local Purple = Color(255, 0, 255, 100)
	local Cyan = Color(0, 255, 255, 100)
	function ENT:RequestGunInfo()
		if Queued[self] then return end

		Queued[self] = true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF.RequestGunInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end

	net.Receive("ACF.RequestGunInfo", function()
		local Gun = net.ReadEntity()
		if not IsValid(Gun) then return end

		Queued[Gun] = nil

		local Crates = util.JSONToTable(net.ReadString())
		local CrateEnts = {}

		for _, E in ipairs(Crates) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				local Col = ColorAlpha(Ent:GetColor(), 25)
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

		local Length = self:GetNW2Float("Length", 0)
		local Class = self:GetNWString("ACF_Class")
		local ClassData = Weapons.Get(Class)
		if not ClassData then return end

		if ClassData.BreechConfigs and Length > 0 then
			local BreechIndex = self:GetNW2Int("BreechIndex", 1)
			local Caliber = self:GetNW2Float("Caliber", 0)
			local Depth = -Length / ACF.InchToCm / 2

			local Scale = Caliber / ClassData.BreechConfigs.MeasuredCaliber
			for Index, Config in ipairs(ClassData.BreechConfigs.Locations) do
				local Pos = self:LocalToWorld(Config.LPos * Scale)
				local Ang = self:LocalToWorldAngles(Config.LAng)
				local MinBox = Vector(Depth, -Config.Width / 2 * Scale, -Config.Height / 2 * Scale)
				local MaxBox = Vector(0, Config.Width / 2 * Scale, Config.Height / 2 * Scale)

				render.DrawWireframeBox(Pos, Ang, MinBox, MaxBox, Index == BreechIndex and Purple or Cyan, true)
				if Index == BreechIndex then render.DrawWireframeSphere(Pos, 2, 10, 10, Purple, true) end -- Draw the location of the breech
			end
		end

		-- Get the currently selected crate
		local CrateID = self:GetNW2Int("CurCrate", 0)
		local Temp = Entity(CrateID)

		if next(SelfTbl.Crates) then
			for _, T in ipairs(SelfTbl.Crates) do
				local E = T.Ent

				if IsValid(E) then
					local Pos  = E:GetPos()
					local Ang  = E:GetAngles()
					local Mins = E:OBBMins()
					local Maxs = E:OBBMaxs()

					-- Double outline selected crate for visibility
					if E == Temp then
						render.DrawWireframeBox(Pos, Ang, Mins * 1.1, Maxs * 1.1, T.Col, true)
					end

					render.DrawWireframeBox(Pos, Ang, Mins, Maxs, T.Col, true)
					render.DrawBox(Pos, Ang, Mins, Maxs, T.Col)
					if E.DrawStage then E:DrawStage() end
				end
			end
		end
	end
end