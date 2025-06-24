local ACF		= ACF
local Clock		= ACF.Utilities.Clock
local Queued	= {}

include("shared.lua")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel())
end

do	-- NET SURFER 2.0
	net.Receive("ACF_InvalidateEngineInfo", function()
		local Engine	= net.ReadEntity()

		if not IsValid(Engine) then return end

		Engine.HasData	= false
	end)

	net.Receive("ACF_RequestEngineInfo", function()
		local Engine	= net.ReadEntity()
		local Data		= util.JSONToTable(net.ReadString())
		local Outputs	= util.JSONToTable(net.ReadString())
		local Fuel		= util.JSONToTable(net.ReadString())

		local OutEnts	= {}
		local FuelTanks	= {}

		for _, E in ipairs(Outputs) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				local Pos = Ent:WorldToLocal(Ent:GetAttachment(Ent:LookupAttachment("input")).Pos)

				OutEnts[#OutEnts + 1] = {Ent = Ent, Pos = Pos}
			end
		end

		for _, E in ipairs(Fuel) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				FuelTanks[#FuelTanks + 1] = {Ent = Ent}
			end
		end

		Engine.Outputs	= OutEnts
		Engine.FuelTanks	= FuelTanks

		Engine.Driveshaft	= Data.Driveshaft

		Engine.HasData	= true
		Engine.Age		= Clock.CurTime + 5

		Queued[Engine]	= nil
	end)

	function ENT:RequestEngineInfo()
		if Queued[self] then return end

		Queued[self]	= true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF_RequestEngineInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end
end

do	-- Overlay
	-- Rendered is used to prevent re-rendering as part of the extended link rendering
	local source = Color(255, 255, 0)
	local orange = Color(255, 127, 0)

	function ENT:DrawLinks(Rendered)
		if Rendered[self] then return end
		local SelfTbl = self:GetTable()

		Rendered[self] = true

		if not SelfTbl.HasData then
			self:RequestEngineInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestEngineInfo()
		end

		-- draw links to gearboxes
		local Perc = (Clock.CurTime / 2) % 1
		local Rad = TimedCos(0.5, 2, 3, 0)

		local OutPos = self:LocalToWorld(SelfTbl.Driveshaft)

		for _, T in ipairs(SelfTbl.Outputs) do
			local E = T.Ent

			if IsValid(E) then
				local Pos = E:LocalToWorld(T.Pos)
				render.DrawBeam(OutPos, Pos, 2, 0, 0, color_black)
				render.DrawBeam(OutPos, Pos, 1.5, 0, 0, color_white)
				local SpherePos = LerpVector(Perc, OutPos, Pos)
				render.DrawSphere(SpherePos, 1.5, 4, 3, orange)

				if E.DrawLinks then
					E:DrawLinks(Rendered, false)
				end
			end
		end

		render.DrawSphere(OutPos, Rad, 4, 3, source)
	end

	local FuelColor	= Color(255, 255, 0, 25)

	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestEngineInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestEngineInfo()
		end

		render.SetColorMaterial()

		if next(SelfTbl.FuelTanks) then
			for _, T in ipairs(SelfTbl.FuelTanks) do
				local E = T.Ent
				if IsValid(E) then
					render.DrawWireframeBox(E:GetPos(), E:GetAngles(), E:OBBMins(), E:OBBMaxs(), FuelColor, true)
					render.DrawBox(E:GetPos(), E:GetAngles(), E:OBBMins(), E:OBBMaxs(), FuelColor)
				end
			end
		end

		self:DrawLinks({self = true}, true)

		local OutTextPos = self:LocalToWorld(SelfTbl.Driveshaft):ToScreen()
		cam.Start2D()
			draw.SimpleTextOutlined("Power Source", "ACF_Title", OutTextPos.x, OutTextPos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
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
			self:RequestEngineInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestEngineInfo()
		end

		local OutPos = self:LocalToWorld(SelfTbl.Driveshaft)

		for _, T in ipairs(SelfTbl.Outputs) do
			local E = T.Ent

			if IsValid(E) then
				local Pos = E:LocalToWorld(T.Pos)

				render.DrawBeam(OutPos, Pos, 1.5, 0, 0, RopeColor)
			end
		end
	end
end