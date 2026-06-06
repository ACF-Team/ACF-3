local ACF     = ACF
local Classes = ACF.Classes
local Fuzes   = Classes.Fuzes
local Fuze    = Fuzes.Register("Optical", "Contact")

Fuze.MinDistance = 40
Fuze.MaxDistance = 2500

function Fuze:WriteDisplayConfig(State)
	Fuze.BaseClass.WriteDisplayConfig(self, State)
	State:AddSubKeyValue("Distance", math.Round(self.Distance * ACF.InchToMeter, 2) .. " m")
end

if CLIENT then
	Fuze.Description = "This fuze fires a beam directly ahead and detonates when the beam hits something close-by. Distance in inches."

	function Fuze:AddMenuControls(Base, ToolData, ...)
		Fuze.BaseClass.AddMenuControls(self, Base, ToolData, ...)

		local Distance = Base:AddSlider("Fuze Distance", self.MinDistance, self.MaxDistance, 2)
		Distance:SetClientData("FuzeDistance", "OnValueChanged")
		Distance:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end
else
	local TraceData = { start = true, endpos = true, filter = true }
	local Entities  = Classes.Entities
	local Trace     = ACF.trace

	Entities.AddArguments("acf_ammo", "FuzeDistance") -- Adding extra info to ammo crates

	function Fuze:GetCost()
		return 1
	end

	function Fuze:VerifyData(EntClass, Data, ...)
		Fuze.BaseClass.VerifyData(self, EntClass, Data, ...)

		local Distance = Data.FuzeDistance
		local Args = Data.FuzeArgs

		if not ACF.CheckNumber(Distance) and Args then
			Distance = ACF.CheckNumber(Args.DS) or 0

			Args.DS = nil
		end

		Data.FuzeDistance = math.Clamp(Distance or 0, self.MinDistance, self.MaxDistance)
	end

	function Fuze:OnFirst(Entity, Data)
		Fuze.BaseClass.OnFirst(self, Entity, Data)

		self.Distance = Data.FuzeDistance
	end

	function Fuze:GetDetonate(Missile)
		if not self:IsArmed() then return false end

		local Position = Missile:GetPos()

		TraceData.start = Position
		TraceData.endpos = Position + Missile:GetForward() * self.Distance
		TraceData.filter = Missile.Filter or { Missile }

		return Trace(TraceData).Hit
	end

	function Fuze:OnLast(Entity)
		Fuze.BaseClass.OnLast(self, Entity)

		Entity.FuzeDistance = nil
	end
end
