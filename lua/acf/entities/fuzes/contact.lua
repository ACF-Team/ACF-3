local ACF     = ACF
local Classes = ACF.Classes
local Clock   = ACF.Utilities.Clock

Classes.DefineClass("ACF.Missiles.Fuze.Contact", "ACF.Missiles.Fuze", function()
	CLASS.Name = "Contact"
	CLASS.MinDelay = 0
	CLASS.MaxDelay = 10

	MENU_FIELD("Number", "ArmingDelay", {Default = 0})

	function CLASS:OnLoaded()
		self.Name = self.ID -- Workaround
	end

	function CLASS:OnFirst(_)
		self.Primer = self.ArmingDelay
	end

	function CLASS:Configure()
		self.TimeStarted = Clock.CurTime
	end

	function CLASS:WriteDisplayConfig(State)
		State:AddSubKeyValue("Primer", math.Round(self.Primer, 2))
	end

	if CLIENT then
		CLASS.Description = "This fuze triggers upon direct contact against solid surfaces."

		function CLASS:AddMenuControls(Base, ToolData)
			local Min = ACF.GetGunValue(ToolData.Weapon, "ArmDelay") or self.MinDelay

			local Delay = Base:AddSlider("Arming Delay", Min, self.MaxDelay, 2)
			Delay:SetClientData("ArmingDelay", "OnValueChanged")
			Delay:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)

				return Value
			end)
		end
	else
		function CLASS:GetCost()
			return 0
		end

		function CLASS:VerifyData(Weapon)
			local Delay = self.ArmingDelay
			local Min = Weapon.ArmDelay or self.MinDelay

			Data.ArmingDelay = math.Clamp(Delay or 0, Min, self.MaxDelay)
		end

		function CLASS:IsArmed()
			return Clock.CurTime - self.TimeStarted >= self.Primer
		end

		-- Do nothing, projectiles auto-detonate on contact anyway.
		function CLASS:GetDetonate()
			return false
		end

		function CLASS:OnLast(Entity)
			Entity.ArmingDelay = nil
		end
	end
end)