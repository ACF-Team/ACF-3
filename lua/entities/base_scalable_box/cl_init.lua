include("shared.lua")

function ENT:ApplyNewSize(NewSize)
	local Size = self:GetOriginalSize()
	local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * NewSize
	local Bounds = NewSize * 0.5
	local Mat = Matrix()

	Mat:Scale(Scale)

	self:EnableMatrix("RenderMultiply", Mat)

	self:PhysicsInitBox(-Bounds, Bounds)
	self:SetRenderBounds(-Bounds, Bounds)
	self:EnableCustomCollisions(true)
	self:SetMoveType(MOVETYPE_NONE)
	self:DrawShadow(false)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
		PhysObj:Sleep()
	end
end
