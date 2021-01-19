DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName     = "Base Scalable Entity"
ENT.WireDebugName = "Base Scalable Entity"
ENT.Contact       = "Don't"
ENT.IsScalable    = true

function ENT:GetSize()
	return self.Size
end

function ENT:GetScale()
	return self.Scale
end
