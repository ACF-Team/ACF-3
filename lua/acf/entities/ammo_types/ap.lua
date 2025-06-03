local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local Ammo      = AmmoTypes.Register("AP")


function Ammo:OnLoaded()
	self.Name		 = "Armor Piercing"
	self.Model		 = "models/munitions/round_100mm_ap_shot.mdl"
	self.Description = "#acf.descs.ammo.ap"
	self.Blacklist = {
		GL = true,
		SL = true,
	}
end

function Ammo:GetPenetration(Bullet, Speed)
	if not isnumber(Speed) then
		Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * ACF.InchToMeter or Bullet.MuzzleVel
	end

	return ACF.Penetration(Speed, Bullet.ProjMass, Bullet.Diameter * 10)
end

function Ammo:GetDisplayData(Data)
	local Display = {
		MaxPen = self:GetPenetration(Data, Data.MuzzleVel)
	}

	hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	Data.ProjMass   = Data.ProjArea * Data.ProjLength * ACF.SteelDensity --Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel  = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass   = Data.PropMass + Data.ProjMass

	hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	Data.ShovePower = 0.2
	Data.LimitVel   = 800 --Most efficient penetration speed in m/s
	Data.Ricochet   = 60 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	if not isnumber(ToolData.Projectile) then
		ToolData.Projectile = ACF.CheckNumber(ToolData.RoundProjectile, 0)
	end

	if not isnumber(ToolData.Propellant) then
		ToolData.Propellant = ACF.CheckNumber(ToolData.RoundPropellant, 0)
	end

	if ToolData.Tracer == nil then
		local Data10 = ToolData.RoundData10

		ToolData.Tracer = Data10 and tobool(tonumber(Data10)) or false -- Haha "0.00" is true but 0 isn't
	end
end

if SERVER then
	local Ballistics = ACF.Ballistics
	local Entities   = Classes.Entities

	Entities.AddArguments("acf_ammo", "Projectile", "Propellant", "Tracer") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Entity.Projectile = nil
		Entity.Propellant = nil
		Entity.Tracer = nil

		-- Cleanup the leftovers aswell
		Entity.RoundProjectile = nil
		Entity.RoundPropellant = nil
		Entity.RoundData10 = nil
	end

	function Ammo:Create(_, BulletData)
		Ballistics.CreateBullet(BulletData)
	end

	function Ammo:ServerConvert(ToolData)
		self:VerifyData(ToolData)

		local Data = self:BaseConvert(ToolData)

		Data.Id = ToolData.Weapon
		Data.Type = ToolData.AmmoType

		return Data
	end

	function Ammo:Network(Entity, BulletData)
		Entity:SetNW2String("AmmoType", "AP")
		Entity:SetNW2Float("Caliber", BulletData.Caliber)
		Entity:SetNW2Float("ProjMass", BulletData.ProjMass)
		Entity:SetNW2Float("PropMass", BulletData.PropMass)
		Entity:SetNW2Float("DragCoef", BulletData.DragCoef)
		Entity:SetNW2Float("Tracer", BulletData.Tracer)
	end

	function Ammo:GetCrateName()
	end

	function Ammo:GetCrateText(BulletData)
		local Data = self:GetDisplayData(BulletData)
		local Text = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm"

		return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.MaxPen, 2))
	end

	function Ammo:PropImpact(Bullet, Trace)
		local Target = Trace.Entity
		local Filter = Bullet.Filter

		if ACF.Check(Target) then
			local Speed  = Bullet.Flight:Length() / ACF.Scale
			local Energy = ACF.Kinetic(Speed, Bullet.ProjMass)

			Bullet.Speed  = Speed
			Bullet.Energy = Energy

			local HitRes = Ballistics.DoRoundImpact(Bullet, Trace)

			if HitRes.Overkill > 0 then
				table.insert(Filter, Target) --"Penetrate" (Ingoring the prop for the retry trace)

				Bullet.Flight = Bullet.Flight:GetNormalized() * (Energy.Kinetic * (1 - HitRes.Loss) * 2000 / Bullet.ProjMass) ^ 0.5 * ACF.MeterToInch

				return "Penetrated"
			elseif HitRes.Ricochet then
				return "Ricochet"
			else
				return false
			end
		else
			table.insert(Filter, Target)

			return "Penetrated"
		end
	end

	function Ammo:WorldImpact(Bullet, Trace)
		if ACF.Check(Trace.Entity) then
			return Ballistics.PenetrateMapEntity(Bullet, Trace)
		else
			return Ballistics.PenetrateGround(Bullet, Trace)
		end
	end

	function Ammo:OnFlightEnd(Bullet)
		Ballistics.RemoveBullet(Bullet)
	end
