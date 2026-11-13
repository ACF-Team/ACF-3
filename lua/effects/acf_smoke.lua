local TraceData = { start = true, endpos = true, mask = true }
local TraceLine = util.TraceLine
local Effects   = ACF.Utilities.Effects
local GetIndex  = ACF.GetAmmoDecalIndex
local GetDecal  = ACF.GetRicochetDecal
local White     = Color(255, 255, 255)

function EFFECT:Init(Data)
	local Origin     = Data:GetOrigin()
	local Normal     = Data:GetNormal()
	local Caliber    = Data:GetRadius()
	local Filler     = math.min(math.log(1 + Data:GetScale()) * 43.42, 350)
	local WPFiller   = math.min(math.log(1 + Data:GetMagnitude()) * 43.42, 350)

	TraceData.start  = Origin
	TraceData.endpos = Origin + Normal * 100
	TraceData.mask   = MASK_SOLID

	local Impact = TraceLine(TraceData)

	if IsValid(Impact.Entity) or Impact.HitWorld then
		local Size = (Filler + WPFiller) * 0.03

		if Size > 0 then
			local Type = GetIndex("ACF.Ammunition.SM")

			util.DecalEx(GetDecal(Type), Impact.Entity, Impact.HitPos, Impact.HitNormal, White, Size, Size)
		end

		local EffectTable = {
			Origin = Origin,
			Normal = Normal,
			Radius = Caliber,
		}

		Effects.CreateEffect("acf_impact", EffectTable)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end