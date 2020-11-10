local Ammo = ACF.RegisterAmmoType("APCR", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing Composite Rigid"
	self.Description = "A hardened core munition designed for weapons in the 1940s."
	self.Blacklist = ACF.GetWeaponBlacklist({
		AL = true,
		AC = true,
		SA = true,
		SC = true,
		C = true,
	})
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	Data.ProjMass  = (Data.FrArea * 1.1111) * (Data.ProjLength * 0.0079) * 0.75 --Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.DragCoef  = (Data.FrArea * 0.000125) / Data.ProjMass -- Worse drag (Manually fudged to make a meaningful difference)
	Data.CartMass  = Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	Data.ShovePower	 = 0.2
	Data.PenArea	 = (Data.FrArea * 0.7) ^ ACF.PenAreaMod -- APCR has a smaller penetrator
	Data.LimitVel	 = 900 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet	 = 55 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

if SERVER then
	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APCR")
	end
else
	ACF.RegisterAmmoDecal("APCR", "damage/apcr_pen", "damage/apcr_rico")
end
