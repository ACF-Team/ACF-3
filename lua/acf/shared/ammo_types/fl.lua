local Ammo = ACF.RegisterAmmoType("Flechette", "Armor Piercing")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.ID = "FL"
	self.Model = "models/munitions/dart_100mm.mdl"
	self.Description = "Flechette rounds contain several long thin steel spikes, functioning as a shotgun shell for cannons.  While it seems like the spikes would penetrate well, they tend to tumble in flight and impact at less than ideal angles, causing only minor penetration and structural damage. They are best used against infantry or lightly armored mobile targets such as aircraft or light tanks, since flechettes trade brute damage for a better chance to hit."
	self.Blacklist = { "AC", "RAC", "MG", "HMG", "GL", "SL" }
end

function Ammo.Create(Gun, BulletData)
	local FlechetteData = {
		Caliber		= math.Round(BulletData.FlechetteRadius * 0.2, 2),
		Id			= BulletData.Id,
		Type		= "AP",
		Owner		= BulletData.Owner,
		Crate		= BulletData.Crate,
		Gun			= BulletData.Gun,
		Pos			= BulletData.Pos,
		FrArea		= BulletData.FlechetteArea,
		ProjMass	= BulletData.FlechetteMass,
		DragCoef	= BulletData.FlechetteDragCoef,
		Tracer		= BulletData.Tracer,
		LimitVel	= BulletData.LimitVel,
		Ricochet	= BulletData.Ricochet,
		PenArea		= BulletData.FlechettePenArea,
		ShovePower	= BulletData.ShovePower,
		KETransfert	= BulletData.KETransfert,
	}

	--if ammo is cooking off, shoot in random direction
	if Gun:GetClass() == "acf_ammo" then
		local MuzzleVec = VectorRand()

		for _ = 1, BulletData.Flechettes do
			local Inaccuracy = VectorRand() / 360 * ((Gun.Spread or 0) + BulletData.FlechetteSpread)

			FlechetteData.Flight = (MuzzleVec + Inaccuracy):GetNormalized() * BulletData.MuzzleVel * 39.37 + Gun:GetVelocity()

			ACF_CreateBullet(FlechetteData)
		end
	else
		local BaseInaccuracy = math.tan(math.rad(Gun:GetSpread()))
		local AddInaccuracy = math.tan(math.rad(BulletData.FlechetteSpread))
		local MuzzleVec = Gun:GetForward()

		for _ = 1, BulletData.Flechettes do
			local BaseInaccuracyMult = (math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4))) * (Gun:GetUp() * (2 * math.random() - 1) + Gun:GetRight() * (2 * math.random() - 1)):GetNormalized()
			local AddSpreadMult = (math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4))) * (Gun:GetUp() * (2 * math.random() - 1) + Gun:GetRight() * (2 * math.random() - 1)):GetNormalized()

			BaseSpread = BaseInaccuracy * BaseInaccuracyMult
			AddSpread = AddInaccuracy * AddSpreadMult

			FlechetteData.Flight = (MuzzleVec + BaseSpread + AddSpread):GetNormalized() * BulletData.MuzzleVel * 39.37 + Gun:GetVelocity()

			ACF_CreateBullet(FlechetteData)
		end
	end
end

function Ammo.Convert(_, PlayerData)
	local ServerData = {}
	local GUIData = {}
	local Data = {
		LengthAdj = 0.5
	}

	if not PlayerData.PropLength then
		PlayerData.PropLength = 0
	end

	if not PlayerData.ProjLength then
		PlayerData.ProjLength = 0
	end

	--flechette count
	if not PlayerData.Data5 then
		PlayerData.Data5 = 3
	end

	--flechette spread
	if not PlayerData.Data6 then
		PlayerData.Data6 = 5
	end

	--tracer
	if not PlayerData.Data10 then
		PlayerData.Data10 = 0
	end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)

	local GunClass = ACF.Weapons.Guns[Data.Id or PlayerData.Id].gunclass

	if GunClass == "SA" then
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 3 - 4.5), 1, 32)
	elseif GunClass == "MO" then
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 4) - 12, 1, 32)
	elseif GunClass == "HW" then
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 4) - 10, 1, 32)
	else
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 4) - 8, 1, 32)
	end

	local PenAdj = 0.8 --higher means lower pen, but more structure (hp) damage (old: 2.35, 2.85)
	local RadiusAdj = 1.0 -- lower means less structure (hp) damage, but higher pen (old: 1.0, 0.8)

	Data.MinFlechettes = math.min(6, Data.MaxFlechettes) --force bigger guns to have higher min count
	Data.Flechettes = math.Clamp(math.floor(PlayerData.Data5), Data.MinFlechettes, Data.MaxFlechettes) --number of flechettes
	Data.MinSpread = 0.25
	Data.MaxSpread = 30
	Data.FlechetteSpread = math.Clamp(tonumber(PlayerData.Data6), Data.MinSpread, Data.MaxSpread)

	local PackRatio = 0.0025 * Data.Flechettes + 0.69 --how efficiently flechettes are packed into shell

	Data.FlechetteRadius = math.sqrt(((PackRatio * RadiusAdj * Data.Caliber * 0.5) ^ 2) / Data.Flechettes) -- max radius flechette can be, to fit number of flechettes in a shell
	Data.FlechetteArea = 3.1416 * Data.FlechetteRadius ^ 2 -- area of a single flechette
	Data.FlechetteMass = Data.FlechetteArea * (Data.ProjLength * 7.9 / 1000) -- volume of single flechette * density of steel
	Data.FlechettePenArea = (PenAdj * Data.FlechetteArea) ^ ACF.PenAreaMod
	Data.FlechetteDragCoef = (Data.FlechetteArea / 10000) / Data.FlechetteMass
	Data.ProjMass = Data.Flechettes * Data.FlechetteMass -- total mass of all flechettes
	Data.PropMass = Data.PropMass
	Data.ShovePower = 0.2
	Data.PenArea = Data.FrArea ^ ACF.PenAreaMod
	Data.DragCoef = ((Data.FrArea / 10000) / Data.ProjMass)
	Data.LimitVel = 500 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 75 --Base ricochet angle
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	Data.BoomPower = Data.PropMass

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

