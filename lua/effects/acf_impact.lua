local TraceData  = { start = true, endpos = true }
local TraceLine  = util.TraceLine
local Effects    = ACF.Utilities.Effects
local Colors     = Effects.MaterialColors
local ValidDecal = ACF.IsValidAmmoDecal
local GetDecal   = ACF.GetRicochetDecal
local GetScale   = ACF.GetDecalScale
local Sounds     = ACF.Utilities.Sounds
local Gravity    = Vector(0, 0, -600)

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

-- Random direction within a cone around Dir, Amount of 1 is roughly a hemisphere
-- If Normal is given, directions going into the surface get mirrored back out of it
local function Spread(Dir, Amount, Normal)
	local Result = (Dir + VectorRand() * Amount):GetNormalized()

	if Normal then
		local Dot = Result:Dot(Normal)

		if Dot < 0 then
			Result = Result - 2 * Dot * Normal
		end
	end

	return Result
end

-- Unlit sprites glow in the dark, so tint them by the light at the hit point
local function GetLitColor(Color, Pos, Normal)
	local Light = render.ComputeLighting(Pos + Normal * 4, Normal) + render.GetAmbientLightColor()

	return math.min(Color.r * math.Clamp(Light.x, 0.15, 1), 255),
		math.min(Color.g * math.Clamp(Light.y, 0.15, 1), 255),
		math.min(Color.b * math.Clamp(Light.z, 0.15, 1), 255)
end

local function AddDust(Emitter, Pos, Normal, Scale, R, G, B, Count, Height, Life)
	for _ = 1, Count do
		local Dust = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Pos)

		if Dust then
			Dust:SetVelocity(Spread(Normal, 0.5, Normal) * math.Rand(0.3, 1) * Height)
			Dust:SetDieTime(math.Rand(0.6, 1) * Life)
			Dust:SetStartAlpha(math.Rand(180, 230))
			Dust:SetEndAlpha(0)
			Dust:SetStartSize(4 * Scale)
			Dust:SetEndSize(math.Rand(10, 16) * Scale)
			Dust:SetRoll(math.Rand(0, 360))
			Dust:SetRollDelta(math.Rand(-0.5, 0.5))
			Dust:SetAirResistance(100)
			Dust:SetGravity(Vector(0, 0, -40))
			Dust:SetColor(R, G, B)
		end
	end
end

local function AddDebris(Emitter, Pos, Normal, Scale, R, G, B, Count, Speed, Materials)
	local Size = Scale ^ 0.8

	for _ = 1, Count do
		local Debris = Emitter:Add(Materials[math.random(#Materials)], Pos)

		if Debris then
			Debris:SetVelocity(Spread(Normal, 0.7, Normal) * math.Rand(0.4, 1) * Speed)
			Debris:SetDieTime(math.Rand(1, 2.5))
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(math.Rand(0.5, 1.5) * Size)
			Debris:SetEndSize(0.5 * Size)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-6, 6))
			Debris:SetAirResistance(30)
			Debris:SetGravity(Gravity)
			Debris:SetCollide(true)
			Debris:SetBounce(0.25)
			Debris:SetColor(R, G, B)
		end
	end
end

local function AddSparks(Emitter, Pos, Normal, Direction, Scale, Count)
	local Reflect = Direction - 2 * Direction:Dot(Normal) * Normal
	local Aim     = (Reflect + Normal):GetNormalized()
	local Size    = Scale ^ 0.5

	for _ = 1, Count do
		local Spark = Emitter:Add("effects/spark", Pos)

		if Spark then
			Spark:SetVelocity(Spread(Aim, 0.8, Normal) * math.Rand(150, 450) * Size)
			Spark:SetDieTime(math.Rand(0.2, 0.6))
			Spark:SetStartAlpha(255)
			Spark:SetEndAlpha(0)
			Spark:SetStartSize(math.Rand(1, 2) * Size)
			Spark:SetEndSize(0)
			Spark:SetStartLength(math.Rand(8, 16) * Size)
			Spark:SetEndLength(0)
			Spark:SetAirResistance(40)
			Spark:SetGravity(Gravity)
			Spark:SetCollide(true)
			Spark:SetBounce(0.4)
			Spark:SetColor(255, math.random(180, 230), 140)
		end
	end
end

local function AddFlash(Emitter, Pos, Scale)
	local Flash = Emitter:Add("sprites/light_glow02_add", Pos)

	if Flash then
		Flash:SetDieTime(0.1)
		Flash:SetStartAlpha(255)
		Flash:SetEndAlpha(0)
		Flash:SetStartSize(8 * Scale)
		Flash:SetEndSize(2 * Scale)
		Flash:SetRoll(math.Rand(0, 360))
		Flash:SetColor(255, 200, 140)
	end

	-- Dimmer glow that hangs around a little after the flash
	local Glow = Emitter:Add("sprites/light_glow02_add", Pos)

	if Glow then
		Glow:SetDieTime(0.25 + Scale * 0.03)
		Glow:SetStartAlpha(160)
		Glow:SetEndAlpha(0)
		Glow:SetStartSize(4 * Scale)
		Glow:SetEndSize(1 * Scale)
		Glow:SetColor(255, 120, 40)
	end
end

local Flecks = {
	Dirt     = { "particle/particle_debris_01", "particle/particle_debris_02", "effects/fleck_cement1", "effects/fleck_cement2" },
	Concrete = { "effects/fleck_cement1", "effects/fleck_cement2", "effects/fleck_tile1", "effects/fleck_tile2" },
	Metal    = { "effects/fleck_tile1", "effects/fleck_tile2" },
	Wood     = { "effects/fleck_wood1", "effects/fleck_wood2" },
	Glass    = { "effects/fleck_glass1", "effects/fleck_glass2", "effects/fleck_glass3" },
}

local Impacts = {}

function Impacts.Dirt(Emitter, Pos, Normal, _, Scale, R, G, B)
	AddDust(Emitter, Pos, Normal, Scale, R, G, B, math.min(4 + Scale * 2, 20), 40 + Scale * 45, 1.5 + Scale * 0.3)
	AddDebris(Emitter, Pos, Normal, Scale, R * 0.6, G * 0.6, B * 0.6, math.min(8 + Scale * 5, 48), 180 + Scale * 50, Flecks.Dirt)

	-- Ground skirt, dust rolling out along the surface on bigger hits
	if Scale < 2 then return end

	local Angles = Normal:Angle()
	local Right  = Angles:Right()
	local Up     = Angles:Up()

	for I = 1, math.min(Scale * 3, 16) do
		local Rad  = I / math.min(Scale * 3, 16) * math.pi * 2
		local Dir  = Right * math.cos(Rad) + Up * math.sin(Rad)
		local Dust = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Pos)

		if Dust then
			Dust:SetVelocity((Dir + Normal * 0.15) * math.Rand(80, 140) * Scale ^ 0.6)
			Dust:SetDieTime(math.Rand(2, 3) + Scale * 0.3)
			Dust:SetStartAlpha(math.Rand(100, 150))
			Dust:SetEndAlpha(0)
			Dust:SetStartSize(3 * Scale)
			Dust:SetEndSize(9 * Scale)
			Dust:SetRoll(math.Rand(0, 360))
			Dust:SetRollDelta(math.Rand(-0.3, 0.3))
			Dust:SetAirResistance(120)
			Dust:SetColor(R, G, B)
		end
	end
