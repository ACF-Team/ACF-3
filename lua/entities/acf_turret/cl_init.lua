local ACF		= ACF
local Clock		= ACF.Utilities.Clock
local Queued	= {}

DEFINE_BASECLASS("acf_base_scalable")

include("shared.lua")

language.Add("Cleanup__acf_turret", "ACF Turrets")
language.Add("Cleanup__acf_turret", "Cleaned up all ACF turrets!")
language.Add("SBoxLimit__acf_turret", "You've reached the ACF turrets limit!")

do	-- NET SURFER
	net.Receive("ACF_RequestTurretInfo",function()
		local Entity	= net.ReadEntity()
		local Rotator	= net.ReadEntity()
		local Data		= util.JSONToTable(net.ReadString())

		if not IsValid(Entity) then return end

		Entity.Rotator	= Rotator
		Entity.LocalCoM = Data.LocalCoM
		Entity.Mass		= Data.Mass
		Entity.MinDeg	= Data.MinDeg
		Entity.MaxDeg	= Data.MaxDeg
		Entity.CoMDist	= Data.CoMDist

		Entity.HasData	= true
		Entity.Age		= Clock.CurTime + 5

		if Queued[Entity] then Queued[Entity] = nil end
	end)

	function ENT:RequestTurretInfo()
		if Queued[self] then return end

		Queued[self] = true

		net.Start("ACF_RequestTurretInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end
end

do	-- Overlay
	local red = Color(255,0,0)
	local green = Color(0,255,0)
	local orange = Color(255,127,0)
	local magenta = Color(255,0,255)

	function ENT:DrawOverlay(Trace)
		if not self.HasData then
			self:RequestTurretInfo()

			return
		elseif Clock.CurTime > self.Age then
			self:RequestTurretInfo()
		end

		local UX = self:GetUp() * 0.5
		local X = self:OBBMaxs().x
		local Pos = self:LocalToWorld(self:OBBCenter())

		render.DrawLine(Pos + UX,Pos + (self:GetForward() * X) + UX,orange,true)

		if IsValid(self.Rotator) then render.DrawLine(Pos,Pos + self.Rotator:GetForward() * X,green,true) end

		local LocPos = self:WorldToLocal(Trace.HitPos)
		local LocDir = Vector(LocPos.x,LocPos.y,0):GetNormalized()

		render.DrawLine(Pos - UX,self:LocalToWorld(self:OBBCenter() + LocDir * X * 2) - UX,magenta,true)

		render.DrawLine(self:LocalToWorld(self:OBBCenter()),self.Rotator:LocalToWorld(self.LocalCoM),red,true)

		render.OverrideDepthEnable(true,true)
			render.DrawWireframeSphere(self.Rotator:LocalToWorld(self.LocalCoM),1.5,4,3,red)
		render.OverrideDepthEnable(false,false)

		if not ((self.MinDeg == -180) and (self.MaxDeg == 180)) then
			local MinDir = Vector(X,0,0)
			MinDir:Rotate(Angle(0,-self.MinDeg,0))
			local MaxDir = Vector(X,0,0)
			MaxDir:Rotate(Angle(0,-self.MaxDeg,0))
			render.DrawLine(Pos - UX,self:LocalToWorld(self:OBBCenter() + MinDir) - UX,red,true)
			render.DrawLine(Pos - UX,self:LocalToWorld(self:OBBCenter() + MaxDir) - UX,green,true)
		end

		local HomePos = (Pos + UX + self:GetForward() * X):ToScreen()
		local CurPos = (Pos + self.Rotator:GetForward() * X):ToScreen()
		local AimPos = (self:LocalToWorld(self:OBBCenter() + LocDir * X) - UX):ToScreen()

		local CoMPos = (self.Rotator:LocalToWorld(self.LocalCoM) - Vector(0,0,2)):ToScreen()

		cam.Start2D()
			draw.SimpleTextOutlined("Zero","DermaDefault",HomePos.x,HomePos.y,orange,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
			draw.SimpleTextOutlined("Current: " .. -math.Round(self:WorldToLocalAngles(self.Rotator:GetAngles()).yaw,2),"DermaDefault",CurPos.x,CurPos.y,green,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
			draw.SimpleTextOutlined("Aim: " .. -math.Round(self:WorldToLocalAngles(self:LocalToWorldAngles(LocDir:Angle())).yaw,2),"DermaDefault",AimPos.x,AimPos.y,magenta,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)

			draw.SimpleTextOutlined("Mass: " .. self.Mass .. "kg","DermaDefault",CoMPos.x,CoMPos.y,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
			draw.SimpleTextOutlined("Lateral Distance: " .. self.CoMDist .. "u","DermaDefault",CoMPos.x,CoMPos.y + 16,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
		cam.End2D()
	end
end