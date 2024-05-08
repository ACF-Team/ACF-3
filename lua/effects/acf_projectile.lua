local ACF       = ACF
local Bullets   = ACF.BulletEffect
local AmmoTypes = ACF.Classes.AmmoTypes
local Clock     = ACF.Utilities.Clock

local Actions = {
	[0] = "Create",
	[1] = "Impact",
	[2] = "Penetrate",
	[3] = "Ricochet"
}

function EFFECT:Init(Data)
	local Index  = Data:GetDamageType()
	local Action = Actions[Data:GetScale()]

	if Action then
		local Function = self[Action]
		local Remove   = Function(self, Index, Data)

		if Remove then self:Remove() end
	else
		print("Invalid action for bullet #" .. Index .. ", removing.")

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
		Color      = Color,
		LastThink  = Clock.CurTime,
		Effect     = self,
	}

	if Color then
		self:ManipulateBoneScale(0, Vector(Caliber * 4, Caliber * 2, Caliber * 2))
		self:SetModel("models/acf/core/tracer.mdl")
		self:SetColor(Color)

		self.IsTracer = true
	else
		self:SetModel("models/munitions/round_100mm_shot.mdl")
		self:SetModelScale(Caliber * 0.1, 0)
	end

	self:SetNoDraw(Data:GetAttachment() == 0)
	self:SetAngles(Bullet.Flight:Angle())
	self:SetPos(Bullet.Pos)

	self.Bullet = Bullet

	--TODO: Add an index delay on the serverside to prevent this, how long though.
	if Bullets[Index] then
		Bullets[Index].Removed = true
		print("WARNING: #" .. Index .. " ALREADY EXISTS.")
	end

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

function EFFECT:Think()
	local Bullet = self.Bullet

	if not Bullet or Bullet.Removed then return false end

	return self:ApplyMovement(Bullet)
end

function EFFECT:ApplyMovement(Bullet)
	local Position = Bullet.Pos

	--TODO: Replace this logic, map bounds might not be compliant with this in all cases
	if math.abs(Position.x) > 16380 or math.abs(Position.y) > 16380 or Position.z < -16380 then
		return false
	end

	if Position.z < 16380 then
		self:SetAngles(Bullet.Flight:Angle())
		self:SetPos(Position)
	end

	return true
end
