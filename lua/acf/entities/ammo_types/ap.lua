local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local Ammo      = AmmoTypes.Register("AP")


function Ammo:OnLoaded()
	self.Name		 = "Armor Piercing"
	self.SpawnIcon   = "acf/icons/shell_ap.png"
	self.Description = "#acf.descs.ammo.ap"
	self.Blacklist = {
		GL = true,
		MO = true,
		SL = true,
	}

	-- Model definitions (FlightModel defaults to MenuModel, MenuModel defaults to CrateModel)
	self.CrateModel  = "models/acf/munitions/cartridge.mdl"
	self.MenuModel   = "models/acf/munitions/projectile.mdl"
	self.Bodygroup   = 0 -- Bodygroup index for crate and menu models
	self.MenuFOV     = 60 -- Default FOV for menu preview
end

--- Default crate model path - used to detect ammo types with custom models
local DefaultCrateModel = "models/acf/munitions/cartridge.mdl"

--- Resolves the model to use for a given context.
--- Precedence: Weapon Round definition > Ammo type custom model > Mortar override > Default ammo model
--- @param Context string The context: "Crate", "Menu", or "Flight"
--- @param Class table|nil The weapon class
--- @param Weapon table|nil The specific weapon entry
--- @return table|nil ModelInfo Table with Model, Offset, Bodygroup, NeedsRotation, FOV
function Ammo:ResolveModel(Context, Class, Weapon)
	local Round = Weapon and Weapon.Round or (Class and Class.Round)

	-- Priority 1: Weapon's Round definition (missiles, bombs, etc.)
	if Round and (Round.Model or Round.RackModel) then
		local ModelPath = (not Round.IgnoreRackModel and Round.RackModel) or Round.Model

		if ModelPath then
			local ModelData = ACF.ModelData.GetModelData(ModelPath)
			local Offset = ModelData and ModelData.Center and Vector(-ModelData.Center.x, 0, 0) or Vector()

			return {
				Model         = ModelPath,
				Offset        = Offset,
				Bodygroup     = 0,
				NeedsRotation = false,
				FOV           = 60,
			}
		end
	end

	-- Priority 2: Ammo type's custom model (e.g., GLATGM missiles)
	-- If the ammo type defines a non-default CrateModel, use it instead of mortar override
	local HasCustomModel = self.CrateModel and self.CrateModel ~= DefaultCrateModel

	if HasCustomModel then
		-- Ammo type has a custom CrateModel (e.g., GLATGM missile)
		-- Use the custom model for all contexts, ignoring inherited MenuModel
		local ModelPath, Bodygroup
		if Context == "Flight" then
			ModelPath = self.FlightModel or self.CrateModel
			Bodygroup = self.FlightBodygroup or self.Bodygroup
		else -- "Menu" or "Crate"
			ModelPath = self.CrateModel
			Bodygroup = self.Bodygroup
		end

		local ModelData = ACF.ModelData.GetModelData(ModelPath)
		local Offset    = ModelData.Center and Vector(-ModelData.Center.x, 0, 0) or Vector()

		return {
			Model         = ModelPath,
			Offset        = Offset,
			Bodygroup     = Bodygroup,
			NeedsRotation = false,
			FOV           = self.MenuFOV,
		}
	end

	-- Priority 3: Mortars have a different model
	local IsMortar = Class and Class.ID == "MO"
	local MortarBodygroup = self.MortarBodygroup

	if IsMortar and MortarBodygroup then
		local ModelPath = "models/acf/munitions/projectile_mortar.mdl"
		local ModelData = ACF.ModelData.GetModelData(ModelPath)
		local Offset    = ModelData.Center and Vector(-ModelData.Center.x, 0, 0) or Vector()

		return {
			Model         = ModelPath,
			Offset        = Offset,
			Bodygroup     = MortarBodygroup,
			NeedsRotation = false,
			FOV           = 105,
		}
	end

	-- Priority 4: Default ammo type model based on context
	local ModelPath, Bodygroup
	if Context == "Menu" then
		ModelPath = self.MenuModel or self.CrateModel
		Bodygroup = self.Bodygroup
	elseif Context == "Flight" then
		ModelPath = self.FlightModel or self.MenuModel or self.CrateModel
		Bodygroup = self.FlightBodygroup or self.Bodygroup
	else -- "Crate" or default
		ModelPath = self.CrateModel
		Bodygroup = self.Bodygroup
	end

	if not ModelPath then return nil end

	local ModelData = ACF.ModelData.GetModelData(ModelPath)
	local Offset = ModelData.Center and Vector(-ModelData.Center.x, 0, 0) or Vector()
	local NeedsRotation = ModelPath == DefaultCrateModel

	return {
		Model         = ModelPath,
		Offset        = Offset,
		Bodygroup     = Bodygroup,
		NeedsRotation = NeedsRotation,
		FOV           = self.MenuFOV,
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
	local Conversion	= ACF.PointConversion

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
		Entity:SetNW2Float("Caliber", BulletData.Diameter)
		Entity:SetNW2Float("ProjMass", BulletData.ProjMass)
		Entity:SetNW2Float("PropMass", BulletData.PropMass)
		Entity:SetNW2Float("DragCoef", BulletData.DragCoef)
		Entity:SetNW2Float("Tracer", BulletData.Tracer)

		-- Network flight model info for bullet effects
		local FlightInfo = self:ResolveModel("Flight")
		if FlightInfo then
			Entity:SetNW2String("FlightModel", FlightInfo.Model)
			Entity:SetNW2Int("FlightBodygroup", FlightInfo.Bodygroup)
		end
	end

	function Ammo:GetCrateName()
	end

	function Ammo:UpdateCrateOverlay(BulletData, State)
		local Data = self:GetDisplayData(BulletData)
		State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
		State:AddNumber("Max Penetration", Data.MaxPen, " mm")
	end

	function Ammo:GetCost(BulletData)
		return (BulletData.ProjMass * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant)
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
			local Overkill = HitRes.Overkill or 0 -- TODO: Sometimes Overkill ends up being nil, but that should never be the case??

			if Overkill > 0 then
				-- Per-convex impacts already filtered the penetrated convex in DoRoundImpact, so the entity
				-- stays hittable and the re-trace advances to the convex behind it. Only meshless targets
				-- (no convex resolution) still need the whole entity filtered to avoid re-hitting it.
				if not Bullet.ConvexHit then
					table.insert(Filter, Target) -- "Penetrate" (Ignoring the prop for the retry trace)
				end

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

	-- Default ammo menu graph: penetration over distance. Overridden by ammo types with bespoke behavior.
	function Ammo:PlotAmmoGraph(Panel, _, BulletData)
		local Colors  = ACF.GraphColors
		local PenText = language.GetPhrase("acf.menu.ammo.penetration")

		Panel:SetYRange(0, math.ceil(BulletData.MaxPen or 0) * 1.1)

		Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.300m"), 300, self:GetRangedPenetration(BulletData, 300), Colors.Blue)
		Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.800m"), 800, self:GetRangedPenetration(BulletData, 800), Colors.Blue)

		Panel:PlotFunction(PenText, Colors.RedAlt, function(X)
			return self:GetRangedPenetration(BulletData, X)
		end)
	end

	function Ammo:OnCreateAmmoPreview(_, Setup, ToolData)
		local Destiny = Classes[ToolData.Destiny or "Weapons"]
		local Class = Classes.GetGroup(Destiny, ToolData.Weapon)
		local Weapon = Destiny and Destiny.GetItem and Destiny.GetItem(Class and Class.ID, ToolData.Weapon)

		local Info = self:ResolveModel("Menu", Class, Weapon)

		if Info then
			Setup.Model     = Info.Model
			Setup.Bodygroup = Info.Bodygroup
			Setup.FOV       = Info.FOV
		end
	end

	function Ammo:ImpactEffect(_, Bullet)
		local EffectTable = {
			Origin = Bullet.SimPos,
			Normal = Bullet.SimFlight:GetNormalized(),
			Scale = Bullet.SimFlight:Length(),
			Magnitude = Bullet.RoundMass,
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

		local MaxPenLabel = Base:AddLabel()
		MaxPenLabel:TrackClientData("Projectile", "SetText")
		MaxPenLabel:TrackClientData("Propellant")
		MaxPenLabel:TrackClientData("FillerRatio")
		MaxPenLabel:DefineSetter(function()
			local Text   = language.GetPhrase("acf.menu.ammo.pen_stats_ap")
			local MaxPen = math.Round(BulletData.MaxPen, 2)
			return Text:format(MaxPen)
		end)
	end
end
