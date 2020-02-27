local Ammo = ACF.RegisterAmmoType("Refill", "AP")

function Ammo:OnLoaded()
	self.Name = "Refill"
	self.Description = "Ammunition refilling station."
	self.Unlistable = true
	self.Blacklist = {}
end

function Ammo.Convert(_, PlayerData)
	return {
		Id = PlayerData.Id,
		Type = PlayerData.Type,
		Caliber = ACF.Weapons.Guns[PlayerData.Id].caliber,
		ProjMass = 6 * 7.9 / 100, --Volume of the projectile as a cylinder * streamline factor (Data5) * density of steel
		PropMass = 6 * ACF.PDensity / 1000, --Volume of the case as a cylinder * Powder density converted from g to kg
		FillerMass = 0,
		DragCoef = 0,
		Tracer = 0,
		MuzzleVel = 0,
		RoundVolume = 36,
	}
end

function Ammo.Network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "Refill")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("FillerMass", BulletData.FillerMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Ammo.GetDisplayData()
	return {}
end

function Ammo.GetCrateText()
	return ""
end

function Ammo.CreateMenu(Panel, Table)
	acfmenupanel:AmmoSelect()

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)	

	Ammo.UpdateMenu(Panel, Table)
end

function Ammo.UpdateMenu()
	RunConsoleCommand("acfmenu_data1", acfmenupanel.CData.AmmoId or "12.7mmMG")
	RunConsoleCommand("acfmenu_data2", "Refill")

	acfmenupanel:CPanelText("Desc", Ammo.Description)

	acfmenupanel.CustomDisplay:PerformLayout()
end

function Ammo.MenuAction(Menu)
	Menu:AddParagraph("Testing Refill menu.")
end
