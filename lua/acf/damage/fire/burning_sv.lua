local ACF     = ACF
local Fire    = ACF.Damage.Fire
local Debug   = ACF.Debug
local HookRun = hook.Run

local DEBUG_TICK_LIFE  = ACF.FireTickRate * 1.2 -- Just over a fire tick, so drawings refreshed every tick stay up
local DEBUG_EVENT_LIFE = 4
local COLOR_FIRE       = Color(255, 140, 40)

-- Kept across reloads so lit fires survive a refresh of this file
Fire.Burning = Fire.Burning or {} -- Burning[Entity] = CurTime() its fire next ticks at

do -- MARK: Ignition
	local SourceNames = {
		Hit        = "hit",
		Jet        = "HEAT jet",
		Fire       = "flames",
		HotSurface = "hot engine",
		Heat       = "heat",
	}

	--- Works out what could have lit fuel from a damage event.
	--- Explosions light whatever their fireball reaches as flames would.
	--- @param Entity entity The entity that was hit.
	--- @param DmgInfo table The DamageInfo object of the hit.
	--- @return string|nil # "Hit", "Jet" or "Fire", or nil if it can't ignite anything.
	function Fire.GetIgnitionSource(Entity, DmgInfo)
		if DmgInfo:GetType() == DMG_PLASMA then return "Fire" end -- The torch

		local Source = DmgInfo:GetIgnition()
		local Radius = DmgInfo:GetFireballRadius()

		if Radius and (Source == "Blast" or Source == "Hit") then
			local Origin = DmgInfo:GetOrigin()

			if Entity:NearestPoint(Origin):DistToSqr(Origin) <= Radius * Radius then return "Fire" end
		end

		if Source == "Blast" then return end -- Overpressure alone doesn't light fuel

		return Source
	end

	--- @return boolean # Whether an extinguisher's agent can put out the entity's fire. Fires that carry their own
	--- oxygen, such as a main-gun cookoff or a battery's thermal runaway, burn on whatever floods them.
	function Fire.IsSuppressible(Entity)
		return Entity.ACF_IsSuppressible ~= nil and Entity:ACF_IsSuppressible() == true
	end

	--- @return boolean # Whether agent an extinguisher flooded the entity with still keeps it from catching fire.
	function Fire.IsInerted(Entity)
		return (Entity.ACF_InertUntil or 0) > CurTime() and Fire.IsSuppressible(Entity)
	end

	--- Sets off the extinguishers watching an entity, as when it catches fire or gets too hot.
	--- @param Flux number|nil W/m² heating it, nil when it caught fire.
	function Fire.Alert(Entity, Flux)
		for Extinguisher in pairs(ACF.Extinguishers) do
			if IsValid(Extinguisher) and Extinguisher:IsWatching(Entity) then Extinguisher:Detect(Entity, Flux) end
		end
	end

	--- Sets an entity on fire. The entity decides if it has anything to burn through ENT:ACF_OnIgnite.
	--- @param Entity entity The entity to ignite.
	--- @param Source string What lit it, see Fire.GetIgnitionSource, or "HotSurface"/"Heat".
	--- @return boolean # True if the entity is burning afterwards.
	function Fire.Ignite(Entity, Source)
		if Fire.Burning[Entity] then return true end
		if not ACF.FireEnabled then return false end
		if not Entity.ACF_FireTick then return false end
		if Fire.IsInerted(Entity) then return false end
		if not HookRun("ACF_PreIgnite", Entity, Source) then return false end
		if Entity.ACF_OnIgnite and Entity:ACF_OnIgnite(Source) == false then return false end

		Fire.Burning[Entity] = CurTime() -- Ticks from now on, every fire tick

		Entity.ACF_IgnitionSource = Source
		Entity:SetNW2Bool("ACF_Burning", true)

		if Debug.SetDeveloperLevel(1) then
			Debug.EntityText(Entity, -1, "Ignited by " .. (SourceNames[Source] or tostring(Source)), DEBUG_EVENT_LIFE, COLOR_FIRE)
		end

		if Entity.UpdateOverlay then Entity:UpdateOverlay() end

		Fire.Alert(Entity)

		return true
	end

	--- Puts out a burning entity.
	--- @param Entity entity The entity to extinguish.
	function Fire.Extinguish(Entity)
		if not Fire.Burning[Entity] then return end

		Fire.Burning[Entity] = nil

		Fire.ForgetHeat(Entity)

		if not IsValid(Entity) then return end

		Entity.ACF_IgnitionSource = nil
		Entity:SetNW2Bool("ACF_Burning", false)

		if Entity.ACF_OnExtinguish then Entity:ACF_OnExtinguish() end
		if Entity.UpdateOverlay then Entity:UpdateOverlay() end
	end

	--- @param Entity entity
	--- @return boolean # Whether the entity is currently burning.
	function Fire.IsBurning(Entity)
		return Fire.Burning[Entity] ~= nil
	end

	--- Has a burning entity's fire tick again as soon as it can, its rhythm counting on from then, as when something
	--- it was waiting on is ready.
	function Fire.Wake(Entity)
		if Fire.Burning[Entity] then Fire.Burning[Entity] = CurTime() end
	end

	--- Adds the entity's fire state, and what lit it, to its overlay.
	function Fire.AddOverlay(Entity, State)
		if not Fire.Burning[Entity] then return end

		State:AddWarning(("Burning (%s)"):format(SourceNames[Entity.ACF_IgnitionSource] or "unknown"))
	end
