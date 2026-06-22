local Classes 	= ACF.Classes
Classes.DefineClass("ACF.Missiles.Guidance.RadioMCLOS", "ACF.Missiles.Guidance.Dumb", function()
	function CLASS:Configure(Missile)
		self.Source = Missile.Launcher
	end

	if CLIENT then
		CLASS.Description = "This guidance package allows you to manually control the direction of the missile."
	else
		local TraceData = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY }
		local Trace     = ACF.trace

		function CLASS:GetCost()
			return 3
		end

		function CLASS:OnLaunched(Missile)
			self.InPos = Missile.MountPoint.Position
			self.OutPos = Missile.ExhaustPos
		end

		function CLASS:GetComputer()
			local Source = self.Source

			if not IsValid(Source) then return end

			local Computer = Source.Computer

			if not IsValid(Computer) then return end
			if Computer.Disabled then return end

			return Computer
		end

		function CLASS:CheckComputer()
			local Computer = self:GetComputer()

			if not Computer then return end
			if not Computer.IsJoystick then return end

			local Pitch = Computer.Pitch or 0
			local Yaw = Computer.Yaw or 0

			return -Pitch, -Yaw
		end

		function CLASS:CheckLOS(Missile)
			if not IsValid(self.Source) then return end
			TraceData.start = self.Source:LocalToWorld(self.InPos)
			TraceData.endpos = Missile:LocalToWorld(self.OutPos)

			local Result = Trace(TraceData)

			return not Result.Hit
		end

		function CLASS:GetGuidance(Missile)
			if not self:CheckLOS(Missile) then return {} end

			local Pitch, Yaw = self:CheckComputer()

			if not Pitch then return {} end
			if Pitch == 0 and Yaw == 0 then return {} end

			local Direction = Angle(Pitch, Yaw):Forward() * 12000

			return { TargetPos = Missile:LocalToWorld(Direction) }
		end
	end
end)