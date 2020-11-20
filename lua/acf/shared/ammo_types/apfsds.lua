local Ammo = ACF.RegisterAmmoType("APFSDS", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing Fin Stabilized"
	self.Model		 = "models/munitions/dart_100mm.mdl"
	self.Description = "A fin stabilized sabot munition designed to trade damage for superior penetration and long range effectiveness."
	self.Blacklist = ACF.GetWeaponBlacklist({
		SB = true,
	})
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local Cylinder  = (3.1416 * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.25 -- A cylinder 1/4 the length of the projectile
	local Hole		= Data.RoundArea * Data.ProjLength * 0.25 -- Volume removed by the hole the dart passes through
	local SabotMass = (Cylinder - Hole) * 2.7 * 0.25 * 0.001 -- A cylinder with a hole the size of the dart in it and im no math wizard so we're just going to take off 3/4 of the mass for the cutout since sabots are shaped like this: ][

	Data.ProjMass  = (Data.RoundArea * 0.6666) * (Data.ProjLength * 0.0079) -- Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass)
	Data.DragCoef  = Data.FrArea * 0.0001 / Data.ProjMass
	Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})
	local SubCaliberRatio = 0.29 -- Ratio of projectile to gun caliber
	local Area = 3.1416 * (Data.Caliber * 0.5 * SubCaliberRatio) ^ 2

	Data.RoundArea	 = Area
	Data.ShovePower	 = 0.2
	Data.PenArea	 = Area ^ ACF.PenAreaMod
	Data.LimitVel	 = 1000 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet	 = 80 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

if SERVER then
	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APFSDS")
	end
else
	ACF.RegisterAmmoDecal("APFSDS", "damage/apcr_pen", "damage/apcr_rico")
end
