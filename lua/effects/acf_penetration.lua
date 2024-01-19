local TraceData  = { start = true, endpos = true }
local TraceLine  = util.TraceLine
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal   = ACF.GetPenetrationDecal
local GetScale   = ACF.GetDecalScale
local Sounds     = ACF.Utilities.Sounds
local Sound      = "acf_base/fx/penetration%s.mp3"
local White      = Color(255, 255, 255)

function EFFECT:Init(Data)
	local Caliber  = Data:GetRadius()
	local Origin   = Data:GetOrigin()
	local Normal   = Data:GetNormal()
	local Velocity = Data:GetScale() -- Velocity of the projectile in gmod units
	local Mass     = Data:GetMagnitude() -- Mass of the projectile in kg
	local Index    = Data:GetDamageType()
	local Emitter  = ParticleEmitter(Origin)
	local Scale    = math.max(Mass * (Velocity * 0.0254) * 0.01, 1) ^ 0.3
	local Level    = math.Clamp(Mass * 200, 65, 500)
	local Pitch    = math.Clamp(Velocity * 0.01, 25, 255)

	TraceData.start = Origin - Normal
	TraceData.endpos = Origin + Normal * Velocity

	local Trace     = TraceLine(TraceData)
	local HitNormal = Trace.HitNormal
	local MatType   = Trace.MatType

	if MatType == 71 or MatType == 73 or MatType == 77 or MatType == 80 then
		self:Metal(Emitter, Origin, Scale, HitNormal)
	else -- Nonspecific
		self:Concrete(Emitter, Origin, Scale, HitNormal)
	end

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local Type = ValidDecal(Index) and Index or 1
		local Size = GetScale(Type, Caliber)

		util.DecalEx(GetDecal(Type), Trace.Entity, Trace.HitPos, HitNormal, White, Size, Size)
	end

	Sounds.PlaySound(Trace.HitPos, Sound:format(math.random(1, 6)), Level, Pitch, 1)
end

function EFFECT:Metal(Emitter, Origin, Scale, HitNormal)
	local Sparks = EffectData()
		Sparks:SetOrigin(Origin)
		Sparks:SetNormal(HitNormal)
		Sparks:SetMagnitude(Scale)
		Sparks:SetScale(Scale)
		Sparks:SetRadius(Scale)
	util.Effect("Sparks", Sparks)

	if not IsValid(Emitter) then return end

	for _ = 0, 4 * Scale do
		local Debris = Emitter:Add("effects/fleck_tile" .. math.random(1, 2), Origin)

		if Debris then
			Debris:SetVelocity(HitNormal * math.random(20, 40 * Scale) + VectorRand() * math.random(25, 50 * Scale))
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(1.5, 3) * Scale * 0.3333)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(1 * Scale)
			Debris:SetEndSize(1 * Scale)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(100)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 5 * Scale do
		local Embers = Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin)

		if Embers then
			Embers:SetVelocity((HitNormal - VectorRand()) * math.random(30 * Scale, 80 * Scale))
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.3, 1) * Scale * 0.2)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(2 * Scale)
			Embers:SetEndSize(0 * Scale)
			Embers:SetStartLength(5 * Scale)
			Embers:SetEndLength(0 * Scale)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetGravity(VectorRand() * 10)
			Embers:SetColor(200, 200, 200)
		end
	end

	Emitter:Finish()
end

function EFFECT:Concrete(Emitter, Origin, Scale, HitNormal)
	local Sparks = EffectData()
		Sparks:SetOrigin(Origin)
		Sparks:SetNormal(HitNormal)
		Sparks:SetMagnitude(Scale)
		Sparks:SetScale(Scale)
		Sparks:SetRadius(Scale)
	util.Effect("Sparks", Sparks)

	if not IsValid(Emitter) then return end

	for _ = 0, 4 * Scale do
		local Debris = Emitter:Add("effects/fleck_tile" .. math.random(1, 2), Origin)

		if Debris then
			Debris:SetVelocity(HitNormal * math.random(20, 40 * Scale) + VectorRand() * math.random(25, 50 * Scale))
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(1.5, 3) * Scale * 0.3333)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(1 * Scale)
			Debris:SetEndSize(1 * Scale)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(100)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 3 * Scale do
		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity(HitNormal * math.random(20, 40 * Scale) + VectorRand() * math.random(25, 50 * Scale))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 2) * Scale * 0.3333)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(1 * Scale)
			Smoke:SetEndSize(2 * Scale)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(200)
			Smoke:SetGravity(Vector(math.random(-5, 5) * Scale, math.random(-5, 5) * Scale, -50))
			Smoke:SetColor(90, 90, 90)
		end
	end

	for _ = 0, 5 * Scale do
		local Embers = Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin)

		if Embers then
			Embers:SetVelocity((HitNormal - VectorRand()) * math.random(30 * Scale, 80 * Scale))
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.3, 1) * Scale * 0.2)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(5 * Scale)
			Embers:SetEndSize(0 * Scale)
			Embers:SetStartLength(5 * Scale)
			Embers:SetEndLength(0 * Scale)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetGravity(VectorRand() * 10)
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