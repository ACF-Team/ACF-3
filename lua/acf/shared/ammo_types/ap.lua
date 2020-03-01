local Ammo = ACF.RegisterAmmoType("AP")
local DecalIndex = ACF.GetAmmoDecalIndex

function Ammo:OnLoaded()
	self.Name = "Armor Piercing"
	self.Type = "Ammo"
	self.Model = "models/munitions/round_100mm_shot.mdl"
	self.Description = "A shell made out of a solid piece of steel, meant to penetrate armor."
	self.Blacklist = {
		MO = true,
		SL = true,
		SB = true,
	}
end

function Ammo.Create(_, BulletData)
	ACF_CreateBullet(BulletData)
end

function Ammo.BaseConvert(_, ToolData)
	if not ToolData.Projectile then ToolData.Projectile = 0 end
	if not ToolData.Propellant then ToolData.Propellant = 0 end

	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	Data.ProjMass = Data.FrArea * (Data.ProjLength * 7.9 / 1000) --Volume of the projectile as a cylinder * density of steel
	Data.ShovePower = 0.2
	Data.PenArea = Data.FrArea ^ ACF.PenAreaMod
	Data.DragCoef = ((Data.FrArea / 10000) / Data.ProjMass)
	Data.LimitVel = 800 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 60 --Base ricochet angle
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	Data.BoomPower = Data.PropMass

	return Data, GUIData
end

function Ammo.ClientConvert(_, ToolData)
	local Data, GUIData = Ammo.BaseConvert(_, ToolData)

	for K, V in pairs(GUIData) do
		Data[K] = V
	end

	for K, V in pairs(Ammo.GetDisplayData(Data)) do
		Data[K] = V
	end

	return Data
end

function Ammo.ServerConvert(_, ToolData)
	local Data = Ammo.BaseConvert(_, ToolData)

	Data.Id = ToolData.Weapon
	Data.Type = ToolData.Ammo

	return Data
end

