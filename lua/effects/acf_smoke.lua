local TraceData = { start = true, endpos = true, mask = true }
local TraceLine = util.TraceLine
local GetIndex = ACF.GetAmmoDecalIndex
local GetDecal = ACF.GetRicochetDecal

local SmokeCount = 7
local SmokeSprites = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0008"
}

function EFFECT:Init(Data)
	local Direction = Data:GetNormal()
	local Caliber = Data:GetRadius()
	local Magnitude = Data:GetMagnitude()
	local Scale = Data:GetScale()

	self.Origin = Data:GetOrigin()
	self.Color = Data:GetStart() or Vector(255, 255, 255)
	self.Scale = math.min(math.log(1 + Scale) * 43.42, 350) --smoke filler (long lasting, slow deploy)
	self.Magnitude = math.min(math.log(1 + Magnitude) * 43.42, 350) --WP filler (fast deploy, short duration)
	self.Emitter = ParticleEmitter(self.Origin)

	TraceData.start = self.Origin
	TraceData.endpos = self.Origin + Direction * 100
	TraceData.mask = MASK_SOLID

	local Impact = TraceLine(TraceData)

	if IsValid(Impact.Entity) or Impact.HitWorld then
		local Size = (self.Scale + self.Magnitude) * 0.03

		if Size > 0 then
			local Type = GetIndex("SM")

			util.DecalEx(GetDecal(Type), Impact.Entity, Impact.HitPos, Impact.HitNormal, Color(255, 255, 255), Size, Size)
		end

		local Effect = EffectData()
		Effect:SetOrigin(self.Origin)
		Effect:SetNormal(Direction)
		Effect:SetRadius(Caliber)

		util.Effect("ACF_Impact", Effect)
	end

	TraceData.start = self.Origin
	TraceData.endpos = self.Origin - Vector(0, 0, 1) * self.Scale
	TraceData.mask = MASK_NPCWORLDSTATIC

	local Ground = TraceLine(TraceData)

	if not Ground.HitWorld then
		Ground.HitNormal = Vector(0, 0, 1)
	end

	--if adjusting, update display data / crate text in smoke round
	if self.Scale > 0 then
		self:SmokeFiller(Ground, self.Scale * 1.25, 0.15, 20 + self.Scale * 0.25) --slow build but long lasting
	end

	if self.Magnitude > 0 then
		self:SmokeFiller(Ground, self.Magnitude * 1.25, 1, 6 + self.Magnitude * 0.1) --quick build and dissipate
	end

	self.Emitter:Finish()
end

function EFFECT:CreateSmokePuff(Ground, ShootVector, Radius, RadiusMod, Density, i, Wind, DeploySpeed, Lifetime)
	local Smoke = self.Emitter:Add(SmokeSprites[math.random(1, SmokeCount)], Ground.HitPos)
	local SmokeColor = self.Color

	if Smoke then
		Smoke:SetVelocity((ShootVector + Vector(0, 0, 0.2)) * (Radius * RadiusMod) * DeploySpeed)
		Smoke:SetLifeTime(0)
		Smoke:SetDieTime(math.Clamp(Lifetime, 1, 60))
		Smoke:SetStartAlpha(math.Rand(200, 255))
		Smoke:SetEndAlpha(0)
		Smoke:SetStartSize(math.Clamp((Radius * RadiusMod) * DeploySpeed, 5, 1000))
		Smoke:SetEndSize(math.Clamp(Radius * RadiusMod * 4, 150, 4000))
		Smoke:SetRoll(math.Rand(0, 360))
		Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
		Smoke:SetAirResistance(100 * DeploySpeed)
		Smoke:SetGravity(Vector(math.Rand(-10, 10) + Wind * 0.5 + (Wind * i / Density), math.Rand(-10, 10), math.Rand(5, 15)) * DeploySpeed)
		Smoke:SetColor(SmokeColor.x, SmokeColor.y, SmokeColor.z)
	end
end

function EFFECT:SmokeFiller(Ground, Radius, DeploySpeed, Lifetime)
	local Density = Radius / 18
	local Angle = Ground.HitNormal:Angle()
	local Wind = ACF.SmokeWind or 0
	local ShootVector = Ground.HitNormal * 0.5

	self:CreateSmokePuff(Ground, Vector(0, 0, 0.3), Radius, 1.5, Density, 0, Wind, DeploySpeed, Lifetime) --smoke filler initial upward puff

	for i = 0, math.floor(Density) do
		self:CreateSmokePuff(Ground, ShootVector, Radius, 1, Density, i, Wind, DeploySpeed, Lifetime)

		ShootVector = Angle:Up()

		Angle:RotateAroundAxis(Angle:Forward(), 360 / Density)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end