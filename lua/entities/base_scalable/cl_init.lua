DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

include("shared.lua")

local Queued = {}

local function ChangeSize(Entity, Size)
	if not isvector(Size) then return false end
	if not Entity:GetOriginalSize() then return false end

	local Original = Entity:GetOriginalSize()
	local Scale = Vector(Size.x / Original.x, Size.y / Original.y, Size.z / Original.z)

	if Entity.ApplyNewSize then Entity:ApplyNewSize(Size, Scale) end

	Entity.Size = Size
	Entity.Scale = Scale

	local PhysObj = Entity:GetPhysicsObject()

	if IsValid(PhysObj) then
		if Entity.OnResized then Entity:OnResized(Size, Scale) end

		hook.Run("OnEntityResized", Entity, PhysObj, Size, Scale)
	end

	return true, Size, Scale
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Initialized = true

	self:GetOriginalSize() -- Getting the original and current size
end

function ENT:GetOriginalSize()
	if not self.OriginalSize then
		if not Queued[self] then
			Queued[self] = true

			net.Start("RequestSize")
				net.WriteEntity(self)
			net.SendToServer()
		end

		return
	end

	return self.OriginalSize
end

function ENT:SetSize(Size)
	if not isvector(Size) then return false end

	return ChangeSize(self, Size)
end

function ENT:SetScale(Scale)
	if isnumber(Scale) then Scale = Vector(Scale, Scale, Scale) end
	if not isvector(Scale) then return false end

	local Original = self:GetOriginalSize()
	local Size = Vector(Original.x, Original.y, Original.z) * Scale

	return ChangeSize(self, Size)
end

function ENT:CalcAbsolutePosition() -- Faking sync
	local PhysObj = self:GetPhysicsObject()
	local Position = self:GetPos()
	local Angles = self:GetAngles()

	if IsValid(PhysObj) then
		PhysObj:SetPos(Position)
		PhysObj:SetAngles(Angles)
		PhysObj:EnableMotion(false) -- Disable prediction
		PhysObj:Sleep()
	end

	return Position, Angles
end

function ENT:Think()
	if not self.Initialized then
		self:Initialize()
	end

	BaseClass.Think(self)
end

net.Receive("RequestSize", function()
	local Entities = util.JSONToTable(net.ReadString())

	for ID, Data in pairs(Entities) do
		local Ent = Entity(ID)

		if not IsValid(Ent) then continue end
		if not Ent.Initialized then continue end

		if Data.Size ~= Ent.Size or Data.Original ~= Ent.OriginalSize then
			if Ent.SetExtraInfo then
				Ent:SetExtraInfo(Data.Extra)
			end

			Ent.OriginalSize = Data.Original
			Ent:SetSize(Data.Size)
		end

		if Queued[Ent] then Queued[Ent] = nil end
	end
end)

-- NOTE: Someone reported this could maybe be causing crashes. Please confirm.
hook.Add("PhysgunPickup", "Scalable Ent Physgun", function(_, Ent)
	if Ent.IsScalable then return false end
end)

hook.Add("NetworkEntityCreated", "Scalable Ent Full Update", function(Ent)
	if Ent.IsScalable then
		local Size = Ent.Size

		Ent.Size = nil -- Forcing the entity to "forget" its current size

		Ent:SetSize(Size)

		if Ent.OnFullUpdate then Ent:OnFullUpdate() end
	end
end)
