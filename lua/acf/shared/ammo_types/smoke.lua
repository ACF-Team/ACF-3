local Ammo = ACF.RegisterAmmoType("SM", "AP")

function Ammo:OnLoaded()
	self.Name = "Smoke"
	self.Description = "A shell filled white phosporous, detonating on impact. Smoke filler produces a long lasting cloud but takes a while to be effective, whereas WP filler quickly creates a cloud that also dissipates quickly."
	self.Blacklist = { "MG", "C", "GL", "HMG", "AL", "AC", "RAC", "SA", "SC" }
end

function Ammo.Convert(_, PlayerData)
	local Data = {}
	local ServerData = {}
	local GUIData = {}

	if not PlayerData.PropLength then
		PlayerData.PropLength = 0
	end

	if not PlayerData.ProjLength then
		PlayerData.ProjLength = 0
	end

	PlayerData.Data5 = math.max(PlayerData.Data5 or 0, 0)
	PlayerData.Data6 = math.max(PlayerData.Data6 or 0, 0)
	PlayerData.Data7 = tonumber(PlayerData.Data7) or 0 --catching some possible errors with string data in legacy dupes

	if not PlayerData.Data10 then
		PlayerData.Data10 = 0
	end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)

	Data.ProjMass = math.max(GUIData.ProjVolume - PlayerData.Data5, 0) * 7.9 / 1000 + math.min(PlayerData.Data5, GUIData.ProjVolume) * ACF.HEDensity / 2000 --Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)

	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass, Data.LimitVel)
	local MaxVol = ACF_RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)

	GUIData.MinFillerVol = 0
	GUIData.MaxFillerVol = math.min(GUIData.ProjVolume, MaxVol)
	GUIData.MaxSmokeVol = math.max(GUIData.MaxFillerVol - PlayerData.Data6, GUIData.MinFillerVol)
	GUIData.MaxWPVol = math.max(GUIData.MaxFillerVol - PlayerData.Data5, GUIData.MinFillerVol)

	local Ratio = math.min(GUIData.MaxFillerVol / (PlayerData.Data5 + PlayerData.Data6), 1)

	GUIData.FillerVol = math.min(PlayerData.Data5 * Ratio, GUIData.MaxSmokeVol)
	GUIData.WPVol = math.min(PlayerData.Data6 * Ratio, GUIData.MaxWPVol)

	Data.FillerMass = GUIData.FillerVol * ACF.HEDensity / 2000
	Data.WPMass = GUIData.WPVol * ACF.HEDensity / 2000
	Data.ProjMass = math.max(GUIData.ProjVolume - (GUIData.FillerVol + GUIData.WPVol), 0) * 7.9 / 1000 + Data.FillerMass + Data.WPMass
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	Data.ShovePower = 0.1
	Data.PenArea = Data.FrArea ^ ACF.PenAreaMod
	Data.DragCoef = ((Data.FrArea / 10000) / Data.ProjMass)
	Data.LimitVel = 100 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 60 --Base ricochet angle
	Data.DetonatorAngle = 80
	Data.CanFuze = Data.Caliber > 2 -- Can fuze on calibers > 20mm

	if PlayerData.Data7 < 0.5 then
		PlayerData.Data7 = 0
		Data.FuseLength = PlayerData.Data7
	else
		PlayerData.Data7 = math.max(math.Round(PlayerData.Data7, 1), 0.5)
		Data.FuseLength = PlayerData.Data7
	end

	Data.BoomPower = Data.PropMass + Data.FillerMass + Data.WPMass

	--Only the crates need this part
	if SERVER then
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type

		return table.Merge(Data, ServerData)
	end

	--Only tthe GUI needs this part
	if CLIENT then
		GUIData = table.Merge(GUIData, Ammo.GetDisplayData(Data))

		return table.Merge(Data, GUIData)
	end
end

