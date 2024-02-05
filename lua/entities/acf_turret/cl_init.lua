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
		Entity.Type		= Data.Type

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

do	-- Turret drive drawing
	local DrawDist	= 1024 ^ 2
	local HideInfo = ACF.HideInfoBubble

	local function CSModel(Ent)
		if not IsValid(Ent) then return end

		if IsValid(Ent.CSModel) then
			if Ent.CSModel:GetModel() ~= Ent:GetModel() then Ent.CSModel:Remove() return end

			return Ent.CSModel
		end

		if not Ent.Matrix then return end

		local CSModel	= ClientsideModel(Ent:GetModel())
		CSModel:SetParent(Ent)
		CSModel:SetPos(Ent:GetPos())
		CSModel:SetAngles(Ent:GetAngles())
		CSModel:SetMaterial(Ent:GetMaterial())
		CSModel:SetColor(Ent:GetColor())

		CSModel.Material = Ent:GetMaterial()
		CSModel.Matrix = Ent.Matrix
		CSModel:EnableMatrix("RenderMultiply", CSModel.Matrix)

		Ent.CSModel	= CSModel

		return Ent.CSModel
	end

	function ENT:Draw()

		-- Partial from base_wire_entity, need the tooltip but without the model drawing since we're drawing our own
		local looked_at = self:BeingLookedAtByLocalPlayer()

		if looked_at then
			self:DrawEntityOutline()
			if not HideInfo() then self:AddWorldTip() end
		end

		local Rotator = self:GetNWEntity("ACF.Rotator")

		if (not IsValid(Rotator)) or ((EyePos()):DistToSqr(self:GetPos()) > DrawDist) then self:DrawModel() return end

		local CSM = CSModel(self)
		if not IsValid(CSM) then self:DrawModel() return end

		if CSM.Material ~= self:GetMaterial() then CSM:Remove() return end
		if CSM:GetColor() ~= self:GetColor() then CSM:Remove() return end
		if CSM.Matrix ~= self.Matrix then CSM:Remove() return end

		if CSM:GetParent() ~= self then CSM:Remove() return end

		CSM:SetAngles(Rotator:GetAngles())
	end

	function ENT:OnRemove()
		if IsValid(self.CSModel) then self.CSModel:Remove() end
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

		if self.Type == "Turret-V" then
			UX = self:GetRight() * 0.5
		end

		render.DrawLine(Pos + UX,Pos + (self:GetForward() * X) + UX,orange,true)

		if IsValid(self.Rotator) then render.DrawLine(Pos,Pos + self.Rotator:GetForward() * X,color_white,true) end

		local LocPos = self:WorldToLocal(Trace.HitPos)
		local AimAng = 0
		local CurAng = 0
		local LocDir = Vector(LocPos.x,LocPos.y,0):GetNormalized()
		local HasArc = not ((self.MinDeg == -180) and (self.MaxDeg == 180))

		if self.Type == "Turret-V" then
			LocDir = Vector(LocPos.x,0,LocPos.z):GetNormalized()
			AimAng = -math.Round(self:WorldToLocalAngles(self:LocalToWorldAngles(LocDir:Angle())).pitch,2)
			CurAng = -math.Round(self:WorldToLocalAngles(self.Rotator:GetAngles()).pitch,2)
		else
			AimAng = -math.Round(self:WorldToLocalAngles(self:LocalToWorldAngles(LocDir:Angle())).yaw,2)
			CurAng = -math.Round(self:WorldToLocalAngles(self.Rotator:GetAngles()).yaw,2)
		end

		render.DrawLine(Pos - UX,self:LocalToWorld(self:OBBCenter() + LocDir * X * 2) - UX,magenta,true)

		render.DrawLine(self:LocalToWorld(self:OBBCenter()),self.Rotator:LocalToWorld(self.LocalCoM),red,true)

		render.OverrideDepthEnable(true,true)
			render.DrawWireframeSphere(self.Rotator:LocalToWorld(self.LocalCoM),1.5,4,3,red)
		render.OverrideDepthEnable(false,false)

		local MinArcPos = {}
		local MaxArcPos = {}
		if HasArc then
			local MinDir = Vector(X,0,0)
			local MaxDir = Vector(X,0,0)

			if self.Type == "Turret-V" then
				MinDir:Rotate(Angle(-self.MinDeg,0,0))
				MaxDir:Rotate(Angle(-self.MaxDeg,0,0))
			else
				MinDir:Rotate(Angle(0,-self.MinDeg,0))
				MaxDir:Rotate(Angle(0,-self.MaxDeg,0))
			end

			render.DrawLine(Pos - UX * 2,self:LocalToWorld(self:OBBCenter() + MinDir) - UX * 2,red,true)
			render.DrawLine(Pos - UX * 2,self:LocalToWorld(self:OBBCenter() + MaxDir) - UX * 2,green,true)

			MinArcPos = (self:LocalToWorld(self:OBBCenter() + MinDir) - UX * 2):ToScreen()
			MaxArcPos = (self:LocalToWorld(self:OBBCenter() + MaxDir) - UX * 2):ToScreen()
		end

		local HomePos = (Pos + UX + self:GetForward() * X):ToScreen()
		local CurPos = (Pos + self.Rotator:GetForward() * X):ToScreen()
		local AimPos = (self:LocalToWorld(self:OBBCenter() + LocDir * X) - UX):ToScreen()

		local CoMPos = (self.Rotator:LocalToWorld(self.LocalCoM) - Vector(0,0,2)):ToScreen()

		cam.Start2D()
			draw.SimpleTextOutlined("Zero","DermaDefault",HomePos.x,HomePos.y,orange,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
			draw.SimpleTextOutlined("Current: " .. CurAng,"DermaDefault",CurPos.x,CurPos.y,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
			draw.SimpleTextOutlined("Aim: " .. AimAng,"DermaDefault",AimPos.x,AimPos.y,magenta,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)

			draw.SimpleTextOutlined("Mass: " .. self.Mass .. "kg","DermaDefault",CoMPos.x,CoMPos.y,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
			draw.SimpleTextOutlined("Lateral Distance: " .. self.CoMDist .. "u","DermaDefault",CoMPos.x,CoMPos.y + 16,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)

			if HasArc then
				draw.SimpleTextOutlined("Min: " .. self.MinDeg,"DermaDefault",MinArcPos.x,MinArcPos.y,red,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
				draw.SimpleTextOutlined("Max: " .. self.MaxDeg,"DermaDefault",MaxArcPos.x,MaxArcPos.y,green,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
			end
		cam.End2D()
	end
end