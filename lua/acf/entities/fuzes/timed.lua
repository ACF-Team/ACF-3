
local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.Fuze.Timed", "ACF.Missiles.Fuze.Contact", function()
	CLASS.Name = "Timed"
	local BASE = BASE

	CLASS.MinTime = 1
	CLASS.MaxTime = 30

	MENU_FIELD("Number", "FuzeTimer", {Default = 0})

	function CLASS:OnFirst(Entity)
		BASE.OnFirst(self, Entity)

		self.Timer = self.FuzeTimer
	end

	function CLASS:WriteDisplayConfig(State)
		BASE.WriteDisplayConfig(self, State)
		State:AddSubKeyValue("Timer",  math.Round(self.Timer, 2) .. " s")
	end

	if CLIENT then
		CLASS.Description = "This fuze triggers upon direct contact, or when the timer ends. Delay in seconds."

		function CLASS:AddMenuControls(Base, ToolData, ...)
			BASE.AddMenuControls(self, Base, ToolData, ...)

			local Timer = Base:AddSlider("Fuze Timer", self.MinTime, self.MaxTime, 2)
			Timer:SetClientData("FuzeTimer", "OnValueChanged")
			Timer:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)

				return Value
			end)
		end
	else
		function CLASS:VerifyData(Weapon)
			BASE.VerifyData(self, Weapon)

			self.FuzeTimer = math.Clamp(self.FuzeTimer or 0, self.MinTime, self.MaxTime)
		end

		function CLASS:IsOnTime()
			return Clock.CurTime - self.TimeStarted >= self.Timer
		end

		function CLASS:GetDetonate()
			return self:IsArmed() and self:IsOnTime()
		end

		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.FuzeTimer = nil
		end
	end

end)