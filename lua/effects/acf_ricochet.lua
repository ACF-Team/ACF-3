local TraceData    = { start = true, endpos = true }
local TraceLine    = util.TraceLine
local ValidDecal   = ACF.IsValidAmmoDecal
local GetDecal     = ACF.GetRicochetDecal
local GetScale     = ACF.GetDecalScale
local Effects      = ACF.Utilities.Effects
local Sounds       = ACF.Utilities.Sounds
local Colors       = Effects.MaterialColors

function EFFECT:Init(Data)
	local Caliber = Data:GetRadius()
	local Origin = Data:GetOrigin()
	local DirVec = Data:GetNormal()
	local Velocity = Data:GetScale() -- Velocity of the projectile in gmod units
	local Mass = Data:GetMagnitude() -- Mass of the projectile in kg
	local Type = Data:GetDamageType()

	TraceData.start = Origin
	TraceData.endpos = Origin - DirVec * Velocity

	local Trace = TraceLine(TraceData)

	-- Ricochet sparks
	local Effect = CreateParticleSystemNoEntity("acf_ricochet", Origin, angle_zero)

	if Effect then
		local DebrisColor = Colors[Trace.MatType] or Colors.Default

		Effect:SetControlPoint(3, Vector(DebrisColor.r, DebrisColor.g, DebrisColor.b))
		Effect:SetControlPoint(4, DirVec * 450)

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

	local SoundData = Sounds.GetHitSoundPath(Data, Trace, "ricochet")

	Sounds.PlaySound(Trace.HitPos, SoundData.SoundPath:format(math.random(0, 4)), 100, SoundData.SoundPitch, 1)
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end