local ACF    = ACF
local Sounds = ACF.Utilities.Sounds

local function FindCratesAtStage(contraption, stage)
	local AmmosByStage = contraption and contraption.AmmosByStage or {}
	return AmmosByStage[stage] or {}
end

local function FindFirstStage(contraption)
	for i = ACF.AmmoStageMin, ACF.AmmoStageMax do
		local temp = FindCratesAtStage(contraption, i) or {}
		for v, _ in pairs(temp) do
			if IsValid(v) then return temp end
		end
	end
	return {}
end

local function FindCrateByStage(contraption, start, check, ...)
	local start = start or ACF.AmmoStageMin
	for i = start, ACF.AmmoStageMax do
		local StageCrates = FindCratesAtStage(contraption, i)
		for v, _ in pairs(StageCrates) do
			if check(v, ...) then return v end
		end
	end
	return nil
end

ACF.FindCratesAtStage = FindCratesAtStage
ACF.FindFirstStage = FindFirstStage
ACF.FindCrateByStage = FindCrateByStage

function ENT:CanRestock()
	local SelfTbl = self:GetTable()

	if SelfTbl.Disabled then return false end
	if not SelfTbl.Load then return false end
	if SelfTbl.Damaged then return false end
	if SelfTbl.IsBelted then return false end

	return SelfTbl.Amount < SelfTbl.Capacity
end

function ENT:Restock()
	local MagSize = math.max(self.MagSize or 1, 1)
	local AmmoCheck = self.Capacity - self.Amount >= MagSize
	local StockCheck = not self.IsRestocking
	if AmmoCheck and StockCheck then
		self.IsRestocking = true

		local crate = FindCrateByStage(
			self:GetContraption(),
			self.AmmoStage + 1,
			function(v) return IsValid(v) and v ~= self and v:CanConsume() and ACF.BulletEquality(self.BulletData, v.BulletData) end
		)

		if crate then
			local Transfer = math.min(MagSize, crate.Amount, self.Capacity - self.Amount)

			local IdealTime = ACF.CalcReloadTimeMag(self.Caliber, self.ClassData, self.WeaponData, self.BulletData, {MagSize = Transfer})
			ACF.ProgressTimer(
				self,
				function() return self:UpdateStockMod() end,
				function()
					Sounds.SendSound(crate, "acf_base/fx/resupply_single.mp3", 70, 100, 0.25)
					Sounds.SendSound(self, "acf_base/fx/resupply_single.mp3", 70, 100, 0.25)
					self.IsRestocking = false
					local Transfer = math.min(MagSize, crate.Amount, self.Capacity - self.Amount)
					crate:Consume(Transfer)
					self:Consume(-Transfer)
				end,
				{MinTime = 1.0,	MaxTime = 3.0, Progress = 0, Goal = IdealTime}
			)
		else
			self.IsRestocking = false
		end
	end
end