DEFINE_BASECLASS("acf_base_simple")

include("shared.lua")

-- Locallization for performance...
local ScrW = ScrW
local ScrH = ScrH
local SetDrawColor = surface.SetDrawColor
local DrawRect = surface.DrawRect
local DrawCircle = surface.DrawCircle
local DrawText = draw.DrawText

local TraceLine = util.TraceLine

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)
end

function ENT:Draw(...)
	BaseClass.Draw(self, ...)
end

-- Note: Since this file is sent to each client, locals are unique to each player...
-- General
local MyController = nil -- The controller the player is using, or nil.
local MyFilter = nil -- The filter for the camera of the current controller

-- Camera related
local CamAng = Angle(0, 0, 0)
local FOV = 90
local Mode = 1
local CamOffset = Vector()
local CamOrbit = 0

local WorldCamMins = Vector(-4, -4, -4)
local WorldCamMaxs = Vector(4, 4, 4)

--- Unclips the camera from the world
local worldUnclipTrace = {
	mask = MASK_SOLID_BRUSHONLY,
	mins = WorldCamMins,
	maxs = WorldCamMaxs
}

local function WorldUnclip(PreOrbit, PostOrbit)
	worldUnclipTrace.start = PreOrbit
	worldUnclipTrace.endpos = PostOrbit
	local Tr = util.TraceHull(worldUnclipTrace)
	if Tr.Hit then return Tr.HitPos end
	return PostOrbit
end

-- Maintain a record of links to the entity from the server
net.Receive("ACF_Controller_Links", function()
	local EntIndex1 = net.ReadUInt(MAX_EDICT_BITS)
	local EntIndex2 = net.ReadUInt(MAX_EDICT_BITS)
	local Linked = net.ReadBool()

	local Ent = Entity(EntIndex1)
	Ent.Targets = Ent.Targets or {}

	if Ent.Targets == nil then return end
	if Linked then Ent.Targets[EntIndex2] = true else Ent.Targets[EntIndex2] = nil end
end)

-- Keep a record of the controller we are currently in, from the server
local UpdateCamera = nil
net.Receive("ACF_Controller_Active", function()
	local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
	local Activated = net.ReadBool()

	local Ent = Entity(EntIndex)
	if not IsValid(Ent) then return end

	-- When entering the seat, update the camera info
	MyController = Activated and Ent or nil
	if Activated then UpdateCamera(LocalPlayer()) end
end)

-- Receive filter from server
net.Receive("ACF_Controller_CamInfo", function()
	Temp = net.ReadTable()
	if #Temp > 0 then MyFilter = Temp end
end)

UpdateCamera = function(ply)
	CamOffset = MyController["GetCam" .. Mode .. "Offset"]()
	CamOrbit = MyController["GetCam" .. Mode .. "Orbit"]()

	net.Start("ACF_Controller_CamInfo")
	net.WriteUInt(MyController:EntIndex(), MAX_EDICT_BITS)
	net.WriteUInt(Mode, 2)
	net.SendToServer(ply)
end

local rangerTrace = {}
local ranger = function(start, dir, length, filter, mask)
	rangerTrace.start = start
	rangerTrace.endpos = start + dir * length
	rangerTrace.mask = mask or MASK_SOLID
	rangerTrace.filter = filter
	local Tr = TraceLine(rangerTrace)
	return Tr.HitPos or vector_origin
end

-- local Scale = MyController:GetHUDScale()
-- surface.CreateFont( "ACFHUDFONT", {
-- 	font = "Arial", extended = false, size = 13 * Scale, weight = 500, blursize = 0, scanlines = 0, antialias = true, underline = false,
-- 	italic = false, strikeout = false, symbol = false, rotary = false, shadow = false, additive = false, outline = false,
-- } )

