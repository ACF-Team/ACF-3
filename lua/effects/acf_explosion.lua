local TraceData = { start = true, endpos = true, mask = MASK_SOLID }
local TraceLine = util.TraceLine
local GetIndex  = ACF.GetAmmoDecalIndex
local GetDecal  = ACF.GetRicochetDecal
local Sounds    = ACF.Utilities.Sounds
local White     = Color(255, 255, 255)
local Yellow    = Color(255, 255, 0)

local Colors = {
	Default        = Color(120, 110, 100),
	[MAT_GRATE]    = Color(170, 160, 144),
	[MAT_CLIP]     = Color(170, 160, 144),
	[MAT_METAL]    = Color(170, 160, 144),
	[MAT_COMPUTER] = Color(170, 160, 144),
	[MAT_CONCRETE] = Color(180, 172, 158),
	[MAT_DIRT]     = Color(95, 80, 63),
	[MAT_GRASS]    = Color(114, 100, 80),
	[MAT_SLOSH]    = Color(104, 90, 70),
	[MAT_SNOW]     = Color(154, 140, 110),
	[MAT_FOLIAGE]  = Color(104, 90, 70),
	[MAT_SAND]     = Color(180, 155, 100),
}

function EFFECT:Init(Data)
	local Origin  = Data:GetOrigin()
	local Normal  = Data:GetNormal():GetNormalized() -- Gross
	local Size    = Data:GetScale()
	local Radius  = math.max(Size * 0.02, 1)
	local Emitter = ParticleEmitter(Origin)
	local Mult    = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)

	debugoverlay.Cross(Origin, 15, 15, Yellow, true)
	--debugoverlay.Sphere(Origin, Size, 15, Yellow, true)

	TraceData.start  = Origin - Normal * 5
	TraceData.endpos = Origin + Normal * Radius

	local Impact     = TraceLine(TraceData)
	local SmokeColor = Colors[Impact.MatType] or Colors.Default

	if Impact.HitSky or not Impact.Hit then
		TraceData.start = Origin
		TraceData.endpos = Origin - Vector(0,0,Size * 2)
		TraceData.collisiongroup = 1
		local Impact = TraceLine(TraceData)
		self:Airburst(Emitter, Impact.Hit, Origin, Impact.HitPos, Radius * 0.5, Normal, SmokeColor, Colors[Impact.MatType] or Colors.Default, Mult)
	else
		local HitNormal = Impact.HitNormal
		local Entity    = Impact.Entity

		self:GroundImpact(Emitter, Origin, Radius, HitNormal, SmokeColor, Mult)

		if Radius > 1 and (IsValid(Entity) or Impact.HitWorld) then
			local Size = Radius * 0.66
			local Type = GetIndex("HE")

			util.DecalEx(GetDecal(Type), Entity, Impact.HitPos, HitNormal, White, Size, Size)
		end
	end
end

function EFFECT:Core(Origin, Radius)
	local Pitch  = math.Clamp(123 - Radius * 3, 60, 120)

	Sounds.PlaySound(Origin, "ambient/explosions/explode_9.wav", 105, Pitch, 1)
	Sounds.PlaySound(Origin, "ambient/levels/streetwar/city_battle19.wav", 105, Pitch, 1)
end

