DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

include("shared.lua")

local HideInfo = ACF.HideInfoBubble

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)

	self:Update()
end

function ENT:Update()
end

-- Copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
function ENT:Draw()
	self:DoNormalDraw(false, HideInfo())

	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end
end
