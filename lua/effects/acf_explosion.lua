local TraceData = { start = true, endpos = true, mask = true }
local TraceLine = util.TraceLine
local GetIndex = ACF.GetAmmoDecalIndex
local GetDecal = ACF.GetRicochetDecal

local Colors = {
	[MAT_GRATE] = Vector(170, 170, 170),
	[MAT_CLIP] = Vector(170, 170, 170),
	[MAT_METAL] = Vector(170, 170, 170),
	[MAT_COMPUTER] = Vector(170, 170, 170),
	[MAT_DIRT] = Vector(100, 80, 50),
	[MAT_FOLIAGE] = Vector(100, 80, 50),
	[MAT_SAND] = Vector(100, 80, 50),
}

function EFFECT:Init(Data)
	local Direction = Data:GetNormal()
	local Caliber = Data:GetRadius()

	self.Origin = Data:GetOrigin()
	self.Radius = math.max(Data:GetScale() * 0.02, 1)
	self.Emitter = ParticleEmitter(self.Origin)
	self.ParticleMul = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)

	TraceData.start = self.Origin - Direction
	TraceData.endpos = self.Origin + Direction * 100
	TraceData.mask = MASK_SOLID

	local Impact = TraceLine(TraceData)

	self.Normal = Impact.HitNormal
	self.Color = Colors[Impact.MatType] or Vector(90, 90, 90)

	if Impact.HitSky or not Impact.Hit then
		self:Airburst()
	else
		self:GroundImpact()

		if Caliber > 0 and (IsValid(Impact.Entity) or Impact.HitWorld) then
			if self.Radius > 0 then
				local Size = self.Radius * 0.66
				local Type = GetIndex("HE")

				util.DecalEx(GetDecal(Type), Impact.Entity, Impact.HitPos, self.Normal, Color(255, 255, 255), Size, Size)
			end

			local Effect = EffectData()
			Effect:SetOrigin(self.Origin)
			Effect:SetNormal(Direction)
			Effect:SetRadius(Caliber)
			Effect:SetDamageType(GetIndex("AP"))

			util.Effect("ACF_Impact", Effect)
		end
	end

	TraceData.start = self.Origin + Vector(0, 0, 1)
	TraceData.endpos = self.Origin - Vector(0, 0, self.Radius)
	TraceData.mask = MASK_NPCWORLDSTATIC

	local Ground = TraceLine(TraceData)

	if Ground.HitWorld then
		self:Shockwave(Ground)
	end

	self.Emitter:Finish()
end

function EFFECT:Core()
	for _ = 0, 2 * self.Radius * self.ParticleMul do
		local Flame = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)

		if Flame then
			Flame:SetVelocity(VectorRand(50, 150 * self.Radius))
			Flame:SetLifeTime(0)
			Flame:SetDieTime(0.15)
			Flame:SetStartAlpha(math.Rand(50, 255))
			Flame:SetEndAlpha(0)
			Flame:SetStartSize(2.5 * self.Radius)
			Flame:SetEndSize(15 * self.Radius)
			Flame:SetRoll(math.random(120, 360))
			Flame:SetRollDelta(math.Rand(-1, 1))
			Flame:SetAirResistance(300)
			Flame:SetGravity(Vector(0, 0, 4))
			Flame:SetColor(255, 255, 255)
		end
	end

	for _ = 0, 4 * self.Radius * self.ParticleMul do
		local Debris = self.Emitter:Add("effects/fleck_tile" .. math.random(1, 2), self.Origin)

		if Debris then
			Debris:SetVelocity(VectorRand(150 * self.Radius, 250 * self.Radius))
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(1.5, 3) * self.Radius / 3)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(1 * self.Radius)
			Debris:SetEndSize(1 * self.Radius)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(10)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 5 * self.Radius * self.ParticleMul do
		local Embers = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)

		if Embers then
			Embers:SetVelocity(VectorRand(70 * self.Radius, 160 * self.Radius))
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.3, 1) * self.Radius / 3)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(1 * self.Radius)
			Embers:SetEndSize(0 * self.Radius)
			Embers:SetStartLength(5 * self.Radius)
			Embers:SetEndLength(0 * self.Radius)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetGravity(Vector(0, 0, -650))
			Embers:SetColor(200, 200, 200)
		end
	end

	for _ = 0, 2 * self.Radius * self.ParticleMul do
		local Whisp = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Origin)

		if Whisp then
			Whisp:SetVelocity(VectorRand(150, 250 * self.Radius))
			Whisp:SetLifeTime(0)
			Whisp:SetDieTime(math.Rand(3, 5) * self.Radius / 3)
			Whisp:SetStartAlpha(math.Rand(20, 50))
			Whisp:SetEndAlpha(0)
			Whisp:SetStartSize(10 * self.Radius)
			Whisp:SetEndSize(80 * self.Radius)
			Whisp:SetRoll(math.Rand(150, 360))
			Whisp:SetRollDelta(math.Rand(-0.2, 0.2))
			Whisp:SetAirResistance(100)
			Whisp:SetGravity(Vector(math.random(-5, 5) * self.Radius, math.random(-5, 5) * self.Radius, 0))
			Whisp:SetColor(150, 150, 150)
		end
	end

	if self.Radius * self.ParticleMul > 4 then
		for _ = 0, 0.5 * self.Radius * self.ParticleMul do
			local Effect = EffectData()
			Effect:SetOrigin(self.Origin)
			Effect:SetScale(self.Radius * 0.1667)

			util.Effect("ACF_Cookoff", Effect)
		end
	end

	sound.Play("ambient/explosions/explode_5.wav", self.Origin, math.Clamp(self.Radius * 10, 75, 165), math.Clamp(300 - self.Radius * 12, 15, 255))
	sound.Play("ambient/explosions/explode_4.wav", self.Origin, math.Clamp(self.Radius * 10, 75, 165), math.Clamp(300 - self.Radius * 25, 15, 255))
