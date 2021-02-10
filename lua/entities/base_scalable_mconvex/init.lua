AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

-- TODO: Add support for creation via vertices table instead of model

local Meshes = {}

do -- Dirty, dirty hacking to prevent other addons initializing physics the wrong way
	local ENT  = FindMetaTable("Entity")
	local Init = Init or ENT.PhysicsInit

	function ENT:PhysicsInit(Solid, Bypass)
		if self.IsScalable and not Bypass then
			if not self.FirstInit then
				self.FirstInit = true
				return
			end

			self:Restore()
			return
		end

		Init(self, Solid)
	end
end

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

function ENT:FindOriginalSize(SizeTable)
	local Key    = self:GetModel()
	local Stored = SizeTable[Key]

	if Stored then
		self.Mesh = table.Copy(Meshes[Key])

		return Stored
	end

	local PhysObj = self:GetPhysicsObject()

	if not IsValid(PhysObj) then
		self:PhysicsInit(SOLID_VPHYSICS, true)

		PhysObj = self:GetPhysicsObject()
	end

	local Min, Max = PhysObj:GetAABB()
	local Mesh = PhysObj:GetMeshConvexes()
	local Size = -Min + Max

	self.Mesh = table.Copy(Mesh)

	SizeTable[Key] = Size
	Meshes[Key] = Mesh

	return Size
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
		Mesh = Meshes[self:GetModel()]
	}
end

function ENT:Restore()
	local Size = self:GetSize() / self:GetOriginalSize()

	self.Mesh = table.Copy(Meshes[self:GetModel()])
	self.Size = Vector(1, 1, 1)
	self:SetSize(Size)

	Print(self:GetSize())
end