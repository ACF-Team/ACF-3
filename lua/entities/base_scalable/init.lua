DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF     = ACF
local Contraption	= ACF.Contraption
local Network = ACF.Networking

function ENT:GetOriginalSize()
	local Data = self.ScaleData

	return Data:GetSize()
end

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
		local Previous = Entity.Size

		Entity.Size  = Size
		Entity.Scale = Scale

		-- If it's not a new entity, then network the new size
		-- Otherwise, the entity will request its size by itself
		if Previous then
			Network.Broadcast("ACF_Scalable_Entity", Entity)
		end

		if IsValid(PhysObj) then
			if Entity.OnResized then Entity:OnResized(Size, Scale) end

			hook.Run("ACF_OnEntityResized", Entity, PhysObj, Size, Scale)
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

do -- Network sender and receivers
	Network.CreateSender("ACF_Scalable_Entity", function(Queue, Entity)
		local Data = Entity.ScaleData

		Queue[Entity:EntIndex()] = {
			Scale = Entity:GetScale(),
			Type  = Data.Type,
			Path  = Data.Path,
		}
	end)

	Network.CreateReceiver("ACF_Scalable_Entity", function(Player, Data)
		for Index in pairs(Data) do
			local Entity = ents.GetByIndex(Index)

			if IsValid(Entity) and Entity.IsScalable then
				Network.Send("ACF_Scalable_Entity", Player, Entity)
			end
		end
	end)
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