function Ammo.Network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "FL")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
	Crate:SetNWFloat("Caliber", math.Round(BulletData.FlechetteRadius * 0.2, 2))
	Crate:SetNWFloat("ProjMass", BulletData.FlechetteMass)
	Crate:SetNWFloat("DragCoef", BulletData.FlechetteDragCoef)
	Crate:SetNWFloat("FillerMass", 0)
end

function Ammo.GetDisplayData(BulletData)
	local Energy = ACF_Kinetic(BulletData.MuzzleVel * 39.37, BulletData.FlechetteMass, BulletData.LimitVel)

	return {
		MaxPen = (Energy.Penetration / BulletData.FlechettePenArea) * ACF.KEtoRHA
	}
end


function Ammo.GetCrateText(BulletData)
	local Text = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nMax Spread: %s degrees"
	local Data = Ammo.GetDisplayData(BulletData)
	local Gun = ACF.Weapons.Guns[BulletData.Id]
	local Spread = 0

	if Gun then
		local GunClass = ACF.Classes.GunClass[Gun.gunclass]

		Spread = GunClass and (GunClass.spread * ACF.GunInaccuracyScale) or 0
	end

	return Text:format(math.Round(BulletData.MuzzleVel, 2), math.floor(Data.MaxPen), math.ceil((BulletData.FlechetteSpread + Spread) * 10) * 0.1)
end

function Ammo.CreateMenu(Panel, Table)
	acfmenupanel:AmmoSelect(Ammo.Blacklist)

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "") --Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "") --Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("Flechettes", 3, 3, 32, 0, "Flechettes", "") --flechette count Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FlechetteSpread", 10, 5, 60, 1, "Flechette Spread", "") --flechette spread Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("PenetrationDisplay", "") --Proj muzzle penetration (Name, Desc)

	Ammo.UpdateMenu(Panel, Table)
end

function Ammo.UpdateMenu(Panel)
	local PlayerData = {
		Id = acfmenupanel.AmmoData.Data.id, --AmmoSelect GUI
		Type = "FL", --Hardcoded, match ACFRoundTypes table index
		PropLength = acfmenupanel.AmmoData.PropLength, --PropLength slider
		ProjLength = acfmenupanel.AmmoData.ProjLength, --ProjLength slider
		Data5 = acfmenupanel.AmmoData.Flechettes, --Flechette count slider
		Data6 = acfmenupanel.AmmoData.FlechetteSpread, --flechette spread slider
		Data10 = acfmenupanel.AmmoData.Tracer and 1 or 0 -- Tracer
	}

	local Data = Ammo.Convert(Panel, PlayerData)

	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength) --For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength) --And Data4 total round mass
	RunConsoleCommand("acfmenu_data5", Data.Flechettes)
	RunConsoleCommand("acfmenu_data6", Data.FlechetteSpread)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("Flechettes", Data.Flechettes, Data.MinFlechettes, Data.MaxFlechettes, 0, "Flechettes", "Flechette Radius: " .. math.Round(Data.FlechetteRadius * 10, 2) .. " mm")
	acfmenupanel:AmmoSlider("FlechetteSpread", Data.FlechetteSpread, Data.MinSpread, Data.MaxSpread, 1, "Flechette Spread", "")
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", Ammo.Description) --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m/s") --Proj muzzle velocity (Name, Desc)

	local R1V, R1P = ACF_PenRanging(Data.MuzzleVel, Data.FlechetteDragCoef, Data.FlechetteMass, Data.FlechettePenArea, Data.LimitVel, 300)
	local R2V, R2P = ACF_PenRanging(Data.MuzzleVel, Data.FlechetteDragCoef, Data.FlechetteMass, Data.FlechettePenArea, Data.LimitVel, 800)

	acfmenupanel:CPanelText("PenetrationDisplay", "Maximum Penetration : " .. math.floor(Data.MaxPen) .. " mm RHA\n\n300m pen: " .. math.Round(R1P, 0) .. "mm @ " .. math.Round(R1V, 0) .. " m\\s\n800m pen: " .. math.Round(R2P, 0) .. "mm @ " .. math.Round(R2V, 0) .. " m\\s\n\nThe range data is an approximation and may not be entirely accurate.") --Proj muzzle penetration (Name, Desc)
end

function Ammo.MenuAction(Menu)
	Menu:AddParagraph("Testing FL menu.")
end

ACF.RegisterAmmoDecal("FL", "damage/ap_pen", "damage/ap_rico")