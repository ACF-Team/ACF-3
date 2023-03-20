local ACF   = ACF
local Types = ACF.Classes.AmmoTypes
local Ammo  = Types.Register("HEATFS", "HEAT")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "High Explosive Anti-Tank Fin Stabilized"
	self.Description = "An improved HEAT round with better standoff and explosive power."
	self.Blacklist = ACF.GetWeaponBlacklist({
		C = true,
		M = true,
		AL = true,
		HW = true,
		SC = true,
	})
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local CapLength       = GUIData.MinProjLength * 0.5
	local BodyLength      = Data.ProjLength - CapLength
	local FreeVol, FreeLength, FreeRadius = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, BodyLength)
	local Standoff        = (CapLength + FreeLength * ToolData.StandoffRatio) * 1e-2 -- cm to m
	local WarheadVol      = FreeVol * (1 - ToolData.StandoffRatio)
	local WarheadLength   = FreeLength * (1 - ToolData.StandoffRatio)
	local WarheadDiameter = 2 * FreeRadius
	local MinConeAng      = math.deg(math.atan(FreeRadius / WarheadLength))
	local LinerAngle      = math.Clamp(ToolData.LinerAngle, MinConeAng, 90) -- Cone angle is angle between cone walls, not between a wall and the center line
	local LinerMass, ConeVol, ConeLength = self:ConeCalc(LinerAngle, FreeRadius)

	-- Charge length increases jet velocity, but with diminishing returns. All explosive sorrounding the cone has 100% effectiveness,
	--  but the explosive behind it sees it reduced. Most papers put the maximum useful head length (explosive length behind the
	--  cone) at around 1.5-1.8 times the charge's diameter. Past that, adding more explosive won't do much.
	local RearFillLen  = WarheadLength - ConeLength  -- Length of explosive behind the liner
	local Exponential  = math.exp(2 * RearFillLen / (WarheadDiameter * ACF.MaxChargeHeadLen))
	local EquivFillLen = WarheadDiameter * ACF.MaxChargeHeadLen * ((Exponential - 1) / (Exponential + 1)) -- Equivalent length of explosive
	local FrontFillVol = WarheadVol * ConeLength / WarheadLength - ConeVol -- Volume of explosive sorounding the liner
	local RearFillVol  = WarheadVol * RearFillLen / WarheadLength -- Volume behind the liner
	local EquivFillVol = WarheadVol * EquivFillLen / WarheadLength + FrontFillVol -- Equivalent total explosive volume
	local LengthPct    = Data.ProjLength / (Data.Caliber * 7.8)
	local OverEnergy   = math.min(math.Remap(LengthPct, 0.6, 1, 1, 0.3), 1) -- Excess explosive power makes the jet lose velocity
	local FillerEnergy = OverEnergy * EquivFillVol * ACF.OctolDensity * 1e3 * ACF.TNTPower * ACF.OctolEquivalent * ACF.HEATEfficiency
	local FillerVol    = FrontFillVol + RearFillVol
	local FillerMass   = FillerVol * ACF.OctolDensity

	-- At lower cone angles, the explosive crushes the cone inward, expelling a jet. The steeper the cone, the faster the jet, but the less mass expelled
	local MinVelMult = math.Remap(LinerAngle, 0, 90, 0.5, 0.99)
	local JetMass    = LinerMass * math.Remap(LinerAngle, 0, 90, 0.25, 1)
	local JetAvgVel  = (2 * FillerEnergy / JetMass) ^ 0.5  -- Average velocity of the copper jet
	local JetMinVel  = JetAvgVel * MinVelMult              -- Minimum velocity of the jet (the rear)
	-- Calculates the maximum velocity, considering the velocity distribution is linear from the rear to the tip (integrated this by hand, pain :) )
	local JetMaxVel  = 0.5 * (3 ^ 0.5 * (8 * FillerEnergy - JetMass * JetMinVel ^ 2) ^ 0.5 / JetMass ^ 0.5 - JetMinVel) -- Maximum velocity of the jet (the tip)

	-- Both the "magic numbers" are unitless, tuning constants that were used to fit the breakup time to real world values, I suggest they not be messed with
	local BreakupTime    = 2.6e-6 * (5e9 * JetMass / (JetMaxVel - JetMinVel)) ^ 0.3333  -- Jet breakup time in seconds
	local BreakupDist    = JetMaxVel * BreakupTime

	GUIData.MinConeAng = MinConeAng

	Data.ConeAng        = LinerAngle
	Data.MinConeAng     = MinConeAng
	Data.FillerMass     = FillerMass
	local NonCasingVol  = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	Data.CasingMass		= (GUIData.ProjVolume - NonCasingVol) * ACF.SteelDensity
	Data.ProjMass       = Data.FillerMass + Data.CasingMass + LinerMass
	Data.MuzzleVel      = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.BoomFillerMass	= Data.FillerMass * ACF.HEATBoomConvert * ACF.OctolEquivalent -- In TNT equivalent
	Data.LinerMass      = LinerMass
	Data.JetMass        = JetMass
	Data.JetMinVel      = JetMinVel
	Data.JetMaxVel      = JetMaxVel
	Data.BreakupTime    = BreakupTime
	Data.Standoff       = Standoff
	Data.BreakupDist    = BreakupDist
	Data.DragCoef		= Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass		= Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	-- Recalculate the standoff for missiles
	if Data.MissileStandoff then
		Data.Standoff = (FreeLength * ToolData.StandoffRatio + Data.MissileStandoff) * 1e-2
	end
	-- God weeped when this spaghetto was written (for missile roundinject)
	if Data.FillerMul or Data.LinerMassMul then
		local LinerMassMul = Data.LinerMassMul or 1
		Data.LinerMass     = LinerMass * LinerMassMul
		local FillerMul    = Data.FillerMul or 1
		Data.FillerEnergy  = OverEnergy * EquivFillVol * ACF.CompBDensity * 1e3 * ACF.TNTPower * ACF.CompBEquivalent * ACF.HEATEfficiency * FillerMul
		local _FillerEnergy = Data.FillerEnergy
		local _LinerAngle   = Data.ConeAng
		local _MinVelMult   = math.Remap(_LinerAngle, 0, 90, 0.5, 0.99)
		local _JetMass      = LinerMass * math.Remap(_LinerAngle, 0, 90, 0.25, 1)
		local _JetAvgVel    = (2 * _FillerEnergy / _JetMass) ^ 0.5
		local _JetMinVel    = _JetAvgVel * _MinVelMult
		local _JetMaxVel    = 0.5 * (3 ^ 0.5 * (8 * _FillerEnergy - _JetMass * _JetMinVel ^ 2) ^ 0.5 / _JetMass ^ 0.5 - JetMinVel)
		Data.BreakupTime   = 1.6e-6 * (5e9 * _JetMass / (_JetMaxVel - _JetMinVel)) ^ 0.3333
		Data.BreakupDist   = _JetMaxVel * Data.BreakupTime
		Data.JetMass       = _JetMass
		Data.JetMinVel     = _JetMinVel
		Data.JetMaxVel     = _JetMaxVel
	end

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

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local LinerAngle = Base:AddSlider("Liner Angle", BulletData.MinConeAng, 90, 1)
		LinerAngle:SetClientData("LinerAngle", "OnValueChanged")
		LinerAngle:TrackClientData("Projectile")
		LinerAngle:DefineSetter(function(Panel, _, Key, Value)
			if Key == "LinerAngle" then
				ToolData.LinerAngle = math.Round(Value, 2)
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMin(BulletData.MinConeAng)
			Panel:SetValue(BulletData.ConeAng)

			return BulletData.ConeAng
		end)

		local StandoffRatio = Base:AddSlider("Extra Standoff Ratio", 0, 0.75, 2)
		StandoffRatio:SetClientData("StandoffRatio", "OnValueChanged")
		StandoffRatio:DefineSetter(function(_, _, _, Value)
			ToolData.StandoffRatio = math.Round(Value, 2)

			self:UpdateRoundData(ToolData, BulletData)

			return ToolData.StandoffRatio
		end)
	end
end
