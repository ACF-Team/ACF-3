include("shared.lua")

local ACF        = ACF
local LightColor = Color(255, 128, 48)

local function RenderMotorLight(Entity)
	local Size = Entity:GetNW2Float("LightSize")

	if Size <= 0 then return end

	local Index = Entity:EntIndex()
	local Pos = Entity:GetPos() - Entity:GetForward() * 64

	ACF.RenderLight(Index, Size * 175, LightColor, Pos)
end

function ENT:Draw()
	self:DrawModel()

	RenderMotorLight(self)
end
