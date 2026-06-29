local Clock		= ACF.Utilities.Clock
local Classes     = ACF.Classes
local Racks = ACF.Classes.Racks
local Queued	= {}

include("shared.lua")

language.Add("Cleanup_acf_rack", "ACF Racks")
language.Add("Cleaned_acf_rack", "Cleaned up all ACF Racks")
language.Add("SBoxLimit__acf_rack", "You've hit the ACF Rack limit!")

do	-- Overlay/networking
	function ENT:RequestRackInfo()
		if Queued[self] then return end

		Queued[self]	= true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF.RequestRackInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end

	net.Receive("ACF.RequestRackInfo", function()
		local Rack = net.ReadEntity()
		if not IsValid(Rack) then return end

		Queued[Rack] = nil

		local RackInfo	= util.JSONToTable(net.ReadString())
		local CrateInfo	= util.JSONToTable(net.ReadString())

		if RackInfo.HasComputer then
			local Computer = Entity(RackInfo.Computer)
			if IsValid(Computer) then
				Rack.Computer = Computer
			end
		end

		if RackInfo.HasRadar then
			local Radar = Entity(RackInfo.Radar)
			if IsValid(Radar) then
				Rack.Radar = Radar
			end
		end

		Rack.MountPoints = {}
		if next(RackInfo.MountPoints) then
			for _, T in ipairs(RackInfo.MountPoints) do
				local Dir = Vector(1, 0, 0)
				Dir:Rotate(T.Ang)
				Rack.MountPoints[#Rack.MountPoints + 1] = {Index = T.Index, Pos = T.Pos, Dir = Dir}
			end
		end

		local CrateEnts = {}
		for _, E in ipairs(CrateInfo) do
			local Crate = Entity(E)

			if IsValid(Crate) then
				local Col = ColorAlpha(Crate:GetColor(), 25)
				CrateEnts[#CrateEnts + 1] = {Ent = Crate, Col = Col}
			end
		end

		Rack.Crates	= CrateEnts
		Rack.HasData	= true
		Rack.Age	= Clock.CurTime + 5
	end)

	-- icon16/feed.png radar sprite
	-- icon16/joystick.png controller sprite
	local Purple = Color(255, 0, 255, 100)
	local Cyan = Color(0, 255, 255, 100)
	local RadarSprite = Material("icon16/transmit.png")
	local JoystickMat = Material("icon16/joystick.png")
	local RadarColor = Color(255, 255, 0, 25)
	local ControllerColor = Color(0, 255, 0, 25)
	local ForwardColor = Color(255, 0, 0)
	local drawOutlineBeam = ACF.DrawOutlineBeam
	local Purple = Color(255, 0, 255, 100)
	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestRackInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestRackInfo()
		end

		if next(SelfTbl.Crates) then
			for _, T in ipairs(SelfTbl.Crates) do
				local E = T.Ent

				if IsValid(E) then
					render.DrawWireframeBox(E:GetPos(), E:GetAngles(), E:OBBMins(), E:OBBMaxs(), T.Col, true)
					render.DrawBox(E:GetPos(), E:GetAngles(), E:OBBMins(), E:OBBMaxs(), T.Col)
				end
			end
		end

		-- Visualize mount point locations
		if next(SelfTbl.MountPoints) then
			for _, T in ipairs(SelfTbl.MountPoints) do
				local Pos1 = self:LocalToWorld(T.Pos - T.Dir * 6)
				local Pos2 = self:LocalToWorld(T.Pos + T.Dir * 6)
				render.DrawBeam(Pos1, Pos2, 2, 0, 0, color_black)
				render.DrawBeam(Pos1, Pos2, 1.5, 0, 0, color_white)
			end

			cam.Start2D()
				for _, T in ipairs(SelfTbl.MountPoints) do
					local Pos = self:LocalToWorld(T.Pos):ToScreen()
					draw.SimpleTextOutlined("Mount " .. T.Index, "ACF_Title", Pos.x, Pos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
				end
			cam.End2D()
		end

		-- Visualize radar location
		if IsValid(SelfTbl.Radar) then
			local Radar = SelfTbl.Radar
			local RadPos, RadAng, OBBMin, OBBMax = Radar:GetPos(), Radar:GetAngles(), Radar:OBBMins(), Radar:OBBMaxs()
			render.DrawWireframeBox(RadPos, RadAng, OBBMin, OBBMax, RadarColor, true)
			render.DrawBox(RadPos, RadAng, OBBMin, OBBMax, RadarColor)

			render.SetMaterial(RadarSprite)
			render.DrawSprite(Radar:LocalToWorld(Radar:OBBCenter()), 12, 12, color_white)
		end

		render.SetColorMaterial()

		-- Visualize guidance computer location
		if IsValid(SelfTbl.Computer) then
			local Computer = SelfTbl.Computer
			local ComPos, ComAng, OBBMin, OBBMax = Computer:GetPos(), Computer:GetAngles(), Computer:OBBMins(), Computer:OBBMaxs()
			render.DrawWireframeBox(ComPos, ComAng, OBBMin, OBBMax, ControllerColor, true)
			render.DrawBox(ComPos, ComAng, OBBMin, OBBMax, ControllerColor)

			render.SetMaterial(JoystickMat)
			render.DrawSprite(Computer:LocalToWorld(Computer:OBBCenter()), 12, 12, color_white)
		end

		-- Rack forward direction
		local p1 = self:GetPos() + self:GetForward() * 24
		local p2 = self:GetPos()
		local dir = (p1 - p2):GetNormalized()
		local dir2 = EyeVector()
		local right = (dir:Cross(dir2)):GetNormalized()

		drawOutlineBeam(0.25, ForwardColor,
			p1, p2,
			p1, p1 + (-dir - right) * 5,
			p1, p1 + (-dir + right) * 5)

		-- Visualize breech location
		local RackClassData = Racks.Get(self:GetNWString("ACF_Class"))
		if not RackClassData then return end

		local IdName	  		= self:GetNWString("ACF_MissileClass")
		if not IdName or IdName == "" then return end
		local IdGroup     		= Classes.GetGroup(Classes.Missiles, IdName)
		local MissileClassData  = IdGroup.Lookup[IdName]

		if RackClassData.BreechConfigs then
			local BreechIndex = self:GetNW2Int("BreechIndex", 1)
			local Caliber = MissileClassData.Round.ActualWidth / 2
			local Depth = -MissileClassData.Round.ActualLength / 2

			for Index, Config in ipairs(RackClassData.BreechConfigs.Locations) do
				local MountPos = self.MountPoints[1].Pos
				local Pos = self:LocalToWorld(Vector(self:OBBCenter().x, MountPos.y, MountPos.z) + Config.LPos * (self:OBBMaxs() - self:OBBMins()) / 2)
				local Ang = self:LocalToWorldAngles(Config.LAng)
				local MinBox = Vector(Depth, -Caliber, -Caliber)
				local MaxBox = Vector(0, Caliber, Caliber)

				render.DrawWireframeBox(Pos, Ang, MinBox, MaxBox, Index == BreechIndex and Purple or Cyan, true)
				if Index == BreechIndex then render.DrawWireframeSphere(Pos, 2, 10, 10, Purple, true) end -- Draw the location of the breech
			end
		end
	end
end