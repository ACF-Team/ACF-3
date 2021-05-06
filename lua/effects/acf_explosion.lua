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

function EFFECT:Core()
	local Radius = self.Radius

	local Level = math.Clamp(Radius * 10, 75, 165)

	sound.Play("ambient/explosions/explode_5.wav", self.Origin, Level, math.Clamp(300 - Radius * 12, 15, 255), ACF.Volume)
	sound.Play("ambient/explosions/explode_4.wav", self.Origin, Level, math.Clamp(300 - Radius * 25, 15, 255), ACF.Volume)
end

function EFFECT:GroundImpact()
	local SmokeColor = self.Color
	local Emitter = self.Emitter
	local Origin = self.Origin
	local Radius = self.Radius
	local Normal = self.Normal
	local Mult = self.ParticleMul

	self:Core(Normal)

	for _ = 0, 3 do
		local Flame = self.Emitter:Add("effects/muzzleflash" .. math.random(1, 4), self.Origin)

		if Flame then
			Flame:SetVelocity((Normal + VectorRand()) * 150 * Radius)
			Flame:SetLifeTime(0)
			Flame:SetDieTime(0.2)
			Flame:SetStartAlpha(255)
			Flame:SetEndAlpha(255)
			Flame:SetStartSize(Radius)
			Flame:SetEndSize(Radius * 40)
			Flame:SetRoll(math.random(120, 360))
			Flame:SetRollDelta(math.Rand(-1, 1))
			Flame:SetAirResistance(300)
			Flame:SetGravity(Vector(0, 0, 4))
			Flame:SetColor(255, 255, 255)
		end
	end
	print(Radius)
	for _ = 0, 5 * math.Clamp(Radius,1,30) * Mult do

		local Debris = self.Emitter:Add("effects/fleck_tile" .. math.random(1, 2), Origin)

		if Debris then
			Debris:SetVelocity((Normal + VectorRand()) * 150 * Radius)
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(0.5, 1) * Radius)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(math.Clamp(Radius,1,7))
			Debris:SetEndSize(math.Clamp(Radius,1,7))
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(30)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 20 * math.Clamp(Radius,1,10) * Mult do
		local Embers = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin)

		if Embers then
			Embers:SetVelocity((Normal + VectorRand()) * 150 * Radius)
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
	local DietimeMod = math.Clamp(Radius,1,14)
	for _ = 0, math.Clamp(Radius,1,10) * Mult do
		if Radius >= 4 then
			local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)
			if Smoke then
				Smoke:SetVelocity((Normal + VectorRand() * 0.75) * 1 * Radius)
				Smoke:SetLifeTime(0)
				Smoke:SetDieTime(math.Rand(0.02, 0.08) * Radius)
				Smoke:SetStartAlpha(math.Rand(180, 255))
				Smoke:SetEndAlpha(0)
				Smoke:SetStartSize(30 * Radius)
				Smoke:SetEndSize(40 * Radius)
				Smoke:SetAirResistance(0)
				Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
				Smoke:SetStartLength(Radius * 20)
				Smoke:SetEndLength(Radius * 125)
			end
		end
		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)
		local Radmod = Radius * 0.25
		if Smoke then
			Smoke:SetVelocity((Normal + VectorRand() * 0.6) * math.random(230,300) * Radmod)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(0.5, 0.6) * DietimeMod)
			Smoke:SetStartAlpha(math.Rand(70, 200))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(100 * Radmod)
			Smoke:SetEndSize(120 * Radmod)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(5 * Radius)
			Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -math.random(10,40) * Radius))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end

	local Density = math.Clamp(Radius,1,10) * 15
	local Angle = Normal:Angle()
	for _ = 0, Density * Mult do
		Angle:RotateAroundAxis(Angle:Forward(), 360 / Density)

		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity(Angle:Up() * math.Rand(50, 200 * Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(0.5, 0.6) * DietimeMod)
			Smoke:SetStartAlpha(math.Rand(20, 50))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(10 * Radius)
			Smoke:SetEndSize(20 * Radius)
			Smoke:SetRoll(math.Rand(0, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(12 * Radius)
			Smoke:SetGravity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(10, 100)))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end
end

function EFFECT:Airburst()
	local SmokeColor = self.Color
	local Emitter = self.Emitter
	local Origin = self.Origin
	local Radius = self.Radius * 0.75
	local Mult = self.ParticleMul
	local Normal = self.DirVec

	self:Core(self.DirVec)

	for _ = 0, 3 do
		local Flame = self.Emitter:Add("effects/muzzleflash" .. math.random(1, 4), self.Origin)

		if Flame then
			Flame:SetLifeTime(0)
			Flame:SetDieTime(0.2)
			Flame:SetStartAlpha(255)
			Flame:SetEndAlpha(255)
			Flame:SetStartSize(Radius)
			Flame:SetEndSize(Radius * 70)
			Flame:SetRoll(math.random(120, 360))
			Flame:SetRollDelta(math.Rand(-1, 1))
			Flame:SetAirResistance(300)
			Flame:SetGravity(Vector(0, 0, 4))
			Flame:SetColor(255, 255, 255)
		end
	end

	local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

	if Smoke then
		Smoke:SetLifeTime(0)
		Smoke:SetDieTime(math.Rand(1, 0.2 * Radius))
		Smoke:SetStartAlpha(math.Rand(150, 200))
		Smoke:SetEndAlpha(0)
		Smoke:SetStartSize(20 * Radius)
		Smoke:SetEndSize(10 * Radius)
		Smoke:SetRoll(math.Rand(150, 360))
		Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
		Smoke:SetGravity(Vector(math.random(-2, 2) * Radius, math.random(-2, 2) * Radius, -math.random(10, 30)))
		Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
	end

	for _ = 0, Radius * Mult do
		Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin - Normal * 4 * Radius)
		local Radmod = Radius * 0.25

		Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity((Normal + VectorRand() * 0.08) * math.random(20,300) * Radmod)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 0.2 * Radius))
			Smoke:SetStartAlpha(math.Rand(80, 200))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(40 * Radmod)
			Smoke:SetEndSize(140 * Radmod)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(math.random(1,_ * 2) * Radius)
			Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -math.random(10, 30)))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end

		Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity((Normal + VectorRand() * 0.08) * -math.random(20,40) * Radmod)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 0.2 * Radius))
			Smoke:SetStartAlpha(math.Rand(40, 80))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(80 * Radmod)
			Smoke:SetEndSize(100 * Radmod)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(math.random(1,_ * 2) * Radius)
			Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -math.random(10, 30)))
			Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
		end
	end

	local Angle = Normal:Angle()
	Angle:RotateAroundAxis(Angle:Forward(), math.random(1,300))
	local rv = math.random(8,12) * Mult * Radius
	for _ = 0, rv do
		Angle:RotateAroundAxis(Angle:Forward(), 360 / rv)
		Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)
		if Smoke then
			if Radius >= 10 then
				Smoke:SetVelocity(Angle:Up() * math.Rand(50, 200) * Radius)
				Smoke:SetLifeTime(0)
				Smoke:SetDieTime(math.Rand(1, 0.2 * Radius))
				Smoke:SetStartAlpha(math.Rand(20, 40))
				Smoke:SetEndAlpha(0)
				Smoke:SetStartSize(10 * Radius)
				Smoke:SetEndSize(15 * Radius)
				Smoke:SetRoll(math.Rand(0, 360))
				Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
				Smoke:SetAirResistance(20 * Radius)
				Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -math.random(20, 40)))
				Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
			else
				Smoke:SetVelocity(Angle:Up() * math.Rand(50, 200) * Radius)
				Smoke:SetLifeTime(0)
				Smoke:SetDieTime(math.Rand(1, 0.2 * Radius))
				Smoke:SetStartAlpha(math.Rand(80, 120))
				Smoke:SetEndAlpha(0)
				Smoke:SetStartSize(20 * Radius)
				Smoke:SetEndSize(40 * Radius)
				Smoke:SetRoll(math.Rand(0, 360))
				Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
				Smoke:SetAirResistance(40 * Radius)
				Smoke:SetGravity(Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -math.random(20, 40)))
				Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
			end
		end
		for _ = 0, 2 do
			local Spark = Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin + (Angle:Up() * math.random(1,10) * Radius))
			if Spark then
				Spark:SetVelocity((Angle:Up() + Normal * math.random(2,40)):GetNormalized() * math.random(2000,4000) * (Radius * 0.2))
				Spark:SetLifeTime(0)
				Spark:SetDieTime(math.Rand(1, 2 * (Radius * 0.15)))
				Spark:SetStartAlpha(255)
				Spark:SetEndAlpha(0)
				Spark:SetStartSize(math.random(2,4) * 0.2 * Radius)
				Spark:SetEndSize(0 * Radius)
				Spark:SetStartLength(math.random(20,40) * Radius)
				Spark:SetEndLength(0)
				Spark:SetRoll(math.Rand(0, 360))
				Spark:SetRollDelta(math.Rand(-0.2, 0.2))
				Spark:SetAirResistance(10)
				Spark:SetGravity(Vector(0,0,-300))
				Spark:SetColor(255, 255, 255)
			end
		end

		EF = self.Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin)
		if EF then
			EF:SetVelocity((Angle:Up() + Normal * math.random(0.3,5)):GetNormalized() *  1)
			EF:SetAirResistance(100)
			EF:SetDieTime(0.2)
			EF:SetStartAlpha(240)
			EF:SetEndAlpha(20 )
			EF:SetStartSize(6 * Radius)
			EF:SetEndSize(4 * Radius)
			EF:SetRoll(800)
			EF:SetRollDelta( math.random(-1, 1) )
			EF:SetColor(255, 255, 255)
			EF:SetStartLength(Radius)
			EF:SetEndLength(Radius * 100)
		end
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
