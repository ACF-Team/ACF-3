DEFINE_BASECLASS("base_scalable") -- Required to get the local BaseClass

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

-- TODO: Add support for creation via vertices table instead of model
function CreateScalableMultiConvex(Player, Pos, Angle, Size)
	local Ent = ents.Create("base_scalable_mconvex")

	if not IsValid(Ent) then return end

	Ent:SetModel("models/props_interiors/pot01a.mdl")
	Ent:SetPlayer(Player)
	Ent:SetAngles(Angle)
	Ent:SetPos(Pos)
	Ent:Spawn()

	Ent:SetSize(Size or VectorRand(3, 96))

	Ent.Owner = Player

	return Ent
end

duplicator.RegisterEntityClass("base_scalable_mconvex", CreateScalableMultiConvex, "Pos", "Angle", "Size")

function ENT:GetOriginalSize()
	local Size, Changed = BaseClass.GetOriginalSize(self)

	if Changed or not self.Mesh then
		self.Mesh = ACF.GetModelMesh(self.LastModel)
	end

	return Size, Changed
end

function ENT:ApplyNewSize(NewSize)
	local Size   = self:GetSize() or self:GetOriginalSize()
	local Factor = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * NewSize
	local Mesh   = self.Mesh

	for I, Hull in ipairs(Mesh) do
		for J, Vertex in ipairs(Hull) do
			Mesh[I][J] = (Vertex.pos or Vertex) * Factor
		end
	end

	self:PhysicsInitMultiConvex(Mesh)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:EnableCustomCollisions(true)
	self:DrawShadow(false)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
	end
end

function ENT:GetExtraInfo()
	return {
		Mesh = ACF.GetModelMesh(self.LastModel)
	}
end
