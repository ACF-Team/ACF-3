local ACF     = ACF
local Damage  = ACF.Damage
local Objects = Damage.Objects
local Fire    = Damage.Fire
local Debug   = ACF.Debug
local Clock   = ACF.Utilities.Clock

local PROPELLANT_HEAT = 4e6 -- J/kg, heat of explosion of gun propellant
local MIN_VOLUME      = 0.05 -- m³, no crate's gas has less room than this
local BURST_GROWTH    = math.log(100) -- A contained burn grows from 1% of the propellant to all of it

local MAX_JETS         = 4 -- Largest breaches that get a jet of flame each; any more share theirs
local MIN_BURN_TIME    = 3 -- Seconds a cookoff takes at least, so a crate with little or no propellant doesn't set its filler off at once

local DEBUG_LIFE  = 6
local COLOR_VENT  = Color(255, 200, 80)
local COLOR_BURST = Color(255, 60, 60)

-- Fire turned off, or vetoed, makes a cookoff just a detonation. Agent still flooding rounds that only go off as a fire
-- heats them keeps them from starting at all.
local function StartCookoff(Entity, Source)
	if Fire.IsInerted(Entity) then return end
	if not Fire.Ignite(Entity, Source) then Entity:Detonate() end
end

-- Leaves the crate empty and destroyed once its contents have gone off
local function Spend(Entity)
	Entity.ACF.Health = 0

	Entity:SetAmount(0)
	Entity:Disable()
	Entity:UpdateOverlay(true)
end

do -- MARK: Damage and heat
	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo) -- Calling the standard damage prop function

		if self.Exploding or self.Cookoff or self.Amount <= 0 then return HitRes end

		local Source    = Fire.GetIgnitionSource(self, DmgInfo) or "Hit"
		local Destroyed = ACF.IsDestroyed(self)

		-- Destroyed outright guarantees a cookoff, otherwise roll for it
		if not Destroyed and (HitRes.Damage / self.BulletData.RoundVolume) ^ 0.1 * self.Capacity / self.Amount <= math.random() then
			return HitRes
		end

		self.Attacker  = DmgInfo.Attacker
		self.Inflictor = DmgInfo.Inflictor

		StartCookoff(self, Source)

		return HitRes
	end

	function ENT:ACF_OnHeat(Flux, DeltaTime)
		if self.Exploding or self.Cookoff or self.Amount <= 0 then return end

		if Fire.AddHeatDose(self, Flux, DeltaTime) >= ACF.AmmoHeatDose then
			StartCookoff(self, "Heat")
		end
	end
end

