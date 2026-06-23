local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.APCR", "ACF.Ammunition.AP", function()
	local BASE = BASE

	CLASS.Name		 = "Armor Piercing Composite Rigid"
	CLASS.SpawnIcon   = "acf/icons/shell_apcr.png"
	CLASS.Bodygroup   = 2 -- APCR bodygroup index
	CLASS.Description = "#acf.descs.ammo.apcr"
	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		C = true,
		AL = true,
		AC = true,
		SA = true,
		SC = true,
		LAC = true,
		RAC = true,
	})

	function CLASS:UpdateRoundData(ToolData, Data, GUIData)
		GUIData = GUIData or Data

		ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

		Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.SteelDensity --Volume of the projectile as a cylinder * density of steel (kg/in3)
		Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.DragCoef  = Data.ProjArea * 0.0001 / Data.ProjMass
		Data.CartMass  = Data.PropMass + Data.ProjMass

		hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert(ToolData)
		local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { ProjScale = 0.75 }) -- APCR has a smaller penetrator

		Data.ShovePower = 0.2
		Data.LimitVel   = 900 --Most efficient penetration speed in m/s
		Data.Ricochet   = 55 --Base ricochet angle

		self:UpdateRoundData(ToolData, Data, GUIData)

		return Data, GUIData
	end

	if SERVER then
		local Conversion	= ACF.PointConversion

		-- Since APCR
		function CLASS:GetCost(BulletData)
			return (BulletData.ProjMass * Conversion.Steel * 2.5) + (BulletData.PropMass * Conversion.Propellant)
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APCR")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APCR", "damage/apcr_pen", "damage/apcr_rico")
	end
end)