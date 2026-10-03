DEFINE_BASECLASS("base_scalable")

include("shared.lua")

local ENTITY = FindMetaTable("Entity")

function ENT:ACF_GetOverlayTarget()
	local Actuator = self:GetNWEntity("ACF.Actuator")

	if IsValid(Actuator) then return Actuator end
end

-- base_wire_entity's Draw would add the Wiremod tooltip; the ACF overlay replaces it
function ENT:Draw()
	local RenderContext = ACF.RenderContext

	if RenderContext.LookAt == self and RenderContext.ShouldDrawOutline and not ACF.HideInfoBubble() then
		self:DrawEntityOutline()
	end

	-- Mirrors the actuator's look here, since tools are blocked on the rod and nothing reports a color/material change
	local Actuator = self:GetNWEntity("ACF.Actuator")

	if not IsValid(Actuator) then return ENTITY.DrawModel(self) end

	local Material = Actuator:GetMaterial()
	local Color    = Actuator:GetColor()

	if self:GetMaterial() ~= Material then self:SetMaterial(Material) end

	render.SetColorModulation(Color.r / 255, Color.g / 255, Color.b / 255)
	render.SetBlend(Color.a / 255)

	ENTITY.DrawModel(self)

	render.SetColorModulation(1, 1, 1)
	render.SetBlend(1)
end
