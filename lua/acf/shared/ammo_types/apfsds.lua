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

	local Cylinder  = (math.pi * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.25 -- A cylinder 1/4 the length of the projectile
	local Hole		= Data.ProjArea * Data.ProjLength * 0.25 -- Volume removed by the hole the dart passes through
	local SabotMass = (Cylinder - Hole) * 0.0027 -- A cylinder with a hole the size of the dart in it and im no math wizard so we're just going to take off 3/4 of the mass for the cutout since sabots are shaped like this: ][

	Data.ProjMass  = Data.ProjArea * Data.ProjLength * 0.0079 -- Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass)
	Data.DragCoef  = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { ProjScale = 0.35, PropScale = 0.85 })

	Data.ShovePower = 0.2
	Data.PenArea    = Data.ProjArea ^ ACF.PenAreaMod
	Data.LimitVel   = 1000 --Most efficient penetration speed in m/s
	Data.Ricochet   = 80 --Base ricochet angle

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
