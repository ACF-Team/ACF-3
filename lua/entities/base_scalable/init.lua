DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local Queued = {}
local Sizes = {}

local function GenerateJSON(Table)
	local Data = {}

	for Entity in pairs(Table) do
		if not IsValid(Entity) then continue end

		Data[Entity:EntIndex()] = {
			Original = Entity:GetOriginalSize(),
			Size = Entity:GetSize()
		}
	end

	return util.TableToJSON(Data)
end

local function SendQueued()
	if Queued.Broadcast then
		net.Start("RequestSize")
			net.WriteString(GenerateJSON(Queued.Broadcast))
		net.Broadcast()

		Queued.Broadcast = nil
	end

	for Player, Data in pairs(Queued) do
		if not IsValid(Player) then continue end

		net.Start("RequestSize")
			net.WriteString(GenerateJSON(Data))
		net.Send(Player)

		Queued[Player] = nil
	end
end

local function NetworkSize(Entity, Player)
	local Key = IsValid(Player) and Player or "Broadcast"
	local Destiny = Queued[Key]

	if Destiny and Destiny[Entity] then return end -- Already queued

	if not Destiny then
		Queued[Key] = {
			[Entity] = true
		}
	else
		Destiny[Entity] = true
	end

	if timer.Exists("ACF Network Sizes") then return end

	timer.Create("ACF Network Sizes", 0.5, 1, SendQueued)
end

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
	return self.Size
end

function ENT:SetSize(NewSize)
	if self:GetSize() == NewSize then return end

	if self.ApplyNewSize then self:ApplyNewSize(NewSize) end

	self.Size = NewSize

	NetworkSize(self)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		if self.OnResized then self:OnResized() end

		hook.Run("OnEntityResized", self, PhysObj, NewSize)
	end
end

do -- AdvDupe2 duped parented ammo workaround
	function ENT:OnDuplicated(EntTable)
		local DupeInfo = EntTable.BuildDupeInfo

		if DupeInfo and DupeInfo.DupeParentID then
			self.ParentIndex = DupeInfo.DupeParentID

			DupeInfo.DupeParentID = nil
		end

		BaseClass.OnDuplicated(self, EntTable)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		if self.ParentIndex then
			self.ParentEnt = CreatedEntities[self.ParentIndex]
			self.ParentIndex = nil
		end

		BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
	end

	hook.Add("AdvDupe_FinishPasting", "ACF Parented Scalable Ent Fix", function(DupeInfo)
		DupeInfo = unpack(DupeInfo)

		local Entities = DupeInfo.CreatedEntities

		for _, Entity in pairs(Entities) do
			if Entity.IsScalable and Entity.ParentEnt then
				Entity:SetParent(Entity.ParentEnt)

				Entity.ParentEnt = nil
			end
		end
	end)
end

util.AddNetworkString("RequestSize")

net.Receive("RequestSize", function(_, Player) -- A client requested the size of an entity
	local E = net.ReadEntity()

	if IsValid(E) and E.IsScalable then -- Send them the size
		NetworkSize(E, Player)
	end
end)
