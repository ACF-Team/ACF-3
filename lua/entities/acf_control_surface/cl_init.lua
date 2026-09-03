include("shared.lua")

DEFINE_BASECLASS("acf_base_scalable")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel())
end

-- Colour-code by the axis the surface actuates, so the whole aircraft's control layout is readable at a glance.
local AxisColor = {
	Pitch = Color(90, 220, 120), -- green
	Yaw   = Color(90, 150, 255), -- blue
	Roll  = Color(255, 110, 90), -- red
}
local Black = Color(0, 0, 0)

function ENT:Draw()
	local Defl = self:GetNW2Float("ACF_Deflection", 0) -- hinge angle in degrees
	local Axis = self:GetNWString("ACF_ControlAxis", "Pitch")

	-- Real control surfaces hinge about their span. The panel is modelled with its span along local Y, so
	-- tilt the drawn rectangle about the world-space right vector to show the deflection direction/amount.
	local Ang = self:GetAngles()
	Ang:RotateAroundAxis(self:GetRight(), Defl)

	local Mins, Maxs = self:OBBMins(), self:OBBMaxs()
	local Col = AxisColor[Axis] or color_white

	render.SetColorMaterial()
	render.DrawBox(self:GetPos(), Ang, Mins, Maxs, Col)
	render.DrawWireframeBox(self:GetPos(), Ang, Mins, Maxs, Black, true)
end
