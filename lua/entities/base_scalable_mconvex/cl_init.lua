include("shared.lua")

function ENT:SetExtraInfo(Extra)
	self.Mesh = Extra.Mesh
end

function ENT:ApplyNewSize(NewSize)
	local Size  = self:GetOriginalSize()
	local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * NewSize
	local Mesh  = self.Mesh

	self.Matrix = Matrix()
	self.Matrix:Scale(Scale)

	self:EnableMatrix("RenderMultiply", self.Matrix)

	for I, Hull in ipairs(Mesh) do
		for J, Vertex in ipairs(Hull) do
			Mesh[I][J] = (Vertex.pos or Vertex) * Scale
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
