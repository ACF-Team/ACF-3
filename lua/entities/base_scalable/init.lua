DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

util.AddNetworkString "ACF_Scalable_Entity"

local ACF     = ACF
local Contraption	= ACF.Contraption

function ENT:GetOriginalSize()
	local Data = self.ScaleData

	return Data:GetSize()
end

local function TransmitScaleInfo(Entity, To)
	local Data  = Entity.ScaleData
	local Scale = Entity:GetScale()

	net.Start("ACF_Scalable_Entity")
	net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
	net.WriteFloat(Scale[1])
	net.WriteFloat(Scale[2])
	net.WriteFloat(Scale[3])
	net.WriteString(Data.Type)
	net.WriteString(Data.Path)

	if To then net.Send(To) else net.Broadcast() end
end

function ENT:TransmitScaleInfo(To)
	TransmitScaleInfo(self, To)
end

net.Receive("ACF_Scalable_Entity", function(_, Player)
	local Entity = ents.GetByIndex(net.ReadUInt(MAX_EDICT_BITS))

	if IsValid(Entity) and Entity.IsScalable then
		TransmitScaleInfo(Entity, Player)
	end
end)

do -- Size and scale setter methods
	local function ApplyScale(Entity, Data, Scale)
		local Mesh = Data:GetMesh(Scale)

		Entity:PhysicsInitMultiConvex(Mesh)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)
		Entity:SetSolid(SOLID_VPHYSICS)
		Entity:EnableCustomCollisions(true)
		Entity:DrawShadow(false)

		local PhysObj = Entity:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
		end

		return PhysObj
	end

	local function ResizeEntity(Entity, Scale)
		local Data     = Entity.ScaleData
		local PhysObj  = ApplyScale(Entity, Data, Scale)
		local Size     = Data:GetSize(Scale)

		Entity.Size  = Size
		Entity.Scale = Scale

		TransmitScaleInfo(Entity)

		if IsValid(PhysObj) then
			if Entity.OnResized then Entity:OnResized(Size, Scale) end

			hook.Run("ACF_OnResizeEntity", Entity, PhysObj, Size, Scale)
		end

		return true
	end

	function ENT:SetSize(Size)
		if not isvector(Size) then return false end

		local Base  = self:GetOriginalSize()
		local Scale = Vector(1 / Base.x, 1 / Base.y, 1 / Base.z) * Size

		return ResizeEntity(self, Scale)
	end

	function ENT:SetScale(Scale)
		if isnumber(Scale) then
			Scale = Vector(Scale, Scale, Scale)
		elseif not isvector(Scale) then
			return false
		end

		return ResizeEntity(self, Scale)
	end
end

function ENT:SetScaledModel( Model )
	if not self.ACF then self.ACF = {} end
	Contraption.SetModel(self, Model)

	local Data = self.ScaleData
	if Model and (Data.Type ~= "Model" or Data.Path ~= Model) then
		self:SetScaleData("Model", Model )
		self:Restore()
	end
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
