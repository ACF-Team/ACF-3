local Classes     = ACF.Classes
local Sounds      = ACF.Utilities.Sounds
local Effects     = ACF.Utilities.Effects
local Colors      = Effects.MaterialColors
local DustAmount  = Effects.DustAmount
local GetLitColor = Effects.GetLitColor
local TraceLine   = util.TraceLine
local TraceData   = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY + MASK_WATER }
local SmokeTint   = Color(238, 237, 234)
local WaterTint   = Color(220, 225, 228)
local Up          = Vector(0, 0, 1)

-- Parented entities report no velocity on the client, the root of the parent chain does
local function GetVelocity(Entity)
	local Root = Entity

	while IsValid(Root:GetParent()) do
		Root = Root:GetParent()
	end

	return Root:GetVelocity()
end

local function SetControlPoints(Effect, Size, Life, Count, Alpha, Tint, Velocity)
	Effect:SetControlPoint(1, Vector(Size, Size, Size))
	Effect:SetControlPoint(2, Vector(Life, Count, Alpha))
	Effect:SetControlPoint(3, Tint)
	Effect:SetControlPoint(4, Velocity)
end

-- Kicks up dust or spray where the blast meets the ground
local function GroundEffect(Gun, Pos, Forward, Size, Life, Count)
	local Reach = 140 * Size

	-- Down the bore first, for guns firing into a slope or the ground ahead, then under the muzzle
	TraceData.start  = Pos
	TraceData.endpos = Pos + Forward * Reach * 0.6

	local Trace = TraceLine(TraceData)

	if not Trace.Hit then
		TraceData.endpos = Pos + (Forward * 0.35 - Up):GetNormalized() * Reach

		Trace = TraceLine(TraceData)
	end

	if not Trace.Hit or Trace.HitSky or Trace.StartSolid then return end

	local Normal = Trace.HitNormal
	local IsWater = bit.band(util.PointContents(Trace.HitPos - Normal), MASK_WATER) ~= 0
	local Amount = IsWater and 1 or DustAmount[Trace.MatType] or 0.2
	local Strength = math.min((1 - Trace.Fraction) * 1.6, 1) * Amount

	if Strength < 0.05 then return end

	-- Rapid fire guns would stack dust every shot, one cloud at a time is plenty
	local Now = CurTime()

	if (Gun.ACF_NextMuzzleDust or 0) > Now then return end

	Gun.ACF_NextMuzzleDust = Now + math.Clamp(Size, 0.1, 0.5)

	local Downrange = Forward - Normal * Forward:Dot(Normal)

	if Downrange:LengthSqr() < 0.01 then
		Downrange = Normal:Angle():Up()
	end

	local Name   = IsWater and "acf_muzzle_water" or "acf_muzzle_dust"
	local Angles = Downrange:GetNormalized():AngleEx(Normal)
	local Effect = CreateParticleSystemNoEntity(Name, Trace.HitPos + Normal, Angles)

	if not Effect then return end

	-- The material colours are for debris, airborne dust is a lot paler
	local Base = Colors[Trace.MatType] or Colors.Default
	local Tint = IsWater and WaterTint or Color(math.min(Base.r * 1.5 + 40, 255), math.min(Base.g * 1.5 + 40, 255), math.min(Base.b * 1.5 + 40, 255))

	SetControlPoints(Effect, Size, Life, Count * math.Clamp(Strength, 0.5, 1), math.Clamp(Strength * 1.5, 0.3, 1),
		GetLitColor(Tint, Trace.HitPos + Normal * 32), vector_origin)
end

function EFFECT:Init(Data)
	local Gun = Data:GetEntity()

	if not IsValid(Gun) then return end

	local Propellant = Data:GetScale()
	local ReloadTime = Data:GetMagnitude()
	local Sound      = Gun:GetNWString("Sound")
	local Pitch      = Gun:GetNWFloat("SoundPitch")
	local Volume     = Gun:GetNWFloat("SoundVolume")
	local Class      = Gun:GetNWString("ACF_Class")
	local ClassData  = Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", Class)
	if not ClassData then return end
	local Attachment = "muzzle"
	local LongBarrel = ClassData.LongBarrel

	if LongBarrel and Gun:GetBodygroup(LongBarrel.Index) == LongBarrel.Submodel then
		Attachment = LongBarrel.NewPos
	end

	if not Sounds.IsValidSound(Sound) then
		Sound = ClassData.Sound
	end

	if Propellant > 0 then
		local GunPos = Gun:GetPos()

		if Sound ~= "" then
			local SoundPressure = (Propellant * 1000) ^ 0.5
			Pitch = math.Clamp(Pitch * 100, 1, 255)

			-- NOTE: Wiki documents level tops out at 180, but seems to fall off past 127
			Sounds.PlaySound(GunPos, Sound, math.Clamp(SoundPressure, 75, 127), Pitch, Volume)

			if not (Class == "ACF.Guns.Machinegun" or Class == "ACF.Guns.RotaryAutocannon") then
				Sounds.PlaySound(GunPos, Sound, math.Clamp(SoundPressure, 75, 127), Pitch, Volume)

				if SoundPressure > 127 then
					Sounds.PlaySound(GunPos, Sound, math.Clamp(SoundPressure - 127, 1, 127), Pitch, Volume)
				end
			end
		end

		-- Flash size follows the propellant burnt, 1 is about a 75mm cannon
		local Caliber = Data:GetRadius()
		local Size    = math.Clamp(math.max(Propellant ^ (1 / 3), Caliber * 0.03), 0.08, 3.5)
		local Life    = math.Clamp(Size ^ 0.5, 0.75, 2) -- Small arms flashes still need to last a frame or two
		local Count   = math.Clamp(Size ^ 0.5, 0.5, 1.6)

		local AttachID = Gun:LookupAttachment(Attachment)
		local Muzzle   = AttachID > 0 and Gun:GetAttachment(AttachID)
		local MuzzlePos, Forward = GunPos, Gun:GetForward()

		if Muzzle then
			MuzzlePos, Forward = Muzzle.Pos, Muzzle.Ang:Forward()
		end

		local Effect = Muzzle and CreateParticleSystem(Gun, ClassData.MuzzleFlash, PATTACH_POINT_FOLLOW, AttachID)
			or CreateParticleSystem(Gun, ClassData.MuzzleFlash, PATTACH_ABSORIGIN_FOLLOW)

		if Effect then
			SetControlPoints(Effect, Size, Life, Count, 1, GetLitColor(SmokeTint, MuzzlePos), GetVelocity(Gun))
		end

		-- Only the bigger guns light up their surroundings, small arms fire too often for it to be worth it
		local Light = Size >= 0.5 and DynamicLight(Gun:EntIndex())

		if Light then
			local Radius   = 500 * Size
			local Duration = 0.07 * Life -- Only the first moments of the fireball, a longer light washes it out

			Light.pos        = MuzzlePos + Forward * 100 * Size -- Middle of the fireball
			Light.r          = 255
			Light.g          = 180
			Light.b          = 100
			Light.brightness = 2 + Size
			Light.Size       = Radius
			Light.Decay      = Radius * 0.7 / Duration -- Shrinks away as the fireball dies
			Light.DieTime    = CurTime() + Duration
		end

		GroundEffect(Gun, MuzzlePos, Forward, Size, Life, Count)

		Gun:Animate(ReloadTime, false)
	else
		Gun:Animate(ReloadTime, true)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
