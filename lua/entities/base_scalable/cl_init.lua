include("shared.lua")

local Queued = {}
local NWVars = { -- Funcs called over the network
	Size = function(Entity, Value)
		Entity:SetSize(Value)
	end,
	OriginalSize = function(Entity, Value)
		Entity.OriginalSize = Value

		if Queued[Entity] then
			Queued[Entity] = nil
			Entity:SetSize(Value)
		end
	end
}

net.Receive("RequestOriginalSize", function()
	local E = net.ReadEntity()

	local Original = net.ReadVector()
	local Current  = net.ReadVector()

	E.OriginalSize = Original
	E:SetSize(Current)

	if Queued[E] then
		Queued[E] = nil
	end
end)

function ENT:SetSize(NewSize)
	if not self.OriginalSize then -- For whatever reason, this doesn't always get networked, so it needs to be requested from the server
		Queued[self] = true

		net.Start("RequestOriginalSize")
			net.WriteEntity(self)
		net.SendToServer()

		return
	end

	local Size  = self.OriginalSize
	local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * NewSize

	self.Size = NewSize

	self:PhysicsInit(SOLID_VPHYSICS) -- Physics must be set to VPhysics before re-scaling

	local Phys = self:GetPhysicsObject()
	local Mesh = Phys:GetMeshConvexes()
	local Mat  = Matrix()

	Mat:Scale(Scale)

	for I, Hull in pairs(Mesh) do
		for J, Vertex in pairs(Hull) do
			Mesh[I][J] = Vertex.pos * Scale
		end
	end

	self:EnableMatrix("RenderMultiply", Mat)
	self:PhysicsInitMultiConvex(Mesh)
	self:EnableCustomCollisions(true)
	self:SetRenderBounds(self:GetCollisionBounds())
	self:DrawShadow(false)

	local Obj = self:GetPhysicsObject()

	if IsValid(Obj) then
		Obj:EnableMotion(false)
		Obj:Sleep()

		if self.OnResized then self:OnResized() end

		hook.Run("OnEntityScaled", self, Obj, NewSize)
	end
end

function ENT:CalcAbsolutePosition() -- Faking sync
	local Phys = self:GetPhysicsObject()
	local Position = self:GetNetworkOrigin()
	local Angles = self:GetAngles()

	if IsValid(Phys) then
		Phys:SetPos(Position)
		Phys:SetAngles(Angles)
		Phys:EnableMotion(false) -- Disable prediction
		Phys:Sleep()
	end

	return Position, Angles
end

hook.Add("EntityNetworkedVarChanged", "Scalable Box NWChange", function(Entity, Name, _, New)
	local NWAction = NWVars[Name]

	if Entity.IsScalable and NWAction then
		NWAction(Entity, New)
	end
end)
