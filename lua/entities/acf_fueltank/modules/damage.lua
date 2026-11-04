local ACF     = ACF
local Damage  = ACF.Damage
local Objects = Damage.Objects
local Fire    = Damage.Fire
local Clock   = ACF.Utilities.Clock
local Debug   = ACF.Debug
local HookRun = hook.Run

local GRAVITY          = 9.81 -- m/s²
local LEAK_COEF        = 0.6 -- Discharge coefficient of a sharp-edged hole
local POOL_DEPTH       = 0.005 -- m, spilled fuel spreads out to this depth, which sets how much of it burns at once
local POOL_MAX_AREA    = 2 -- m², a hull floor can't hold a wider spill
local SEAL_MAX_CALIBER = 20 -- mm, MIL-T-5578 cells seal .50 cal and 20 mm; bigger holes tear the liner
local SEAL_MAX_AREA    = (SEAL_MAX_CALIBER * 0.05) ^ 2 * math.pi / ACF.InchToCmSq -- in², the hole that caliber leaves
local SEAL_TIME        = 5 -- Seconds for the liner to swell shut
local BOIL_OFF         = 0.1 -- Fraction of the fuel a tank vents once heat makes it boil

local DEBUG_TICK_LIFE = 0.3 -- Just over a think, so the drawing stays up while it changes
local COLOR_FUEL      = Color(120, 200, 255)

ENT.Spilled  = 0 -- kg of fuel spilled around the tank, which is what actually burns
ENT.PoolArea = 0 -- m² the spill has spread over; it thins rather than shrinks as it burns or drains

-- Rolls a per-second chance over a tick
local function RollPerSecond(Chance, DeltaTime)
	return math.random() < 1 - (1 - Chance) ^ DeltaTime
end

