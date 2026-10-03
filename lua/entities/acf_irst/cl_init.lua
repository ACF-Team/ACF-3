include("shared.lua")

language.Add("Cleanup_acf_irst", "ACF Infrared Search & Track Sensors")
language.Add("Cleaned_acf_irst", "Cleaned up all ACF Infrared Search & Track Sensors")
language.Add("SBoxLimit__acf_irst", "You've hit the ACF Infrared Search & Track Sensor limit!")

local Length    = 2000 -- Purely visual, the sensor's range is unlimited
local ViewColor = Color(0, 255, 255)
local GimColor  = Color(255, 255, 0, 60)

function ENT:DrawOverlay()
	local Offset = self:GetNW2Vector("ACF_IRSTOffset")
	local Origin = self:LocalToWorld(Offset)
	local Look   = self:GetNW2Vector("ACF_IRSTDir", Vector(1, 0, 0))
	local Dir    = self:LocalToWorld(Look) - self:GetPos()

	ACF.DrawCone(Origin, self:GetForward(), self:GetNW2Float("ACF_IRSTGimbal"), Length, GimColor)
	ACF.DrawCone(Origin, Dir, self:GetNW2Float("ACF_IRSTCone"), Length, ViewColor)
end