function Ammo.Network(Crate, BulletData)
	Crate:SetNW2String("AmmoType", "AP")
	Crate:SetNW2String("AmmoID", BulletData.Id)
	Crate:SetNW2Float("Caliber", BulletData.Caliber)
	Crate:SetNW2Float("ProjMass", BulletData.ProjMass)
	Crate:SetNW2Float("PropMass", BulletData.PropMass)
	Crate:SetNW2Float("DragCoef", BulletData.DragCoef)
	Crate:SetNW2Float("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNW2Float("Tracer", BulletData.Tracer)
end

function Ammo.GetDisplayData(BulletData)
	local Energy = ACF_Kinetic(BulletData.MuzzleVel * 39.37, BulletData.ProjMass, BulletData.LimitVel)

	return {
		MaxPen = (Energy.Penetration / BulletData.PenArea) * ACF.KEtoRHA
	}
end

function Ammo.GetCrateText(BulletData)
	local Data = Ammo.GetDisplayData(BulletData)
	local Text = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm"

	return Text:format(math.Round(BulletData.MuzzleVel, 2), math.floor(Data.MaxPen))
end

function Ammo.PropImpact(_, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check(Target) then
		local Speed = Bullet.Flight:Length() / ACF.Scale
		local Energy = ACF_Kinetic(Speed, Bullet.ProjMass, Bullet.LimitVel)
		local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

		if HitRes.Overkill > 0 then
			table.insert(Bullet.Filter, Target) --"Penetrate" (Ingoring the prop for the retry trace)
			Bullet.Flight = Bullet.Flight:GetNormalized() * (Energy.Kinetic * (1 - HitRes.Loss) * 2000 / Bullet.ProjMass) ^ 0.5 * 39.37

			return "Penetrated"
		elseif HitRes.Ricochet then
			return "Ricochet"
		else
			return false
		end
	else
		table.insert(Bullet.Filter, Target)

		return "Penetrated"
	end
end

function Ammo.WorldImpact(_, Bullet, HitPos, HitNormal)
	local Energy = ACF_Kinetic(Bullet.Flight:Length() / ACF.Scale, Bullet.ProjMass, Bullet.LimitVel)
	local HitRes = ACF_PenetrateGround(Bullet, Energy, HitPos, HitNormal)

	if HitRes.Penetrated then
		return "Penetrated"
	elseif HitRes.Ricochet then
		return "Ricochet"
	else
		return false
	end
end

function Ammo.OnFlightEnd(Index)
	ACF_RemoveBullet(Index)
end

function Ammo.ImpactEffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Impact", Effect)
end

function Ammo.PenetrationEffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Penetration", Effect)
end

function Ammo.RicochetEffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Ricochet", Effect)
end

function Ammo.MenuAction(Menu)
	local ToolData = {
		Weapon = ACF.ReadString("Weapon"),
		WeaponClass = ACF.ReadString("WeaponClass"),
		Projectile = ACF.ReadNumber("Projectile"),
		Propellant = ACF.ReadNumber("Propellant"),
		Tracer = ACF.ReadBool("Tracer"),
	}

	local Data = Ammo.ClientConvert(Menu, ToolData)

	Menu:AddParagraph(Ammo.Description)

	local RoundLength = Menu:AddParagraph()
	RoundLength:TrackDataVar("Projectile", "SetText")
	RoundLength:TrackDataVar("Propellant")
	RoundLength:TrackDataVar("Tracer")
	RoundLength:SetValueFunction(function()
		local Text = "Round Length: %s / %s cm"
		local CurLength = Data.ProjLength + Data.PropLength + Data.Tracer
		local MaxLength = Data.MaxRoundLength

		return Text:format(CurLength, MaxLength)
	end)

	local Projectile = Menu:AddSlider("Projectile Length", 0, Data.MaxRoundLength, 2)
	Projectile:SetDataVar("Projectile", "OnValueChanged")
	Projectile:TrackDataVar("Propellant")
	Projectile:TrackDataVar("Tracer")
	Projectile:SetValueFunction(function(Panel, IsTracked)
		ToolData.Projectile = ACF.ReadNumber("Projectile")

		if not IsTracked then
			Data.Priority = "Projectile"
		end

		ACF.UpdateRoundSpecs(ToolData, Data)

		ACF.WriteValue("Projectile", Data.ProjLength)
		ACF.WriteValue("Propellant", Data.PropLength)

		Panel:SetValue(Data.ProjLength)

		return Data.ProjLength
	end)

	local Propellant = Menu:AddSlider("Propellant Length", 0, Data.MaxRoundLength, 2)
	Propellant:SetDataVar("Propellant", "OnValueChanged")
	Propellant:TrackDataVar("Projectile")
	Propellant:TrackDataVar("Tracer")
	Propellant:SetValueFunction(function(Panel, IsTracked)
		ToolData.Propellant = ACF.ReadNumber("Propellant")

		if not IsTracked then
			Data.Priority = "Propellant"
		end

		ACF.UpdateRoundSpecs(ToolData, Data)

		ACF.WriteValue("Propellant", Data.PropLength)
		ACF.WriteValue("Projectile", Data.ProjLength)

		Panel:SetValue(Data.PropLength)

		return Data.PropLength
	end)

	local Tracer = Menu:AddCheckBox("Tracer")
	Tracer:SetDataVar("Tracer", "OnChange")
	Tracer:SetValueFunction(function(Panel)
		local NewValue = ACF.ReadBool("Tracer")

		ToolData.Tracer = NewValue

		ACF.UpdateRoundSpecs(ToolData, Data)

		ACF.WriteValue("Projectile", Data.ProjLength)
		ACF.WriteValue("Propellant", Data.PropLength)

		Panel:SetText("Tracer : " .. (NewValue and Data.Tracer or 0) .. " cm")
		Panel:SetValue(NewValue)

		return NewValue
	end)

	local RoundStats = Menu:AddParagraph()
	RoundStats:TrackDataVar("Projectile", "SetText")
	RoundStats:TrackDataVar("Propellant")
	RoundStats:TrackDataVar("Tracer")
	RoundStats:SetValueFunction(function()
		Data = Ammo.ClientConvert(_, ToolData)

		local Text = "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s"
		local MuzzleVel = math.Round(Data.MuzzleVel * ACF.Scale, 2)
		local ProjMass = ACF.GetProperMass(Data.ProjMass * 1000)
		local PropMass = ACF.GetProperMass(Data.PropMass * 1000)

		return Text:format(MuzzleVel, ProjMass, PropMass)
	end)

	local PenStats = Menu:AddParagraph()
	PenStats:TrackDataVar("Projectile", "SetText")
	PenStats:TrackDataVar("Propellant")
	PenStats:TrackDataVar("Tracer")
	PenStats:SetValueFunction(function()
		Data = Ammo.ClientConvert(_, ToolData)

		local Text = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
		local MaxPen = math.Round(Data.MaxPen, 2)
		local R1V, R1P = ACF.PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
		local R2V, R2P = ACF.PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)

		return Text:format(MaxPen, R1P, R1V, R2P, R2V)
	end)
end

ACF.RegisterAmmoDecal("AP", "damage/ap_pen", "damage/ap_rico")
