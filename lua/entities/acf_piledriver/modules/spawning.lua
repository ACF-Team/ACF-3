local ACF         = ACF
local Classes     = ACF.Classes
local AmmoTypes   = Classes.AmmoTypes
local Piledrivers = Classes.Piledrivers
local Contraption = ACF.Contraption
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock

function ENT.ACF_Limit(Player, Data)
    local Class = Piledrivers.Get(Data.Weapon)
    local Limit = Class.LimitConVar.Name

    return Player:CheckLimit(Limit)
end

function ENT:ACF_PreSpawn(_, _, _, Data)
    self.ACF          = {}
    local Class = Piledrivers.Get(Data.Weapon)
    Contraption.SetModel(self, Class.Model)
end

function ENT:ACF_OnSpawn(_)
    local AmmoType = AmmoTypes.Get("HP")

    self.RoundData    = AmmoType()
    self.LastThink    = Clock.CurTime
    self.State        = "Loading"
    self.Firing       = false
    self.Charge       = 0
    self.SingleCharge = 0
    self.CurrentShot  = 0
end

function ENT:ACF_PostSpawn()
    WireLib.TriggerOutput(self, "State", "Loading")
end