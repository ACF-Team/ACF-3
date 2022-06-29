local ACF   = ACF
local Types = ACF.Classes.AmmoTypes
local Ammo  = Types.Register("APDS", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing Discarding Sabot"
	self.Description = "A subcaliber munition designed to trade damage for penetration. Loses energy quickly over distance."
	self.Blacklist = ACF.GetWeaponBlacklist({
		C = true,
		AL = true,
		AC = true,
		SA = true,
		RAC = true,
	})
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local Cylinder  = (math.pi * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.5 -- A cylinder 1/2 the length of the projectile
	local Hole		= Data.ProjArea * Data.ProjLength * 0.5 -- Volume removed by the hole the dart passes through
	local SabotMass = (Cylinder - Hole) * ACF.AluminumDensity -- Aluminum sabot

	Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.SteelDensity -- Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass, Data.Efficiency)
	Data.DragCoef  = Data.ProjArea * 0.000125 / Data.ProjMass -- Worse drag (Manually fudged to make a meaningful difference)
	Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { ProjScale = 0.45 }) -- Ratio of projectile to gun caliber

	Data.ShovePower = 0.2
	Data.LimitVel   = 950 --Most efficient penetration speed in m/s
	Data.Ricochet   = 80 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

if SERVER then
	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APDS")
	end
else
	ACF.RegisterAmmoDecal("APDS", "damage/apcr_pen", "damage/apcr_rico")
end
