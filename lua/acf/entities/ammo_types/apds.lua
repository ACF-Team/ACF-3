local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.APDS", "ACF.Ammunition.AP", function()
	local BASE = BASE

	CLASS.Name		 = "Armor Piercing Discarding Sabot"
	CLASS.SpawnIcon   = "acf/icons/shell_apds.png"
	CLASS.Bodygroup   = 3 -- APDS bodygroup index
	CLASS.Description = "#acf.descs.ammo.apds"
	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.Cannon"] = true,
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.SemiautomaticCannon"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
	})

	function CLASS:UpdateRoundData(Data, GUIData)
		GUIData = GUIData or Data

		ACF.UpdateRoundSpecs(self, Data, GUIData)

		local Cylinder  = (math.pi * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.5 -- A cylinder 1/2 the length of the projectile
		local Hole		= Data.ProjArea * Data.ProjLength * 0.5 -- Volume removed by the hole the dart passes through
		local SabotMass = (Cylinder - Hole) * ACF.AluminumDensity -- Aluminum sabot

		Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.SteelDensity -- Volume of the projectile as a cylinder * density of steel
		Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass, Data.Efficiency)
		Data.DragCoef  = Data.ProjArea * 0.000125 / Data.ProjMass -- Worse drag (Manually fudged to make a meaningful difference)
		Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert()
		local Data, GUIData = ACF.RoundBaseGunpowder(self, { ProjScale = 0.45 }) -- Ratio of projectile to gun caliber

		Data.ShovePower = 0.2
		Data.LimitVel   = 950 --Most efficient penetration speed in m/s
		Data.Ricochet   = 80 --Base ricochet angle

		self:UpdateRoundData(Data, GUIData)

		return Data, GUIData
	end

	if SERVER then
		local Conversion	= ACF.PointConversion

		function CLASS:GetCost(BulletData)
			local SabotMass	= BulletData.CartMass - BulletData.PropMass - BulletData.ProjMass

			return (BulletData.ProjMass * Conversion.Steel * 6) + (BulletData.PropMass * Conversion.Propellant) + (SabotMass * Conversion.Aluminum)
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APDS")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APDS", "damage/apcr_pen", "damage/apcr_rico")
	end

end)