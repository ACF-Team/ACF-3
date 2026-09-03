include("shared.lua")

DEFINE_BASECLASS("acf_base_scalable")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel())
end

function ENT:Think()
	self.ACF_BladeRotation = (self.ACF_BladeRotation or 0) + (self:GetNW2Float("ACF_PropellerRPM", 0) * FrameTime())
end

local Rot = Angle(0, 0, 0)
function ENT:Draw()
	local Bone = self:LookupBone("blades")
	if Bone then
		local A = ((CurTime() * 720) % 360)
		self.ACF_BladeRotation = (self.ACF_BladeRotation or 0) % 360
		A = A + self.ACF_BladeRotation

		Rot[2] = A
		self:ManipulateBoneAngles(Bone, Rot)
		self:SetupBones()
	end

	BaseClass.Draw(self)
end
