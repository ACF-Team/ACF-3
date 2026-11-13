local Sounds    = ACF.Utilities.Sounds
local GetAngles = ACF.Utilities.Effects.GetSurfaceAngles

function EFFECT:Init(Data)
	local DirVec = Data:GetNormal()
	local Origin = Data:GetOrigin() + DirVec * -15
	local Radius = math.Clamp(Data:GetScale() * 0.042, 0.1, 10)
	local Mult   = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)
	local Rings  = math.random(20, 40) * Mult

	local sndrad = math.Clamp(Radius * 20, 75, 165)
	local sndradp = 300 - Radius
	Sounds.PlaySound(Origin, "ambient/explosions/explode_4.wav", sndrad, math.Clamp(sndradp * 25, 15, 170), 1)
	Sounds.PlaySound(Origin, "ambient/explosions/explode_9.wav", sndrad, math.Clamp(sndradp * 22, 15, 120), 1)

	local Effect = CreateParticleSystemNoEntity("acf_glatgm", Origin, GetAngles(DirVec))

	if not Effect then return end

	Effect:SetControlPoint(1, Vector(Radius, Radius, Radius))
	Effect:SetControlPoint(2, Vector(Radius, Radius * Mult, Rings / 6))
	Effect:SetControlPoint(4, Vector(Rings * (4 * Radius + 1) / 5, 0, 0)) -- Flashes in each of the 5 bands of the ring's spokes

	-- How far back along the axis the smoke ring and the sparks get thrown
	local Push = DirVec * Radius

	Effect:SetControlPoint(5, Push * -0.05 * 250)
	Effect:SetControlPoint(6, Push * -1.05 * 250)
	Effect:SetControlPoint(7, Push * 0.5 * 70)
	Effect:SetControlPoint(8, Push * -0.5 * 70)
	Effect:SetControlPoint(9, Push * -1.5 * 70)
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
