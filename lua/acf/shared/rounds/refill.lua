local Round = {}
Round.type = "Ammo" --Tells the spawn menu what entity to spawn
Round.name = "Refill" --Human readable name
Round.model = "models/munitions/round_100mm_shot.mdl" --Shell flight model
Round.desc = "Ammo Refill"

-- Function to convert the player's slider data into the complete round data
function Round.convert(_, PlayerData)
	local BulletData = {
		Id = PlayerData.Id,
		Type = PlayerData.Type,
		Caliber = ACF.Weapons.Guns[PlayerData.Id].caliber,
		ProjMass = 5.5 * 7.9 / 100, --Volume of the projectile as a cylinder * streamline factor (Data5) * density of steel
		PropMass = 5.5 * ACF.PDensity / 1000, --Volume of the case as a cylinder * Powder density converted from g to kg
		FillerMass = 0,
		DragCoef = 0,
		Tracer = 0,
		MuzzleVel = 0,
		RoundVolume = 35,
	}
	BulletData.CartMass = BulletData.PropMass + BulletData.ProjMass
	return BulletData
end

function Round.getDisplayData()
	return {}
end

function Round.network(Crate, BulletData)
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

function Round.cratetxt()
	return ""
end

function Round.guicreate(Panel, Table)
	acfmenupanel:AmmoSelect()
	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)		
	Round.guiupdate(Panel, Table)
end

function Round.guiupdate()
	RunConsoleCommand("acfmenu_data1", acfmenupanel.CData.AmmoId or "12.7mmMG")
	RunConsoleCommand("acfmenu_data2", "Refill")

	acfmenupanel:AmmoUpdate()
	acfmenupanel.CustomDisplay:PerformLayout()
end

ACF.RoundTypes.Refill = Round --Set the round properties
