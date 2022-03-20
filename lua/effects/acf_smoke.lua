local TraceData = { start = true, endpos = true, mask = true }
local TraceLine = util.TraceLine
local GetIndex  = ACF.GetAmmoDecalIndex
local GetDecal  = ACF.GetRicochetDecal
local White     = Color(255, 255, 255)
local Sprites = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0008"
}

function EFFECT:Init(Data)
	local Origin     = Data:GetOrigin()
	local Normal     = Data:GetNormal()
	local Caliber    = Data:GetRadius()
	local Filler     = math.min(math.log(1 + Data:GetScale()) * 43.42, 350) --smoke filler (long lasting, slow deploy)
	local WPFiller   = math.min(math.log(1 + Data:GetMagnitude()) * 43.42, 350) --WP filler (fast deploy, short duration)
	local SmokeColor = Color(Data:GetStart():Unpack())
	local Emitter    = ParticleEmitter(Origin)

	TraceData.start  = Origin
	TraceData.endpos = Origin + Normal * 100
	TraceData.mask   = MASK_SOLID

	local Impact = TraceLine(TraceData)

	if IsValid(Impact.Entity) or Impact.HitWorld then
		local Size = (Filler + WPFiller) * 0.03

		if Size > 0 then
			local Type = GetIndex("SM")

			util.DecalEx(GetDecal(Type), Impact.Entity, Impact.HitPos, Impact.HitNormal, White, Size, Size)
		end

		local Effect = EffectData()
		Effect:SetOrigin(Origin)
		Effect:SetNormal(Normal)
		Effect:SetRadius(Caliber)

		util.Effect("acf_impact", Effect)
	end

	if not IsValid(Emitter) then return end

	if Filler + WPFiller > 0 then
		TraceData.start  = Origin
		TraceData.endpos = Origin - Vector(0, 0, 1) * math.max(Filler, WPFiller)
		TraceData.mask   = MASK_NPCWORLDSTATIC

		local Ground = TraceLine(TraceData)

		if not Ground.HitWorld then
			Ground.HitNormal = Vector(0, 0, 1)
		end

		--if adjusting, update display data / crate text in smoke round
		if Filler > 0 then
			self:DeploySmoke(Emitter, Ground, SmokeColor, Filler * 1.25, 0.25, 10 + Filler * 0.25) --slow build but long lasting
		end

		if WPFiller > 0 then
			self:DeploySmoke(Emitter, Ground, SmokeColor, WPFiller * 1.25, 1, 5 + WPFiller * 0.1) --quick build and dissipate
		end
	end

	Emitter:Finish()
end

function EFFECT:CreateCloud(Emitter, HitPos, SmokeColor, Direction, Radius, Density, i, Wind, DeploySpeed, Lifetime)
	local Smoke = Emitter:Add(Sprites[math.random(1, #Sprites)], HitPos)

	if Smoke then
		Smoke:SetVelocity((Direction + Vector(0, 0, 0.2)) * Radius * DeploySpeed)
		Smoke:SetLifeTime(0)
		Smoke:SetDieTime(math.Clamp(Lifetime, 1, 60))
		Smoke:SetStartAlpha(math.Rand(200, 255))
		Smoke:SetEndAlpha(0)
		Smoke:SetStartSize(math.Clamp(Radius * DeploySpeed, 5, 1000))
		Smoke:SetEndSize(math.Clamp(Radius * 4, 150, 4000))
		Smoke:SetRoll(math.Rand(0, 360))
		Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
		Smoke:SetAirResistance(100 * DeploySpeed)
		Smoke:SetGravity(Vector(math.Rand(-10, 10) + Wind * 0.5 + (Wind * i / Density), math.Rand(-10, 10), math.Rand(5, 15)) * DeploySpeed)
		Smoke:SetColor(SmokeColor:Unpack())
	end
end

function EFFECT:DeploySmoke(Emitter, Ground, SmokeColor, Radius, DeploySpeed, Lifetime)
	local Density   = Radius / 18
	local Angle     = Ground.HitNormal:Angle()
	local Wind      = ACF.SmokeWind or 0
	local Direction = Ground.HitNormal * 0.5
	local HitPos    = Ground.HitPos

	self:CreateCloud(Emitter, HitPos, SmokeColor, Vector(0, 0, 0.3), Radius, Density, 0, Wind, DeploySpeed, Lifetime) --smoke filler initial upward puff

	for i = 0, math.floor(Density) do
		self:CreateCloud(Emitter, HitPos, SmokeColor, Direction, Radius, Density, i, Wind, DeploySpeed, Lifetime)

		Direction = Angle:Up()

		Angle:RotateAroundAxis(Angle:Forward(), 360 / Density)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end