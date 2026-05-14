local Clock		= ACF.Utilities.Clock
local Queued	= {}

include ("shared.lua")

language.Add("Cleanup_acf_radar", "ACF Radars")
language.Add("Cleaned_acf_radar", "Cleaned up all ACF Radars")
language.Add("SBoxLimit__acf_radar", "You've hit the ACF Radar limit!")

do	-- Overlay/networking
	function ENT:RequestRadarInfo()
		if Queued[self] then return end

		Queued[self]	= true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF.RequestRadarInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end

	net.Receive("ACF.RequestRadarInfo", function()
		local Radar = net.ReadEntity()
		if not IsValid(Radar) then return end

		Queued[Radar] = nil

		local RadarInfo	= util.JSONToTable(net.ReadString())

		Radar.Spherical	= RadarInfo.Spherical
		Radar.Cone		= RadarInfo.Cone
		Radar.Origin	= RadarInfo.Origin
		Radar.Range		= RadarInfo.Range

		Radar.HasData	= true
		Radar.Age		= Clock.CurTime + 5
	end)

	local Col = Color(255, 255, 0, 25)
	local Col2 = Color(255, 255, 0)
	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestRadarInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestRadarInfo()
		end

		local Origin = self:LocalToWorld(SelfTbl.Origin)
		if SelfTbl.Spherical then
			render.DrawWireframeSphere(Origin, SelfTbl.Range, 50, 50, Col2)
		else

			for I = 0, 7 do
				local Dir = Vector(16384, 0, 0)
				Dir:Rotate(Angle(SelfTbl.Cone, 0, 0))
				Dir:Rotate(Angle(0, 0, 45 * I))
				local Point = self:LocalToWorld(SelfTbl.Origin + Dir)
				local Dir2 = Vector(16384, 0, 0)
				Dir2:Rotate(Angle(SelfTbl.Cone, 0, 0))
				Dir2:Rotate(Angle(0, 0, 45 * (I + 1)))
				local Point2 = self:LocalToWorld(SelfTbl.Origin + Dir2)

				render.DrawQuad(Origin, Point, Point2, Point, Col)
				render.DrawLine(Point, Point2, Col, true)
				render.DrawLine(Origin, Point, Col, true)
			end
		end
	end
end