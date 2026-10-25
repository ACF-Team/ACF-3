local TraceData   = { start = true, endpos = true, mask = MASK_SOLID }
local TraceLine   = util.TraceLine
local GetIndex    = ACF.GetAmmoDecalIndex
local GetDecal    = ACF.GetRicochetDecal
local Effects     = ACF.Utilities.Effects
local Sounds      = ACF.Utilities.Sounds
local Debug       = ACF.Debug
local Colors      = Effects.MaterialColors
local DustAmount  = Effects.DustAmount
local GetLitColor = Effects.GetLitColor
local White       = Color(255, 255, 255)
local Yellow      = Color(255, 255, 0)
local SmokeTint   = Color(62, 58, 54)
local Up          = Vector(0, 0, 1)
local LightIndex  = 0

-- Above this height (in sizes) the blast no longer throws up dust, it only sprays the ground with fragments
local DustHeight = 150
-- Fragments stop raising any dust past this height (in sizes)
local FragHeight = 1200

local function SetControlPoints(Effect, Size, Life, Count, Alpha, DustTint, SmokeColor)
	Effect:SetControlPoint(1, Vector(Size, Size, Size))
	Effect:SetControlPoint(2, Vector(Life, Count, Alpha))
	Effect:SetControlPoint(3, DustTint)
	Effect:SetControlPoint(4, SmokeColor)
end

-- The material colours are for debris, airborne dust is a lot paler
local function GetDustTint(Trace, Pos)
	local Base = Colors[Trace.MatType] or Colors.Default

	return GetLitColor(Color(math.min(Base.r * 1.5 + 40, 255), math.min(Base.g * 1.5 + 40, 255), math.min(Base.b * 1.5 + 40, 255)), Pos)
end

-- Any direction along the surface, used to orient the effect so its up is the surface normal
local function GetSurfaceAngles(Normal)
	local Side = math.abs(Normal.z) < 0.9 and Up or Vector(1, 0, 0)

	return Side:Cross(Normal):GetNormalized():AngleEx(Normal)
end