-- HUD RELATED
local red = Color(255, 0, 0, 255)
local green = Color(0, 255, 0, 255)
hook.Add( "HUDPaintBackground", "ACFAddonControllerHUD", function()
	if not IsValid(MyController) then return end

	-- Determine screen params
	local resx, resy = ScrW(), ScrH()
	local x, y = resx / 2, resy / 2
	local thick = 1

	-- Rescale if needed
	local Scale = MyController:GetHUDScale()
	resx, resy, thick = resx * Scale, resy * Scale, thick

	local ColData = MyController:GetHUDColor() or Vector(255, 255, 255) -- See shared.lua
	local Col = Color(ColData.x * 255, ColData.y * 255, ColData.z * 255, 255)
	SetDrawColor( Col )

	if MyController:GetDisableAIOHUD() then return end -- Disable hud if not enabled

	-- HUD 1
	local HudType = MyController:GetHUDType()
	if HudType == 0 then
		DrawRect( x - 40 * Scale, y - thick / 2, 80 * Scale, thick )
		DrawRect( x - thick / 2, y - 40 * Scale, thick, 80 * Scale )

		local AmmoType, AmmoCount = MyController:GetNWString("AHS_Primary_AT", ""), MyController:GetNWInt("AHS_Primary_SL", 0)
		DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 10 * Scale, y + 50 * Scale, Col, TEXT_ALIGN_RIGHT)
		local TimeLeft = math.Round(MyController:GetNWFloat("AHS_Primary_NF", 0) - CurTime(), 2)
		DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x + 10 * Scale, y + 50 * Scale, Col, TEXT_ALIGN_LEFT)
	elseif HudType == 1 then
		DrawRect( x - 120 * Scale, y - thick / 2, 240 * Scale, thick )
		DrawRect( x - thick / 2, y - 60 * Scale, thick, 120 * Scale )

		DrawRect( x - 170 * Scale, y - thick / 2, 40 * Scale, thick )
		DrawRect( x + 130 * Scale, y - thick / 2, 40 * Scale, thick )

		DrawRect( x - thick / 2, y - 110 * Scale, thick, 40 * Scale )
		DrawRect( x - thick / 2, y + 70 * Scale, thick, 40 * Scale )

		DrawRect( x - 400 * Scale, y - 200 * Scale, thick, 60 * Scale )
		DrawRect( x - 400 * Scale, y + 140 * Scale, thick, 60 * Scale )
		DrawRect( x + 400 * Scale, y - 200 * Scale, thick, 60 * Scale )
		DrawRect( x + 400 * Scale, y + 140 * Scale, thick, 60 * Scale )

		DrawRect( x - 400 * Scale, y - 200 * Scale, 60 * Scale, thick )
		DrawRect( x - 400 * Scale, y + 200 * Scale, 60 * Scale, thick )
		DrawRect( x + 340 * Scale, y - 200 * Scale, 60 * Scale, thick )
		DrawRect( x + 340 * Scale, y + 200 * Scale, 60 * Scale, thick )

		SetDrawColor( Col )
		local AmmoType, AmmoCount = MyController:GetNWString("AHS_Primary_AT", ""), MyController:GetNWInt("AHS_Primary_SL", 0)
		DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 330 * Scale, y + 210 * Scale, Col, TEXT_ALIGN_RIGHT)
		local TimeLeft = math.Round(MyController:GetNWFloat("AHS_Primary_NF", 0) - CurTime(), 2)
		DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x - 310 * Scale, y + 210 * Scale, Col, TEXT_ALIGN_LEFT)

		local AmmoType, AmmoCount = MyController:GetNWString("AHS_Secondary_AT", ""), MyController:GetNWInt("AHS_Secondary_SL", 0)
		DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 330 * Scale, y + 230 * Scale, Col, TEXT_ALIGN_RIGHT)
		local TimeLeft = math.Round(MyController:GetNWFloat("AHS_Secondary_NF", 0) - CurTime(), 2)
		DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x - 310 * Scale, y + 230 * Scale, Col, TEXT_ALIGN_LEFT)

		local AmmoType, AmmoCount = MyController:GetNWString("AHS_Tertiary_AT", ""), MyController:GetNWInt("AHS_Tertiary_SL", 0)
		DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 330 * Scale, y + 250 * Scale, Col, TEXT_ALIGN_RIGHT)
		local TimeLeft = math.Round(MyController:GetNWFloat("AHS_Tertiary_NF", 0) - CurTime(), 2)
		DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x - 310 * Scale, y + 250 * Scale, Col, TEXT_ALIGN_LEFT)

		local unit = MyController:GetSpeedUnit() == 0 and " KPH" or " MPH"
		DrawText("SPD: " .. MyController:GetNWFloat("AHS_Speed") .. unit, "DermaDefault", x + 310 * Scale, y + 210 * Scale, Col, TEXT_ALIGN_LEFT)
		DrawText("Gear: " .. MyController:GetNWFloat("AHS_Gear"), "DermaDefault", x + 310 * Scale, y + 230 * Scale, Col, TEXT_ALIGN_LEFT)
		local unit = MyController:GetFuelUnit() == 0 and " L" or " H"
		DrawText("Fuel: " .. MyController:GetNWFloat("AHS_Fuel") .. unit, "DermaDefault", x + 310 * Scale, y + 250 * Scale, Col, TEXT_ALIGN_LEFT)
	end

	local Primary = MyController:GetNWEntity( "AHS_Primary", MyController )
	if IsValid(Primary) then
		local HitPos = ranger( Primary:GetPos(), Primary:GetForward(), 99999, MyFilter )
		local sp = HitPos:ToScreen()
		local Ready = MyController:GetNWBool("AHS_Primary_RD", false)
		SetDrawColor( Ready and green or red )
		DrawCircle( sp.x, sp.y, 10 * Scale)
	end
