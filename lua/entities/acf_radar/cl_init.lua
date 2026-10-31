DEFINE_BASECLASS("acf_base_simple")

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
			ACF.DrawCone(Origin, self:GetForward(), SelfTbl.Cone, SelfTbl.Range, Col, Col)
		end
	end
end

do	-- Dish rotation
	local SpinSpeed = 360 -- Degrees per second
	local SpinAccel = 540 -- Degrees per second squared, used for both spin-up and braking
	local SpinAng   = Angle()

	-- Entity up axis in the bone's frame, which a spin about that axis leaves unchanged
	local function GetSpinAxis(Entity, Bone)
		local Matrix = Entity:GetBoneMatrix(Bone)
		if not Matrix then return end

		local Up = Entity:GetUp()

		return Vector(Up:Dot(Matrix:GetForward()), -Up:Dot(Matrix:GetRight()), Up:Dot(Matrix:GetUp()))
	end

	local function UpdateSpin(Entity)
		local SelfTbl = Entity:GetTable()
		local Model   = Entity:GetModel()

		if SelfTbl.SpinModel ~= Model then -- Updating the radar can swap its model
			SelfTbl.SpinModel = Model
			SelfTbl.SpinBone  = Entity:LookupBone("radar_rot")
			SelfTbl.SpinAxis  = nil
			SelfTbl.SpinAngle = 0
			SelfTbl.SpinSpeed = 0
			SelfTbl.SpinStop  = nil
		end

		local Bone = SelfTbl.SpinBone
		if not Bone then return end

		local Now   = Clock.CurTime
		local Delta = Now - (SelfTbl.SpinTime or Now) -- Not FrameTime, so the dish catches up after being off-screen
		local Speed = SelfTbl.SpinSpeed
		local Ang   = SelfTbl.SpinAngle

		SelfTbl.SpinTime = Now

		if Entity:GetNW2Bool("ACF_RadarSpin") then
			Speed = math.min(Speed + SpinAccel * Delta, SpinSpeed)
			Ang   = (Ang + Speed * Delta) % 360

			SelfTbl.SpinStop = nil
		elseif Speed > 0 then
			local Stop = SelfTbl.SpinStop

			if not Stop then -- First home position we can brake into without exceeding SpinAccel
				Stop = math.ceil((Ang + Speed * Speed / (2 * SpinAccel)) / 360) * 360

				SelfTbl.SpinStop = Stop
			end

			Ang = math.min(Ang + Speed * Delta, Stop)

			local Left = Stop - Ang

			if Left <= 0 then
				Ang, Speed = 0, 0

				SelfTbl.SpinStop = nil
			else
				Speed = math.min(Speed, math.sqrt(2 * SpinAccel * Left)) -- Coast until on the braking curve
			end
		else
			return
		end

		SelfTbl.SpinSpeed = Speed
		SelfTbl.SpinAngle = Ang

		local Axis = SelfTbl.SpinAxis or GetSpinAxis(Entity, Bone)
		if not Axis then return end

		SelfTbl.SpinAxis = Axis

		SpinAng:Zero()
		SpinAng:RotateAroundAxis(Axis, -Ang)

		Entity:ManipulateBoneAngles(Bone, SpinAng)
	end

	function ENT:Draw(...)
		BaseClass.Draw(self, ...)

		UpdateSpin(self) -- After drawing so the bone matrix is set up, takes effect next frame
	end
end