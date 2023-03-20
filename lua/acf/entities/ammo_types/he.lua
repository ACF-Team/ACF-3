local ACF   = ACF
local Types = ACF.Classes.AmmoTypes
local Ammo  = Types.Register("HE", "APHE")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "High Explosive"
	self.Description = "A shell filled with explosives, detonates on impact."
	self.Blacklist = {
		MG = true,
		RAC = true,
	}
end

function Ammo:GetPenetration()
	return 0
end

function Ammo:GetDisplayData(Data)
	local FragMass	= Data.ProjMass - Data.FillerMass
	local Fragments	= math.max(math.floor((Data.FillerMass / FragMass) * ACF.HEFrag), 2)
	local Display   = {
		BlastRadius = Data.FillerMass ^ 0.33 * 8,
		Fragments   = Fragments,
		FragMass    = FragMass / Fragments,
		FragVel     = (Data.FillerMass * ACF.HEPower * 1000 / (FragMass / Fragments) / Fragments) ^ 0.5,
	}

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

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinFillerVol = 0

	Data.ShovePower		= 0.1
	Data.LimitVel		= 100 --Most efficient penetration speed in m/s
	Data.Ricochet		= 60 --Base ricochet angle
	Data.DetonatorAngle	= 80
	Data.CanFuze		= Data.Caliber * 10 > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

if SERVER then
	local Ballistics = ACF.Ballistics

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "HE")
	end

	function Ammo:GetCrateText(BulletData)
		local Text = "Muzzle Velocity: %s m/s\nBlast Radius: %s m\nBlast Energy: %s KJ"
		local Data = self:GetDisplayData(BulletData)

		return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.BlastRadius, 2), math.Round(BulletData.FillerMass * ACF.HEPower, 2))
	end

	function Ammo:PropImpact(Bullet, Trace)
		if ACF.Check(Trace.Entity) then
			local Speed  = Bullet.Flight:Length() / ACF.Scale
			local Energy = ACF.Kinetic(Speed, Bullet.ProjMass)

			Bullet.Speed  = Speed
			Bullet.Energy = Energy

			local HitRes = Ballistics.DoRoundImpact(Bullet, Trace)

			if HitRes.Ricochet then return "Ricochet" end
		end

		return false
	end

	function Ammo:WorldImpact()
		return false
	end
else
	ACF.RegisterAmmoDecal("HE", "damage/he_pen", "damage/he_rico")

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
	end
end