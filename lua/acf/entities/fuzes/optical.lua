local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.Fuze.Optical", "ACF.Missiles.Fuze.Contact", function()
	local BASE = BASE
	CLASS.MinDistance = 40
	CLASS.MaxDistance = 2500

	MENU_FIELD("Number", "FuzeDistance", {Default = 0})

	function CLASS:WriteDisplayConfig(State)
		BASE.WriteDisplayConfig(self, State)
		State:AddSubKeyValue("Distance", math.Round(self.Distance * ACF.InchToMeter, 2) .. " m")
	end

	if CLIENT then
		CLASS.Description = "This fuze fires a beam directly ahead and detonates when the beam hits something close-by. Distance in inches."

		function CLASS:AddMenuControls(Base, ToolData, ...)
			BASE.AddMenuControls(self, Base, ToolData, ...)

			local Distance = Base:AddSlider("Fuze Distance", self.MinDistance, self.MaxDistance, 2)
			Distance:SetClientData("FuzeDistance", "OnValueChanged")
			Distance:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)

				return Value
			end)
		end
	else
		local TraceData = { start = true, endpos = true, filter = true }
		local Trace     = ACF.trace

		function CLASS:GetCost()
			return 1
		end

		function CLASS:VerifyData(EntClass, Data, ...)
			BASE.VerifyData(self, EntClass, Data, ...)

			local Distance = Data.FuzeDistance
			local Args = Data.FuzeArgs

			if not ACF.CheckNumber(Distance) and Args then
				Distance = ACF.CheckNumber(Args.DS) or 0

				Args.DS = nil
			end

			Data.FuzeDistance = math.Clamp(Distance or 0, self.MinDistance, self.MaxDistance)
		end

		function CLASS:OnFirst(Entity)
			BASE.OnFirst(self, Entity)

			self.Distance = self.FuzeDistance
		end

		function CLASS:GetDetonate(Missile)
			if not self:IsArmed() then return false end

			local Position = Missile:GetPos()

			TraceData.start = Position
			TraceData.endpos = Position + Missile:GetForward() * self.Distance
			TraceData.filter = Missile.Filter or { Missile }

			return Trace(TraceData).Hit
		end

		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.FuzeDistance = nil
		end
	end
end)