function EFFECT:GroundImpact(Emitter, Origin, Radius, HitNormal, SmokeColor, Mult)
	self:Core(Origin, Radius)

	if not IsValid(Emitter) then return end

	for _ = 0, 3 do
		local Flame = Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin)

		if Flame then
			Flame:SetVelocity((HitNormal + VectorRand()) * 150 * Radius)
			Flame:SetLifeTime(0)
			Flame:SetDieTime(0.13)
			Flame:SetStartAlpha(255)
			Flame:SetEndAlpha(255)
			Flame:SetStartSize(Radius * 8)
			Flame:SetEndSize(Radius * 90)
			Flame:SetRoll(math.random(120, 360))
			Flame:SetRollDelta(math.Rand(-1, 1))
			Flame:SetAirResistance(300)
			Flame:SetGravity(Vector(0, 0, 4))
			Flame:SetColor(255, 255, 255)
		end
	end

	for _ = 0, 5 * math.Clamp(Radius,1,30) * Mult do
		local Debris = Emitter:Add("effects/fleck_tile" .. math.random(1, 2), Origin)

		if Debris then
			Debris:SetVelocity((HitNormal + VectorRand()) * 150 * Radius)
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

	for _ = 0, 5 * math.Clamp(Radius,7,10) * Mult do
		local Embers = Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin)

		if Embers then
			Embers:SetVelocity((HitNormal + VectorRand()) * 170 * Radius)
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.4, 0.8) * Radius)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(Radius * 1.2)
			Embers:SetEndSize(0)
			Embers:SetStartLength(Radius * 3)
			Embers:SetEndLength(0)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(5)
			Embers:SetGravity(Vector(0,0,-2000))
			Embers:SetColor(200, 200, 200)
		end
	end

	local DietimeMod = math.Clamp(Radius, 1, 14)

	for _ = 0, math.Clamp(Radius,3,14) * Mult do
		if Radius >= 4 then
			local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

			if Smoke then
				Smoke:SetVelocity((HitNormal + VectorRand() * 0.75) * 1 * Radius)
				Smoke:SetLifeTime(0)
				Smoke:SetDieTime(math.Rand(0.02, 0.04) * Radius)
				Smoke:SetStartAlpha(math.Rand(180, 255))
				Smoke:SetEndAlpha(0)
				Smoke:SetStartSize(30 * Radius)
				Smoke:SetEndSize(40 * Radius)
				Smoke:SetAirResistance(0)
				Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
				Smoke:SetStartLength(Radius * 20)
				Smoke:SetEndLength(Radius * 125)
			end
		end

		local Smoke  = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)
		local Radmod = Radius * 0.25
		local ScaleAdd = _ * 30
		if Smoke then
			Smoke:SetVelocity((HitNormal + VectorRand() * 0.237) * (math.random(300,450) + ScaleAdd * 1.3) * Radmod)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(0.8, 1) * DietimeMod)
			Smoke:SetStartAlpha(math.Rand(150, 200))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize((80 + ScaleAdd * 0.3) * Radmod)
			Smoke:SetEndSize((90 + ScaleAdd * 0.34) * Radmod)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(14 * Radius)
			Smoke:SetGravity(Vector(math.random(-2, 2) * Radius, math.random(-2, 2) * Radius, -math.random(50,70) * Radius))
			Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
		end
	end

	local Density = math.Clamp(Radius,10,14) * 8
	local Angle = HitNormal:Angle()

	for _ = 0, Density * Mult do
		Angle:RotateAroundAxis(Angle:Forward(), 360 / Density)

		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin + Angle:Up() * math.Rand(5, 50) * Radius)

		if Smoke then
			Smoke:SetVelocity(Angle:Up() * math.Rand(5, 70 * Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(0.5, 0.6) * DietimeMod)
			Smoke:SetStartAlpha(math.Rand(100, 140))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(10 * Radius)
			Smoke:SetEndSize(25 * Radius)
			Smoke:SetRoll(math.Rand(0, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(12 * Radius)
			Smoke:SetGravity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(10, 100)))
			Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
		end

		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin + Angle:Up() * math.Rand(40, 100) * Radius)

		if Smoke then
			Smoke:SetVelocity(Angle:Up() * math.Rand(5, 10 * Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(0.2, 0.4) * DietimeMod)
			Smoke:SetStartAlpha(math.Rand(70, 120))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(5 * Radius)
			Smoke:SetEndSize(10 * Radius)
			Smoke:SetRoll(math.Rand(0, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(12 * Radius)
			Smoke:SetGravity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(10, 100)))
			Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
		end

		local EF = Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin)

		if EF then
			EF:SetVelocity((Angle:Up() + HitNormal * math.random(0.3,5)):GetNormalized() *  1)
			EF:SetAirResistance(100)
			EF:SetDieTime(0.13)
			EF:SetStartAlpha(240)
			EF:SetEndAlpha(20)
			EF:SetStartSize(10 * Radius)
			EF:SetEndSize(8 * Radius)
			EF:SetRoll(800)
			EF:SetRollDelta( math.random(-1, 1) )
			EF:SetColor(255, 255, 255)
			EF:SetStartLength(Radius * 0.05)
			EF:SetEndLength(Radius * 70)
		end
	end

	Emitter:Finish()
end

