include("shared.lua")

local HideInfo = ACF.HideInfoBubble

language.Add("Cleanup_acf_gearbox", "ACF Gearboxes")
language.Add("Cleaned_acf_gearbox", "Cleaned up all ACF Gearboxes")
language.Add("SBoxLimit__acf_gearbox", "You've reached the ACF Gearboxes limit!")

function ENT:Initialize()
	self:Update()
end

function ENT:Update()
	self.HitBoxes = ACF.HitBoxes[self:GetModel()]
end

-- copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
function ENT:Draw()
	self:DoNormalDraw(false, HideInfo())

	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end
end
