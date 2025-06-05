local TraceData  = { start = true, endpos = true }
local TraceLine  = util.TraceLine
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal   = ACF.GetRicochetDecal
local GetScale   = ACF.GetDecalScale
local Sounds     = ACF.Utilities.Sounds
local Sound      = "^acf_base/fx/metal/ricochet/large/4.wav"

function EFFECT:Init(Data)
	local Caliber = Data:GetRadius()
	local Origin = Data:GetOrigin()
	local DirVec = Data:GetNormal()
	local Velocity = Data:GetScale() --Velocity of the projectile in gmod units
	local Mass = Data:GetMagnitude() --Mass of the projectile in kg
	local Type = Data:GetDamageType()

	TraceData.start = Origin
	TraceData.endpos = Origin - DirVec * Velocity

	local Trace = TraceLine(TraceData)
	local MatType   = Trace.MatType
	
	if IsValid(Trace.Entity) or Trace.HitWorld then
		local DecalType = ValidDecal(Type) and Type or 1
		local Scale = GetScale(DecalType, Caliber)

		util.DecalEx(GetDecal(DecalType), Trace.Entity, Trace.HitPos, Trace.HitNormal, Color(255, 255, 255), Scale, Scale)
	end

	local SoundData = Sounds.HitSound(Data, Trace, "ricochet")

	Sounds.PlaySound(Trace.HitPos, SoundData.SoundPath:format(math.random(0,4)), 100, SoundData.SoundPitch, 1)
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end