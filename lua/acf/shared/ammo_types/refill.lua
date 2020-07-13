local Ammo = ACF.RegisterAmmoType("Refill", "AP")

function Ammo:OnLoaded()
	self.Name				= "Refill"
	self.Description		= "Provides supplies to other ammo crates."
	self.Blacklist			= {}
	self.SupressDefaultMenu	= true
end

function Ammo:BaseConvert(_, ToolData)
	local Class = ACF.Classes.Weapons[ToolData.WeaponClass]
	local Weapon = Class and Class.Items[ToolData.Weapon]

	return {
		Id			= ToolData.Weapon,
		Type		= ToolData.Ammo,
		Caliber		= Weapon and Weapon.Caliber or 12.7,
		ProjMass	= 6 * 0.079, --Volume of the projectile as a cylinder * streamline factor (Data5) * density of steel
		PropMass	= 6 * ACF.PDensity * 0.001, --Volume of the case as a cylinder * Powder density converted from g to kg
		FillerMass	= 0,
		DragCoef	= 0,
		Tracer		= 0,
		MuzzleVel	= 0,
		RoundVolume	= 36,
	}
end

function Ammo:Network(Crate, BulletData)
	Crate:SetNW2String("AmmoType", "Refill")
	Crate:SetNW2String("AmmoID", BulletData.Id)
	Crate:SetNW2Float("Caliber", BulletData.Caliber)
	Crate:SetNW2Float("ProjMass", BulletData.ProjMass)
	Crate:SetNW2Float("FillerMass", BulletData.FillerMass)
	Crate:SetNW2Float("PropMass", BulletData.PropMass)
	Crate:SetNW2Float("DragCoef", BulletData.DragCoef)
	Crate:SetNW2Float("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNW2Float("Tracer", BulletData.Tracer)
end

function Ammo:GetDisplayData()
	return {}
end

function Ammo:GetCrateText()
	return ""
end

function Ammo:MenuAction()
end
