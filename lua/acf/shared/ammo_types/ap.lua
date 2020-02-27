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

function Ammo.CreateMenu(Panel, Table)
	acfmenupanel:AmmoSelect(Ammo.Blacklist)

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "") --Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "") --Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("PenetrationDisplay", "") --Proj muzzle penetration (Name, Desc)

	Ammo.UpdateMenu(Panel, Table)
end

function Ammo.UpdateMenu(Panel)
	local PlayerData = {
		Id = acfmenupanel.AmmoData.Data.id, --AmmoSelect GUI
		Type = "AP", --Hardcoded, match ACFRoundTypes table index
		PropLength = acfmenupanel.AmmoData.PropLength, --PropLength slider
		ProjLength = acfmenupanel.AmmoData.ProjLength, --ProjLength slider
		Data10 = acfmenupanel.AmmoData.Tracer and 1 or 0
	}

	local Data = Ammo.Convert(Panel, PlayerData)

	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength) --For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength) --And Data4 total round mass
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", Ammo.Description) --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m/s") --Proj muzzle velocity (Name, Desc)

	local R1V, R1P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
	local R2V, R2P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)

	acfmenupanel:CPanelText("PenetrationDisplay", "Maximum Penetration : " .. math.floor(Data.MaxPen) .. " mm RHA\n\n300m pen: " .. math.Round(R1P, 0) .. "mm @ " .. math.Round(R1V, 0) .. " m/s\n800m pen: " .. math.Round(R2P, 0) .. "mm @ " .. math.Round(R2V, 0) .. " m/s\n\nThe range data is an approximation and may not be entirely accurate.") --Proj muzzle penetration (Name, Desc)
end

function Ammo.MenuAction(Menu)
	local ToolData = {
		Weapon = ACF.ReadString("Weapon"),
		WeaponClass = ACF.ReadString("WeaponClass"),
		Projectile = ACF.ReadNumber("Projectile"),
		Propellant = ACF.ReadNumber("Propellant"),
		Tracer = ACF.ReadBool("Tracer"),
	}

	local Data = Ammo.ClientConvert(Panel, ToolData)

	Menu:AddParagraph(Ammo.Description)

	local Projectile = Menu:AddSlider("Projectile Length", Data.MinProjLength, Data.MaxProjLength, 2)
	Projectile:SetDataVar("Projectile")
	Projectile:TrackDataVar("Propellant")
	Projectile:TrackDataVar("Tracer")

	local Propellant = Menu:AddSlider("Propellant Length", Data.MinPropLength, Data.MaxPropLength, 2)
	Propellant:SetDataVar("Propellant")
	Propellant:TrackDataVar("Projectile")
	Propellant:TrackDataVar("Tracer")

	local Tracer = Menu:AddCheckBox("Tracer")
	Tracer:SetDataVar("Tracer")

	--[[

	local Test = Menu:AddComboBox()
	Test:TrackDataVar("WeaponClass")
	Test:TrackDataVar("Weapon")
	Test:SetValueFunction(function()
		return ACF.ReadString("WeaponClass") .. " - " .. ACF.ReadString("Weapon")
	end)

	local Test1 = Menu:AddSlider("Projectile", 0, 10, 2)
	Test1:SetDataVar("Projectile")
	Test1:TrackDataVar("Propellant")
	Test1:SetValueFunction(function(Panel)
		local Min, Max = Panel:GetMin(), Panel:GetMax()
		local Projectile = math.Clamp(ACF.ReadNumber("Projectile"), Min, Max)
		local Propellant = ACF.ReadNumber("Propellant")
		local Difference = Max - Projectile

		ACF.WriteValue("Projectile", Projectile)
		ACF.WriteValue("Propellant", math.min(Propellant, Difference))

		return Projectile
	end)

	local Test2 = Menu:AddSlider("Propellant", 0, 10, 2)
	Test2:SetDataVar("Propellant")
	Test2:TrackDataVar("Projectile")
	Test2:SetValueFunction(function(Panel)
		local Min, Max = Panel:GetMin(), Panel:GetMax()
		local Projectile = ACF.ReadNumber("Projectile")
		local Propellant = math.Clamp(ACF.ReadNumber("Propellant"), Min, Max)
		local Difference = Max - Propellant

		ACF.WriteValue("Propellant", Propellant)
		ACF.WriteValue("Projectile", math.min(Projectile, Difference))

		return Propellant
	end)

	]]--
end

ACF.RegisterAmmoDecal("AP", "damage/ap_pen", "damage/ap_rico")
