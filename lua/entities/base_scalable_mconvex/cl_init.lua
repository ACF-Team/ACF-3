include("shared.lua")

function ENT:SetExtraInfo(Extra)
	self.RealMesh = Extra.Mesh
	self.Mesh     = table.Copy(Extra.Mesh)
end

function ENT:ApplyNewSize(_, NewScale)
	local Mesh = self.Mesh

	self.Matrix = Matrix()
	self.Matrix:Scale(NewScale)

	self:EnableMatrix("RenderMultiply", self.Matrix)

	for I, Hull in ipairs(Mesh) do
		for J, Vertex in ipairs(Hull) do
			Mesh[I][J] = (Vertex.pos or Vertex) * NewScale
		end
	end

	self:PhysicsInitMultiConvex(Mesh)
	self:EnableCustomCollisions(true)
	self:SetRenderBounds(self:GetCollisionBounds())
	self:DrawShadow(false)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
		PhysObj:Sleep()
	end
end
