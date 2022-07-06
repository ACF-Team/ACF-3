local Invisible = Color(0, 0, 0, 0)
local Clock     = ACF.Utilities.Clock

function EFFECT:Init(Data)
	local Origin  = Data:GetOrigin()
	local Emitter = ParticleEmitter(Origin)

	if not IsValid(Emitter) then return self:Remove() end

	self:SetModel("models/dav0r/hoverball.mdl")
	self:SetColor(Invisible)
	self:SetPos(Origin)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	self.Scale    = Data:GetScale() * 5
	self.LifeTime = Clock.CurTime + math.random(1, 2)
	self.Emitter  = Emitter

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:Wake()
		PhysObj:ApplyForceCenter(VectorRand(500, 800) * self.Scale)
	end
end

function EFFECT:Think()
	local Emitter = self.Emitter
	local Remove  = self.LifeTime > Clock.CurTime

	if Emitter then
		local Origin = self:GetPos()
		local Scale  = self.Scale
		local Smoke  = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), Origin)

		if Smoke then
			Smoke:SetVelocity(VectorRand(20, 50))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(2, 4))
			Smoke:SetStartAlpha(math.random(20, 80))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(Scale * 2)
			Smoke:SetEndSize(Scale * 4)
			Smoke:SetRoll(math.Rand(0, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(50)
			Smoke:SetGravity(Vector())
			Smoke:SetColor(90, 90, 90)
		end

		local Fire = Emitter:Add("particles/flamelet" .. math.random(1, 5), Origin)

		if Fire then
			Fire:SetVelocity(VectorRand(50, 100))
			Fire:SetLifeTime(0)
			Fire:SetDieTime(0.15)
			Fire:SetStartAlpha(math.random(100, 150))
			Fire:SetEndAlpha(0)
			Fire:SetStartSize(Scale * 0.5)
			Fire:SetEndSize(Scale)
			Fire:SetRoll(math.Rand(0, 360))
			Fire:SetRollDelta(math.Rand(-0.2, 0.2))
			Fire:SetAirResistance(100)
			Fire:SetGravity(VectorRand() * Scale)
			Fire:SetColor(255, 255, 255)
		end

		if Remove then
			Emitter:Finish()
		end
	end

	return Remove
end

function EFFECT:Render()
	self:DrawModel()
end
