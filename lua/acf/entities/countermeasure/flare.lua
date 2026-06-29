local ACF             = ACF
local Countermeasures = ACF.Classes.Countermeasures
local Countermeasure  = Countermeasures.Register("Flare")

function Countermeasure:OnLoaded()
	self.Name = self.ID -- Workaround
	self.AppliesTo = {
		Infrared = true,
		["Active Radar"] = true,
		["Semi-Active Radar"] = true,
	}
end

if SERVER then
	local Clock   = ACF.Utilities.Clock
	local Bullets = ACF.Ballistics.Bullets

	Countermeasure.SuccessChance   = 1 -- chance as a fraction, 0 - 1
	Countermeasure.Active          = false
	Countermeasure.ApplyContinuous = false -- indicate to ACF that this should only be applied when guidance is activated or Flare is spawned - not per-frame.

	function Countermeasure:Configure(Flare)
		self.Flare = Flare
		self.SuccessChance = Flare.DistractChance

		self:UpdateActive()
	end

	function Countermeasure:UpdateActive()
		local Flare = self.Flare

		self.Active = Flare and (Flare.CreateTime + Flare.BurnTime) > Clock.CurTime or false
	end

	function Countermeasure:GetGuidanceOverride()
		if not self.Flare then return end

		self:UpdateActive()

		if not self.Active then return end

		local Flare = Bullets[self.Flare.Index]

		if not (Flare and Flare.FlareUID == self.Flare.FlareUID) then return end

		return { TargetPos = self.Flare.Pos }
	end

	-- TODO: refine formula.
	function Countermeasure:ApplyChance()
		self:UpdateActive()

		return self.Active and math.random() < self.SuccessChance or false
	end

	-- roll the dice against a missile.  returns true if the Flare succeeds in distracting the missile.
	-- does not actually apply the effect, just tests the chance of it happening.
	-- 'Flare' is bulletdata.
	function Countermeasure:TryAgainst(Missile, Guidance)
		if not self.Flare then return end

		self:UpdateActive()

		if not self.Active then return end

		local SeekCone = Guidance.SeekCone

		if not SeekCone or SeekCone <= 0 then return end

		local Position = Missile:GetPos()
		local Forward = Missile:GetForward()

		return Countermeasures.ConeContainsPos(Position, Forward, SeekCone, self.Flare.Pos) and self:ApplyChance(Missile, Guidance, self.Flare)
	end

	-- counterpart to ApplyAll.  this takes one Flare and applies it to all missiles.
	-- returns all missiles which should be affected by this Flare.
	function Countermeasure:ApplyToAll()
		if not self.Flare then return {} end

		self:UpdateActive()

		if not self.Active then return {} end

		local Result = {}
		local Targets = Countermeasures.GetAllMissilesWhichCanSee(self.Flare.Pos)

		for Missile in pairs(Targets) do
			local Guidance = Missile.GuidanceData

			if self:ApplyChance(Missile, Guidance) then
				Result[Missile] = true
			end
		end

		return Result
	end

	-- 'static' function to iterate over all flares in flight and return one which affects the guidance.
	-- TODO: apply sub-1 chance to distract guidance in Countermeasures.GetAnyFlareInCone.
	function Countermeasure.ApplyAll(Missile, Guidance)
		local SeekCone = Guidance.SeekCone

		if not SeekCone or SeekCone <= 0 then return end

		local Position = Missile:GetPos()
		local Forward = Missile:GetForward()
		local Flares = Countermeasures.GetFlaresInCone(Position, Forward, SeekCone)

		for Flare in pairs(Flares) do
			local Result = Flare.FlareObj

			if Result:ApplyChance(Missile, Guidance, Flare) then
				return Result
			end
		end
	end
end
