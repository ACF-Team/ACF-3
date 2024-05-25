local ACF		= ACF
local Clock		= ACF.Utilities.Clock
local Queued	= {}

include("shared.lua")

language.Add("Cleanup_acf_engine", "ACF Engines")
language.Add("Cleaned_acf_engine", "Cleaned up all ACF Engines")
language.Add("SBoxLimit__acf_engine", "You've reached the ACF Engines limit!")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel())
end

do	-- NET SURFER 2.0
	net.Receive("ACF_InvalidateEngineInfo",function()
		local Engine	= net.ReadEntity()

		if not IsValid(Engine) then return end

		Engine.HasData	= false
	end)

	net.Receive("ACF_RequestEngineInfo",function()
		local Engine	= net.ReadEntity()
		local Data		= util.JSONToTable(net.ReadString())
		local Outputs	= util.JSONToTable(net.ReadString())

		local OutEnts	= {}

		for _,E in ipairs(Outputs) do
			local Ent = Entity(E)
			local Pos = Ent:WorldToLocal(Ent:GetAttachment(Ent:LookupAttachment("input")).Pos)

			OutEnts[#OutEnts + 1] = {Ent = Ent, Pos = Pos}
		end

		Engine.Outputs	= OutEnts

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

	local red = Color(255,0,0)
	local orange = Color(255,127,0)
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

		local OutPos = self:LocalToWorld(SelfTbl.Driveshaft)
		for _,T in ipairs(SelfTbl.Outputs) do
			local E = T.Ent

			if IsValid(E) then

				local Pos = E:LocalToWorld(T.Pos)
				--render.DrawLine(OutPos, Pos, color_white, true)
				render.DrawBeam(OutPos, Pos, 2, 0, 0, color_black)
				render.DrawBeam(OutPos, Pos, 1.5, 0, 0, color_white)
				local SpherePos = LerpVector(Perc, OutPos, Pos)
				render.DrawSphere(SpherePos, 2, 4, 3, orange)

				if E.DrawLinks then
					E:DrawLinks(Rendered,false)
				end
			end
		end

		render.DrawSphere(OutPos, 2, 4, 3, red)
	end

	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestEngineInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestEngineInfo()
		end

		render.SetColorMaterial()

		self:DrawLinks({self = true}, true)

		local OutTextPos = self:LocalToWorld(SelfTbl.Driveshaft):ToScreen()
		cam.Start2D()
			draw.SimpleTextOutlined("Output","ACF_Title",OutTextPos.x,OutTextPos.y,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
		cam.End2D()
	end
end