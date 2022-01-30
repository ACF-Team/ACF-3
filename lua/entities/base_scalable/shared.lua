DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName     = "Base Scalable Entity"
ENT.WireDebugName = "Base Scalable Entity"
ENT.Contact       = "Don't"
ENT.IsScalable    = true

function ENT:GetSize()
	local Size = self.Size

	if Size then
		return Vector(Size)
	end
end

function ENT:GetScale()
	local Scale = self.Scale

	if Scale then
		return Vector(Scale)
	end
end

function ENT:Restore()
	local Size = self:GetSize()

	-- We must manually reset the mesh on the clientside for this to work
	if CLIENT then
		self.Mesh = table.Copy(self.RealMesh)
	end

	self:SetSize(Size)
end

-- Dirty, dirty hacking to prevent other addons initializing physics the wrong way
-- Required for stuff like Proper Clipping resetting the physics object when clearing out physclips
do
	local EntMeta = FindMetaTable("Entity")
	local Physics = EntMeta.PhysicsInit

	function EntMeta:PhysicsInit(Solid, Bypass, ...)
		if not self.IsScalable or Bypass then
			return Physics(self, Solid, Bypass, ...)
		end

		local Init = self.FirstInit

		if not Init then
			self.FirstInit = true
		end

		if Init or CLIENT then
			self:Restore()

			return true
		end
	end
end
