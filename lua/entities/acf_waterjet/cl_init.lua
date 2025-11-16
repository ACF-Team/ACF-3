include("shared.lua")

DEFINE_BASECLASS "acf_base_scalable"

function ENT:Think()
    self.ACF_BladeRotation = (self.ACF_BladeRotation or 0) + (self:GetNW2Float("ACF_WaterjetRPM", 0) * FrameTime())
end

local Rot = Angle(0, 0, 0)
function ENT:Draw()
    local A
    -- Counter the blades rotation (because gmod is being dumb)
    A = ((CurTime() * 720) % 360)
    -- Clamp ACF_BladeRotation to 360 degrees
    self.ACF_BladeRotation = (self.ACF_BladeRotation or 0) % 360
    -- Add our rotation.
    A = A + self.ACF_BladeRotation
    -- Apply it
    Rot[2] = A
    self:ManipulateBoneAngles(self:LookupBone("blades"), Rot)

    self:SetupBones()
    BaseClass.Draw(self)
end

ACF.Classes.Entities.Register()