end

-- Flashes go in last so they draw over the dust, and sit off the surface so it doesn't clip them
function Impacts.Concrete(Emitter, Pos, Normal, _, Scale, R, G, B)
	AddDust(Emitter, Pos, Normal, Scale, R, G, B, math.min(3 + Scale * 2, 16), 30 + Scale * 40, 1 + Scale * 0.3)
	AddDebris(Emitter, Pos, Normal, Scale, R * 0.8, G * 0.8, B * 0.8, math.min(6 + Scale * 3, 30), 200 + Scale * 30, Flecks.Concrete)

	if Scale > 1.5 then
		AddFlash(Emitter, Pos + Normal * 2 * Scale, Scale * 0.5)
	end
end

function Impacts.Metal(Emitter, Pos, Normal, Direction, Scale, R, G, B)
	AddDust(Emitter, Pos, Normal, Scale * 0.6, R * 0.6, G * 0.6, B * 0.6, math.min(2 + Scale, 10), 20 + Scale * 20, 1 + Scale * 0.2)
	AddDebris(Emitter, Pos, Normal, Scale * 0.25, R * 0.4, G * 0.4, B * 0.4, math.min(3 + Scale, 10), 200 + Scale * 30, Flecks.Metal)
	AddSparks(Emitter, Pos, Normal, Direction, Scale, math.min(8 + Scale * 6, 50))
	AddFlash(Emitter, Pos + Normal * 3 * Scale, Scale)
end

function Impacts.Wood(Emitter, Pos, Normal, _, Scale, R, G, B)
	AddDust(Emitter, Pos, Normal, Scale * 0.8, R, G, B, math.min(2 + Scale, 10), 20 + Scale * 30, 1 + Scale * 0.2)
	AddDebris(Emitter, Pos, Normal, Scale, 255, 255, 255, math.min(6 + Scale * 4, 36), 180 + Scale * 30, Flecks.Wood)
end

function Impacts.Glass(Emitter, Pos, Normal, _, Scale, R, G, B)
	AddDust(Emitter, Pos, Normal, Scale * 0.5, R, G, B, math.min(1 + Scale, 6), 20 + Scale * 20, 0.8)
	AddDebris(Emitter, Pos, Normal, Scale, 255, 255, 255, math.min(8 + Scale * 4, 36), 200 + Scale * 30, Flecks.Glass)
end

function Impacts.Flesh(_, Pos, Normal, _, Scale)
	Effects.CreateEffect("BloodImpact", { Origin = Pos, Normal = Normal, Scale = Scale })
end

function Impacts.Water(_, Pos, _, _, Scale)
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

	local Emitter = ParticleEmitter(Pos)

	if IsValid(Emitter) then
		local R, G, B = GetLitColor(Colors[MatType] or Colors.Default, Pos, Normal)

		Impacts[Surface](Emitter, Pos + Normal, Normal, DirVec, Scale, R, G, B)

		Emitter:Finish()
	end

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
