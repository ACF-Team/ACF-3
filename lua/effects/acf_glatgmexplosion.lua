local TraceData = { start = true, endpos = true, mask = true }
local TraceLine = util.TraceLine
local Sounds    = ACF.Utilities.Sounds

function EFFECT:Init(Data)
	self.DirVec = Data:GetNormal()
	self.Origin = Data:GetOrigin() + self.DirVec * -15
	self.Radius = math.Clamp(Data:GetScale() * 0.042, 0.1, 10)

	self.Emitter = ParticleEmitter(self.Origin)
	self.ParticleMul = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)

	TraceData.start = self.Origin - self.DirVec
	TraceData.endpos = self.Origin + self.DirVec * 100
	TraceData.mask = MASK_SOLID

	local Impact = TraceLine(TraceData)

	self.Normal = Impact.HitNormal
	self.Color = Vector(102, 93, 77)
	self:Airburst()

	self.Emitter:Finish()
end

function EFFECT:Airburst()
	local SmokeColor = self.Color
	local Emitter = self.Emitter
	local Origin = self.Origin
	local Radius = self.Radius
	local Mult = self.ParticleMul
	local sndrad = math.Clamp(Radius * 20, 75, 165)
	local sndradp = 300 - Radius
	Sounds.PlaySound(self.Origin, "ambient/explosions/explode_4.wav", sndrad, math.Clamp(sndradp * 25, 15, 170), 1)
	Sounds.PlaySound(self.Origin, "ambient/explosions/explode_9.wav", sndrad, math.Clamp(sndradp * 22, 15, 120), 1)
	local EF = self.Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin )
	if EF then
		EF:SetVelocity(self.DirVec * 100)
		EF:SetAirResistance( 200)
		EF:SetDieTime(0.2)
		EF:SetStartAlpha(255)
		EF:SetEndAlpha(2)
		EF:SetStartSize(30 * Radius)
		EF:SetEndSize(30 * Radius)
		EF:SetRoll(800)
		EF:SetRollDelta(math.random(-1, 1))
		EF:SetColor(255, 255, 255)
	end
	local EI = 20 * Radius * Mult
	for E = 0, EI do
	EF = self.Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin )
		if EF then
			EF:SetVelocity( self.DirVec * (EI - E) * 60)
			EF:SetAirResistance(100)
			EF:SetDieTime(0.1)
			EF:SetStartAlpha(255)
			EF:SetEndAlpha(0)
			EF:SetStartSize(E * 2)
			EF:SetEndSize(0)
			EF:SetRoll(800)
			EF:SetRollDelta(math.random(-1, 1))
			EF:SetColor(255, 255, 255)
		end
	end
	EI = 10 * Radius * Mult
	for E = 0, EI do
	EF = self.Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin)
		if EF then
			EF:SetVelocity(self.DirVec * (EI - E) * -40)
			EF:SetAirResistance(400)
			EF:SetDieTime(0.1)
			EF:SetStartAlpha(255)
			EF:SetEndAlpha(0)
			EF:SetStartSize(E * 4)
			EF:SetEndSize(0)
			EF:SetRoll(800)
			EF:SetRollDelta(math.random(-1, 1))
			EF:SetColor(255, 255, 255)
		end
	end
	local Angle = self.DirVec:Angle()
	Angle:RotateAroundAxis(Angle:Forward(), math.random(1, 300))
	local rv = math.random(20, 40) * Mult
	for _ = 0, rv do
		Angle:RotateAroundAxis(Angle:Forward(), 360 / rv)
		EF = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)
		if EF then
			EF:SetVelocity((Angle:Up() - self.DirVec * math.random(0.05, 0.25)) * math.random(200, 300) * Radius)
			EF:SetDieTime(math.random(0.35, 0.8))
			EF:SetStartAlpha(100)
			EF:SetEndAlpha(0)
			EF:SetStartSize(15 * Radius)
			EF:SetEndSize(20 * Radius)
			EF:SetRoll(math.random(0, 360))
			EF:SetRollDelta(math.random(-1, 1))
			EF:SetAirResistance(400)
			EF:SetGravity(Vector(math.random(-10, 10) * Radius, math.random(-10, 10) * Radius, 20))
			EF:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
		local Spark = Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)
		if Spark then
			Spark:SetVelocity((Angle:Up() - self.DirVec * math.random(-0.5, 1)) * math.random(40, 100) * Radius)
			Spark:SetLifeTime(0)
			Spark:SetDieTime(math.Rand(2, 8) * self.Radius)
			Spark:SetStartAlpha(255)
			Spark:SetEndAlpha(20)
			Spark:SetStartSize(math.random(2, 4) * 0.2 * self.Radius)
			Spark:SetEndSize(0 * self.Radius)
			Spark:SetStartLength(math.random(2, 7) * 0.5 * self.Radius)
			Spark:SetEndLength(0)
			Spark:SetRoll(math.Rand(0, 360))
			Spark:SetRollDelta(math.Rand(-0.2, 0.2))
			Spark:SetAirResistance(10)
			Spark:SetGravity(Vector(0, 0, -400))
			Spark:SetColor(200, 200, 200)
			Spark:SetCollide(true)
			Spark:SetBounce(0.2)
		end
		EI = 4 * Radius
		for E = 0, EI do
			EF = self.Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin)
			if EF then
				EF:SetVelocity(Angle:Up() * (EI - E) * 70)
				EF:SetAirResistance(100)
				EF:SetDieTime(0.15)
				EF:SetStartAlpha(240)
				EF:SetEndAlpha(20 )
				EF:SetStartSize(E * 6)
				EF:SetEndSize(E * 4)
				EF:SetRoll(800)
				EF:SetRollDelta( math.random(-1, 1) )
				EF:SetColor(255, 255, 255)
			end
		end
	end
	for _ = 0, 4 * Radius * Mult do
		local AirBurst = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)
		if AirBurst then
			AirBurst:SetVelocity((self.DirVec + VectorRand(-4.8, 4.8)) * -math.random(10, 20) * Radius)
			AirBurst:SetLifeTime(0)
			AirBurst:SetDieTime(4.8)
			AirBurst:SetStartAlpha(10)
			AirBurst:SetEndAlpha(0)
			AirBurst:SetStartSize(1 * Radius)
			AirBurst:SetEndSize(100 * Radius)
			AirBurst:SetRoll(math.Rand(150, 360))
			AirBurst:SetRollDelta(math.Rand(-0.2, 0.2))
			AirBurst:SetAirResistance(math.random(70, 120))
			AirBurst:SetGravity(Vector(math.random(-10, 10) * Radius, math.random(-10, 10) * Radius, 20))
			AirBurst:SetColor(200, 200, 200)
		end
	end
	for _ = 0, 3 * Radius * Mult do
		local AirBurst = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)
		if AirBurst then
			AirBurst:SetVelocity(VectorRand(-100, 100) * Radius)
			AirBurst:SetLifeTime(0)
			AirBurst:SetDieTime(4.7)
			AirBurst:SetStartAlpha(30)
			AirBurst:SetEndAlpha(0)
			AirBurst:SetStartSize(15 * Radius)
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
