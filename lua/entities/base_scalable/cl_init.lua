include("shared.lua")

local Queued = {}
local Sizes = {}

net.Receive("RequestSize", function()
	local E = net.ReadEntity()
	local Original = net.ReadVector()
	local Current  = net.ReadVector()

	if not IsValid(E) then return end

	Sizes[E:GetModel()] = Original

	E.OriginalSize = Original
	E:SetSize(Current)

	if Queued[E] then Queued[E] = nil end
end)

function ENT:GetOriginalSize()
	if not self.OriginalSize then
		local Size = Sizes[self:GetModel()]

		if not Size then
			Queued[self] = true

			net.Start("RequestOriginalSize")
				net.WriteEntity(self)
			net.SendToServer()

			return
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
	if not self:GetOriginalSize() then return end

	if self.ApplyNewSize then self:ApplyNewSize(NewSize) end

	self.Size = NewSize

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		if self.OnResized then self:OnResized() end

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
