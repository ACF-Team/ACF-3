local TimerCreate = timer.Create
local TimerExists = timer.Exists

function ENT:CanConsume()
	if not ACF.IsOperational(self) then return false end
	if not self.Load then return false end
	if self.Amount <= 0 then return false end

	return self:FindNextKind() ~= nil
end

--- Sets the Loading output to whether weapons can take rounds from the crate now
function ENT:UpdateLoading()
	WireLib.TriggerOutput(self, "Loading", self:CanConsume() and 1 or 0)
end

function ENT:SetAmount(Amount)
	local OldAmount = self.Amount or 0

	-- Counts first, the base container refreshes the overlay that draws them
	self:SyncRoundCounts(math.Clamp(Amount or 0, 0, self.Capacity or 0))
	self.BaseClass.SetAmount(self, Amount)
	self:UpdateOverlay() -- The base skips changes soon after a refresh, so a resupply's last step could go unshown
	self.Ammo = self.Amount

	-- Play resupply sound when ammo increases
	if self.Amount > OldAmount then
		self:EmitSound("acf_base/fx/resupply_single.mp3", 70, 100, 0.5)
	end

	-- Keep trace invisibility and network the change
	self.ACF_InvisibleToTrace = self.Amount <= 0

	local ID = "ACF Ammo Buffer " .. self:EntIndex()
	if TimerExists(ID) then return end

	TimerCreate(ID, 0, 1, function()
		if not IsValid(self) then return end
		self:SetNWInt("Ammo", self.Amount)
	end)
end

function ENT:Consume(Amount)
	-- Default to consuming 1 round when Amount is unspecified (gun calls Crate:Consume())
	if Amount == nil then Amount = 1 end

	self.BaseClass.Consume(self, Amount)

	self:UpdateLoading()

	self.ACF_InvisibleToTrace = self.Amount <= 0

	local ID = "ACF Ammo Buffer " .. self:EntIndex()
	if TimerExists(ID) then return end

	TimerCreate(ID, 0.25, 1, function()
		if not IsValid(self) then return end

		self:SetNWInt("Ammo", self.Amount)
	end)
end

function ENT:Enable()
	self:UpdateLoading()

	self:UpdateMass(true)
end

function ENT:Disable()
	WireLib.TriggerOutput(self, "Loading", 0)

	self:UpdateMass(true)
end