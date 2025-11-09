local ACF       = ACF
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock
local hook      = hook

function ENT:Disable()
    self.Charge       = 0
    self.SingleCharge = 0
    self.CurrentShot  = 0

    self:SetState("Loading")
end

function ENT:SetState(State)
    self.State = State

    self:UpdateOverlay()

    WireLib.TriggerOutput(self, "Status", State)
    WireLib.TriggerOutput(self, "Ready", State == "Loaded" and 1 or 0)
end

function ENT:Consume(Num)
    self.Charge      = math.Clamp(self.Charge - (Num or 1), 0, self.MagSize)
    self.CurrentShot = math.floor(self.Charge)

    WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

    self:UpdateOverlay()
end

function ENT:Think()
    local Time = Clock.CurTime

    if not self.Disabled and self.CurrentShot < self.MagSize then
        local Delta  = Time - self.LastThink
        local Amount = self.ChargeRate * Delta

        self:Consume(-Amount) -- Slowly recharging the piledriver

        self.SingleCharge = self.Charge - self.CurrentShot

        if not self.Loading and self.State == "Loading" and self.CurrentShot > 0 then
            self:SetState("Loaded")
        end
    end

    self:NextThink(Time)

    self.LastThink = Time

    return true
end

function ENT:OnRemove()
    local Class = self.ClassData

    if Class.OnLast then
        Class.OnLast(self, Class)
    end

    hook.Run("ACF_OnEntityLast", "acf_piledriver", self, Class)

    WireLib.Remove(self)
end