do -- MARK: Damage and leaks
	local function UpdateLeakState(Entity)
		local Leaking = Entity.Leaking > 0

		WireLib.TriggerOutput(Entity, "Leaking", Leaking and 1 or 0)
		ACF.Hints.Set(Entity, "fueltank_leaking", Leaking)
	end

	--- @return number # Open area of the tank in in²: holes through its shell, holes its liner hasn't closed yet, plus a rupture while it's destroyed.
	function ENT:GetLeakArea()
		local MeshData = self.ACF_Volumetric_Mesh
		local Area     = 0

		if MeshData then
			for _, Convex in ipairs(MeshData.Convexes) do
				Area = Area + (Convex.HoleArea or 0)
			end
		end

		if self.Seals then
			for _, Seal in ipairs(self.Seals) do
				Area = Area + Seal.Area
			end
		end

		if ACF.IsDestroyed(self) then
			local Size = self:OBBMaxs() - self:OBBMins()

			Area = Area + 2 * (Size.x * Size.y + Size.y * Size.z + Size.z * Size.x) * ACF.FuelRuptureAreaRatio
		end

		return Area
	end

	--- @return number # Liters per second a liquid would pour out of the tank's holes, by orifice flow under its own weight.
	function ENT:GetOrificeFlow()
		if self.Amount <= 0 then return 0 end

		local Area = self:GetLeakArea()

		if Area <= 0 then return 0 end

		local Size   = self:OBBMaxs() - self:OBBMins()
		local Up     = self:WorldToLocal(self:GetPos() + vector_up) - self:WorldToLocal(self:GetPos())
		local Height = (math.abs(Up.x) * Size.x + math.abs(Up.y) * Size.y + math.abs(Up.z) * Size.z) * ACF.InchToMeter
		local Head   = self.Amount / self.Capacity * Height * 0.5 -- Holes sit halfway down the fuel on average
		local Flow   = LEAK_COEF * ACF.FuelLeakMult * Area * ACF.InchToCmSq * 1e-4 * math.sqrt(2 * GRAVITY * Head) -- m³/s

		return Flow * 1000
	end

	--- Moves fuel out of the tank into the spill around it.
	--- @param Amount number Liters of fuel to spill.
	function ENT:Spill(Amount)
		Amount = math.min(Amount, self.Amount)

		if Amount <= 0 then return end

		self:Consume(Amount)

		self.Spilled  = self.Spilled + Amount * self.UnitMass
		self.PoolArea = math.max(self.PoolArea, math.min(self.Spilled / self.UnitMass * 0.001 / POOL_DEPTH, POOL_MAX_AREA))

		self:NextThink(Clock.CurTime) -- Start draining it
	end

	--- Takes fuel out of the spill, as a fire burns it or it drains away.
	--- @param Mass number kg to take.
	--- @return number # kg taken, which is all that's left if that's less.
	function ENT:TakeSpill(Mass)
		Mass = math.min(Mass, self.Spilled)

		self.Spilled = self.Spilled - Mass

		if self.Spilled <= 0 then self.PoolArea = 0 end

		return Mass
	end

	-- The convexes a hit reaches, with the hole area each had before it
	local function GetHitConvexes(Entity, DmgInfo)
		local MeshData   = Entity.ACF_Volumetric_Mesh
		local ConvexHits = MeshData and DmgInfo:GetConvexHits()
		local Before     = {}

		if not ConvexHits then return Before end

		for _, Hit in ipairs(ConvexHits) do
			local Convex = MeshData.Convexes[Hit.ConvexID]

			if Convex then Before[Hit] = { Convex = Convex, Area = Convex.HoleArea } end
		end

		return Before
	end

	-- The thin shell around the fuel opens wherever a round goes in, not just where one comes out.
	-- A liner only closes what the hit opened, so a capped convex's earlier tear stays open.
	local function PunchHoles(Entity, HitConvexes)
		for Hit, Entry in pairs(HitConvexes) do
			if Hit.HitArea and (Hit.Frac or 1) > 0 then Damage.AddConvexHole(Entry.Convex, Hit.HitArea, Entity, Hit.EntryPos, Hit.ExitPos, Hit.EntryNormal) end
		end

		if not Entity.SelfSealing then return end

		for Hit, Entry in pairs(HitConvexes) do
			local Convex = Entry.Convex
			local Opened = (Convex.HoleArea or 0) - (Entry.Area or 0) -- 0 once a hit sharing this convex took it

			if Opened > 0 and (Hit.HitArea or 0) / (Hit.Holes or 1) <= SEAL_MAX_AREA then
				-- The hole leaks from the seal instead of the convex, so closing it removes the seal rather than
				-- subtracting back out of the convex, which would leave rounding behind as a leak that never ends
				Convex.HoleArea = Entry.Area

				local Seals = Entity.Seals or {}

				Seals[#Seals + 1] = { Area = Opened, Time = Clock.CurTime + SEAL_TIME }

				Entity.Seals = Seals
			end
		end
	end

	local function UpdateSeals(Entity, Now)
		local Seals = Entity.Seals

		if not Seals then return end

		for I = #Seals, 1, -1 do
			if Now >= Seals[I].Time then table.remove(Seals, I) end
		end

		if not Seals[1] then Entity.Seals = nil end
	end

	-- Running engines' hot surfaces can light a spill, even diesel
	local function IsNearRunningEngine(Entity)
		local Contraption = Entity:CFW_GetContraption()
		local Engines     = Contraption and Contraption.entsbyclass.acf_engine

		if not Engines then return false end

		local Center   = Entity:WorldSpaceCenter()
		local RangeSqr = ACF.FuelHotSurfaceRange * ACF.FuelHotSurfaceRange

		for Engine in pairs(Engines) do
			if IsValid(Engine) and Engine.Active then
				local EnginePoint = Engine:NearestPoint(Center)

				if Entity:NearestPoint(EnginePoint):DistToSqr(EnginePoint) <= RangeSqr then return true end
			end
		end

		return false
	end

	-- Hot engines can light a spill, and an unlit one runs off through the hull.
	-- A lit one is left to its fire, as draining it away would put out fires too small to outburn the drain.
	local function UpdateSpill(Entity, FuelType, DeltaTime)
		if Entity.Spilled <= 0 or Fire.IsBurning(Entity) then return end

		local Chance = FuelType and FuelType:GetIgnitionChance("HotSurface", 0) or 0

		if Chance > 0 and IsNearRunningEngine(Entity) and RollPerSecond(Chance, DeltaTime) and Fire.Ignite(Entity, "HotSurface") then return end

		Entity:TakeSpill(ACF.FuelPoolDrainRate * DeltaTime)
	end

	--- Moves leaking fuel into the spill, closes sealed holes and drains the spill away
	function ENT:Think()
		local Now       = Clock.CurTime
		local DeltaTime = math.min(Now - (self.LastThink or Now), 0.5)
		local FuelType  = self:ACF_GetUserVar("FuelType")
		local Leaking   = FuelType and FuelType:GetLeakRate(self) or 0 -- L/s
		local WasLeaking = self.Leaking > 0

		UpdateSeals(self, Now)

		if Leaking > 0 then FuelType:Release(self, Leaking * DeltaTime) end

		self.Leaking = Leaking

		if (Leaking > 0) ~= WasLeaking then UpdateLeakState(self) end

		UpdateSpill(self, FuelType, DeltaTime)

		if (Leaking > 0 or self.Spilled > 0) and Debug.SetDeveloperLevel(2) then
			Debug.EntityText(self, 2, ("Leak %.2f L/s, spill %.1f kg over %.2f m²"):format(Leaking, self.Spilled, self.PoolArea), DEBUG_TICK_LIFE, COLOR_FUEL)
		end

		self.LastThink = Now

		if Leaking > 0 or self.Seals or self.Spilled > 0 then
			self:NextThink(Now + 0.25)

			return true
		end

		return false
	end

	--- Handles damage to fuel tanks
	--- Damage spills fuel, which can then be lit depending on what hit the tank and the fuel type
	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		local OldHealth   = self.ACF.Health
		local HitConvexes = GetHitConvexes(self, DmgInfo) -- Before the hit's exit holes go in
		local HitRes      = Damage.doPropDamage(self, DmgResult, DmgInfo)
		local FuelType    = self:ACF_GetUserVar("FuelType")

		if not FuelType then return HitRes end

		local Attacker = DmgInfo:GetAttacker()

		if IsValid(Attacker) and Attacker:IsPlayer() then self.Attacker = Attacker end

		self.Inflictor = DmgInfo:GetInflictor()

		PunchHoles(self, HitConvexes)

		self.Leaking = FuelType:GetLeakRate(self)

		UpdateLeakState(self)

		self:NextThink(Clock.CurTime)

		local Source = Fire.GetIgnitionSource(self, DmgInfo)

		if not Source or Fire.IsBurning(self) then return HitRes end

		local Destroyed = ACF.IsDestroyed(self)
		local Damaged   = Destroyed and 1 or (OldHealth - self.ACF.Health) / self.ACF.MaxHealth

		if math.random() < FuelType:GetIgnitionChance(Source, Damaged) and Fire.Ignite(self, Source) and Destroyed then
			self:Fireball(FuelType:GetFlashAmount(self))
		end

		return HitRes
	end
end

do -- MARK: Fire
	--- Flashes over fuel a rupture sprays out of the tank, creating an explosion
	--- @param Sprayed number Liters taken from the tank, see FuelType:GetFlashAmount.
	function ENT:Fireball(Sprayed)
		Sprayed = math.min(Sprayed, self.Amount)

		if Sprayed <= 0 then return end
		if not HookRun("ACF_PreExplodeFuel", self) then return end

		self:Consume(Sprayed)

		local Position  = self:WorldSpaceCenter()
		local Explosive = Sprayed * self.UnitMass * ACF.FuelFireballYield
		local DmgInfo   = Objects.DamageInfo(self.Attacker or self, self.Inflictor)

		Damage.createExplosion(Position, Explosive, Explosive * 0.5, { self }, DmgInfo)
		Damage.explosionEffect(Position, nil, Explosive)
	end

	--- Ruptures the tank, as when what it's mounted on is destroyed, and lets flames light what comes out
	function ENT:Detonate()
		local FuelType = self:ACF_GetUserVar("FuelType")

		if not FuelType then return end

		local Sprayed = FuelType:GetFlashAmount(self) -- Held back so the spill doesn't take it

		FuelType:Release(self, self.Amount - Sprayed)

		if math.random() < FuelType:GetIgnitionChance("Fire", 1) and Fire.Ignite(self, "Fire") then
			self:Fireball(Sprayed)
		end

		FuelType:Release(self, self.Amount) -- Whatever didn't flash over
	end

	function ENT:ACF_OnIgnite()
		local FuelType = self:ACF_GetUserVar("FuelType")

		return FuelType ~= nil and FuelType:CanBurn(self)
	end

	function ENT:ACF_IsSuppressible()
		local FuelType = self:ACF_GetUserVar("FuelType")

		return FuelType ~= nil and FuelType.Suppressible
	end

	--- @return number|nil # Heat released in watts, nil once there's nothing left to burn
	function ENT:ACF_FireTick(DeltaTime)
		local FuelType = self:ACF_GetUserVar("FuelType")

		if not FuelType then return end

		return FuelType:Burn(self, DeltaTime)
	end

	--- Flames reaching spilled fuel light it, and enough heat makes an intact tank vent and catch fire
	function ENT:ACF_OnHeat(Flux, DeltaTime)
		if Fire.IsBurning(self) then return end

		local FuelType = self:ACF_GetUserVar("FuelType")

		if not FuelType then return end

		if Flux >= ACF.FireContactFlux and FuelType:IsExposed(self) then
			if RollPerSecond(FuelType:GetIgnitionChance("Fire", 1), DeltaTime) then Fire.Ignite(self, "Fire") end

			return
		end

		if Fire.AddHeatDose(self, Flux, DeltaTime) < ACF.FuelTankHeatDose then return end

		FuelType:Release(self, self.Amount * BOIL_OFF)

		Fire.Ignite(self, "Heat")
	end
end
