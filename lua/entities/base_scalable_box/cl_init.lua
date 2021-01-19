include("shared.lua")

function ENT:ApplyNewSize(NewSize, NewScale)
	local Bounds = NewSize * 0.5

	self.Matrix = Matrix()
	self.Matrix:Scale(NewScale)

	self:EnableMatrix("RenderMultiply", self.Matrix)

	self:PhysicsInitBox(-Bounds, Bounds)
	self:SetRenderBounds(-Bounds, Bounds)
	self:EnableCustomCollisions(true)
	self:DrawShadow(false)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
		PhysObj:Sleep()
	end
end