function EFFECT:Init(Data)
	self.Start = CurTime()
	self.ShockwaveLife = 0.1

	local Origin = Data:GetOrigin()
	local Normal = Data:GetNormal():GetNormalized() -- Gross
	local Scale  = Data:GetScale()
	local Radius = math.max(Scale * 0.02, 1)
	local Size   = math.Clamp(Scale / 315, 0.1, 6) -- Blast radius of a kilogram of filler is about 315 inches
	local Mult   = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)
	-- Autocannons fire these several times a second, so the small ones are kept short and sparse
	local Life   = math.Clamp(Size ^ 0.35, 0.5, 1.15)
	local Count  = math.Clamp(Size ^ 0.9, 0.12, 1.5) * Mult

	self.Radius = Radius

	if Debug.SetDeveloperLevel(1) then
		Debug.Cross(Origin, 15, 15, Yellow, true)
	end

	self:Core(Origin, Radius)

	if Count <= 0 then return end

	-- The surface the round hit, if any
	TraceData.start  = Origin - Normal * 5
	TraceData.endpos = Origin + Normal * math.max(Radius, 12)

	local Impact = TraceLine(TraceData)
	local Ground, Height

	if Impact.Hit and not Impact.HitSky then
		Ground, Height = Impact, 0

		local Entity = Impact.Entity

		if Radius > 1 and (IsValid(Entity) or Impact.HitWorld) then
			local DecalSize = Radius * 0.66
			local Type      = GetIndex("ACF.Ammunition.HE")

			if Type then
				util.DecalEx(GetDecal(Type), Entity, Impact.HitPos, Impact.HitNormal, White, DecalSize, DecalSize)
			end
		end
	else
		-- Burst in the air, look for the ground under it
		TraceData.start  = Origin
		TraceData.endpos = Origin - Up * Size * FragHeight

		local Below = TraceLine(TraceData)

		if Below.Hit and not Below.HitSky and not Below.StartSolid then
			Ground, Height = Below, Below.Fraction * Size * FragHeight
		end
	end

	-- The closer to the ground, the more dirt it throws up and the more of the fireball that dirt hides
	local Dust = Ground and math.Clamp(1 - Height / (Size * DustHeight), 0, 1) * (DustAmount[Ground.MatType] or 0.2) or 0
	local Fire = 1 - Dust * 0.85
	local SmokeColor = GetLitColor(SmokeTint, Origin + Up * 32)

	if Dust > 0.25 then
		local Pos    = Ground.HitPos + Ground.HitNormal * 2
		local Effect = CreateParticleSystemNoEntity("acf_he_ground", Pos, GetSurfaceAngles(Ground.HitNormal))

		if Effect then
			SetControlPoints(Effect, Size, Life, Count * math.Clamp(Dust, 0.5, 1), math.Clamp(Dust * 1.3, 0.4, 1),
				GetDustTint(Ground, Pos + Ground.HitNormal * 32), SmokeColor)
		end
	end

	if Fire > 0.25 then
		-- Bursts on a surface are pushed off it so the fireball isn't half buried in it
		local Pos    = Height == 0 and Ground.HitPos + Ground.HitNormal * 90 * Size or Origin
		local Effect = CreateParticleSystemNoEntity("acf_he_air", Pos, angle_zero)

		if Effect then
			SetControlPoints(Effect, Size, Life, Count * Fire, 1, vector_origin, SmokeColor)
		end

		local Light = Size >= 0.3 and DynamicLight(0x7000 + LightIndex)

		if Light then
			local Duration = 0.12 * Life
			local Reach    = 600 * Size * Fire

			LightIndex = (LightIndex + 1) % 64

			Light.pos        = Pos
			Light.r          = 255
			Light.g          = 170
			Light.b          = 90
			Light.brightness = 2 + Size * Fire
			Light.Size       = Reach
			Light.Decay      = Reach / Duration
			Light.DieTime    = CurTime() + Duration
		end
	end

	-- Airbursts spray the ground under them with fragments, each one kicking up a little dust
	if Ground and Height > Size * 40 then
		local Spread   = math.Clamp(Height * 0.9, 80, 1600)
		local Falloff  = math.Clamp(1.4 - Height / (Size * FragHeight), 0.3, 1)
		local Amount   = DustAmount[Ground.MatType] or 0.2
		local PuffSize = math.Clamp(Size ^ 0.5, 0.4, 2)
		local Pos      = Ground.HitPos + Up * 200 -- Each puff traces down from here onto the terrain
		local Effect   = CreateParticleSystemNoEntity("acf_he_frag_ground", Pos, angle_zero)

		if Effect then
			SetControlPoints(Effect, PuffSize, Life, Count * Falloff, math.Clamp(Amount * 1.3, 0.3, 1),
				GetDustTint(Ground, Ground.HitPos + Up * 32), SmokeColor)
			Effect:SetControlPoint(1, Vector(Spread * 0.01, PuffSize, PuffSize)) -- How far the puffs spread, how fast they rise
			Effect:SetControlPoint(5, Vector(PuffSize, PuffSize, PuffSize))
		end
	end
end

function EFFECT:Core(Origin, Radius)
	local SoundData = Sounds.GetExplosionSoundPath(Radius)

	Sounds.PlaySound(Origin, SoundData.SoundPath:format(math.random(0, 4)), SoundData.SoundVolume, SoundData.SoundPitch, 1)
end

function EFFECT:Think()
	return (CurTime() - self.Start) < self.ShockwaveLife
end

local WorkingColor = Color(255, 255, 255, 255)
local ShockwaveMaterial = CreateMaterial("ACF_RefractTest4", "Aftershock", {
	["$normalmap"] = "models/props_combine/portalball001_sheet"
})
function EFFECT:Render()
	local Radius = self.Radius
	local Ratio  = math.ease.OutQuad((CurTime() - self.Start) / self.ShockwaveLife)
	render.SetMaterial(ShockwaveMaterial)
	ShockwaveMaterial:SetFloat("$bluramount", Ratio * 0.03)
	ShockwaveMaterial:SetFloat("$refractamount", 0.05 * (1 - Ratio))
	ShockwaveMaterial:SetFloat("$time", 4) -- this might not do anything after all
	ShockwaveMaterial:SetFloat("$silhouettethickness", Ratio * 1.2)
	WorkingColor.a = 255 - (Ratio * 255)
	render.DrawSphere(self:GetPos(), 50 + (Radius * Ratio * 120), 32, 16, WorkingColor)
end
