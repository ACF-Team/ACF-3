AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local Sizes = {}

function ENT:GetOriginalSize()
	if not self.OriginalSize then
		local Size = Sizes[self:GetModel()]

		if not Size then
			local Min, Max = self:GetPhysicsObject():GetAABB()

			Size = -Min + Max

			Sizes[self:GetModel()] = Size
		end

		self.OriginalSize = Size
	end

	return self.OriginalSize
end

function ENT:GetSize()
	return self.Size or self:GetOriginalSize()
end

function ENT:SetSize(NewSize)
	if self:GetSize() == NewSize then return end

	if self.ApplyNewSize then self:ApplyNewSize(NewSize) end

	self.Size = NewSize

	local PhysObj = self:GetPhysicsObject()

	net.Start("RequestSize")
		net.WriteEntity(self)
		net.WriteVector(self:GetOriginalSize())
		net.WriteVector(self:GetSize())
	net.Broadcast()

	if IsValid(PhysObj) then
		if self.OnResized then self:OnResized() end

		hook.Run("OnEntityResized", self, PhysObj, NewSize)
	end
end

util.AddNetworkString("RequestOriginalSize")
util.AddNetworkString("RequestSize")

net.Receive("RequestOriginalSize", function(_, Player) -- A client requested the size of an entity
	local E = net.ReadEntity()

	if IsValid(E) and E.IsScalable then -- Send them the size
		net.Start("RequestSize")
			net.WriteEntity(E)
			net.WriteVector(E:GetOriginalSize())
			net.WriteVector(E:GetSize())
		net.Send(Player)
	end
end)
