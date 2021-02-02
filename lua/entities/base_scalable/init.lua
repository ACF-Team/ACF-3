DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local Queued = {}

local function GenerateJSON(Table)
	local Data = {}

	for Entity in pairs(Table) do
		if not IsValid(Entity) then continue end

		Data[Entity:EntIndex()] = {
			Original = Entity:GetOriginalSize(),
			Size = Entity:GetSize(),
			Extra = Entity.GetExtraInfo and Entity:GetExtraInfo(),
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

	-- Avoiding net message spam by sending all the events of a tick at once
	if timer.Exists("ACF Network Sizes") then return end

	timer.Create("ACF Network Sizes", 0, 1, SendQueued)
end

local function ChangeSize(Entity, Size)
	local Original = Entity:GetOriginalSize()
	local Scale = Vector(1 / Original.x, 1 / Original.y, 1 / Original.z) * Size

	if Entity.ApplyNewSize then Entity:ApplyNewSize(Size, Scale) end

	-- If it's not a new entity, then network the new size
	-- Otherwise, the entity will request its size by itself
	if Entity.Size then NetworkSize(Entity) end

	Entity.Size = Size
	Entity.Scale = Scale

	local PhysObj = Entity:GetPhysicsObject()

	if IsValid(PhysObj) then
		if Entity.OnResized then Entity:OnResized(Size, Scale) end

		hook.Run("OnEntityResized", Entity, PhysObj, Size, Scale)
	end

	if Entity.UpdateExtraInfo then Entity:UpdateExtraInfo() end

	return true, Size, Scale
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:GetOriginalSize() -- Instantly saving the original size
end

function ENT:GetOriginalSize()
	local Model   = self.ACF and self.ACF.Model or self:GetModel()
	local Changed = self.LastModel ~= Model

	if Changed or not self.OriginalSize then
		self.LastModel = Model

		self.OriginalSize = ACF.GetModelSize(Model)
	end

	return self.OriginalSize, Changed
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

do -- AdvDupe2 duped parented ammo workaround
	-- Duped parented scalable entities were uncapable of spawning on the correct position
	-- That's why they're parented AFTER the dupe is done pasting
	-- Only applies for Advanced Duplicator 2

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
		local Dupe      = unpack(DupeInfo, 1, 1)
		local Player    = Dupe.Player
		local CanParent = not IsValid(Player) or tobool(Player:GetInfo("advdupe2_paste_parents"))

		if not CanParent then return end

		for _, Entity in pairs(Dupe.CreatedEntities) do
			if not Entity.IsScalable then continue end
			if not Entity.ParentEnt then continue end

			Entity:SetParent(Entity.ParentEnt)

			Entity.ParentEnt = nil
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
