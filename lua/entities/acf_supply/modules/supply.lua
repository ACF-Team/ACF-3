local ACF           = ACF
local Utilities     = ACF.Utilities
local Clock         = Utilities.Clock
local Sounds        = Utilities.Sounds
local ActiveCrates  = ACF.AmmoCrates or {}
local ActiveTanks   = ACF.FuelTanks or {}
local SupplyDist2   = (ACF.SupplyDistance or 300) * (ACF.SupplyDistance or 300)
local CombatTimeout = 30 / engine.TickInterval() -- 30 seconds

local function SupplyEffect(Entity, RefilledAmmo, RefilledFuel)
	net.Start("ACF_SupplyEffect")
		net.WriteEntity(Entity)
		net.WriteBool(RefilledAmmo)
		net.WriteBool(RefilledFuel)
	net.Broadcast()
end

local function StopSupplyEffect(Entity)
	net.Start("ACF_StopSupplyEffect")
		net.WriteEntity(Entity)
	net.Broadcast()
end

local function SetEffectState(Entity, Active, RefilledAmmo, RefilledFuel)
	if Active and not Entity.EffectActive then
		Entity.EffectActive = true
		SupplyEffect(Entity, RefilledAmmo, RefilledFuel)
	elseif not Active and Entity.EffectActive then
		Entity.EffectActive = nil
		StopSupplyEffect(Entity)
	end
end

local function CanSupply(Supply, Target, Distance2)
	if Supply == Target then return false end
	if Target.Disabled then return false end
	if Target.Damaged then return false end

	local Amount = Target.Amount
	local Cap    = Target.Capacity

	if (Cap - Amount) <= 0.005 then return false end -- Treat near-full as full to avoid micro top-ups

	-- Check if target's contraption is in combat
	local TC = Target:GetContraption()
	if TC and TC.InCombat and (engine.TickCount() - TC.InCombat) < CombatTimeout then
		return false -- Still in combat, cannot refill
	end

	return Distance2 <= SupplyDist2
end

function ENT:Enable()
	if self.BaseClass.Enable then
		self.BaseClass.Enable(self)
	end

	-- Start thinking when enabled
	self.LastThink = Clock.CurTime
	self:NextThink(Clock.CurTime + 1)
end

function ENT:Disable()
	if self.BaseClass.Disable then
		self.BaseClass.Disable(self)
	end

	-- Stop effect when disabled
	SetEffectState(self, false)
end

function ENT:Think()
	-- Only think if active
	if not self.Active then return end

	local Now = Clock.CurTime
	local DT  = Now - (self.LastThink or Now)

	self.LastThink = Now
	self:NextThink(Now + 1)

	if not self:CanConsume() then
		SetEffectState(self, false)
		return true
	end

	-- Search for targets to supply
	local Pos = self:GetPos()
	local Recipients, Count = {}, 0

	for Target in pairs(ActiveCrates) do
		if IsValid(Target) then
			local Dist2 = Pos:DistToSqr(Target:GetPos())
			if CanSupply(self, Target, Dist2) then
				Count = Count + 1
				Recipients[Count] = Target
			end
		end
	end

	for Target in pairs(ActiveTanks) do
		if IsValid(Target) then
			local Dist2 = Pos:DistToSqr(Target:GetPos())
			if CanSupply(self, Target, Dist2) then
				Count = Count + 1
				Recipients[Count] = Target
			end
		end
	end

	if Count == 0 then
		SetEffectState(self, false)
		return true
	end

	-- Determine how much mass we can transfer
	local TransferRate = ACF.SupplyMassRate * self.Volume
	local Budget       = math.min(TransferRate * math.max(DT, 0), self.Amount)

	if Budget <= 0 then return true end

	local PerTargetBudget = Budget / Count
	local UsedBudget = 0
	local RefilledAmmo, RefilledFuel = false, false

	for i = 1, Count do
		local Remaining = self.Amount - UsedBudget
		if Remaining <= 0 then break end

		local Target   = Recipients[i]
		local UnitMass = Target:GetUnitMass()
		local Need     = Target.Capacity - Target.Amount

		-- Determine how much mass we can transfer to this target
		local TransferMass = math.min(PerTargetBudget, Remaining)

		if Target.IsACFAmmoCrate then
			-- For ammo crates: only whole cartridges can be transferred
			-- If we can't transfer enough mass for a full cartridge, build it up until we can

			local Buffer = (self.MassBuffers[Target] or 0) + TransferMass -- Add mass to buffer
			local Units  = math.min(math.floor(Buffer / UnitMass), Need) -- Check if we have enough in the buffer for at least one cartridge

			if Units > 0 then
				-- There is enough: Transfer as many as possible
				Target:Consume(-Units)
				RefilledAmmo = true

				Sounds.SendSound(self, "acf_base/fx/resupply_single.mp3", 70, 100, 0.5)

				local TransferredMass = Units * UnitMass

				UsedBudget = UsedBudget + TransferredMass
				Buffer     = Buffer - TransferredMass

				if Units < Need then
					-- Not all units were transferred: Keep the remaining mass in the buffer
					self.MassBuffers[Target] = Buffer
				else
					-- All units were transferred: Clear the buffer
					self.MassBuffers[Target] = nil
				end
			else
				-- Not enough: Build up the buffer until we have enough for a cartridge
				self.MassBuffers[Target] = Buffer
			end
		else
			-- For fuel tanks, transfer any fractional amount. They're liquids after all!
			local Units = math.min(TransferMass / UnitMass, Need)

			Target:Consume(-Units)
			RefilledFuel = true

			if Target.FuelType == "Electric" then
				Sounds.SendSound(self, "ambient/energy/newspark04.wav", 70, 100, 0.5)
				Sounds.SendSound(Target, "ambient/energy/newspark04.wav", 70, 100, 0.5)
			else
				Sounds.SendSound(self, "vehicles/jetski/jetski_no_gas_start.wav", 70, 120, 0.5)
				Sounds.SendSound(Target, "vehicles/jetski/jetski_no_gas_start.wav", 70, 120, 0.5)
			end

			UsedBudget = UsedBudget + Units * UnitMass
		end
	end

	-- Show effect if we're trying to refill anything
	SetEffectState(self, true, RefilledAmmo, RefilledFuel)

	if UsedBudget > 0 then
		self:Consume(UsedBudget)
	end

	-- Clean up buffers
	for Target in pairs(self.MassBuffers) do
		if not IsValid(Target) or not CanSupply(self, Target, Pos:DistToSqr(Target:GetPos())) then
			self.MassBuffers[Target] = nil
		end
	end

	return true
end