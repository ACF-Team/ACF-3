local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.AP", "ACF.Ammunition.BaseAmmo", function()
	CLASS.Name		 = "Armor Piercing"
	CLASS.SpawnIcon   = "acf/icons/shell_ap.png"
	CLASS.Description = "#acf.descs.ammo.ap"
	CLASS.Blacklist = {
		GL = true,
		MO = true,
		SL = true,
	}

	-- Model definitions (FlightModel defaults to MenuModel, MenuModel defaults to CrateModel)
	CLASS.CrateModel  = "models/acf/munitions/cartridge.mdl"
	CLASS.MenuModel   = "models/acf/munitions/projectile.mdl"
	CLASS.Bodygroup   = 0 -- Bodygroup index for crate and menu models
	CLASS.MenuFOV     = 60 -- Default FOV for menu preview

	--- Default crate model path - used to detect ammo types with custom models
	local DefaultCrateModel = "models/acf/munitions/cartridge.mdl"

	--- Resolves the model to use for a given context.
	--- Precedence: Weapon Round definition > Ammo type custom model > Mortar override > Default ammo model
	--- @param Context string The context: "Crate", "Menu", or "Flight"
	--- @param Class table|nil The weapon class
	--- @param Weapon table|nil The specific weapon entry
	--- @return table|nil ModelInfo Table with Model, Offset, Bodygroup, NeedsRotation, FOV
	function CLASS:ResolveModel(Context, Class, Weapon)
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

	function CLASS:GetPenetration(Bullet, Speed)
		if not isnumber(Speed) then
			Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * ACF.InchToMeter or Bullet.MuzzleVel
		end

		return ACF.Penetration(Speed, Bullet.ProjMass, Bullet.Diameter * 10)
	end

	function CLASS:GetDisplayData(Data)
		local Display = {
			MaxPen = self:GetPenetration(Data, Data.MuzzleVel)
		}

		hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

		return Display
	end

	function CLASS:UpdateRoundData(ToolData, Data, GUIData)
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

	function CLASS:BaseConvert(ToolData)
		local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

		Data.ShovePower = 0.2
		Data.LimitVel   = 800 --Most efficient penetration speed in m/s
		Data.Ricochet   = 60 --Base ricochet angle

		self:UpdateRoundData(ToolData, Data, GUIData)

		return Data, GUIData
	end

	function CLASS:VerifyData(ToolData)
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

	MENU_FIELD("Number", "Projectile", 	{Default = 0})
	MENU_FIELD("Number", "Propellant", 	{Default = 0})
	MENU_FIELD("Number", "Tracer", 		{Default = 0})

	if SERVER then
		local Ballistics = ACF.Ballistics
		local Conversion	= ACF.PointConversion

		function CLASS:OnLast(Entity)
			Entity.Projectile = nil
			Entity.Propellant = nil
			Entity.Tracer = nil

			-- Cleanup the leftovers aswell
			Entity.RoundProjectile = nil
			Entity.RoundPropellant = nil
			Entity.RoundData10 = nil
		end

		function CLASS:Create(_, BulletData)
			Ballistics.CreateBullet(BulletData)
		end

		function CLASS:ServerConvert(ToolData)
			self:VerifyData(ToolData)

			local Data = self:BaseConvert(ToolData)

			Data.Id = ToolData.Weapon
			Data.Type = ToolData.AmmoType

			return Data
		end

		function CLASS:Network(Entity, BulletData)
			Entity:SetNW2String("AmmoType", "ACF.Ammunition.AP")
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

		function CLASS:GetCrateName()
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			local Data = self:GetDisplayData(BulletData)
			State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
			State:AddNumber("Max Penetration", Data.MaxPen, " mm")
		end

		function CLASS:GetCost(BulletData)
			return (BulletData.ProjMass * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant)
		end

		function CLASS:PropImpact(Bullet, Trace)
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
					table.insert(Filter, Target) -- "Penetrate" (Ignoring the prop for the retry trace)

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

		function CLASS:WorldImpact(Bullet, Trace)
			if ACF.Check(Trace.Entity) then
				return Ballistics.PenetrateMapEntity(Bullet, Trace)
			else
				return Ballistics.PenetrateGround(Bullet, Trace)
			end
		end

		function CLASS:OnFlightEnd(Bullet)
			Ballistics.RemoveBullet(Bullet)
		end
	else
		local Effects = ACF.Utilities.Effects

		ACF.RegisterAmmoDecal("ACF.Ammunition.AP", "damage/ap_pen", "damage/ap_rico")

		local DecalIndex = ACF.GetAmmoDecalIndex

		function CLASS:ClientConvert(ToolData)
			self:VerifyData(ToolData)

			local Data, GUIData = self:BaseConvert(ToolData)

			if GUIData then
				for K, V in pairs(GUIData) do
					Data[K] = V
				end
			end

			return Data
		end

		function CLASS:GetRangedPenetration(Bullet, Range)
			local Speed = ACF.GetRangedSpeed(Bullet.MuzzleVel, Bullet.DragCoef, Range) * ACF.InchToMeter

			return math.Round(self:GetPenetration(Bullet, Speed), 2), math.Round(Speed, 2)
		end

		function CLASS:OnCreateAmmoPreview(_, Setup, ToolData)
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

		function CLASS:ImpactEffect(_, Bullet)
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

		function CLASS:PenetrationEffect(_, Bullet)
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

		function CLASS:RicochetEffect(_, Bullet)
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

		function CLASS:OnCreateCrateInformation(_, Label)
			Label:TrackClientData("Projectile")
			Label:TrackClientData("Propellant")
		end

		function CLASS:OnCreateAmmoInformation(Base, ToolData, BulletData)
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
end)