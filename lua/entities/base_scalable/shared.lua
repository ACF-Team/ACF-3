DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName      = "Base Scalable Entity"
ENT.WireDebugName  = "Base Scalable Entity"
ENT.Contact        = "Don't"
ENT.IsScalable     = true
ENT.UseCustomIndex = true
ENT.ScaleData      = { Type = false, Path = false }

function ENT:SetScaleData(Type, Path)
	local Data = self.ScaleData

	Data.Type    = Type
	Data.Path    = Path
	Data.GetMesh = self["Get" .. Type .. "Mesh"]
	Data.GetSize = self["Get" .. Type .. "Size"]
end

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
	self:SetScale(self:GetScale())
end

do -- Model-based scalable entity methods
	local ModelData = ACF.ModelData

	function ENT.GetModelMesh(Data, Scale)
		return ModelData.GetModelMesh(Data.Path, Scale)
	end

	function ENT.GetModelSize(Data, Scale)
		return ModelData.GetModelSize(Data.Path, Scale)
	end
end

-- Dirty, dirty hacking to prevent other addons initializing physics the wrong way
-- Required for stuff like Proper Clipping resetting the physics object when clearing out physclips
do
	local EntMeta = FindMetaTable("Entity")

	function ENT:PhysicsInit(Solid, Bypass, ...)
		if Bypass then
			return EntMeta.PhysicsInit(self, Solid, Bypass, ...)
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
