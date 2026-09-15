
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
		local Primary = self:GetGun1()
		if IsValid(Primary) then
			RecacheBindNW(self, SelfTbl, "AHS_Primary_SL", Primary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_AT", ACF.GetLegacyStyleClassName(Primary.BulletData.AmmoType), self.SetNWString)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_NF", Primary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_RT", Primary.ReloadTime or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_RD", Primary.State == "Loaded", self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Primary", Primary, self.SetNWEntity)
			RecacheBindNW(self, SelfTbl, "AHS_Primary_MV", Primary.BulletData.MuzzleVel or 0, self.SetNWFloat)
		end

		local Secondary = self:GetGun2()
		if IsValid(Secondary) then
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_SL", Secondary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_AT", ACF.GetLegacyStyleClassName(Secondary.BulletData.AmmoType), self.SetNWString)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_NF", Secondary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_RT", Secondary.ReloadTime or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary_RD", Secondary.State == "Loaded", self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Secondary", Secondary, self.SetNWEntity)
		end

		local Tertiary = self:GetGun3()
		if IsValid(Tertiary) then
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_SL", Tertiary.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_AT", ACF.GetLegacyStyleClassName(Tertiary.BulletData.AmmoType), self.SetNWString)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_NF", Tertiary.NextFire or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_RT", Tertiary.ReloadTime or 0, self.SetNWFloat)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary_RD", Tertiary.State == "Loaded", self.SetNWBool)
			RecacheBindNW(self, SelfTbl, "AHS_Tertiary", Tertiary, self.SetNWEntity)
		end

		if IsValid(SelfTbl.Smoke) then
			RecacheBindNW(self, SelfTbl, "AHS_Smoke_SL", SelfTbl.Smoke.TotalAmmo or 0, self.SetNWInt)
			RecacheBindNW(self, SelfTbl, "AHS_Smoke_RD", SelfTbl.Smoke.State == "Loaded" or false, self.SetNWBool)
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
		local Contraption = self:CFW_GetContraption()
		local Crew = Contraption and Contraption.Crews or {}
		for CrewMember, _ in pairs(Crew) do
			if CrewMember.IsAlive then AliveCrew = AliveCrew + 1 end
			TotalCrew = TotalCrew + 1
		end
		RecacheBindNW(self, SelfTbl, "AHS_Crew", AliveCrew, self.SetNWInt)
		RecacheBindNW(self, SelfTbl, "AHS_CrewCap", TotalCrew, self.SetNWInt) -- Should only run once effectively
	end
end