function EFFECT:Airburst(Emitter, GroundHit, Origin, GroundOrigin, Radius, Direction, SmokeColor, GroundColor, Mult)
	self:Core(Origin, Radius)

	if not IsValid(Emitter) then return end

	for _ = 0, 3 do
		local Flame = Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin)

		if Flame then
			Flame:SetLifeTime(0)
			Flame:SetDieTime(0.17)
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
		Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
	end

	for I = 0, math.Clamp(Radius,1,10) * Mult do
		Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin - Direction * 4 * Radius)
		local Gravity = Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -math.random(10, 30))
		local Radmod = Radius * 0.25

		Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity((Direction + VectorRand() * 0.08) * math.random(20,300) * Radmod)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 0.2 * Radius))
			Smoke:SetStartAlpha(math.Rand(80, 200))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(40 * Radmod)
			Smoke:SetEndSize(140 * Radmod)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(math.random(1, I * 2) * Radius)
			Smoke:SetGravity(Gravity)
			Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
		end

		Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity((Direction + VectorRand() * 0.08) * -math.random(20,40) * Radmod)
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 0.2 * Radius))
			Smoke:SetStartAlpha(math.Rand(40, 80))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(80 * Radmod)
			Smoke:SetEndSize(100 * Radmod)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(math.random(1, I * 2) * Radius)
			Smoke:SetGravity(Gravity)
			Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
		end
	end

	local rv = math.Clamp(math.random(8,12) * Mult * Radius,1,150)
	local GroundAngle = Angle(-90,0,0)
	local Angle = Direction:Angle()
	GroundAngle:RotateAroundAxis(GroundAngle:Forward(), math.random(1,300))
	Angle:RotateAroundAxis(Angle:Forward(), math.random(1,300))
	local DietimeMod = math.Clamp(Radius, 1, 14)

	for _ = 0, rv do
		local rrv = 360 / rv
		Angle:RotateAroundAxis(Angle:Forward(), rrv)
		GroundAngle :RotateAroundAxis(GroundAngle:Forward(), rrv)

		local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin + Angle:Up() * math.Rand(5, 20) * Radius)

		if Smoke then
			local Gravity = Vector(math.random(-5, 5) * Radius, math.random(-5, 5) * Radius, -math.random(20, 40))

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
				Smoke:SetGravity(Gravity)
				Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
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
				Smoke:SetGravity(Gravity)
				Smoke:SetColor(SmokeColor.r, SmokeColor.g, SmokeColor.b)
			end
		end

		for _ = 0, 2 do
			if GroundHit then
				local Smoke = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), GroundOrigin + GroundAngle:Up() * math.Rand(5, 200) * Radius)

				if Smoke then
					Smoke:SetVelocity(GroundAngle:Up() * math.Rand(10, 50 * Radius))
					Smoke:SetLifeTime(0)
					Smoke:SetDieTime(math.Rand(0.2, 0.4) * DietimeMod)
					Smoke:SetStartAlpha(math.Rand(100, 150))
					Smoke:SetEndAlpha(0)
					Smoke:SetStartSize(15 * Radius)
					Smoke:SetEndSize(25 * Radius)
					Smoke:SetRoll(math.Rand(0, 360))
					Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
					Smoke:SetAirResistance(12 * Radius)
					Smoke:SetGravity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(10, 100)))
					Smoke:SetColor(GroundColor.r, GroundColor.g, GroundColor.b)
				end
			end
			local Spark = Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin + (Angle:Up() * math.random(1,10) * Radius))

			if Spark then
				Spark:SetVelocity((Angle:Up() + Direction * math.random(2,40)):GetNormalized() * math.random(5000,7000) * (Radius * 0.2))
				Spark:SetLifeTime(0)
				Spark:SetDieTime(0.3)
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

		local EF = Emitter:Add("effects/muzzleflash" .. math.random(1, 4), Origin)

		if EF then
			EF:SetVelocity((Angle:Up() + Direction * math.random(0.3,5)):GetNormalized() *  1)
			EF:SetAirResistance(100)
			EF:SetDieTime(0.17)
			EF:SetStartAlpha(240)
			EF:SetEndAlpha(20)
			EF:SetStartSize(6 * Radius)
			EF:SetEndSize(4 * Radius)
			EF:SetRoll(800)
			EF:SetRollDelta( math.random(-1, 1) )
			EF:SetColor(255, 255, 255)
			EF:SetStartLength(Radius)
			EF:SetEndLength(Radius * 100)
		end
	end

	Emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
