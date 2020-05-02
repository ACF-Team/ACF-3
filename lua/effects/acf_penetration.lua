local TraceData = { start = true, endpos = true }
local TraceLine = util.TraceLine
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal = ACF.GetPenetrationDecal
local GetScale = ACF.GetDecalScale

function EFFECT:Init(Data)
	self.Caliber = Data:GetRadius()
	self.Origin = Data:GetOrigin()
	self.DirVec = Data:GetNormal()
	self.Velocity = Data:GetScale() --Mass of the projectile in kg
	self.Mass = Data:GetMagnitude() --Velocity of the projectile in gmod units
	self.Type = Data:GetDamageType()
	self.Emitter = ParticleEmitter(self.Origin)
	self.Scale = math.max(self.Mass * (self.Velocity * 0.0254) * 0.01, 1) ^ 0.3

	TraceData.start = self.Origin - self.DirVec
	TraceData.endpos = self.Origin + self.DirVec * self.Velocity

	local Trace = TraceLine(TraceData) --Trace to see if it will hit anything

	self.Normal = Trace.HitNormal

	local Mat = Trace.MatType

	-- Metal
	if Mat == 71 or Mat == 73 or Mat == 77 or Mat == 80 then
		self:Metal()
	else -- Nonspecific
		self:Concrete()
	end

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local Type = ValidDecal(self.Type) and self.Type or 1
		local Scale = GetScale(Type, self.Caliber)

		util.DecalEx(GetDecal(Type), Trace.Entity, Trace.HitPos, self.Normal, Color(255, 255, 255), Scale, Scale)
	end

	-- Sound
	if self.Caliber >= 10 then
		sound.Play("/acf_other/penetratingshots/large/0" .. math.random(0, 8) .. ".mp3", Trace.HitPos, math.Clamp(self.Mass * 200, 65, 500), math.Clamp(self.Velocity * 0.01, 25, 100), 0.4) --100mm and up
	else
		sound.Play("/acf_other/penetratingshots/medium/0" .. math.random(0, 9) .. ".mp3", Trace.HitPos, math.Clamp(self.Mass * 200, 65, 500), math.Clamp(self.Velocity * 0.01, 15, 100), 0.35) --99mm and down
	end

end

function EFFECT:Metal()
	for _ = 0, 4 * self.Scale do
		local Debris = self.Emitter:Add("effects/fleck_tile" .. math.random(1, 2), self.Origin)

		if (Debris) then
			Debris:SetVelocity(self.Normal * math.random(20, 40 * self.Scale) + VectorRand() * math.random(25, 50 * self.Scale))
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(1.5, 3) * self.Scale / 3)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(1 * self.Scale)
			Debris:SetEndSize(1 * self.Scale)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(100)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 5 * self.Scale do
		local Embers = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)

		if (Embers) then
			Embers:SetVelocity((self.Normal - VectorRand()) * math.random(30 * self.Scale, 80 * self.Scale))
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.3, 1) * self.Scale / 5)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(2 * self.Scale)
			Embers:SetEndSize(0 * self.Scale)
			Embers:SetStartLength(5 * self.Scale)
			Embers:SetEndLength(0 * self.Scale)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetGravity(VectorRand() * 10)
			Embers:SetColor(200, 200, 200)
		end
	end

	local Sparks = EffectData()
	Sparks:SetOrigin(self.Origin)
	Sparks:SetNormal(self.Normal)
	Sparks:SetMagnitude(self.Scale)
	Sparks:SetScale(self.Scale)
	Sparks:SetRadius(self.Scale)
	util.Effect("Sparks", Sparks)
end

function EFFECT:Concrete()
	for _ = 0, 4 * self.Scale do
		local Debris = self.Emitter:Add("effects/fleck_tile" .. math.random(1, 2), self.Origin)

		if (Debris) then
			Debris:SetVelocity(self.Normal * math.random(20, 40 * self.Scale) + VectorRand() * math.random(25, 50 * self.Scale))
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(1.5, 3) * self.Scale / 3)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(1 * self.Scale)
			Debris:SetEndSize(1 * self.Scale)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(100)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 3 * self.Scale do
		local Smoke = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Origin)

		if (Smoke) then
			Smoke:SetVelocity(self.Normal * math.random(20, 40 * self.Scale) + VectorRand() * math.random(25, 50 * self.Scale))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 2) * self.Scale / 3)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(1 * self.Scale)
			Smoke:SetEndSize(2 * self.Scale)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(200)
			Smoke:SetGravity(Vector(math.random(-5, 5) * self.Scale, math.random(-5, 5) * self.Scale, -50))
			Smoke:SetColor(90, 90, 90)
		end
	end

	for _ = 0, 5 * self.Scale do
		local Embers = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)

		if (Embers) then
			Embers:SetVelocity((self.Normal - VectorRand()) * math.random(30 * self.Scale, 80 * self.Scale))
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.3, 1) * self.Scale / 5)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(5 * self.Scale)
			Embers:SetEndSize(0 * self.Scale)
			Embers:SetStartLength(5 * self.Scale)
			Embers:SetEndLength(0 * self.Scale)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetGravity(VectorRand() * 10)
			Embers:SetColor(200, 200, 200)
		end
	end

	local Sparks = EffectData()
	Sparks:SetOrigin(self.Origin)
	Sparks:SetNormal(self.Normal)
	Sparks:SetMagnitude(self.Scale)
	Sparks:SetScale(self.Scale)
	Sparks:SetRadius(self.Scale)
	util.Effect("Sparks", Sparks)
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
