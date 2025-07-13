local TraceData    = { start = true, endpos = true }
local TraceLine    = util.TraceLine
local ValidDecal   = ACF.IsValidAmmoDecal
local GetDecal     = ACF.GetRicochetDecal
local GetScale     = ACF.GetDecalScale
local Effects      = ACF.Utilities.Effects
local Sounds       = ACF.Utilities.Sounds
local Sound        = "acf_base/fx/ricochet%s.mp3"
local Colors       = Effects.MaterialColors

function EFFECT:Init(Data)
	local Caliber = Data:GetRadius()
	local Origin = Data:GetOrigin()
	local DirVec = Data:GetNormal()
	local Velocity = Data:GetScale() -- Velocity of the projectile in gmod units
	local Mass = Data:GetMagnitude() -- Mass of the projectile in kg
	local Type = Data:GetDamageType()

	local Emitter = ParticleEmitter(Origin)

	TraceData.start = Origin
	TraceData.endpos = Origin - DirVec * Velocity

	local Trace = TraceLine(TraceData)
	local Radius = 3

	-- Ricochet sparks
	if IsValid(Emitter) then
		local DebrisColor = Colors[Trace.MatType] or Colors.Default

		for _ = 0, math.Rand(12, 24) do
			local Debris = Emitter:Add("effects/fleck_tile" .. math.random(1, 2), Origin)

			if Debris then
				Debris:SetVelocity((DirVec + VectorRand()) * 150 * Radius)
				Debris:SetLifeTime(0)
				Debris:SetDieTime(math.Rand(0.5, 1) * Radius)
				Debris:SetStartAlpha(255)
				Debris:SetEndAlpha(0)
				Debris:SetStartSize(math.Clamp(Radius, 1, 7))
				Debris:SetEndSize(math.Clamp(Radius, 1, 7))
				Debris:SetRoll(math.Rand(0, 360))
				Debris:SetRollDelta(math.Rand(-3, 3))
				Debris:SetAirResistance(30)
				Debris:SetGravity(Vector(0, 0, -1200))
				Debris:SetColor(DebrisColor.r, DebrisColor.g, DebrisColor.b)
			end
		end

		local EffectTable = {
			Radius = Caliber,
			Origin = Origin,
			Normal = DirVec,
			Scale = Velocity,
			Magnitude = Mass,
			DamageType = Type,
		}

		Effects.CreateEffect("ManhackSparks", EffectTable)
	end

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local DecalType = ValidDecal(Type) and Type or 1
		local Scale = GetScale(DecalType, Caliber)

		util.DecalEx(GetDecal(DecalType), Trace.Entity, Trace.HitPos, Trace.HitNormal, color_white, Scale, Scale)
	end

	local Level = math.Clamp(Mass * 200, 65, 500)
	local Pitch = math.Clamp(Velocity * 0.01, 25, 255)

	Sounds.PlaySound(Origin, Sound:format(math.random(1, 4)), Level, Pitch, 1)
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end