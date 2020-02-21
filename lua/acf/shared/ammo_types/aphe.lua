local Ammo = ACF.RegisterAmmoType("APHE", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name = "Armor Piercing High Explosive"
	self.Description = "An armor piercing round with a cavity for High explosives. Less capable of defeating armor than plain Armor Piercing, but will explode after penetration"
	self.Blacklist = { "MO", "MG", "SL", "RAC" }
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

	if not PlayerData.Data10 then
		PlayerData.Data10 = 0
	end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)

	Data.ProjMass = math.max(GUIData.ProjVolume - PlayerData.Data5, 0) * 7.9 / 1000 + math.min(PlayerData.Data5, GUIData.ProjVolume) * ACF.HEDensity / 1000 --Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass, Data.LimitVel)
	local MaxVol = ACF_RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)
	GUIData.MinFillerVol = 0
	GUIData.MaxFillerVol = math.min(GUIData.ProjVolume, MaxVol * 0.9)
	GUIData.FillerVol = math.min(PlayerData.Data5, GUIData.MaxFillerVol)
	Data.FillerMass = GUIData.FillerVol * ACF.HEDensity / 1000
	Data.ProjMass = math.max(GUIData.ProjVolume - GUIData.FillerVol, 0) * 7.9 / 1000 + Data.FillerMass
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	Data.ShovePower = 0.1
	Data.PenArea = Data.FrArea ^ ACF.PenAreaMod
	Data.DragCoef = ((Data.FrArea / 10000) / Data.ProjMass)
	Data.LimitVel = 700 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 65 --Base ricochet angle
	Data.BoomPower = Data.PropMass + Data.FillerMass

	--Only the crates need this part
	if SERVER then
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type

		return table.Merge(Data, ServerData)
	end

	--Only the GUI needs this part
	if CLIENT then
		GUIData = table.Merge(GUIData, Ammo.GetDisplayData(Data))

		return table.Merge(Data, GUIData)
	end
end

function Ammo.Networkd(Crate, BulletData)
	Crate:SetNWString("AmmoType", "APHE")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("FillerMass", BulletData.FillerMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Ammo.GetDisplayData(BulletData)
	local Data = Ammo.BaseClass.GetDisplayData(BulletData)
	local FragMass = BulletData.ProjMass - BulletData.FillerMass

	Data.BlastRadius = BulletData.FillerMass ^ 0.33 * 8
	Data.Fragments = math.max(math.floor((BulletData.FillerMass / FragMass) * ACF.HEFrag), 2)
	Data.FragMass = FragMass / GUIData.Fragments
	Data.FragVel = (BulletData.FillerMass * ACF.HEPower * 1000 / GUIData.FragMass / GUIData.Fragments) ^ 0.5

	return Data
end

function Ammo.GetCrateText(BulletData)
	local Data = Ammo.GetDisplayData(BulletData)
	local BaseText = Ammo.BaseClass.GetCrateText(BulletData)
	local Text = BaseText .. "\nBlast Radius: %s m\nBlast Energy: %s KJ"

	return Text:format(math.Round(Data.BlastRadius, 2), math.floor(BulletData.FillerMass * ACF.HEPower))
end

function Ammo.OnFlightEnd(Index, Bullet, HitPos)
	ACF_HE(HitPos - Bullet.Flight:GetNormalized() * 3, Bullet.FillerMass, Bullet.ProjMass - Bullet.FillerMass, Bullet.Owner, nil, Bullet.Gun)

	Ammo.BaseClass.OnFlightEnd(Index, Bullet, Hitpos)
end

function Ammo.ImpactEffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(math.max(Bullet.FillerMass ^ 0.33 * 8 * 39.37, 1))
	Effect:SetRadius(Bullet.Caliber)

	util.Effect("ACF_Explosion", Effect)
end

function Ammo.CreateMenu(Panel, Table)
	acfmenupanel:AmmoSelect(Ammo.Blacklist)

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "") --Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "") --Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", 0, 0, 1000, 3, "HE Filler", "") --Hollow Point Cavity Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("PenetrationDisplay", "") --Proj muzzle penetration (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "") --HE Blast data (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "") --HE Fragmentation data (Name, Desc)
	acfmenupanel:CPanelText("PenetrationRanging", "") --penetration ranging (Name, Desc)

	Ammo.UpdateMenu(Panel, Table)
end

function Ammo.UpdateMenu(Panel)
	local PlayerData = {
		Id = acfmenupanel.AmmoData.Data.id, --AmmoSelect GUI
		Type = "APHE", --Hardcoded, match ACFRoundTypes table index
		PropLength = acfmenupanel.AmmoData.PropLength, --PropLength slider
		ProjLength = acfmenupanel.AmmoData.ProjLength, --ProjLength slider
		Data5 = acfmenupanel.AmmoData.FillerVol,
		Data10 = acfmenupanel.AmmoData.Tracer and 1 or 0,
	}

	local Data = Ammo.Convert(Panel, PlayerData)

	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength) --For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength) --And Data4 total round mass
	RunConsoleCommand("acfmenu_data5", Data.FillerVol)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", Data.FillerVol, Data.MinFillerVol, Data.MaxFillerVol, 3, "HE Filler Volume", "HE Filler Mass : " .. (math.floor(Data.FillerMass * 1000)) .. " g") --HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", Ammo.Description) --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m/s") --Proj muzzle velocity (Name, Desc)	
	acfmenupanel:CPanelText("PenetrationDisplay", "Maximum Penetration : " .. math.floor(Data.MaxPen) .. " mm RHA") --Proj muzzle penetration (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "Blast Radius : " .. (math.floor(Data.BlastRadius * 100) / 100) .. " m") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "Fragments : " .. Data.Fragments .. "\n Average Fragment Weight : " .. (math.floor(Data.FragMass * 10000) / 10) .. " g \n Average Fragment Velocity : " .. math.floor(Data.FragVel) .. " m/s") --Proj muzzle penetration (Name, Desc)

	local R1V, R1P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
	local R2V, R2P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)

	acfmenupanel:CPanelText("PenetrationRanging", "\n300m pen: " .. math.Round(R1P, 0) .. "mm @ " .. math.Round(R1V, 0) .. " m/s\n800m pen: " .. math.Round(R2P, 0) .. "mm @ " .. math.Round(R2V, 0) .. " m/s\n\nThe range data is an approximation and may not be entirely accurate.") --Proj muzzle penetration (Name, Desc)
end

function Ammo.MenuAction(Menu)
	Menu:AddParagraph("Testing APHE menu.")
end

ACF.RegisterAmmoDecal("APHE", "damage/ap_pen", "damage/ap_rico")
