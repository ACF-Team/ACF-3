local TraceData  = { start = true, endpos = true }
local TraceLine  = util.TraceLine
local Effects    = ACF.Utilities.Effects
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal   = ACF.GetRicochetDecal
local GetScale   = ACF.GetDecalScale

function EFFECT:Init(Data)
	local Caliber = Data:GetRadius() or 0

	if Caliber <= 0 then return end

	local Origin   = Data:GetOrigin()
	local DirVec   = Data:GetNormal()
	local Type     = Data:GetDamageType()
	local Velocity = Data:GetScale() -- Velocity of the projectile in gmod units
	local Mass     = Data:GetMagnitude() -- Mass of the projectile in kg

	TraceData.start = Origin - DirVec
	TraceData.endpos = Origin + DirVec * Velocity

	local Trace = TraceLine(TraceData)
	local Normal = (DirVec + Trace.HitNormal):GetNormalized()

	local EffectTable = {
		Start = Origin,
		Normal = Normal,
		Magnitude = Mass,
		DamageType = Type,
		Radius = Caliber,
		Scale = Velocity,
	}

	Effects.CreateEffect("ManhackSparks", EffectTable)

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local DecalType = ValidDecal(Type) and Type or 1
		local Scale = GetScale(DecalType, Caliber)

		util.DecalEx(GetDecal(DecalType), Trace.Entity, Trace.HitPos, Trace.HitNormal, color_white, Scale, Scale)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end