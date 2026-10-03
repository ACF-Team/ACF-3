include("shared.lua")

language.Add("Cleanup_acf_irst", "ACF Infrared Search / Track Sensors")
language.Add("Cleaned_acf_irst", "Cleaned up all ACF Infrared Search / Track Sensors")
language.Add("SBoxLimit__acf_irst", "You've hit the ACF Infrared Search / Track Sensor limit!")

local Length    = 2000 -- Purely visual, the sensor's range is unlimited
local ViewColor = Color(0, 255, 255)
local GimColor  = Color(255, 255, 0, 60)

local function DrawCone(Origin, Dir, Degrees, Col)
	local Ang    = Dir:Angle()
	local Radius = math.tan(math.rad(Degrees)) * Length
	local Center = Origin + Dir * Length
	local Last

	for I = 0, 16 do
		local Roll  = math.rad(I * 22.5)
		local Point = Center + (Ang:Right() * math.cos(Roll) + Ang:Up() * math.sin(Roll)) * Radius

		if Last then render.DrawLine(Last, Point, Col, true) end
		if I % 4 == 0 then render.DrawLine(Origin, Point, Col, true) end

		Last = Point
	end
end

function ENT:DrawOverlay()
	local Offset = self:GetNW2Vector("ACF_IRSTOffset")
	local Origin = self:LocalToWorld(Offset)
	local Look   = self:GetNW2Vector("ACF_IRSTDir", Vector(1, 0, 0))
	local Dir    = self:LocalToWorld(Look) - self:GetPos()

	DrawCone(Origin, self:GetForward(), self:GetNW2Float("ACF_IRSTGimbal"), GimColor)
	DrawCone(Origin, Dir, self:GetNW2Float("ACF_IRSTCone"), ViewColor)
end
