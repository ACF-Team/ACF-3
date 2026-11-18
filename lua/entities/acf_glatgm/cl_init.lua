include("shared.lua")

local FlareMat = Material("sprites/orangeflare1")
local Size = 2000 * 0.025

function ENT:Draw()
	self:DrawModel()

	-- nil until the model loads, or forever if the client doesnt have it
	local Exhaust = self:GetAttachment(1)
	if not Exhaust then return end

	render.SetMaterial(FlareMat)
	render.DrawSprite(Exhaust.Pos, Size, Size, Color(255, 255, 255))
end
