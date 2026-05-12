local ACF     = ACF
local Classes = ACF.Classes
local Clock   = ACF.Utilities.Clock
local Fuzes   = Classes.Fuzes
local Fuze    = Fuzes.Register("Contact")

Fuze.MinDelay = 0
Fuze.MaxDelay = 10

function Fuze:OnLoaded()
	self.Name = self.ID -- Workaround
end

function Fuze:OnFirst(_, Data)
	self.Primer = Data.ArmingDelay
end

function Fuze:Configure()
	self.TimeStarted = Clock.CurTime
end

function Fuze:WriteDisplayConfig(State)
	State:AddSubKeyValue("Primer", math.Round(self.Primer, 2))
end

if CLIENT then
	Fuze.Description = "This fuze triggers upon direct contact against solid surfaces."

	function Fuze:AddMenuControls(Base, ToolData)
		local Min = ACF.GetGunValue(ToolData.Weapon, "ArmDelay") or self.MinDelay

		local Delay = Base:AddSlider("Arming Delay", Min, self.MaxDelay, 2)
		Delay:SetClientData("ArmingDelay", "OnValueChanged")
		Delay:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end
else
	local Entities = Classes.Entities

	Entities.AddArguments("acf_ammo", "ArmingDelay") -- Adding extra info to ammo crates

	function Fuze:GetCost()
		return 0
	end

	function Fuze:VerifyData(_, Data)
		local Delay = Data.ArmingDelay
		local Args = Data.FuzeArgs

		if not ACF.CheckNumber(Delay) and Args then
			Delay = ACF.CheckNumber(Args.AD) or 0

			Args.AD = nil
		end

		local Min = ACF.GetGunValue(Data.Weapon, "ArmDelay") or self.MinDelay

		Data.ArmingDelay = math.Clamp(Delay or 0, Min, self.MaxDelay)
	end

	function Fuze:IsArmed()
		return Clock.CurTime - self.TimeStarted >= self.Primer
	end

	-- Do nothing, projectiles auto-detonate on contact anyway.
	function Fuze:GetDetonate()
		return false
	end

	function Fuze:OnLast(Entity)
		Entity.ArmingDelay = nil
	end
end
