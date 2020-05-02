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
	local Caliber = Data:GetRadius()

	self.Origin = Data:GetOrigin()
	self.DirVec = Data:GetNormal()
	self.Radius = math.max(Data:GetScale() * 0.02, 1)
	self.Emitter = ParticleEmitter(self.Origin)
	self.ParticleMul = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)

	TraceData.start = self.Origin - self.DirVec
	TraceData.endpos = self.Origin + self.DirVec * 100
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
			Effect:SetNormal(self.DirVec)
			Effect:SetRadius(Caliber)
			Effect:SetDamageType(GetIndex("AP"))

			util.Effect("ACF_Impact", Effect)
		end
	end

	self.Emitter:Finish()
end

function EFFECT:Core(Direction)
	local Radius = self.Radius
	local Mult = self.ParticleMul

	for _ = 0, 2 * Radius * Mult do
		local Flame = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)

		if Flame then
			Flame:SetVelocity((Direction + VectorRand()) * 150 * Radius)
			Flame:SetLifeTime(0)
			Flame:SetDieTime(0.15)
			Flame:SetStartAlpha(math.Rand(100, 200))
			Flame:SetEndAlpha(0)
			Flame:SetStartSize(Radius)
			Flame:SetEndSize(Radius * 15)
			Flame:SetRoll(math.random(120, 360))
			Flame:SetRollDelta(math.Rand(-1, 1))
			Flame:SetAirResistance(300)
			Flame:SetGravity(Vector(0, 0, 4))
			Flame:SetColor(255, 255, 255)
		end
	end

	for _ = 0, 5 * Radius * Mult do
		local Debris = self.Emitter:Add("effects/fleck_tile" .. math.random(1, 2), self.Origin)

		if Debris then
			Debris:SetVelocity((Direction + VectorRand()) * 150 * Radius)
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(0.5, 1) * Radius)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(Radius)
			Debris:SetEndSize(Radius)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(30)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 20 * Radius * Mult do
		local Embers = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)

		if Embers then
			Embers:SetVelocity((Direction + VectorRand()) * 150 * Radius)
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.1, 0.2) * Radius)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(Radius * 0.5)
			Embers:SetEndSize(0)
			Embers:SetStartLength(Radius * 4)
			Embers:SetEndLength(0)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetColor(200, 200, 200)
		end
	end

	sound.Play("/acf_other/explosion/large/0" .. math.random(0, 2) .. ".mp3", self.Origin, math.Clamp(Radius * 10, 75, 165), math.Clamp(300 - Radius * 12, 15, 100)) --kABOOMM
	sound.Play("/acf_other/explosion/medium/0" .. math.random(0, 4) .. ".mp3", self.Origin, math.Clamp(Radius * 10, 75, 165), math.Clamp(300 - Radius * 25, 15, 100)) --boom
end

function EFFECT:GroundImpact()
	local SmokeColor = self.Color
	local Emitter = self.Emitter
	local Origin = self.Origin
	local Radius = self.Radius
	local Normal = self.Normal
	local Mult = self.ParticleMul

	self:Core(Normal)

	for _ = 0, 5 * Radius * Mult do
		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity((Normal + VectorRand()) * 30 * Radius)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(0.5, 1) * Radius)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(5 * Radius)
			Smoke:SetEndSize(30 * Radius)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(75)
			Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -50))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end

	local Density = Radius * 15
	local Angle = Normal:Angle()

	for _ = 0, Density * Mult do
		Angle:RotateAroundAxis(Angle:Forward(), 360 / Density)

		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity(Angle:Up() * math.Rand(5, 200 * Radius))
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

function EFFECT:Airburst()
	local SmokeColor = self.Color
	local Emitter = self.Emitter
	local Origin = self.Origin
	local Radius = self.Radius
	local Mult = self.ParticleMul

	self:Core(self.DirVec)

	for _ = 0, 5 * Radius * Mult do
		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity(VectorRand(-30, 30) * Radius)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(0.5, 1) * Radius)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(5 * Radius)
			Smoke:SetEndSize(30 * Radius)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(75)
			Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -50))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end

	for _ = 0, 5 * Radius * Mult do
		local AirBurst = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if AirBurst then
			AirBurst:SetVelocity(VectorRand(-100, 100) * Radius)
			AirBurst:SetLifeTime(0)
			AirBurst:SetDieTime(math.Rand(0.33, 0.66) * Radius)
			AirBurst:SetStartAlpha(math.Rand(100, 255))
			AirBurst:SetEndAlpha(0)
			AirBurst:SetStartSize(6 * Radius)
			AirBurst:SetEndSize(35 * Radius)
			AirBurst:SetRoll(math.Rand(150, 360))
			AirBurst:SetRollDelta(math.Rand(-0.2, 0.2))
			AirBurst:SetAirResistance(200)
			AirBurst:SetGravity(Vector(math.random(-10, 10) * Radius, math.random(-10, 10) * Radius, 20))
			AirBurst:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
