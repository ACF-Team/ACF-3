local TraceData = { start = true, endpos = true }
local TraceLine = util.TraceLine
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal = ACF.GetRicochetDecal
local GetScale = ACF.GetDecalScale

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

	--Sound
	if Caliber >= 10 then
		sound.Play("/acf_other/ricochets/large/0" .. math.random(0, 6) .. ".mp3", Origin, math.Clamp(Mass * 200, 65, 500), math.Clamp(Velocity * 0.01, 25, 100), 0.45) -- 100mm and up
	else
		sound.Play("/acf_other/ricochets/medium/0" .. math.random(0, 9) .. ".mp3", Origin, math.Clamp(Mass * 200, 65, 500), math.Clamp(Velocity * 0.01, 25, 100), 0.4) --99mm and down
	end

end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
