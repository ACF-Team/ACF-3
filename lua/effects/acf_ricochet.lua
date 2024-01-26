local TraceData  = { start = true, endpos = true }
local TraceLine  = util.TraceLine
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal   = ACF.GetRicochetDecal
local GetScale   = ACF.GetDecalScale
local Sounds     = ACF.Utilities.Sounds
local Sound      = "acf_base/fx/ricochet%s.mp3"

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

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local DecalType = ValidDecal(Type) and Type or 1
		local Scale = GetScale(DecalType, Caliber)

		util.DecalEx(GetDecal(DecalType), Trace.Entity, Trace.HitPos, Trace.HitNormal, Color(255, 255, 255), Scale, Scale)
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