DEFINE_BASECLASS("base_point")

ACF.AddParentDetour("acf_turret_rotator", "turret")

function ENT:Initialize(turret)
    self.turret = turret or self:GetParent()
end

function ENT:OnRemove()
    if IsValid(self.turret) then
        self.turret:Remove()
    end
end