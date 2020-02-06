local TraceData = { start = true, endpos = true }
local TraceLine = util.TraceLine
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal = ACF.GetRicochetDecal
local GetScale = ACF.GetDecalScale

function EFFECT:Init(Data)
	local Caliber = Data:GetRadius() or 0

	if Caliber <= 0 then return end

	local Origin = Data:GetOrigin()
	local DirVec = Data:GetNormal()
	local Type = Data:GetDamageType()

	TraceData.start = Origin - DirVec
	TraceData.endpos = Origin + DirVec * 100

	local Trace = TraceLine(TraceData)

	-- Placeholder
	local Effect = EffectData()
	Effect:SetStart(Origin)
	Effect:SetNormal(Trace.HitNormal)
	Effect:SetMagnitude(0)

	util.Effect("ElectricSpark", Effect)

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local DecalType = ValidDecal(Type) and Type or 1
		local Scale = GetScale(DecalType, Caliber)

		util.DecalEx(GetDecal(DecalType), Trace.Entity, Trace.HitPos, Trace.HitNormal, Color(255, 255, 255), Scale, Scale)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end