end

function EFFECT:Shockwave(Ground)
	local Radius = (1 - Ground.Fraction) * self.Radius
	local Density = 15 * Radius
	local Angle = Ground.HitNormal:Angle()
	local SmokeColor = self.Color

	for _ = 0, Density * self.ParticleMul do
		Angle:RotateAroundAxis(Angle:Forward(), 360 / Density)
		local ShootVector = Angle:Up()
		local Smoke = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Ground.HitPos)

		if Smoke then
			Smoke:SetVelocity(ShootVector * math.Rand(5, 200 * Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 2) * Radius / 3)
			Smoke:SetStartAlpha(math.Rand(50, 120))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(4 * Radius)
			Smoke:SetEndSize(15 * Radius)
			Smoke:SetRoll(math.Rand(0, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(200)
			Smoke:SetGravity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(10, 100)))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end
end

function EFFECT:GroundImpact()
	self:Core()

	local SmokeColor = self.Color

	for _ = 0, 3 * self.Radius * self.ParticleMul do
		local Smoke = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Origin)

		if Smoke then
			Smoke:SetVelocity(self.Normal * math.random(50, 80 * self.Radius) + VectorRand(30, 60 * self.Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 2) * self.Radius / 3)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(5 * self.Radius)
			Smoke:SetEndSize(30 * self.Radius)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(100)
			Smoke:SetGravity(Vector(math.random(-5, 5) * self.Radius, math.random(-5, 5) * self.Radius, -50))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end
end

function EFFECT:Airburst()
	self:Core()

	local SmokeColor = self.Color

	for _ = 0, 3 * self.Radius * self.ParticleMul do
		local Smoke = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Origin)

		if Smoke then
			Smoke:SetVelocity(VectorRand(25, 50 * self.Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 2) * self.Radius / 3)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(5 * self.Radius)
			Smoke:SetEndSize(30 * self.Radius)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(100)
			Smoke:SetGravity(Vector(math.random(-5, 5) * self.Radius, math.random(-5, 5) * self.Radius, -50))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end

	for _ = 0, 10 * self.Radius * self.ParticleMul do
		local AirBurst = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Origin)

		if AirBurst then
			AirBurst:SetVelocity(VectorRand(150, 200 * self.Radius))
			AirBurst:SetLifeTime(0)
			AirBurst:SetDieTime(math.Rand(1, 2) * self.Radius / 3)
			AirBurst:SetStartAlpha(math.Rand(100, 255))
			AirBurst:SetEndAlpha(0)
			AirBurst:SetStartSize(6 * self.Radius)
			AirBurst:SetEndSize(35 * self.Radius)
			AirBurst:SetRoll(math.Rand(150, 360))
			AirBurst:SetRollDelta(math.Rand(-0.2, 0.2))
			AirBurst:SetAirResistance(200)
			AirBurst:SetGravity(Vector(math.random(-10, 10) * self.Radius, math.random(-10, 10) * self.Radius, 20))
			AirBurst:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end