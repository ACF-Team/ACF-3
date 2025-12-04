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

local ENTITY = FindMetaTable("Entity")

function ENT:Draw()
	local HaloTip = not HideInfo()

	local RenderContext = ACF.RenderContext
	local LookedAt = RenderContext.LookAt == self

	if HaloTip and LookedAt then
		if RenderContext.ShouldDrawOutline then
			self:DrawEntityOutline()
		end
		ENTITY.DrawModel(self)
	else
		ENTITY.DrawModel(self)
	end

	WireRender(self)
end