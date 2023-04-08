local ACF   = ACF
local Types = ACF.Classes.AmmoTypes
local Ammo  = Types.Register("APFSDS", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing Fin Stabilized"
	self.Model		 = "models/munitions/dart_100mm.mdl"
	self.Description = "A fin stabilized sabot munition designed to trade damage for superior penetration and long range effectiveness."
	self.Blacklist = ACF.GetWeaponBlacklist({
		C = true,
		AC = true,
		AL = true,
		SA = true,
		SC = true,
	})
end

-- Long rod penetrators are different, so we'll use Lanz Odermatt Penetration Equation with them
-- See: http://www.longrods.ch/perfeq.php
-- Speed is on m/s
-- Returns penetration in mm
-- NOTE: This assume we're hitting a RHA plate at 0°
function Ammo:GetPenetration(Bullet, Speed)
	if not isnumber(Speed) then
		Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * 0.0254 or Bullet.MuzzleVel
	end

	Speed = Speed * 0.001 -- From m/s to km/s

	local RoundLength   = Bullet.ProjLength * 10 -- From cm to mm
	local RoundCaliber  = Bullet.Diameter * 10 -- From cm to mm
	local RoundBrinell  = 294
	local RoundDensity  = 19250 -- in kg/m3
	local TargetBrinell = 237 -- Assuming we're hitting RHA
	local TargetDensity = 7840 -- Assuming we're hitting RHA
	local Constant      = 1.104 -- Steel specific constant
	local S2            = 9874 * TargetBrinell ^ 0.3598 * RoundBrinell ^ -0.2342 / RoundDensity

	local FirstChunk    = 1 / math.tanh(0.283 + 0.0656 * RoundLength / RoundCaliber)
	local SecondChunk   = (RoundDensity / TargetDensity) ^ 0.5
	local ThirdChunk    = math.exp(-S2 / (Speed * Speed))

	return Constant * FirstChunk * SecondChunk * ThirdChunk * RoundLength
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local Cylinder  = (math.pi * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.25 -- A cylinder 1/4 the length of the projectile
	local Hole		= Data.ProjArea * Data.ProjLength * 0.25 -- Volume removed by the hole the dart passes through
	local SabotMass = (Cylinder - Hole) * ACF.AluminumDensity -- A cylinder with a hole the size of the dart in it and im no math wizard so we're just going to take off 3/4 of the mass for the cutout since sabots are shaped like this: ][

	Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.SteelDensity -- Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass, Data.Efficiency)
	Data.DragCoef  = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { ProjScale = 0.35 })

	Data.ShovePower = 0.2
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
