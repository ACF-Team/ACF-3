DEFINE_BASECLASS("base_scalable") -- Required to get the local BaseClass

include("shared.lua")

local HideInfo = ACF.HideInfoBubble
local WireRender = Wire_Render

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)

	self:Update()
end

function ENT:Update()
end

-- Copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
function ENT:Draw()
	self:DoNormalDraw(HideInfo(), HideInfo())

	WireRender(self)
end