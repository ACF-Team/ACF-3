local TraceData  = { start = true, endpos = true }
local TraceLine  = util.TraceLine
local Effects    = ACF.Utilities.Effects
local Colors     = Effects.MaterialColors
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal   = ACF.GetRicochetDecal
local GetScale   = ACF.GetDecalScale
local Sounds     = ACF.Utilities.Sounds
local GetAngles  = Effects.GetSurfaceAngles
local White      = Vector(255, 255, 255)

local Surfaces = {
	[MAT_DIRT]        = "Dirt",
	[MAT_GRASS]       = "Dirt",
	[MAT_SAND]        = "Dirt",
	[MAT_SNOW]        = "Dirt",
	[MAT_SLOSH]       = "Dirt",
	[MAT_FOLIAGE]     = "Dirt",
	[MAT_METAL]       = "Metal",
	[MAT_GRATE]       = "Metal",
	[MAT_VENT]        = "Metal",
	[MAT_COMPUTER]    = "Metal",
	[MAT_CLIP]        = "Metal",
	[MAT_WOOD]        = "Wood",
	[MAT_GLASS]       = "Glass",
	[MAT_FLESH]       = "Flesh",
	[MAT_BLOODYFLESH] = "Flesh",
	[MAT_ALIENFLESH]  = "Flesh",
	[MAT_ANTLION]     = "Flesh",
}

-- Unlit sprites glow in the dark, so tint them by the light at the hit point
local function GetLitColor(Color, Pos, Normal)
	local Light = render.ComputeLighting(Pos + Normal * 4, Normal) + render.GetAmbientLightColor()

	return Vector(
		math.min(Color.r * math.Clamp(Light.x, 0.15, 1), 255),
		math.min(Color.g * math.Clamp(Light.y, 0.15, 1), 255),
		math.min(Color.b * math.Clamp(Light.z, 0.15, 1), 255)
	)
end

-- Local Z of every system is Dir
local function Create(Name, Pos, Dir, Size, Speed, Life, Count, Tint)
	local Effect = CreateParticleSystemNoEntity(Name, Pos, GetAngles(Dir))

	if not Effect then return end

	Effect:SetControlPoint(1, Vector(Size, Speed, Speed))
	Effect:SetControlPoint(2, Vector(Life, Count, 1))

	if Tint then
		Effect:SetControlPoint(3, Tint)
	end

	return Effect
end

local function AddDust(Pos, Normal, Scale, Tint, Count, Height, Life)
	Create("acf_impact_dust", Pos, Normal, Scale, Height, Life, math.floor(Count) / 3, Tint)
end

-- How many materials each surface's debris is split into
local Flecks = { Dirt = 4, Concrete = 4, Metal = 2, Wood = 2, Glass = 3 }

local function AddDebris(Pos, Normal, Scale, Tint, Count, Speed, Surface)
	Create("acf_impact_debris_" .. Surface:lower(), Pos, Normal, Scale ^ 0.8, Speed, 1, math.floor(Count) / Flecks[Surface], Tint)
end

local function AddSparks(Pos, Normal, Direction, Scale, Count)
	local Reflect = Direction - 2 * Direction:Dot(Normal) * Normal
	local Size    = Scale ^ 0.5

	Create("acf_impact_sparks", Pos, Reflect + Normal, Size, Size, 1, math.floor(Count))
end

local function AddFlash(Pos, Scale)
	local Effect = CreateParticleSystemNoEntity("acf_impact_flash", Pos, angle_zero)

	if not Effect then return end

	Effect:SetControlPoint(1, Vector(Scale, Scale, Scale))
	Effect:SetControlPoint(2, Vector((0.25 + Scale * 0.03) / 0.25, 1, 1)) -- Dimmer glow that hangs around a little after the flash
end

local Impacts = {}

function Impacts.Dirt(Pos, Normal, _, Scale, Tint)
	AddDust(Pos, Normal, Scale, Tint, math.min(4 + Scale * 2, 20), 40 + Scale * 45, 1.5 + Scale * 0.3)
	AddDebris(Pos, Normal, Scale, Tint * 0.6, math.min(8 + Scale * 5, 48), 180 + Scale * 50, "Dirt")

	-- Ground skirt, dust rolling out along the surface on bigger hits
	if Scale < 2 then return end

	local Effect = Create("acf_impact_skirt", Pos, Normal, Scale, Scale ^ 0.6, (2.5 + Scale * 0.3) / 2.5, math.floor(math.min(Scale * 3, 16)) / 3, Tint)

	if Effect then
		Effect:SetControlPoint(4, Normal * 0.15 * 110 * Scale ^ 0.6)
	end
