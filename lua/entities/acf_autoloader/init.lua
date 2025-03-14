
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local hook      = hook
local ACF       = ACF
local Contraption	= ACF.Contraption
local Damage    = ACF.Damage
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock
local Sounds    = Utilities.Sounds

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local CheckLegal  = ACF.CheckLegal
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance

local function CheckDistantLinks(Entity, Source)
	local Position = Entity:GetPos()

	for Link in pairs(Entity[Source]) do
		if Position:DistToSqr(Link:GetPos()) > MaxDistance then
			local Sound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(Entity, Sound, 70, 100, 1)
			Sounds.SendSound(Link, Sound, 70, 100, 1)

			Entity:Unlink(Link)
		end
	end
end

--===============================================================================================--

do -- Spawn and update function
	local Classes    = ACF.Classes
	local WireIO     = Utilities.WireIO
	local Components = Classes.Components
	local Entities   = Classes.Entities
	local AutoloaderTypes = Classes.AutoloaderTypes

	local Inputs     = {}
	local Outputs    = { "Entity (The Autoloader itself.) [ENTITY]" }

	local function VerifyData(Data)
		if not Data.AutoloaderModelID then
			Data.AutoloaderModelID = Data.Component or Data.Id
		end

		local Class = Classes.GetGroup(Components, Data.AutoloaderModelID)

		if not Class or Class.Entity ~= "acf_autoloader" then
			Data.AutoloaderModelID = "CST"

			Class = Classes.GetGroup(Components, Data.AutoloaderModelID)
		end

		if Data.AutoloaderTypeID == nil then Data.AutoloaderTypeID = "Type1" end

		local X = ACF.CheckNumber(Data.AutoloaderSizeX, 24)
		local Y = ACF.CheckNumber(Data.AutoloaderSizeY, 24)
		local Z = ACF.CheckNumber(Data.AutoloaderSizeZ, 24)

		Data.Size = Vector(X, Y, Z)

		do
			Data.Size.x = math.Clamp(math.Round(Data.Size.x), ACF.AutoloaderMinSize, ACF.AutoloaderMaxSize)
			Data.Size.y = math.Clamp(math.Round(Data.Size.y), ACF.AutoloaderMinSize, ACF.AutoloaderMaxSize)
			Data.Size.z = math.Clamp(math.Round(Data.Size.z), ACF.AutoloaderMinSize, ACF.AutoloaderMaxSize)
		end
	end

	local function UpdateAutoloader(Entity, Data, Class, AutoloaderModel, AutoloaderType)
		Entity.ACF = Entity.ACF or {}

		Entity:SetScaledModel(AutoloaderModel.Model)
		Entity:SetSize(Data.Size)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name         = AutoloaderModel.Name
		Entity.ShortName    = AutoloaderModel.ID
		Entity.EntType      = "Autoloader"
		Entity.ClassData    = Class

		Entity.AutoloaderModelName = AutoloaderModel.Name
		Entity.AutoloaderTypeName = AutoloaderType.Name

		WireIO.SetupInputs(Entity, Inputs, Data, Class, AutoloaderModel)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, AutoloaderModel)

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, AutoloaderModel.Mass or 1000)
	end

	-------------------------------------------------------------------------------

	function MakeACF_Autoloader(Player, Pos, Ang, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Components, Data.AutoloaderModelID)
		local AutoloaderModel = Class.Lookup[Data.AutoloaderModelID]
		local AutoloaderType = AutoloaderTypes.Get(Data.AutoloaderTypeID)

		local Limit = Class.LimitConVar.Name
		if not Player:CheckLimit(Limit) then return false end

		local Entity = ents.Create("acf_autoloader")

		if not IsValid(Entity) then return end

		Entity:SetMaterial("phoenix_storms/MetalSet_1-2")
		Entity:SetScaledModel(AutoloaderModel.Model)
		Entity:SetAngles(Ang)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Player:AddCleanup("acf_autoloader", Entity)
		Player:AddCount(Limit, Entity)

		Entity.DataStore = Entities.GetArguments("acf_autoloader")

		UpdateAutoloader(Entity, Data, Class, AutoloaderModel, AutoloaderType)

		hook.Run("ACF_OnSpawnEntity", "acf_autoloader", Entity, Data, Class, AutoloaderModel, AutoloaderType)

		duplicator.ClearEntityModifier(Entity, "mass")

		CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_autoloader", MakeACF_Autoloader, "AutoloaderModelID", "AutoloaderTypeID")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Class    = Classes.GetGroup(Components, Data.AutoloaderModelID)
		local AutoloaderModel = Class.Lookup[Data.AutoloaderModelID]
		local AutoloaderType = AutoloaderTypes.Get(Data.AutoloaderTypeID)

		hook.Run("ACF_OnEntityLast", "acf_autoloader", self)

		ACF.SaveEntity(self)

		UpdateAutoloader(self, Data, Class, AutoloaderModel, AutoloaderType)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, AutoloaderModel, AutoloaderType)
		end

		hook.Run("ACF_OnUpdateEntity", "acf_autoloader", self, Data, Class, AutoloaderModel, AutoloaderType)

		return true, "Autoloader updated successfully!"
	end
end

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	return HitRes
end

function ENT:Enable()
	print("Entity Enabled")
	if self.OnEnabled then
		self:OnEnabled()
	end
end

function ENT:Disable()
	print("Entity Disabled")
	if self.OnDisabled then
		self:OnDisabled()
	end
end

function ENT:UpdateOverlayText()
	str = string.format("Model: %s\nType: %s\n",
		self.AutoloaderModelName,
		self.AutoloaderTypeName
	)
	return str
end

function ENT:Think()
	if self.OnThink then
		self:OnThink()
	end

	self:NextThink(Clock.CurTime)

	return true
end

function ENT:PreEntityCopy()

	-- wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	local EntMods = Ent.EntityMods

	-- Wire dupe info
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	hook.Run("ACF_OnEntityLast", "acf_autoloader", self)

	WireLib.Remove(self)
end
