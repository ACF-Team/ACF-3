AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function CreateScalableBox(Player, Pos, Angle, Size)
	local Ent = ents.Create("base_scalable_box")

	if not IsValid(Ent) then return end

	Ent:SetModel("models/holograms/cube.mdl")
	Ent:SetPlayer(Player)
	Ent:SetAngles(Angle)
	Ent:SetPos(Pos)
	Ent:Spawn()

	Ent:SetSize(Size)

	Ent.Owner = Player

	return Ent
end

duplicator.RegisterEntityClass("base_scalable_box", CreateScalableBox, "Pos", "Angle", "Size")

function ENT:ApplyNewSize(NewSize)
	local Bounds = NewSize * 0.5

	self:PhysicsInitBox(-Bounds, Bounds)
	self:EnableCustomCollisions(true)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
	end
end
