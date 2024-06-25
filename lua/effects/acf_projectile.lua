local util      = util
local ACF       = ACF
local Bullets   = ACF.BulletEffect
local AmmoTypes = ACF.Classes.AmmoTypes


local Actions = {
	[0] = "Create",
	[1] = "Impact",
	[2] = "Penetrate",
	[3] = "Ricochet"
}

function EFFECT.HasLeftWorld(Position)
	local Contents = util.PointContents(Position)

	return bit.band(Contents, 1) == 1 -- CONTENTS_SOLID = 1
end

function EFFECT:Init(Data)
	local Index  = Data:GetDamageType()
	local Action = Actions[Data:GetScale()]

	if Action then
		local Function = self[Action]
		local Remove   = Function(self, Index, Data)

		if Remove then self:Remove() end
	else
		print("Invalid action for bullet #" .. Index .. ", ignoring.")

		self:Remove()
	end
end

function EFFECT:Create(Index, Data)
	local Crate = Data:GetEntity()

	--TODO: Check if it is actually a crate
	if not IsValid(Crate) then return true end

	local Flight  = Data:GetStart() * 10
	local Pos     = Data:GetOrigin()
	local Caliber = Crate:GetNW2Float("Caliber", 10)
	local Tracer  = Crate:GetNW2Float("Tracer") > 0
	local Color   = Tracer and Crate:GetColor() or nil
	local Bullet = {
		Index      = Index,
		Crate      = Crate,
		Pos        = Pos,
		LastPos    = Pos,
		Flight     = Flight,
		Caliber    = Caliber,
		ProjMass   = Crate:GetNW2Float("ProjMass", 10),
		FillerMass = Crate:GetNW2Float("FillerMass"),
		WPMass     = Crate:GetNW2Float("WPMass"),
		DragCoef   = Crate:GetNW2Float("DragCoef", 1),
		AmmoType   = Crate:GetNW2String("AmmoType", "AP"),
		Accel      = Crate:GetNW2Vector("Accel", ACF.Gravity),
		Effect     = self,
	}

	self.Bullet = Bullet

	self:SetNoDraw(Data:GetAttachment() == 0)
	self:SetAngles(Bullet.Flight:Angle())
	self:SetPos(Bullet.Pos)
	self:SetTracer(Color)

	Bullets[Index] = Bullet
end

function EFFECT:Impact(Index, Data)
	local Bullet = Bullets[Index]

	if not Bullet or Bullet.Removed then return true end

	local Effect = Bullet.Effect

	if not IsValid(Effect) then return true end

	local AmmoType = AmmoTypes.Get(Bullet.AmmoType)

	Effect:SetNoDraw(Data:GetAttachment() == 0)

	Bullet.Flight  = Data:GetStart() * 10
	Bullet.Pos     = Data:GetOrigin()
	Bullet.Removed = true

	AmmoType:ImpactEffect(Effect, Bullet)

	Bullets[Index] = nil

	return true
end

function EFFECT:Penetrate(Index, Data)
	local Bullet = Bullets[Index]

	if not Bullet or Bullet.Removed then return true end

	local Effect = Bullet.Effect

	if not IsValid(Effect) then return true end

	local AmmoType = AmmoTypes.Get(Bullet.AmmoType)

	Effect:SetNoDraw(Data:GetAttachment() == 0)

	Bullet.Flight = Data:GetStart() * 10
	Bullet.Pos    = Data:GetOrigin()

	AmmoType:PenetrationEffect(Effect, Bullet)

	return true
end

function EFFECT:Ricochet(Index, Data)
	local Bullet = Bullets[Index]

	if not Bullet or Bullet.Removed then return true end

	local Effect = Bullet.Effect

	if not IsValid(Effect) then return true end

	local AmmoType = AmmoTypes.Get(Bullet.AmmoType)

	Effect:SetNoDraw(Data:GetAttachment() == 0)

	Bullet.Flight = Data:GetStart() * 10
	Bullet.Pos    = Data:GetOrigin()

	AmmoType:RicochetEffect(Effect, Bullet)

	return true
end

function EFFECT:SetTracer(Color)
	local IsTracer = Color and true or false
	local Bullet   = self.Bullet
	local Caliber  = Bullet.Caliber

	if IsTracer then
		self:ManipulateBoneScale(0, Vector(Caliber * 4, Caliber * 2, Caliber * 2))
		self:SetModel("models/tracer.mdl")
		self:SetColor(Color)
	else
		self:SetModel("models/munitions/round_100mm_shot.mdl")
		self:SetModelScale(Caliber * 0.1, 0)
	end

	self.IsTracer = IsTracer
end

function EFFECT:Think()
	local Bullet = self.Bullet

	if not Bullet or Bullet.Removed then return false end

	return self:ApplyMovement(Bullet)
end

function EFFECT:ApplyMovement(Bullet)
	local Position = Bullet.Pos

	if self.HasLeftWorld(Position) then
		--print("Bullet #" .. Bullet.Index .. " has left the world, removing.")
		return false
	end

	self:SetAngles(Bullet.Flight:Angle())
	self:SetPos(Position)

	return true
end
