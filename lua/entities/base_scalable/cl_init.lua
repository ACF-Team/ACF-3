DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

include("shared.lua")

local ACF     = ACF
local Network = ACF.Networking
local Standby = {}

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Initialized = true

	-- Instantly requesting ScaleData and Scale
	if not Standby[self] then
		Network.Send("ACF_Scalable_Entity", self)
	end
end

function ENT:CalcAbsolutePosition() -- Faking sync
	local PhysObj  = self:GetPhysicsObject()
	local Position = self:GetPos()
	local Angles   = self:GetAngles()

	if IsValid(PhysObj) then
		PhysObj:SetPos(Position)
		PhysObj:SetAngles(Angles)
		PhysObj:EnableMotion(false) -- Disable prediction
		PhysObj:Sleep()
	end

	return Position, Angles
end

function ENT:Think(...)
	if not self.Initialized then
		self:Initialize()
	end

	return BaseClass.Think(self, ...)
end

function ENT:GetOriginalSize()
	local Data = self.ScaleData
	local Size = Data.GetSize and Data:GetSize()

	if not Size then
		if not (Data.Type or Standby[self]) then
			Network.Send("ACF_Scalable_Entity", self)
		end

		return
	end

	return Size
end

do -- Size and scale setter methods
	local ModelData = ACF.ModelData

	local function ApplyScale(Entity, Data, Scale)
		local Mesh = Data:GetMesh(Scale)

		Entity.Matrix = Matrix()
		Entity.Matrix:SetScale(Scale)

		Entity:EnableMatrix("RenderMultiply", Entity.Matrix)
		Entity:PhysicsInitMultiConvex(Mesh)
		Entity:EnableCustomCollisions(true)
		Entity:SetRenderBounds(Entity:GetCollisionBounds())
		Entity:DrawShadow(false)

		local PhysObj = Entity:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
			PhysObj:Sleep()
		end

		return PhysObj
	end

	local function ResizeEntity(Entity, Scale)
		local Data = Entity.ScaleData

		if not Scale then
			local Path = Data.Path

			-- We have updated ScaleData but no ModelData yet
			-- We'll wait for it and instantly tell the entity to rescale
			if Path and ModelData.IsOnStandby(Path) then
				ModelData.QueueRefresh(Path, Entity, function()
					local Saved = Entity.SavedScale

					if not Saved then return end

					Entity:SetScale(Saved)

					Entity.SavedScale = nil
				end)
			end

			return false
		end

		local PhysObj = ApplyScale(Entity, Data, Scale)
		local Size    = Data:GetSize(Scale)

		Entity.Size  = Size
		Entity.Scale = Scale

		if IsValid(PhysObj) then
			if Entity.OnResized then Entity:OnResized(Size, Scale) end

			hook.Run("ACF_OnEntityResized", Entity, PhysObj, Size, Scale)
		end

		return true
	end

	function ENT:SetSize(Size)
		if not isvector(Size) then return false end

		local Base  = self:GetOriginalSize()
		local Scale = Base and Vector(1 / Base.x, 1 / Base.y, 1 / Base.z) * Size

		return ResizeEntity(self, Scale)
	end

	function ENT:SetScale(Scale)
		if isnumber(Scale) then
			Scale = Vector(Scale, Scale, Scale)
		elseif not isvector(Scale) then
			return false
		end

		local Base = self:GetOriginalSize()

		return ResizeEntity(self, Base and Scale)
	end
end

Network.CreateSender("ACF_Scalable_Entity", function(Queue, Entity)
	Queue[Entity:EntIndex()] = true
	Standby[Entity] = true

	Entity:CallOnRemove("ACF_Scalable_Entity", function()
		Standby[Entity] = nil
	end)
end)

Network.CreateReceiver("ACF_Scalable_Entity", function(Data)
	for Index, Info in pairs(Data) do
		local Entity = ents.GetByIndex(Index)

		if not IsValid(Entity) then continue end
		if not Entity.IsScalable then continue end

		local Scale = Info.Scale

		Standby[Entity] = nil

		Entity:RemoveCallOnRemove("ACF_Scalable_Entity")
		Entity:SetScaleData(Info.Type, Info.Path)

		if not Entity:SetScale(Scale) then
			Entity.SavedScale = Scale
		end
	end
end)

do -- Dealing with visual clip's bullshit
	local EntMeta = FindMetaTable("Entity")

	function ENT:EnableMatrix(Type, Value, ...)
		if Type == "RenderMultiply" and self.Matrix then
			local Current = self.Matrix:GetScale()
			local Scale   = Value:GetScale()

			-- Visual clip provides a scale of 0, 0, 0
			-- So we just update it with our actual scale
			if Current ~= Scale then
				Value:SetScale(Current)
			end
		end

		return EntMeta.EnableMatrix(self, Type, Value, ...)
	end

	function ENT:DisableMatrix(Type, ...)
		if Type == "RenderMultiply" and self.Matrix then
			-- Visual clip will attempt to disable the matrix
			-- We don't want that to happen with scalable entities
			self:EnableMatrix(Type, self.Matrix)

			return
		end

		return EntMeta.DisableMatrix(self, Type, ...)
	end
end

do -- Scalable entity related hooks
	hook.Add("Initialize", "ACF Scalable Decals", function()
		-- Detour decals to scale better on scaled entities
		local DecalEx = util.DecalEx

		util.DecalEx = function(Mat, Entity, Pos, Normal, Color, W, H, ...)
			if Entity.IsScalable and Entity:GetSize() then -- If entity is scaled, offset decal pos
				local Offset = Pos - Entity:GetPos()

				-- Thank you, Garry. Very cool.
				local O 	 = Entity:GetOriginalSize()
				local C 	 = Entity:GetSize()
				local Scaler = Vector(O[1] / C[1], O[2] / C[2], O[3] / C[3])

				Pos = Entity:GetPos() + Offset * Scaler

				local Max = math.max(Scaler[1], Scaler[2], Scaler[3])

				W = W * Max
				H = H * Max
			end

			DecalEx(Mat, Entity, Pos, Normal, Color, W, H, ...)
		end

		hook.Remove("Initialize", "Scalable Entities")
	end)

	-- NOTE: Someone reported this could maybe be causing crashes. Please confirm.
	hook.Add("PhysgunPickup", "Scalable Entity Physgun", function(_, Entity)
		if Entity.IsScalable then return false end
	end)

	hook.Add("NetworkEntityCreated", "Scalable Entity Full Update", function(Entity)
		if not Entity.IsScalable then return end

		-- Instantly requesting ScaleData and Scale
		if not Standby[Entity] then
			Network.Send("ACF_Scalable_Entity", Entity)
		end

		if Entity.OnFullUpdate then Entity:OnFullUpdate() end
	end)
end
