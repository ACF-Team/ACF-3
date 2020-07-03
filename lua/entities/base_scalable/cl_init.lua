include("shared.lua")

local Unexistant = {}
local Queued = {}
local Sizes = {}

net.Receive("RequestSize", function()
	local Entities = util.JSONToTable(net.ReadString())

	for ID, Data in pairs(Entities) do
		local Ent = Entity(ID)

		if IsValid(Ent) then
			Sizes[Ent:GetModel()] = Data.Original

			Ent.OriginalSize = Data.Original
			Ent:SetSize(Data.Size)

			if Queued[Ent] then Queued[Ent] = nil end
		else
			Unexistant[ID] = Data
		end
	end
end)

hook.Add("OnEntityCreated", "Scalable Ent Startup", function(Ent)
	timer.Simple(0.1, function()
		if not IsValid(Ent) then return end
		if not Ent.IsScalable then return end

		local Data = Unexistant[Ent:EntIndex()]

		if Data then
			Sizes[Ent:GetModel()] = Data.Original
			Unexistant[Ent:EntIndex()] = nil

			Ent.OriginalSize = Data.Original
			Ent:SetSize(Data.Size)

			if Queued[Ent] then Queued[Ent] = nil end
		else
			Ent:GetOriginalSize()
		end
	end)
end)

function ENT:GetOriginalSize()
	if not self.OriginalSize then
		local Size = Sizes[self:GetModel()]

		if not Size then
			if not Queued[self] then
				Queued[self] = true

				net.Start("RequestSize")
					net.WriteEntity(self)
				net.SendToServer()
			end

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
