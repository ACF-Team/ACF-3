local ACF       = ACF
local ModelData = ACF.ModelData
local Models    = ModelData.Models
local Network   = ACF.Networking

do -- Pointer entity creation
	local function Create()
		if IsValid(ModelData.Entity) then return end -- No need to create it if it already exists

		local Entity = ents.Create("base_entity")

		if not IsValid(Entity) then return print("[SERVER] Failed to create ModelData entity") end

		function Entity:UpdateTransmitState()
			return TRANSMIT_ALWAYS
		end

		Entity:SetModel("models/props_junk/popcan01a.mdl")
		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_NONE)
		Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
		Entity:SetNotSolid(true)
		Entity:SetNoDraw(true)
		Entity:Spawn()

		Entity:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
		Entity:CallOnRemove("ACF_ModelData", function()
			hook.Add("Think", "ACF_ModelData_Entity", function()
				Create()

				hook.Remove("Think", "ACF_ModelData_Entity")
			end)
		end)

		Network.Broadcast("ACF_ModelData_Entity", Entity)

		ModelData.Entity = Entity
	end

	hook.Add("InitPostEntity", "ACF_ModelData", function()
		Create()

		hook.Remove("InitPostEntity", "ACF_ModelData")
	end)

	hook.Add("ACF_OnPlayerLoaded", "ACF_ModelData", function(Player)
		Network.Send("ACF_ModelData_Entity", Player, ModelData.Entity)
	end)

	hook.Add("ShutDown", "ACF_ModelData", function()
		local Entity = ModelData.Entity

		if not IsValid(Entity) then return end

		Entity:RemoveCallOnRemove("ACF_ModelData")
	end)
end

do -- Model data getter method
	local util = util

	local function CreatePhysObj(Model)
		util.PrecacheModel(Model)

		local Entity = ModelData.Entity

		Entity:SetModel(Model)
		Entity:PhysicsInit(SOLID_VPHYSICS)

		return Entity:GetPhysicsObject()
	end

	local function SanitizeMesh(PhysObj)
		local Mesh = PhysObj:GetMeshConvexes()

		for I, Hull in ipairs(Mesh) do
			for J, Vertex in ipairs(Hull) do
				Mesh[I][J] = Vertex.pos
			end
		end

		return Mesh
	end

	-------------------------------------------------------------------

	function ModelData.GetModelData(Model)
		local Path = ModelData.GetModelPath(Model)

		if not Path then return end

		local Data = Models[Path]

		if Data then return Data end

		local PhysObj = CreatePhysObj(Path)

		if not IsValid(PhysObj) then return end

		local Min, Max = PhysObj:GetAABB()

		Data = {
			Mesh   = SanitizeMesh(PhysObj),
			Volume = PhysObj:GetVolume(),
			Center = (Min + Max) * 0.5,
			Size   = Max - Min,
		}

		Models[Path] = Data

		return Data
	end
end

hook.Add("ACF_OnLoadAddon", "ACF_ModelData", function()
	Network.CreateSender("ACF_ModelData_Entity", function(Queue, Entity)
		Queue.Index = Entity:EntIndex()
	end)

	Network.CreateReceiver("ACF_ModelData", function(Player, Data)
		for Model in pairs(Data) do
			Network.Send("ACF_ModelData", Player, Model)
		end
	end)

	Network.CreateSender("ACF_ModelData", function(Queue, Model)
		Queue[Model] = ModelData.GetModelData(Model)
	end)

	hook.Remove("ACF_OnLoadAddon", "ACF_ModelData")
end)
