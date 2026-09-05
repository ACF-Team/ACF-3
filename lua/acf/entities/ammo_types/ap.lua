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
	-- Two piece rounds stow their propellant as a separate charge, so the shell is the cased half
	self.TwoPieceCrateModel = "models/acf/munitions/cartridge_half.mdl"
	self.MenuModel   = "models/acf/munitions/projectile.mdl"
	self.Bodygroup   = 0 -- Bodygroup index for crate and menu models
	self.MenuFOV     = 60 -- Default FOV for menu preview
end

--- Default crate model path - used to detect ammo types with custom models
local DefaultCrateModel = "models/acf/munitions/cartridge.mdl"

--- The stock crate models, whose length runs along their own Z and so need the -90 pitch correction
local StockCrateModels = {
	["models/acf/munitions/cartridge.mdl"]      = true,
	["models/acf/munitions/cartridge_half.mdl"] = true,
}

--- Resolves the model to use for a given context.
--- Precedence: Weapon Round definition > Ammo type custom model > Mortar override > Default ammo model
--- @param Context string The context: "Crate", "Menu", or "Flight"
--- @param Class table|nil The weapon class
--- @param Weapon table|nil The specific weapon entry
--- @param TwoPiece boolean|nil Crate context only: swaps the stock cartridge for its cased half
--- @return table|nil ModelInfo Table with Model, Offset, Bodygroup, NeedsRotation, FOV
function Ammo:ResolveModel(Context, Class, Weapon, TwoPiece)
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
		-- Only the stock cartridge has a half variant; ammo types with their own crate model
		-- never reach here, having been handled as a custom model above
		ModelPath = TwoPiece and self.TwoPieceCrateModel or self.CrateModel
		Bodygroup = self.Bodygroup
	end

	if not ModelPath then return nil end

	local ModelData = ACF.ModelData.GetModelData(ModelPath)
	local Offset = ModelData.Center and Vector(-ModelData.Center.x, 0, 0) or Vector()
	local NeedsRotation = StockCrateModels[ModelPath] or false

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

--- Inverse of GetPenetration, solved for Speed; override alongside GetPenetration for other formulas.
function Ammo:CalcSpeed(Bullet, Penetration)
	return ACF.CalcSpeed(Penetration, Bullet.ProjMass, Bullet.Diameter * 10)
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
	ACF.VerifyRoundLengthData(ToolData)

	if ToolData.Tracer == nil then
		local Data10 = ToolData.RoundData10

		ToolData.Tracer = Data10 and tobool(tonumber(Data10)) or false -- Haha "0.00" is true but 0 isn't
	end
end

-- Shared with the client so the spawn menu can price a crate without spawning it.
local Conversion = ACF.PointConversion

function Ammo:GetCost(BulletData)
	return (BulletData.ProjMass * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant)
end

if SERVER then
	local Ballistics = ACF.Ballistics
	local Entities   = Classes.Entities

	Entities.AddArguments("acf_ammo", "RoundLength", "PropRatio", "Tracer", "CaseScale") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Entity.RoundLength = nil
		Entity.PropRatio = nil
		Entity.Tracer = nil
		Entity.CaseScale = nil

		-- Cleanup the leftovers aswell (including pre-RoundLength/PropRatio legacy fields)
		Entity.Projectile = nil
		Entity.Propellant = nil
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

				-- Remaining penetration capacity after the hit, converted back to speed to keep multi-layer penetration consistent
				local RemainingPen = Bullet:GetPenetration() * (1 - HitRes.Loss)
				local NewSpeed = self:CalcSpeed(Bullet, RemainingPen)

				Bullet.Flight = Bullet.Flight:GetNormalized() * NewSpeed * ACF.MeterToInch

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

	-- Default ammo menu visual: a side profile of the case/projectile, built from a GeoPrim tree (see
	-- acf/core/geo_prim_sh.lua) so the shape has one definition shared with any future volume queries.
	-- Overridden by ammo types with a distinct shape (e.g. HEAT's shaped charge, APFSDS's sabot/rod).
	function Ammo:DrawAmmoVisual(Panel, w, h, _, BulletData)
		local GeoPrim  = ACF.GeoPrim
		local Margin   = 10
		local DrawW    = w - Margin * 2
		local Diameter = BulletData.Diameter or BulletData.Caliber

		local Length = BulletData.ProjLength + BulletData.PropLength

		if Length <= 0 then return end

		-- Cap Scale by the case, the widest part, so the case/bore step survives the height budget
		local CaseDia = BulletData.CaseDiameter

		if CaseDia <= 0 then return end

		local Scale      = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / CaseDia)
		local DiameterPx = CaseDia * Scale
		local CenterY    = h * 0.5

		local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
		Propellant:SetMaterial("Propellant")

		local Penetrator = GeoPrim.New("Cylinder", { Radius = Diameter * 0.5, Height = BulletData.ProjLength })
		Penetrator:SetMaterial("Steel Penetrator")

		local X = Margin
		X = Propellant:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(180, 150, 60), Color(30, 30, 30))
		local BodyStartX = X
		Penetrator:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(120, 120, 130), Color(30, 30, 30))

		-- Tracer, a colored segment at the base of the projectile, drawn last (and not as a Body child --
		-- Draw() paints an entire subtree in one Color, so a child never gets a color of its own) so it
		-- takes hover priority and actually renders red instead of inheriting the penetrator's gray.
		if BulletData.Tracer and BulletData.Tracer > 0 then
			local Tracer = GeoPrim.New("Cylinder", { Radius = Diameter * 0.5, Height = BulletData.Tracer })
			Tracer:SetMaterial("Tracer")
			Tracer:Draw(Panel, BodyStartX, CenterY, Scale, DiameterPx, Color(220, 40, 30), Color(30, 30, 30))
		end
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
		Label:TrackClientData("RoundLength")
		Label:TrackClientData("PropRatio")
		Label:TrackClientData("CaseScale")
	end

	function Ammo:OnCreateAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("RoundLength", "SetText")
		RoundStats:TrackClientData("PropRatio")
		RoundStats:TrackClientData("CaseScale")
		RoundStats:TrackClientData("TelescopeRatio")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= language.GetPhrase("acf.menu.ammo.round_stats_ap")
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.FormatMass(BulletData.ProjMass)
			local PropMass	= ACF.FormatMass(BulletData.PropMass)

			return Text:format(MuzzleVel, ProjMass, PropMass)
		end)

		local MaxPenLabel = Base:AddLabel()
		MaxPenLabel:TrackClientData("RoundLength", "SetText")
		MaxPenLabel:TrackClientData("PropRatio")
		MaxPenLabel:TrackClientData("CaseScale")
		MaxPenLabel:TrackClientData("FillerRatio")
		MaxPenLabel:TrackClientData("TelescopeRatio")
		MaxPenLabel:DefineSetter(function()
			local Text   = language.GetPhrase("acf.menu.ammo.pen_stats_ap")
			local MaxPen = math.Round(BulletData.MaxPen, 2)
			return Text:format(MaxPen)
		end)
	end
end