do -- MARK: Cookoff
	-- The blow-out panels linked to any crate of the compartment that would give way, the opening they'd add,
	-- and the crate each was found for, which it blows out away from. How much of each panel the gas reaches comes
	-- from the survey's rays where they found it.
	local function GetPanelVent(Crates, PanelReach)
		local Area, Panels, PanelCrates = 0

		for _, Crate in ipairs(Crates) do
			for Panel in pairs(Crate.BlowoutPanels or {}) do
				if not (PanelCrates and PanelCrates[Panel]) then
					local PanelArea = IsValid(Panel) and Panel:GetVentArea(Crate, PanelReach[Panel]) or 0

					if PanelArea > 0 then
						Area        = Area + PanelArea
						Panels      = Panels or {}
						PanelCrates = PanelCrates or {}

						Panels[#Panels + 1] = Panel
						PanelCrates[Panel]  = Crate
					end
				end
			end
		end

		return Area, Panels, PanelCrates
	end

	-- Rounds sealed in cases of their own, with no filler and little propellant each, go off one at a time as the fire
	-- heats them: one doesn't set off the next, so they never go off together or fill a space with their gas
	local function IsSmallArms(Crate)
		local BulletData = Crate.BulletData

		return (BulletData.FillerMass or 0) <= 0 and (BulletData.PropMass or 0) * ACF.PropImpetus <= ACF.SmallArmsRoundEnergy
	end

	-- kg of propellant a crate still has to go off together with the rest of its space
	local function GetPropellant(Crate)
		if not IsValid(Crate) or Crate.Exploding or Crate.Amount <= 0 or IsSmallArms(Crate) then return 0 end

		return Crate.Amount * (Crate.BulletData.PropMass or 0)
	end

	-- m² of holes shot through the walls around the crate
	local function GetBreachArea(Walls)
		local Area = 0

		for _, Wall in ipairs(Walls) do
			if IsValid(Wall.Entity) then Area = Area + (Wall.Convex.HoleArea or 0) end
		end

		return Area * ACF.InchToMeter ^ 2
	end

	--- Works out how a cookoff of the crate's compartment would play out, without starting one.
	--- The compartment is the space the crate's survey finds and the other crates in it. Once one of them cooks off
	--- its flames light the rest within seconds, so the gas to get out is the whole rack's.
	--- Gas that can't get out of a sealed space at the pressure the structure holds bursts it, and more
	--- opening is needed the more propellant there is, since confined propellant burns faster with pressure.
	--- Blow-out panels linked to any of its crates only open, and so only count, if with them the gas can get out.
	--- @param Survey table|nil A finished survey around the crate (see Fire.QueueSurvey); surveyed on the spot without one.
	--- @return table # Burst, the pressure it would reach sealed, the openings it has besides breaches (VentArea, PanelArea), the opening it would need, and the crates sharing the space (Crates, this one included).
	function ENT:GetCookoffPlan(Survey)
		local Vent, Volume, Walls, Others, PanelReach

		if Survey then
			Vent, Volume, Walls, Others, PanelReach = Survey.Vent, Survey.Volume, Survey.WallList, Survey.CrateList, Survey.PanelReach
		else
			Vent, Volume, Walls, Others, PanelReach = Fire.SurveyEnclosure(self)
		end

		local Crates     = { self }
		local Propellant = GetPropellant(self)

		for _, Crate in ipairs(Others) do
			Crates[#Crates + 1] = Crate
			Propellant          = Propellant + GetPropellant(Crate)
		end

		local PanelVent, Panels, PanelCrates = GetPanelVent(Crates, PanelReach)
		local Pressure = Propellant * ACF.PropImpetus * 1000 / math.max(Volume, MIN_VOLUME) -- Pa, closed-vessel pressure
		local Required = Propellant * ACF.AmmoVentAreaPerKg
		local Burst    = Pressure >= ACF.AmmoBurstPressure and Vent + PanelVent + GetBreachArea(Walls) < Required

		if Burst then PanelVent, Panels, PanelCrates = 0, nil, nil end

		return {
			Burst       = Burst,
			Pressure    = Pressure,
			Volume      = Volume,
			VentArea    = Vent + PanelVent,
			PanelArea   = PanelVent,
			Panels      = Panels,
			PanelCrates = PanelCrates,
			Walls       = Walls,
			Crates      = Crates,
			Propellant  = Propellant,
			Required    = Required,
			Center      = self:WorldSpaceCenter(),
		}
	end

	--- Starts the cookoff; how it plays out is worked out on the fire tick, outside whatever lit it
	function ENT:ACF_OnIgnite()
		if self.Exploding or self.Amount <= 0 then return false end

		if not hook.Run("ACF_PreBurnAmmo", self) then
			self:Detonate()

			return false
		end

		self.Cookoff    = { Planned = false }
		self.ACF_Survey = nil -- One left over from a cookoff cut short would be out of date

		return true
	end

	-- A crate put out mid-cookoff (fire turned off) can't hold its burning propellant, unless its rounds only go off
	-- one by one as the fire heats them: then the ones left stay put, though the heat they took in stays with them
	function ENT:ACF_OnExtinguish()
		if not self.Cookoff then return end

		self.Cookoff = nil

		if IsSmallArms(self) then return self:UpdateOverlay() end

		self:Detonate()
	end

	-- Small arms only go off as the fire around them heats them, so an extinguisher stops them; a main-gun charge
	-- burns on its own propellant's oxygen whatever floods it
	function ENT:ACF_IsSuppressible()
		return IsSmallArms(self)
	end

	-- A compartment is the crates sharing one space, with the plan they all cook off by while any of them burns.
	-- It lasts as long as one of its crates is cooking off by it; a crate lit after that surveys afresh.
	local function IsActive(Compartment)
		for Crate in pairs(Compartment.Crates) do
			if IsValid(Crate) and Crate.Cookoff and Crate.Cookoff.Compartment == Compartment then return true end
		end

		return false
	end

	local function GetActiveCompartment(Crate)
		local Compartment = IsValid(Crate) and Crate.ACF_Compartment

		return Compartment and IsActive(Compartment) and Compartment or nil
	end

	-- The burning gas fills the space on its way out, washing over every crate in it whether it can see the fire or not
	local function AddMember(Compartment, Crate)
		if not IsValid(Crate) then return end

		Compartment.Crates[Crate]        = true
		Compartment.Plan.Engulfed[Crate] = ACF.AmmoFlameFlux
		Crate.ACF_Compartment            = Compartment
	end

	-- The first crate of a space to cook off surveys it and decides for all of it; the rest join that plan.
	-- The survey takes a few server ticks, and the crate's fire ticks again as soon as it's done.
	-- @return boolean # False while the crate waits for its survey.
	local function PlanCookoff(Entity)
		-- Small arms burn out on their own, round by round, with no space to share
		if IsSmallArms(Entity) then
			Entity.Cookoff = {
				Planned   = true,
				SmallArms = true,
				Rate      = ACF.SmallArmsBurnRate / math.max(Entity.BulletData.PropMass or 0, 1e-6), -- Rounds per second
				Partial   = 0,
				Burnt     = 0,
			}

			Entity:UpdateOverlay()

			return true
		end

		local Compartment = GetActiveCompartment(Entity)

		if not Compartment then
			local Survey = Entity.ACF_Survey

			if not Survey then
				Entity.ACF_Survey = Fire.QueueSurvey(Entity, function()
					if IsValid(Entity) then Fire.Wake(Entity) end
				end)

				return false
			end

			if not Survey.Done then return false end

			Entity.ACF_Survey = nil

			local Plan = Entity:GetCookoffPlan(Survey)

			-- Its own survey can find crates of a space already cooking off that the first survey missed
			for _, Crate in ipairs(Plan.Crates) do
				Compartment = GetActiveCompartment(Crate)

				if Compartment then break end
			end

			if Compartment then
				for _, Crate in ipairs(Plan.Crates) do AddMember(Compartment, Crate) end
			else
				Compartment = { Crates = {}, Plan = Plan }

				Plan.Start    = Clock.CurTime
				Plan.Jets     = {}
				Plan.Breaches = {}
				Plan.Engulfed = {}

				for _, Crate in ipairs(Plan.Crates) do AddMember(Compartment, Crate) end

				if Debug.SetDeveloperLevel(1) then
					local Text = ("%s: vent %.3f of %.3f m² (panels %.3f), %.1f MPa sealed, %d crates, %.1f kg"):format(Plan.Burst and "Bursting" or "Venting", Plan.VentArea, Plan.Required, Plan.PanelArea, Plan.Pressure / 1e6, #Plan.Crates, Plan.Propellant)

					Debug.EntityText(Entity, 2, Text, DEBUG_LIFE, Plan.Burst and COLOR_BURST or COLOR_VENT)
				end

				-- Venting, the panels give way and the propellant burns out through them
				if not Plan.Burst and Plan.Panels then
					for _, Panel in ipairs(Plan.Panels) do
						if IsValid(Panel) then Panel:BlowOut(Plan.PanelCrates[Panel]) end
					end
				end
			end
		elseif Debug.SetDeveloperLevel(1) then
			Debug.EntityText(Entity, 2, "Joins its compartment's cookoff", DEBUG_LIFE, Compartment.Plan.Burst and COLOR_BURST or COLOR_VENT)
		end

		AddMember(Compartment, Entity)

		Entity.Cookoff = {
			Planned     = true,
			Compartment = Compartment,
			Plan        = Compartment.Plan,
			Rate        = math.min(ACF.AmmoBurnRate / math.max(Entity.BulletData.PropMass or 0, 1e-6), Entity.Amount / MIN_BURN_TIME), -- Rounds per second
			Partial     = 0,
			Burnt       = 0,
			Jets        = {}, -- This crate's share of the compartment's jets
		}

		Entity:UpdateOverlay()

		return true
	end

	-- The burnt rounds' HE filler goes off once their propellant is gone
	local function FinishCookoff(Entity)
		local BulletData = Entity.BulletData
		local Filler     = (BulletData.FillerMass or 0) * Entity.Cookoff.Burnt

		Entity.Cookoff   = nil
		Entity.Exploding = true

		if Filler > 0 and hook.Run("ACF_PreExplodeAmmo", Entity) then
			local Position = Entity:WorldSpaceCenter()
			local DmgInfo  = Objects.DamageInfo(Entity.Attacker or Entity, Entity.Inflictor)

			Damage.createExplosion(Position, Filler, BulletData.ProjMass or Filler * 0.5, { Entity }, DmgInfo)
			Damage.explosionEffect(Position, nil, Filler)
		end

		Spend(Entity)
	end

	-- The structure gives way around the whole space at once, and every crate in it still holding rounds goes off
	-- where it is, lit or not. Small arms don't go off with the rest: the flames light them, and they burn out on their own.
	local function Rupture(Compartment)
		for _, Crate in ipairs(table.GetKeys(Compartment.Crates)) do
			if IsValid(Crate) and not Crate.Exploding and Crate.Amount > 0 then
				if IsSmallArms(Crate) then
					if not Crate.Cookoff then StartCookoff(Crate, "Fire") end
				else
					Crate.Cookoff = nil

					Crate:Detonate(false, true)
				end
			end
		end
	end

	-- Sealed in, the burn speeds up with the pressure the space builds until the structure gives way
	local function BuildPressure(Entity, Cookoff, PropMass)
		local Elapsed = Clock.CurTime - Cookoff.Plan.Start

		if Elapsed >= ACF.AmmoBurstDelay then return Rupture(Cookoff.Compartment) end

		local Rate = BURST_GROWTH / ACF.AmmoBurstDelay

		return Entity.Amount * PropMass * PROPELLANT_HEAT * 0.01 * Rate * math.exp(Elapsed * Rate)
	end

	-- Venting, the rounds burn through one after another
	local function BurnPropellant(Entity, Cookoff, PropMass, DeltaTime)
		local Rounds = math.min(Entity.Amount - Cookoff.Partial, Cookoff.Rate * DeltaTime)

		Cookoff.Partial = Cookoff.Partial + Rounds

		local Whole = math.floor(Cookoff.Partial)

		if Whole > 0 then
			Cookoff.Partial = Cookoff.Partial - Whole
			Cookoff.Burnt   = Cookoff.Burnt + Whole

			Entity:Consume(Whole)
		end

		if Entity.Amount - Cookoff.Partial <= 0 then return FinishCookoff(Entity) end

		return Rounds * PropMass * PROPELLANT_HEAT / DeltaTime
	end

	local function ByHoleArea(A, B)
		return A.Convex.HoleArea > B.Convex.HoleArea
	end

	-- The gas spreads out of the wall's far face around its holes, straight out from the wall whichever way the
	-- shots went through it. Holes from before the face was kept fall back to the point the survey found past the wall.
	local function AimJet(Jet, Wall, Center)
		local Entity, Convex = Wall.Entity, Wall.Convex
		local Weight         = Convex.HoleChannelArea

		if Weight and Weight > 0 and Convex.HoleNormal then
			local HoleCenter = Entity:LocalToWorld(Convex.HoleCenter / Weight)
			local Axis       = (Entity:LocalToWorld(Convex.HoleNormal) - Entity:GetPos()):GetNormalized()

			if Axis:Dot(HoleCenter - Center) < 0 then Axis:Mul(-1) end

			Jet.Origin = HoleCenter + Axis * (Convex.HoleThickness / Weight * 0.5 + 1)
			Jet.Axis   = Axis
			Jet.Wall   = Wall
		else
			Jet.Origin = Entity:LocalToWorld(Wall.LocalExit)
			Jet.Axis   = (Jet.Origin - Center):GetNormalized()
			Jet.Wall   = Wall
		end
	end

	-- Once a server tick at most, whichever of the compartment's crates burns lays out its breaches and jets. The largest
	-- breaches carry the whole breach share between them, the smaller ones' included.
	local function UpdateBreaches(Plan)
		local Tick = engine.TickCount()

		if Plan.Tick == Tick then return end

		Plan.Tick = Tick

		local Breaches = Plan.Breaches
		local Jets     = Plan.Jets
		local Breached = 0
		local Count    = 0

		for _, Wall in ipairs(Plan.Walls) do
			local Hole = Wall.Convex.HoleArea

			if Hole and IsValid(Wall.Entity) then
				Count           = Count + 1
				Breaches[Count] = Wall
				Breached        = Breached + Hole
			end
		end

		for I = Count + 1, #Breaches do Breaches[I] = nil end

		if Breached <= 0 then
			Plan.BreachShare = 0

			for I = #Jets, 1, -1 do Jets[I] = nil end

			return
		end

		table.sort(Breaches, ByHoleArea)

		local Shown     = math.min(Count, MAX_JETS)
		local ShownArea = 0

		for I = 1, Shown do
			ShownArea = ShownArea + Breaches[I].Convex.HoleArea
		end

		for I = 1, Shown do
			local Jet = Jets[I] or {}

			AimJet(Jet, Breaches[I], Plan.Center)

			Jet.Share = ShownArea > 0 and Breaches[I].Convex.HoleArea / ShownArea or 0
			Jets[I]   = Jet
		end

		for I = Shown + 1, #Jets do Jets[I] = nil end

		Plan.BreachShare = 1 - Plan.VentArea / (Plan.VentArea + Breached * ACF.InchToMeter ^ 2)
	end

	-- Gas leaves through every opening in proportion to its area, so a breach in the walls around the compartment
	-- carries its share of each crate's burning propellant through to whatever is beyond, as jets of flame. Each crate
	-- sends its own share through the compartment's jets on its own fire tick.
	local function SplitThroughBreaches(Cookoff, HeatRelease)
		local Plan = Cookoff.Plan

		UpdateBreaches(Plan)

		local BreachHeat = HeatRelease * Plan.BreachShare
		local Mine       = Cookoff.Jets

		for I = #Mine, #Plan.Jets + 1, -1 do Mine[I] = nil end

		if BreachHeat <= 0 then return HeatRelease end

		for I, Jet in ipairs(Plan.Jets) do
			local Share = Mine[I] or {}

			Share.Origin, Share.Axis, Share.Wall = Jet.Origin, Jet.Axis, Jet.Wall
			Share.HeatRelease = BreachHeat * Jet.Share
			Mine[I]           = Share
		end

		return HeatRelease - BreachHeat, Mine
	end

	--- @return number|nil # Heat released in watts, nil once the cookoff is over
	--- @return table|nil # This crate's share of the jets of flame through breaches in the compartment's walls.
	--- @return table|nil # Engulfed[Entity] = W/m², the crates sharing its space and the flames they're in.
	function ENT:ACF_FireTick(DeltaTime)
		local Cookoff = self.Cookoff

		if not Cookoff then return end
		if not Cookoff.Planned and not PlanCookoff(self) then return 0 end

		Cookoff = self.Cookoff

		local Plan     = Cookoff.Plan
		local PropMass = math.max(self.BulletData.PropMass or 0, 1e-6)
		local HeatRelease

		if Cookoff.SmallArms then return BurnPropellant(self, Cookoff, PropMass, DeltaTime) end

		if Plan.Burst then
			HeatRelease = BuildPressure(self, Cookoff, PropMass)
		else
			HeatRelease = BurnPropellant(self, Cookoff, PropMass, DeltaTime)
		end

		if not HeatRelease then return end

		local Rest, Jets = SplitThroughBreaches(Cookoff, HeatRelease)

		return Rest, Jets, Plan.Engulfed
	end

	--- Sets off the crate's contents
	--- @param VisualOnly boolean Only show the explosion.
	--- @param Full boolean Use everything in the crate, as a contained cookoff bursting does, rather than the damped legacy amount.
	function ENT:Detonate(VisualOnly, Full)
		if self.Exploding then return end

		local CanExplode = hook.Run("ACF_PreExplodeAmmo", self)

		if not CanExplode then return end

		self.Exploding = true

		local Position   = self:LocalToWorld(self:OBBCenter() + VectorRand() * self:GetSize() * 0.5) -- Random position within the crate
		local BulletData = self.BulletData
		local Filler     = BulletData.FillerMass or 0
		local Propellant = BulletData.PropMass or 0
		local AmmoPower  = Full and self.Amount or self.Amount ^ 0.7 -- Arbitrary exponent to reduce ammo-based explosive power
		local Explosive  = (Filler + Propellant * (ACF.PropImpetus / ACF.HEPower)) * AmmoPower
		local FragMass   = BulletData.ProjMass or Explosive * 0.5
		local DmgInfo    = Objects.DamageInfo(self.Attacker or self, self.Inflictor)

		ACF.KillChildProps(self, Position, Explosive)

		if not VisualOnly then
			Damage.createExplosion(Position, Explosive, FragMass, { self }, DmgInfo, Full and self:CFW_GetContraption() or nil)
		end

		Damage.explosionEffect(Position, nil, Explosive)

		Spend(self)
	end
end
