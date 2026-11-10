local TraceData  = { start = true, endpos = true }
local TraceLine  = util.TraceLine
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal   = ACF.GetPenetrationDecal
local GetScale   = ACF.GetDecalScale
local Sounds     = ACF.Utilities.Sounds
local Effects    = ACF.Utilities.Effects
local Colors     = Effects.MaterialColors
local White      = Color(255, 255, 255)

local MetalMaterials = {
	[MAT_GRATE] = true,
	[MAT_CLIP] = true,
	[MAT_METAL] = true,
	[MAT_COMPUTER] = true,
	[MAT_VENT] = true,
}

function EFFECT:Init(Data)
	local Caliber  = Data:GetRadius()
	local Origin   = Data:GetOrigin()
	local Normal   = Data:GetNormal()
	local Velocity = Data:GetScale() -- Velocity of the projectile in gmod units
	local Mass     = Data:GetMagnitude() -- Mass of the projectile in kg
	local Index    = Data:GetDamageType()
	local Scale    = math.max(Mass * (Velocity * ACF.InchToMeter) * 0.01, 1) ^ 0.3

	TraceData.start = Origin - Normal
	TraceData.endpos = Origin + Normal * Velocity

	local Trace       = TraceLine(TraceData)
	local HitNormal   = Trace.HitNormal
	local MatType     = Trace.MatType
	local DebrisColor = Colors[MatType] or Colors.Default

	local SoundData = Sounds.GetHitSoundPath(Data, Trace, "penetration")
	Sounds.PlaySound(Trace.HitPos, SoundData.SoundPath:format(math.random(0, 4)), 100, SoundData.SoundPitch, 1)

	local EffectTable = {
		Origin = Origin,
		Normal = Normal,
		Magnitude = Scale,
		Scale = Scale,
		Radius = Scale,
	}

	Effects.CreateEffect("Sparks", EffectTable)

	-- Nonspecific materials get concrete
	local Effect = CreateParticleSystemNoEntity(MetalMaterials[MatType] and "acf_penetration_metal" or "acf_penetration_concrete", Origin, angle_zero)

	if Effect then
		Effect:SetControlPoint(1, Vector(Scale, Scale, Scale))
		Effect:SetControlPoint(2, Vector(Scale, Scale, 1))
		Effect:SetControlPoint(3, Vector(DebrisColor.r, DebrisColor.g, DebrisColor.b))
		Effect:SetControlPoint(4, Normal * 225) -- Debris
		Effect:SetControlPoint(5, Normal * 55 * Scale) -- Embers
		Effect:SetControlPoint(6, Normal * 30 * Scale) -- Smoke
	end

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local Type = ValidDecal(Index) and Index or 1
		local Size = GetScale(Type, Caliber)

		util.DecalEx(GetDecal(Type), Trace.Entity, Trace.HitPos, HitNormal, White, Size, Size)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end