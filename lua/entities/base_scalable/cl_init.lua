DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

include("shared.lua")

local Queued = {}

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

function ENT:GetSize()
	return self.Size
end

function ENT:SetSize(NewSize)
	if not isvector(NewSize) then return end
	if self.Size == NewSize then return end
	if not self:GetOriginalSize() then return end

	if self.ApplyNewSize then self:ApplyNewSize(NewSize) end

	self.Size = NewSize

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		if self.OnResized then self:OnResized(NewSize) end

		hook.Run("OnEntityResized", self, PhysObj, NewSize)
	end
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
			Ent.OriginalSize = Data.Original
			Ent:SetSize(Data.Size)
		end

		if Queued[Ent] then Queued[Ent] = nil end
	end
end)

-- Commented out for the moment, something's causing crashes
-- TODO: Maybe hijack PhysObj:EnableMotion instead?
--hook.Add("PhysgunPickup", "Scalable Ent Physgun", function(_, Ent)
	--if Ent.IsScalable then return false end
--end)

hook.Add("NetworkEntityCreated", "Scalable Ent Full Update", function(Ent)
	if Ent.IsScalable then
		local Size = Ent.Size

		Ent.Size = nil -- Forcing the entity to "forget" its current size

		Ent:SetSize(Size)

		if Ent.OnFullUpdate then Ent:OnFullUpdate() end
	end
end)