end)

hook.Add("KeyPress", "ACFControllerCamMode", function(ply, key)
	if not IsValid(ply) or ply ~= LocalPlayer() then return end
	if not IsFirstTimePredicted() then return end
	if not IsValid(MyController) then return end

	if key == IN_DUCK then
		Mode = Mode + 1
		if Mode > MyController:GetCamCount() then Mode = 1 end
		UpdateCamera(ply)
	end
end)

hook.Add("InputMouseApply", "ACFControllerCamMove", function(_, x, y, _)
	if not IsValid(MyController) then return end

	local MinFOV = MyController:GetZoomMin()
	local MaxFOV = MyController:GetZoomMax()

	local MinSlew = MyController:GetSlewMin()
	local MaxSlew = MyController:GetSlewMax()

	local ZoomFrac = (FOV - MinFOV) / (MaxFOV - MinFOV)
	local Slew = MinSlew + ZoomFrac * (MaxSlew - MinSlew)

	local TrueSlew = Slew * FrameTime()
	CamAng = Angle(math.Clamp(CamAng.pitch + y * TrueSlew, -90, 90), CamAng.yaw - x * TrueSlew, 0)

	net.Start("ACF_Controller_CamData")
	net.WriteUInt(MyController:EntIndex(), MAX_EDICT_BITS)
	net.WriteAngle(CamAng)
	net.SendToServer()
end)

hook.Add("PlayerBindPress", "ACFControllerScroll", function(ply, bind, _)
	local delta = bind == "invnext" and 1 or bind == "invprev" and -1 or nil
	if not delta then return end

	if ply ~= LocalPlayer() then return end
	if not IsValid(MyController) then return end

	local MinFOV = MyController:GetZoomMin()
	local MaxFOV = MyController:GetZoomMax()
	local SpeedFOV = MyController:GetZoomSpeed()
	FOV = math.Clamp(FOV + delta * SpeedFOV, MinFOV, MaxFOV)

	return true
end)

hook.Add("CalcView", "ACFControllerView", function(Player, _, _, _)
	if Player ~= LocalPlayer() then return end
	if not IsValid(MyController) then return end
	if MyController:GetDisableAIOCam() then return end

	local Pod = Player:GetVehicle()
	if not IsValid(Pod) then return end

	local PreOrbit = MyController:LocalToWorld(CamOffset)
	local PostOrbit = PreOrbit - CamAng:Forward() * CamOrbit

	local View = {
		origin = WorldUnclip(PreOrbit, PostOrbit),
		angles = CamAng,
		fov = FOV,
		drawviewer = true,
	}

	return View
end)

function ENT:DrawOverlay()
	if self.Targets then
		for Target in pairs(self.Targets) do
			local Target = Entity(Target)
			if not IsValid(Target) then continue end
			render.DrawWireframeBox(Target:GetPos(), Target:GetAngles(), Target:OBBMins(), Target:OBBMaxs(), green, true)
		end
	end
end