function Ammo.Network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "SM")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("FillerMass", BulletData.FillerMass)
	Crate:SetNWFloat("WPMass", BulletData.WPMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Ammo.GetDisplayData(Data)
	local SMFiller = math.min(math.log(1 + Data.FillerMass * 8 * 39.37) / 0.02303, 350)
	local WPFiller = math.min(math.log(1 + Data.WPMass * 8 * 39.37) / 0.02303, 350)

	return {
		SMFiller = SMFiller, --smoke filler
		SMLife = math.Round(20 + SMFiller * 0.25, 1),
		SMRadiusMin = math.Round(SMFiller * 1.25 * 0.15 * 0.0254, 1),
		SMRadiusMax = math.Round(SMFiller * 1.25 * 2 * 0.0254, 1),
		WPFiller = WPFiller, --wp filler
		WPLife = math.Round(6 + WPFiller * 0.1, 1),
		WPRadiusMin = math.Round(WPFiller * 1.25 * 0.0254, 1),
		WPRadiusMax = math.Round(WPFiller * 1.25 * 2 * 0.0254, 1),
	}
end

function Ammo.GetCrateText(BulletData)
	local Text = "Muzzle Velocity: %s m/s%s%s"
	local Data = Ammo.GetDisplayData(BulletData)
	local WPText, SMText = "", ""


	if Data.WPFiller > 0 then
		local Template = "\nWP Radius: %s m to %s m\nWP Lifetime: %s s"

		WPText = Template:format(Data.WPRadiusMin, Data.WPRadiusMax, Data.WPLife)
	end

	if Data.SMFiller > 0 then
		local Template = "\nSM Radius: %s m to %s m\nSM Lifetime: %s s"

		SMText = Template:format(Data.SMRadiusMin, Data.SMRadiusMax, Data.SMLife)
	end

	return Text:format(math.Round(BulletData.MuzzleVel, 2), WPText, SMText)
end

function Ammo.PropImpact(_, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check(Target) then
		local Speed = Bullet.Flight:Length() / ACF.Scale
		local Energy = ACF_Kinetic(Speed, Bullet.ProjMass - (Bullet.FillerMass + Bullet.WPMass), Bullet.LimitVel)
		local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

		if HitRes.Ricochet then return "Ricochet" end
	end

	return false
end

function Ammo.WorldImpact()
	return false
end

function Ammo.ImpactEffect(_, Bullet)
	local Crate = Bullet.Crate
	local Color = IsValid(Crate) and Crate:GetColor() or Color(255, 255, 255)

	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(math.max(Bullet.FillerMass * 8 * 39.37, 0))
	Effect:SetMagnitude(math.max(Bullet.WPMass * 8 * 39.37, 0))
	Effect:SetStart(Vector(Color.r, Color.g, Color.b))
	Effect:SetRadius(Bullet.Caliber)

	util.Effect("ACF_Smoke", Effect)
end

function Ammo.CreateMenu(Panel, Table)
	acfmenupanel:AmmoSelect(Ammo.Blacklist)

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "") --Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "") --Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", 0, 0, 1000, 3, "Smoke Filler", "") --Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("WPVol", 0, 0, 1000, 3, "WP Filler", "") --Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FuseLength", 0, 0, 1000, 3, "Timed Fuse", "")
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "") --HE Blast data (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "") --HE Fragmentation data (Name, Desc)

	Ammo.UpdateMenu(Panel, Table)
end

function Ammo.UpdateMenu(Panel)
	local PlayerData = {
		Id = acfmenupanel.AmmoData.Data.id, --AmmoSelect GUI
		Type = "SM", --Hardcoded, match ACFRoundTypes table index
		PropLength = acfmenupanel.AmmoData.PropLength, --PropLength slider
		ProjLength = acfmenupanel.AmmoData.ProjLength, --ProjLength slider
		Data5 = acfmenupanel.AmmoData.FillerVol,
		Data6 = acfmenupanel.AmmoData.WPVol,
		Data7 = acfmenupanel.AmmoData.FuseLength,
		Data10 = acfmenupanel.AmmoData.Tracer and 1 or 0,
	}

	local Data = Ammo.Convert(Panel, PlayerData)

	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength) --For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength) --And Data4 total round mass
	RunConsoleCommand("acfmenu_data5", Data.FillerVol)
	RunConsoleCommand("acfmenu_data6", Data.WPVol)
	RunConsoleCommand("acfmenu_data7", Data.FuseLength)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", Data.FillerVol, Data.MinFillerVol, Data.MaxFillerVol, 3, "Smoke Filler Volume", "Smoke Filler Mass : " .. (math.floor(Data.FillerMass * 1000)) .. " g") --HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("WPVol", Data.WPVol, Data.MinFillerVol, Data.MaxFillerVol, 3, "WP Filler Volume", "WP Filler Mass : " .. (math.floor(Data.WPMass * 1000)) .. " g") --HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FuseLength", Data.FuseLength, 0, 10, 1, "Fuse Time", Data.FuseLength .. " s")
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", Ammo.Description) --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m/s") --Proj muzzle velocity (Name, Desc)	
end

function Ammo.MenuAction(Menu)
	Menu:AddParagraph("Testing SM menu.")
end

ACF.RegisterAmmoDecal("SM", "damage/he_pen", "damage/he_rico")
