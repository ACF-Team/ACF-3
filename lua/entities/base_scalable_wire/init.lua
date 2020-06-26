AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function CreateWireScalable(Player, Pos, Angle, Size)
	local Ent = ents.Create("base_scalable_wire")

	if not IsValid(Ent) then return end

	Ent:SetModel("models/hunter/blocks/cube1x1x1.mdl")
	Ent:SetAngles(Angle)
	Ent:SetPos(Pos)
	Ent:Spawn()

	Ent:SetSize(Size)

	Ent.Owner = Player

	return Ent
end
duplicator.RegisterEntityClass("base_scalable_wire", CreateWireScalable, "Pos", "Angle", "Size")

function ENT:GetOriginalSize()
	if not self.OriginalSize then
		local Min, Max = self:GetPhysicsObject():GetAABB()

		self.OriginalSize = -Min + Max
		self:SetNW2Vector("OriginalSize", -Min + Max)
	end

	return self.OriginalSize
end

function ENT:SetSize(NewSize)
	if NewSize == self.Size then return end

	local Size  = self:GetOriginalSize()
	local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * NewSize

	self:PhysicsInit(SOLID_VPHYSICS) -- Physics must be set to VPhysics before re-scaling
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)

	local Phys = self:GetPhysicsObject()
	local Mesh = Phys:GetMeshConvexes()

	for I, Hull in pairs(Mesh) do -- Scale the mesh
		for J, Vertex in pairs(Hull) do
			Mesh[I][J] = Vertex.pos * Scale
		end
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInitMultiConvex(Mesh) -- Apply new mesh
	self:EnableCustomCollisions(true)

	self:SetNW2Vector("Size", NewSize)
	self.Size = NewSize

	local Obj = self:GetPhysicsObject()

	if IsValid(Obj) then
		Obj:SetMass(Obj:GetVolume() / 1000)

		if self.OnResized then self:OnResized() end

		hook.Run("OnEntityScaled", self, Obj, NewSize)
	end
end

util.AddNetworkString("RequestOriginalSize")

net.Receive("RequestOriginalSize", function(_, Ply) -- A client requested the size of an entity
	local E = net.ReadEntity()

	if IsValid(E) and E.OriginalSize then -- Send them the size
		net.Start("RequestOriginalSize")
			net.WriteEntity(E)
			net.WriteVector(E.OriginalSize)
			net.WriteVector(E.Size)
		net.Send(Ply)
	end
end)