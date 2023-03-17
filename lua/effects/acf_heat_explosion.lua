function EFFECT:Init(Data)
	local Origin  = Data:GetOrigin()
	local Normal  = Data:GetNormal()
	local Radius  = math.max(Data:GetRadius() * 0.02, 1)
	local Emitter = ParticleEmitter(Origin)

	local Effect = EffectData()
		Effect:SetOrigin(Origin)
		Effect:SetNormal(Normal)
		Effect:SetScale(Radius * 50)

	util.Effect("ACF_Explosion", Effect)

	if not IsValid(Emitter) then return end

	local Mult = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)

	for _ = 0, 3 * Radius * Mult do
		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity((-Normal + VectorRand() * 0.1) * math.random(50, 130 * Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 2) * Radius * 0.3333)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(2 * Radius)
			Smoke:SetEndSize(15 * Radius)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(300)
			Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -450))
			Smoke:SetColor(160, 160, 160)
		end
	end

	for _ = 0, 4 * Radius * Mult do
		local Debris = Emitter:Add("effects/fleck_tile" .. math.random(1, 2), Origin)

		if Debris then
			Debris:SetVelocity((Normal + VectorRand() * 0.1) * math.random(250 * Radius, 450 * Radius))
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(1.5, 3) * Radius * 0.3333)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(0.3 * Radius)
			Debris:SetEndSize(0.3 * Radius)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(200)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 5 * Radius * Mult do
		local Embers = Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin)

		if Embers then
			Embers:SetVelocity((Normal + VectorRand() * 0.1) * math.random(50 * Radius, 300 * Radius))
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.3, 1) * Radius * 0.3333)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(1 * Radius)
			Embers:SetEndSize(0 * Radius)
			Embers:SetStartLength(5 * Radius)
			Embers:SetEndLength(0 * Radius)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetGravity(Vector(0, 0, -650))
			Embers:SetColor(200, 200, 200)
		end
	end

	Emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
