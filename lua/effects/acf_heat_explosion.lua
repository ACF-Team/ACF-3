local Effects   = ACF.Utilities.Effects
local GetAngles = Effects.GetSurfaceAngles

function EFFECT:Init(Data)
	local Origin = Data:GetOrigin()
	local Normal = Data:GetNormal()
	local Radius = math.max(Data:GetRadius() * 0.02, 1)

	local EffectTable = {
		Origin = Origin,
		Normal = Normal,
		Scale = Radius * 50,
	}

	Effects.CreateEffect("ACF_Explosion", EffectTable)

	local Effect = CreateParticleSystemNoEntity("acf_heat", Origin, GetAngles(Normal))

	if not Effect then return end

	local Mult = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)

	Effect:SetControlPoint(1, Vector(Radius, Radius, Radius))
	Effect:SetControlPoint(2, Vector(Radius / 3, Radius * Mult, 1))
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