else
	local Effects = ACF.Utilities.Effects

	ACF.RegisterAmmoDecal("AP", "damage/ap_pen", "damage/ap_rico")

	local DecalIndex = ACF.GetAmmoDecalIndex

	function Ammo:ClientConvert(ToolData)
		self:VerifyData(ToolData)

		local Data, GUIData = self:BaseConvert(ToolData)

		if GUIData then
			for K, V in pairs(GUIData) do
				Data[K] = V
			end
		end

		return Data
	end

	function Ammo:GetRangedPenetration(Bullet, Range)
		local Speed = ACF.GetRangedSpeed(Bullet.MuzzleVel, Bullet.DragCoef, Range) * ACF.InchToMeter

		return math.Round(self:GetPenetration(Bullet, Speed), 2), math.Round(Speed, 2)
	end

	function Ammo:OnCreateAmmoPreview(_, Setup)
		Setup.Model = self.Model
		Setup.FOV   = 60
	end

	function Ammo:ImpactEffect(_, Bullet)
		local EffectTable = {
			Origin = Bullet.SimPos,
			Normal = Bullet.SimFlight:GetNormalized(),
			Radius = Bullet.Caliber,
			DamageType = DecalIndex(Bullet.AmmoType),
		}

		Effects.CreateEffect("ACF_Impact", EffectTable)
	end

	function Ammo:PenetrationEffect(_, Bullet)
		local EffectTable = {
			Origin = Bullet.SimPos,
			Normal = Bullet.SimFlight:GetNormalized(),
			Scale = Bullet.SimFlight:Length(),
			Magnitude = Bullet.RoundMass,
			Radius = Bullet.Caliber,
			DamageType = DecalIndex(Bullet.AmmoType),
		}

		Effects.CreateEffect("ACF_Penetration", EffectTable)
	end

	function Ammo:RicochetEffect(_, Bullet)
		local EffectTable = {
			Origin = Bullet.SimPos,
			Normal = Bullet.SimFlight:GetNormalized(),
			Scale = Bullet.SimFlight:Length(),
			Magnitude = Bullet.RoundMass,
			Radius = Bullet.Caliber,
			DamageType = DecalIndex(Bullet.AmmoType),
		}

		Effects.CreateEffect("ACF_Ricochet", EffectTable)
	end

	function Ammo:OnCreateCrateInformation(_, Label)
		Label:TrackClientData("Projectile")
		Label:TrackClientData("Propellant")
	end

	function Ammo:OnCreateAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= language.GetPhrase("acf.menu.ammo.round_stats_ap")
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
			local PropMass	= ACF.GetProperMass(BulletData.PropMass)

			return Text:format(MuzzleVel, ProjMass, PropMass)
		end)

		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text     = language.GetPhrase("acf.menu.ammo.pen_stats_ap")
			local MaxPen   = math.Round(BulletData.MaxPen, 2)
			local R1P, R1V = self:GetRangedPenetration(BulletData, 300)
			local R2P, R2V = self:GetRangedPenetration(BulletData, 800)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Base:AddLabel("#acf.menu.ammo.approx_pen_warning")
	end
end
