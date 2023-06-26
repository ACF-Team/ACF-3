local ACF       = ACF
local Classes   = ACF.Classes
local Damage    = ACF.Damage
local AmmoTypes = Classes.AmmoTypes
local Ammo      = AmmoTypes.Register("APHE", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing High Explosive"
	self.Description = "Less capable armor piercing round with an explosive charge inside."
	self.Blacklist = {
		GL = true,
		MG = true,
		SL = true,
		RAC = true,
	}
end

function Ammo:GetPenetration(Bullet, Speed)
	if not isnumber(Speed) then
		Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * 0.0254 or Bullet.MuzzleVel
	end

	return ACF.Penetration(Speed, Bullet.ProjMass, Bullet.Diameter * 10) * (1 - Bullet.FillerRatio)
end

function Ammo:GetDisplayData(Data)
	local Display  = Ammo.BaseClass.GetDisplayData(self, Data)
	local FragMass = Data.ProjMass - Data.FillerMass

	Display.BlastRadius = Data.FillerMass ^ 0.33 * 8
	Display.Fragments   = math.max(math.floor((Data.FillerMass / FragMass) * ACF.HEFrag), 2)
	Display.FragMass    = FragMass / Display.Fragments
	Display.FragVel     = (Data.FillerMass * ACF.HEPower * 1000 / Display.FragMass / Display.Fragments) ^ 0.5

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local FreeVol   = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	local FillerVol = FreeVol * math.Clamp(ToolData.FillerRatio, 0, 1)

	Data.FillerMass = FillerVol * ACF.HEDensity
	Data.ProjMass   = math.max(GUIData.ProjVolume - FillerVol, 0) * ACF.SteelDensity + Data.FillerMass
	Data.MuzzleVel  = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass   = Data.PropMass + Data.ProjMass
	Data.FillerRatio = math.Clamp(ToolData.FillerRatio, 0, 1)

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	Data.ShovePower = 0.1
	Data.LimitVel   = 700 --Most efficient penetration speed in m/s
	Data.Ricochet   = 65 --Base ricochet angle
	Data.CanFuze    = Data.Caliber * 10 > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

	GUIData.MinFillerVol = 0

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not isnumber(ToolData.FillerRatio) then
		ToolData.FillerRatio = 1
	end
end

if SERVER then
	local Entities = Classes.Entities
	local Objects  = Damage.Objects

	Entities.AddArguments("acf_ammo", "FillerRatio") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.FillerRatio = nil

		-- Cleanup the leftovers aswell
		Entity.FillerMass  = nil
		Entity.RoundData5  = nil

		Entity:SetNW2Float("FillerMass", 0)
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APHE")
		Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
	end

	function Ammo:GetCrateText(BulletData)
		local BaseText = Ammo.BaseClass.GetCrateText(self, BulletData)
		local Text	   = BaseText .. "\nBlast Radius: %s m\nBlast Energy: %s KJ"
		local Data	   = self:GetDisplayData(BulletData)

		return Text:format(math.Round(Data.BlastRadius, 2), math.Round(BulletData.FillerMass * ACF.HEPower, 2))
	end

	function Ammo:OnFlightEnd(Bullet, Trace)
		if not Bullet.DetByFuze then
			local Offset = Bullet.ProjLength * 0.39 * 0.5 -- Pulling the explosion back by half of the projectiles length

			Bullet.Pos = Trace.HitPos - Bullet.Flight:GetNormalized() * Offset
		end

		local Position = Bullet.Pos
		local Filler   = Bullet.FillerMass
		local Fragment = Bullet.ProjMass - Filler
		local DmgInfo  = Objects.DamageInfo(Bullet.Owner, Bullet.Gun)

		Damage.createExplosion(Position, Filler, Fragment, nil, DmgInfo)

		Ammo.BaseClass.OnFlightEnd(self, Bullet, Trace)
	end
else
	ACF.RegisterAmmoDecal("APHE", "damage/ap_pen", "damage/ap_rico")

	function Ammo:ImpactEffect(_, Bullet)
		local Position  = Bullet.SimPos
		local Direction = Bullet.SimFlight
		local Filler    = Bullet.FillerMass

		Damage.explosionEffect(Position, Direction, Filler)
	end

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local FillerRatio = Base:AddSlider("Filler Ratio", 0, 1, 2)
		FillerRatio:SetClientData("FillerRatio", "OnValueChanged")
		FillerRatio:DefineSetter(function(_, _, _, Value)
			ToolData.FillerRatio = math.Round(Value, 2)

			self:UpdateRoundData(ToolData, BulletData)

			return BulletData.FillerVol
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.FillerRatio = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("FillerRatio")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s\nExplosive Mass : %s"
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
			local PropMass	= ACF.GetProperMass(BulletData.PropMass)
			local Filler	= ACF.GetProperMass(BulletData.FillerMass)

			return Text:format(MuzzleVel, ProjMass, PropMass, Filler)
		end)

		local FillerStats = Base:AddLabel()
		FillerStats:TrackClientData("FillerRatio", "SetText")
		FillerStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Blast Radius : %s m\nFragments : %s\nFragment Mass : %s\nFragment Velocity : %s m/s"
			local Blast	   = math.Round(BulletData.BlastRadius, 2)
			local FragMass = ACF.GetProperMass(BulletData.FragMass)
			local FragVel  = math.Round(BulletData.FragVel, 2)

			return Text:format(Blast, BulletData.Fragments, FragMass, FragVel)
		end)

		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("FillerRatio")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text     = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen   = math.Round(BulletData.MaxPen, 2)
			local R1P, R1V = self:GetRangedPenetration(BulletData, 300)
			local R2V, R2P = self:GetRangedPenetration(BulletData, 800)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Base:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end