end

-- Flashes go in last so they draw over the dust, and sit off the surface so it doesn't clip them
function Impacts.Concrete(Pos, Normal, _, Scale, Tint)
	AddDust(Pos, Normal, Scale, Tint, math.min(3 + Scale * 2, 16), 30 + Scale * 40, 1 + Scale * 0.3)
	AddDebris(Pos, Normal, Scale, Tint * 0.8, math.min(6 + Scale * 3, 30), 200 + Scale * 30, "Concrete")

	if Scale > 1.5 then
		AddFlash(Pos + Normal * 2 * Scale, Scale * 0.5)
	end
end

function Impacts.Metal(Pos, Normal, Direction, Scale, Tint)
	AddDust(Pos, Normal, Scale * 0.6, Tint * 0.6, math.min(2 + Scale, 10), 20 + Scale * 20, 1 + Scale * 0.2)
	AddDebris(Pos, Normal, Scale * 0.25, Tint * 0.4, math.min(3 + Scale, 10), 200 + Scale * 30, "Metal")
	AddSparks(Pos, Normal, Direction, Scale, math.min(8 + Scale * 6, 50))
	AddFlash(Pos + Normal * 3 * Scale, Scale)
end

function Impacts.Wood(Pos, Normal, _, Scale, Tint)
	AddDust(Pos, Normal, Scale * 0.8, Tint, math.min(2 + Scale, 10), 20 + Scale * 30, 1 + Scale * 0.2)
	AddDebris(Pos, Normal, Scale, White, math.min(6 + Scale * 4, 36), 180 + Scale * 30, "Wood")
end

function Impacts.Glass(Pos, Normal, _, Scale, Tint)
	AddDust(Pos, Normal, Scale * 0.5, Tint, math.min(1 + Scale, 6), 20 + Scale * 20, 0.8)
	AddDebris(Pos, Normal, Scale, White, math.min(8 + Scale * 4, 36), 200 + Scale * 30, "Glass")
end

function Impacts.Flesh(Pos, Normal, _, Scale)
	Effects.CreateEffect("BloodImpact", { Origin = Pos, Normal = Normal, Scale = Scale })
end

function Impacts.Water(Pos, _, _, Scale)
	Effects.CreateEffect("watersplash", { Origin = Pos, Normal = Vector(0, 0, 1), Scale = 4 + Scale * 3 })
end

function EFFECT:Init(Data)
	local Caliber = Data:GetRadius() or 0

	if Caliber <= 0 then return end

	local Origin   = Data:GetOrigin()
	local DirVec   = Data:GetNormal()
	local Type     = Data:GetDamageType()
	local Velocity = Data:GetScale() -- Velocity of the projectile in gmod units

	TraceData.start = Origin - DirVec
	TraceData.endpos = Origin + DirVec * Velocity

	local Trace   = TraceLine(TraceData)
	local Pos     = Trace.Hit and Trace.HitPos or Origin
	local Normal  = Trace.Hit and Trace.HitNormal or -DirVec
	local MatType = Trace.MatType
	local Scale   = math.max(Caliber, 0.5) ^ 0.75 -- 7.62mm ~0.8, 20mm ~1.7, 75mm ~4.5, 120mm ~6.4
	local Surface = Surfaces[MatType]

	if bit.band(util.PointContents(Pos), CONTENTS_WATER) == CONTENTS_WATER then
		Surface = "Water"
	elseif not Surface then
		-- Anything we don't know about is concrete in the world and metal on props
		Surface = Trace.HitWorld and "Concrete" or "Metal"
	end

	Impacts[Surface](Pos + Normal, Normal, DirVec, Scale, GetLitColor(Colors[MatType] or Colors.Default, Pos, Normal))

	if IsValid(Trace.Entity) or Trace.HitWorld then
		local DecalType = ValidDecal(Type) and Type or 1
		local DecalSize = GetScale(DecalType, Caliber)

		util.DecalEx(GetDecal(DecalType), Trace.Entity, Trace.HitPos, Trace.HitNormal, color_white, DecalSize, DecalSize)
	end

	local SoundData = Sounds.GetHitSoundPath(Data, Trace, "impact")
	Sounds.PlaySound(Trace.HitPos, SoundData.SoundPath:format(math.random(0, 4)), 100, SoundData.SoundPitch, 1)
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
