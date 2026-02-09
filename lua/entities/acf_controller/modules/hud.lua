
local RecacheBindNW = ENT.RecacheBindNW
-- Hud related
do
	local BallCompStatusToCode = {
		-- Busy
		["Calculating..."] = 1,
		["Processing..."] = 1,
		["Tracking"] = 1,
		["Adjusting..."] = 1,
		-- Success
		["Ready"] = 2,
		["Super elevation calculated!"] = 2,
		["Firing solution found!"] = 2,
		-- Error
		["Target unable to be reached!"] = 3,
		["Gun unlinked!"] = 3,
		["Took too long!"] = 3,
		["Disabled"] = 3,
	}

	function ENT:ProcessHUDs(SelfTbl)
		-- Network various statistics
		if IsValid(SelfTbl.Primary) then
			RecacheBindNW(self, SelfTbl, "AHS_Primary_SL", SelfTbl.Primary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_AT", SelfTbl.Primary.BulletData.Type or 0, self.SetNWString)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_NF", SelfTbl.Primary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_RT", SelfTbl.Primary.ReloadTime or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_RD", SelfTbl.Primary.State == "Loaded" or false, self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Primary", SelfTbl.Primary, self.SetNWEntity)
		else
			SelfTbl.Primary = next(self.GunsPrimary)
		end

		if IsValid(SelfTbl.Secondary) then
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_SL", SelfTbl.Secondary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_AT", SelfTbl.Secondary.BulletData.Type or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_NF", SelfTbl.Secondary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_RT", SelfTbl.Secondary.ReloadTime or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_RD", SelfTbl.Secondary.State == "Loaded" or false, self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary", SelfTbl.Secondary, self.SetNWEntity)
		else
			SelfTbl.Secondary = next(self.GunsSecondary)
		end

		if IsValid(SelfTbl.Tertiary) then
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_SL", SelfTbl.Tertiary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_AT", SelfTbl.Tertiary.BulletData.Type or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_NF", SelfTbl.Tertiary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_RT", SelfTbl.Tertiary.ReloadTime or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_RD", SelfTbl.Tertiary.State == "Loaded" or false, self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary", SelfTbl.Tertiary, self.SetNWEntity)
		else
			SelfTbl.Tertiary = next(self.Racks)
		end

		if IsValid(SelfTbl.Smoke) then
			RecacheBindNW(self, SelfTbl, "AHS_Smoke_SL", SelfTbl.Smoke.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Smoke_RD", SelfTbl.Smoke.State == "Loaded" or false, self.SetNWBool)
		else
			SelfTbl.Smoke = next(self.GunsSmoke)
		end

		if IsValid(SelfTbl.TurretComputer) then
			local Status = SelfTbl.TurretComputer.Status
			local Code = BallCompStatusToCode[Status] or 0
			RecacheBindNW(self, SelfTbl, "AHS_TurretComp_Status", Code, self.SetNWInt)
		end

		RecacheBindNW(self, SelfTbl, "AHS_Speed", math.Round(SelfTbl.Speed or 0), self.SetNWInt)
		if IsValid(SelfTbl.Gearbox) then RecacheBindNW(self, SelfTbl, "AHS_Gear", SelfTbl.Gearbox.Gear, self.SetNWInt) end

		local FuelLevel = 0
		local Conv = self:GetFuelUnit() == 0 and 1 or 0.264172 -- Liters / Gallons
		for Fuel in pairs(SelfTbl.Fuels) do
			if IsValid(Fuel) then FuelLevel = FuelLevel + Fuel.Amount end
		end
		RecacheBindNW(self, SelfTbl, "AHS_Fuel", math.Round(FuelLevel * Conv), self.SetNWInt)
		RecacheBindNW(self, SelfTbl, "AHS_FuelCap", math.Round(SelfTbl.FuelCapacity * Conv), self.SetNWInt) -- Should only run once effectively

		local RPM = 0
		local EngineCount = 0
		for Engine in pairs(SelfTbl.Engines) do
			if IsValid(Engine) then
				RPM = RPM + Engine.FlyRPM
				EngineCount = EngineCount + 1
			end
		end
		local AvgRPM = EngineCount > 0 and RPM / EngineCount or 0
		RecacheBindNW(self, SelfTbl, "AHS_RPM", math.Round(AvgRPM / 100) * 100, self.SetNWInt)

		local AliveCrew = 0
		local TotalCrew = 0
		local Contraption = self:GetContraption()
		local Crew = Contraption and Contraption.Crews or {}
		for CrewMember, _ in pairs(Crew) do
			if CrewMember.IsAlive then AliveCrew = AliveCrew + 1 end
			TotalCrew = TotalCrew + 1
		end
		RecacheBindNW(self, SelfTbl, "AHS_Crew", AliveCrew, self.SetNWInt)
		RecacheBindNW(self, SelfTbl, "AHS_CrewCap", TotalCrew, self.SetNWInt) -- Should only run once effectively
	end
end