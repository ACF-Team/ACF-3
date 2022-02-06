DEFINE_BASECLASS("base_wire_entity") -- Required to get the local BaseClass

include("shared.lua")

local Queued = {}

local function ChangeSize(Entity, Size)
	if not isvector(Size) then return false end
	if not Entity:GetOriginalSize() then return false end

	local Original = Entity:GetOriginalSize()
	local Scale = Vector(Size.x / Original.x, Size.y / Original.y, Size.z / Original.z)

	Entity:ApplyNewSize(Size, Scale)

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

function ENT:ApplyNewSize(_, NewScale)
	local Mesh = self.Mesh

	self.Matrix = Matrix()
	self.Matrix:Scale(NewScale)

	self:EnableMatrix("RenderMultiply", self.Matrix)

	for I, Hull in ipairs(Mesh) do
		for J, Vertex in ipairs(Hull) do
			Mesh[I][J] = (Vertex.pos or Vertex) * NewScale
		end
	end

	self:PhysicsInitMultiConvex(Mesh)
	self:EnableCustomCollisions(true)
	self:SetRenderBounds(self:GetCollisionBounds())
	self:DrawShadow(false)

	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
		PhysObj:Sleep()
	end
end

function ENT:SetExtraInfo(Extra)
	self.RealMesh = Extra.Mesh
	self.Mesh     = table.Copy(Extra.Mesh)
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

function ENT:Think()
	if not self.Initialized then
		self:Initialize()
	end

	BaseClass.Think(self)
end

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

hook.Add("Initialize", "ACF Scalable Decals", function()
	-- Detour decals to scale better on scaled entities
	local DecalEx = util.DecalEx

	util.DecalEx = function(Mat, Ent, Pos, Normal, Color, W, H, ...)
		if Ent.IsScalable and Ent:GetSize() then -- If entity is scaled, offset decal pos
			local Offset = Pos - Ent:GetPos()

			-- Thank you, Garry. Very cool.
			local O 	 = Ent:GetOriginalSize()
			local C 	 = Ent:GetSize()
			local Scaler = Vector(O[1] / C[1], O[2] / C[2], O[3] / C[3])

			Pos = Ent:GetPos() + Offset * Scaler

			local Max = math.max(Scaler[1], Scaler[2], Scaler[3])

			W = W * Max
			H = H * Max
		end

		DecalEx(Mat, Ent, Pos, Normal, Color, W, H, ...)
	end

	hook.Remove("Initialize", "Scalable Entities")
end)

-- NOTE: Someone reported this could maybe be causing crashes. Please confirm.
hook.Add("PhysgunPickup", "Scalable Ent Physgun", function(_, Ent)
	if Ent.IsScalable then return false end
end)

hook.Add("NetworkEntityCreated", "Scalable Ent Full Update", function(Ent)
	if Ent.IsScalable then
		local Size    = Ent:GetSize()
		local Scale   = Ent:GetScale()
		local Counter = Vector(1 / Scale.x, 1 / Scale.y, 1 / Scale.z)

		Ent:SetScale(Counter) -- Return to normal size
		Ent:SetSize(Size) -- Reapply size

		if Ent.OnFullUpdate then Ent:OnFullUpdate() end
	end
end)