end

do -- MARK: Fire tick
	local Exposure  = {} -- Exposure[Entity] = W/m² the fire ticking now sends it
	local Engulfing = {} -- Engulfing[Entity] = W/m² of the flames of the fire ticking now that it's in
	local Due       = {} -- Fires due this frame; one can light others, which mustn't join Burning mid-traversal

	-- Burns one fire's fuel and sends its heat out, or puts it out once there's nothing left.
	-- ACF_FireTick returns the watts it releases (nil once burnt out), and optionally a list of jets,
	-- { Origin, Axis, Wall, HeatRelease }, carrying more of its heat out of a breached wall, and the entities
	-- its flames wash over, { [Entity] = W/m² }.
	local function TickFire(Entity, DeltaTime, TickCount)
		if not Fire.Burning[Entity] then return end -- Put out earlier this frame
		if not IsValid(Entity) then
			Fire.Burning[Entity] = nil

			return Fire.ForgetHeat(Entity)
		end

		if not ACF.FireEnabled then return Fire.Extinguish(Entity) end

		local HeatRelease, Jets, Engulfed = Entity:ACF_FireTick(DeltaTime)

		if not HeatRelease then return Fire.Extinguish(Entity) end

		local Contraption = Entity:CFW_GetContraption()

		if Contraption then Contraption.InCombat = TickCount end -- Crew don't recover while their vehicle burns

		if HeatRelease > 0 then
			Fire.SpreadHeat(Entity, HeatRelease, Exposure)

			for _, Jet in ipairs(Jets or {}) do
				if Jet.HeatRelease > 0 then Fire.SpreadHeat(Entity, Jet.HeatRelease, Exposure, Jet.Origin, Jet.Axis, Jet.Wall) end
			end

			for Target, Flux in pairs(Engulfed or {}) do
				if IsValid(Target) and not Fire.Burning[Target] then Engulfing[Target] = Flux end
			end
		end

		if Debug.SetDeveloperLevel(2) then
			Debug.EntityText(Entity, 0, ("Fire %.2f MW"):format(HeatRelease / 1e6), DEBUG_TICK_LIFE, COLOR_FIRE)
		end

		-- Applied even with nothing sent, so what it no longer reaches stops counting it
		Fire.ApplyHeat(Entity, Exposure, Engulfing, DeltaTime)
	end

	-- Every fire ticks on its own rhythm from when it was lit, so fires lit at different moments tick at different moments
	hook.Add("Think", "ACF_FireTick", function()
		local Now       = CurTime()
		local Rate      = ACF.FireTickRate
		local TickCount = engine.TickCount()
		local Count     = 0

		for Entity, Next in pairs(Fire.Burning) do
			if Next <= Now then
				Count = Count + 1

				Due[Count] = Entity
			end
		end

		for I = 1, Count do
			local Entity = Due[I]
			local Next   = Fire.Burning[Entity]

			Due[I] = nil

			if Next then
				-- A server hitch shouldn't make it catch up with several ticks in a row
				Fire.Burning[Entity] = Next + Rate > Now and Next + Rate or Now + Rate

				-- An error would stop this fire for good, so it goes out through Extinguish so its own cleanup runs
				-- (a crate's cookoff detonates instead of sticking).
				if not xpcall(TickFire, ErrorNoHaltWithStack, Entity, Rate, TickCount) then
					xpcall(Fire.Extinguish, ErrorNoHaltWithStack, Entity)
				end

				table.Empty(Exposure)
				table.Empty(Engulfing)
			end
		end
	end)

	-- Walls heat and cool on a rhythm of their own, from whatever reached them since
	timer.Create("ACF_FireWalls", ACF.FireTickRate, 0, function()
		Fire.UpdateWalls(ACF.FireTickRate)
	end)
end
