local ACF		= ACF
local Clock		= ACF.Utilities.Clock
local Queued	= {}

include("shared.lua")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel(), self:GetScale())
end

function ENT:OnResized()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel(), self:GetScale())
end

do	-- NET SURFER 2.0
	net.Receive("ACF_InvalidateGearboxInfo", function()
		local Gearbox	= net.ReadEntity()

		if not IsValid(Gearbox) then return end

		Gearbox.HasData	= false
	end)

	net.Receive("ACF_RequestGearboxInfo", function()
		local Gearbox	= net.ReadEntity()
		local Data		= util.JSONToTable(net.ReadString())
		local Inputs	= util.JSONToTable(net.ReadString())
		local OutL		= util.JSONToTable(net.ReadString())
		local OutR		= util.JSONToTable(net.ReadString())

		local InEnts	= {}
		local OutLEnts	= {}
		local OutREnts	= {}

		for _, E in ipairs(Inputs) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				InEnts[#InEnts + 1] = {Ent = Ent}
			end
		end

		for _, E in ipairs(OutL) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				local Pos = Vector()

				if Ent:GetClass() == "acf_gearbox" then
					Pos = Ent:WorldToLocal(Ent:GetAttachment(Ent:LookupAttachment("input")).Pos)
				end

				OutLEnts[#OutLEnts + 1] = {Ent = Ent, Pos = Pos}
			end
		end
		for _, E in ipairs(OutR) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				local Pos = Vector()

				if Ent:GetClass() == "acf_gearbox" then
					Pos = Ent:WorldToLocal(Ent:GetAttachment(Ent:LookupAttachment("input")).Pos)
				end

				OutREnts[#OutREnts + 1] = {Ent = Ent, Pos = Pos}
			end
		end

		Gearbox.Inputs		= InEnts
		Gearbox.OutputsL	= OutLEnts
		Gearbox.OutputsR	= OutREnts

		Gearbox.In		= Data.In
		Gearbox.OutL	= Data.OutL
		Gearbox.OutR	= Data.OutR
		Gearbox.Mid		= (Data.OutL + Data.OutR) / 2

		Gearbox.IsStraight = (Data.OutL == Data.OutR)

		Gearbox.HasData	= true
		Gearbox.Age		= Clock.CurTime + 5

		Queued[Gearbox]	= nil
	end)

	function ENT:RequestGearboxInfo()
		if Queued[self] then return end

		Queued[self]	= true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF_RequestGearboxInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end
end

do	-- Overlay
	-- Rendered is used to prevent re-rendering as part of the extended link rendering
	-- Focus will render links different to show what is linked

	local orange = Color(255, 127, 0)
	local teal = Color(0, 195, 255)
	local red = Color(255, 0, 0)
	local green = Color(0, 255, 0)
	local innerConnection = Color(127, 127, 127)
	local outerConnection = Color(255, 255, 255)

	function ENT:DrawLinks(Rendered)
		if Rendered[self] then return end
		local SelfTbl = self:GetTable()

		Rendered[self] = true

		if not SelfTbl.HasData then
			self:RequestGearboxInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestGearboxInfo()
		end

		local Perc = (Clock.CurTime / 2) % 1

		local InPos		= self:LocalToWorld(SelfTbl.In)
		local LeftPos	= self:LocalToWorld(SelfTbl.OutL)
		local RightPos	= self:LocalToWorld(SelfTbl.OutR)
		local MidPoint	= self:LocalToWorld(SelfTbl.Mid)

		-- Rendering more along the chain
		for _, T in ipairs(SelfTbl.Inputs) do
			local E = T.Ent

			if IsValid(E) and E.DrawLinks then
				E:DrawLinks(Rendered, false)
			end
		end

		if not SelfTbl.IsStraight then
			render.DrawBeam(LeftPos, RightPos, 2, 0, 0, color_black)
			render.DrawBeam(LeftPos, RightPos, 1.5, 0, 0, innerConnection)
			render.DrawBeam(InPos, MidPoint, 2, 0, 0, color_black)
			render.DrawBeam(InPos, MidPoint, 1.5, 0, 0, innerConnection)

			local SpherePos1 = LerpVector(Perc, InPos, MidPoint)
			render.DrawSphere(SpherePos1, 1.5, 4, 3, orange)
			local SpherePos2 = LerpVector(Perc, MidPoint, LeftPos)
			render.DrawSphere(SpherePos2, 1.5, 4, 3, orange)
			local SpherePos3 = LerpVector(Perc, MidPoint, RightPos)
			render.DrawSphere(SpherePos3, 1.5, 4, 3, orange)
		else
			render.DrawBeam(InPos, LeftPos, 2, 0, 0, color_black)
			render.DrawBeam(InPos, LeftPos, 1.5, 0, 0, innerConnection)

			local SpherePos1 = LerpVector(Perc, InPos, LeftPos)
			render.DrawSphere(SpherePos1, 1.5, 4, 3, orange)
		end

		for _, T in ipairs(SelfTbl.OutputsL) do
			local E = T.Ent

			if IsValid(E) then

				local Pos = E:LocalToWorld(T.Pos)
				render.DrawBeam(LeftPos, Pos, 2, 0, 0, color_black)
				render.DrawBeam(LeftPos, Pos, 1.5, 0, 0, outerConnection)
				local SpherePos = LerpVector(Perc, LeftPos, Pos)
				render.DrawSphere(SpherePos, 1.5, 4, 3, orange)

				if E.DrawLinks then
					E:DrawLinks(Rendered, false)
				else -- prop
					render.DrawSphere(Pos, 2, 4, 3, teal)
				end
			end
		end

		for _, T in ipairs(SelfTbl.OutputsR) do
			local E = T.Ent

			if IsValid(E) then

				local Pos = E:LocalToWorld(T.Pos)
				render.DrawBeam(RightPos, Pos, 2, 0, 0, color_black)
				render.DrawBeam(RightPos, Pos, 1.5, 0, 0, outerConnection)
				local SpherePos = LerpVector(Perc, RightPos, Pos)
				render.DrawSphere(SpherePos, 1.5, 4, 3, orange)

				if E.DrawLinks then
					E:DrawLinks(Rendered, false)
				else -- prop
					render.DrawSphere(Pos, 2, 4, 3, teal)
				end
			end
		end

		render.DrawSphere(InPos, 2, 4, 3, green)
		render.DrawSphere(LeftPos, 2, 4, 3, red)
		if not SelfTbl.IsStraight then
			render.DrawSphere(RightPos, 2, 4, 3, red)
		end
	end

	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestGearboxInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestGearboxInfo()
		end

		render.SetColorMaterial()

		self:DrawLinks({self = true}, true)

		local InTextPos = self:LocalToWorld(SelfTbl.In):ToScreen()
		local OutLTextPos = self:LocalToWorld(SelfTbl.OutL):ToScreen()
		local OutRTextPos = self:LocalToWorld(SelfTbl.OutR):ToScreen()

		cam.Start2D()
			draw.SimpleTextOutlined("Input", "ACF_Title", InTextPos.x, InTextPos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

			if SelfTbl.IsStraight then
				draw.SimpleTextOutlined("Output", "ACF_Title", OutLTextPos.x, OutLTextPos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			else
				draw.SimpleTextOutlined("Left Output", "ACF_Title", OutLTextPos.x, OutLTextPos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
				draw.SimpleTextOutlined("Right Output", "ACF_Title", OutRTextPos.x, OutRTextPos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			end
		cam.End2D()
	end
end

do -- Rendering mobility links
	local RopesCvar = GetConVar("acf_mobilityropelinks")
	local RopeMat = Material("cable/cable2")
	local RopeColor = Color(127, 127, 127)

	function ENT:Draw()
		self.BaseClass.Draw(self)

		if RopesCvar:GetBool() then
			self:DrawRopes({self = true}, true)
		end
	end

	function ENT:DrawRopes(Rendered)
		if Rendered[self] then return end

		local SelfTbl = self:GetTable()

		render.SetMaterial(RopeMat)
		Rendered[self] = true

		if not SelfTbl.HasData then
			self:RequestGearboxInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestGearboxInfo()
		end

		local LeftPos	= self:LocalToWorld(SelfTbl.OutL)
		local RightPos	= self:LocalToWorld(SelfTbl.OutR)

		for _, T in ipairs(SelfTbl.OutputsL) do
			local E = T.Ent

			if IsValid(E) then

				local Pos = E:LocalToWorld(T.Pos)
				render.DrawBeam(LeftPos, Pos, 1.5, 0, 0, RopeColor)
			end
		end

		for _, T in ipairs(SelfTbl.OutputsR) do
			local E = T.Ent

			if IsValid(E) then

				local Pos = E:LocalToWorld(T.Pos)
				render.DrawBeam(RightPos, Pos, 1.5, 0, 0, RopeColor)
			end
		end
	end
end