include("shared.lua")

local FlareMat = Material("sprites/orangeflare1")
local Size = 2000 * 0.025

function ENT:Draw()
	self:DrawModel()

	render.SetMaterial(FlareMat)
	render.DrawSprite(self:GetAttachment(1).Pos, Size, Size, Color(255, 255, 255))
end
