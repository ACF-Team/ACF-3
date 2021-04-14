local Ammo = ACF.RegisterAmmoType("HEATFS", "HEAT")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "High Explosive Anti-Tank Fin Stabilized"
	self.Description = "An improved HEAT round with higher penetration and muzzle velocity."
	self.Blacklist = ACF.GetWeaponBlacklist({
		SB = true,
	})
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local MaxConeAng = math.deg(math.atan((Data.ProjLength - Data.Caliber * 0.02) / (Data.Caliber * 0.5)))
	local LinerAngle = math.Clamp(ToolData.LinerAngle, GUIData.MinConeAng, MaxConeAng)
	local _, ConeArea, AirVol = self:ConeCalc(LinerAngle, Data.Caliber * 0.5)

	local LinerRad    = math.rad(LinerAngle * 0.5)
	local SlugCaliber = Data.Caliber - Data.Caliber * (math.sin(LinerRad) * 0.5 + math.cos(LinerRad) * 1.5) * 0.5
	local SlugArea    = math.pi * (SlugCaliber * 0.5) ^ 2
	local ConeVol     = ConeArea * Data.Caliber * 0.02
	local ProjMass    = math.max(GUIData.ProjVolume - ToolData.FillerMass, 0) * 0.0079 + math.min(ToolData.FillerMass, GUIData.ProjVolume) * ACF.HEDensity + ConeVol * 0.0079 --Volume of the projectile as a cylinder - Volume of the filler - Volume of the crush cone * density of steel + Volume of the filler * density of TNT + Area of the cone * thickness * density of steel
	local MuzzleVel   = ACF.MuzzleVelocity(Data.PropMass, ProjMass, Data.Efficiency)
	local Energy      = ACF.Kinetic(MuzzleVel * 39.37, ProjMass)
	local MaxVol      = ACF.RoundShellCapacity(Energy.Momentum, Data.ProjArea, Data.Caliber, Data.ProjLength)

	GUIData.MaxConeAng   = MaxConeAng
	GUIData.MaxFillerVol = math.max(math.Round(MaxVol - AirVol - ConeVol, 2), GUIData.MinFillerVol)
	GUIData.FillerVol    = math.Clamp(ToolData.FillerMass, GUIData.MinFillerVol, GUIData.MaxFillerVol)

	Data.ConeAng        = LinerAngle
	Data.FillerMass     = GUIData.FillerVol * ACF.HEDensity
	Data.ProjMass       = math.max(GUIData.ProjVolume - GUIData.FillerVol - AirVol - ConeVol, 0) * 0.0079 + Data.FillerMass + ConeVol * 0.0079
	Data.MuzzleVel      = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency) * 1.25
	Data.SlugMass       = ConeVol * 0.0079
	Data.SlugCaliber    = SlugCaliber
	Data.SlugDragCoef   = SlugArea * 0.0001 / Data.SlugMass
	Data.BoomFillerMass	= Data.FillerMass * ACF.HEATBoomConvert
	Data.HEATFillerMass = Data.FillerMass * (1 - ACF.HEATBoomConvert)
	Data.SlugMV			= self:CalcSlugMV(Data)
	Data.CasingMass		= Data.ProjMass - Data.FillerMass - ConeVol * 0.0079
	Data.DragCoef		= Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass		= Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

if SERVER then
	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "HEATFS")
	end
else
	ACF.RegisterAmmoDecal("HEATFS", "damage/heat_pen", "damage/heat_rico", function(Caliber) return Caliber * 0.1667 end)
end
