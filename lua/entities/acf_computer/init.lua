
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

ACF.RegisterClassLink("acf_computer", "acf_rack", function(Computer, Target)
	if Computer.Weapons[Target] then return false, "This rack is already linked to this computer!" end
	if Target.Computer == Computer then return false, "This rack is already linked to this computer!" end

	Computer.Weapons[Target] = true
	Target.Computer = Computer

	Computer:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Rack linked successfully!"
end)

ACF.RegisterClassUnlink("acf_computer", "acf_rack", function(Computer, Target)
	if Computer.Weapons[Target] or Target.Computer == Computer then
		Computer.Weapons[Target] = nil
		Target.Computer = nil

		Computer:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Rack unlinked successfully!"
	end

	return false, "This rack is not linked to this computer."
end)

ACF.RegisterClassLink("acf_computer", "acf_gun", function(Computer, Target)
	if Computer.Weapons[Target] then return false, "This computer is already linked to this weapon!" end
	if Target.Computer == Computer then return false, "This computer is already linked to this weapon!" end

	Computer.Weapons[Target] = true
	Target.Computer = Computer

	Computer:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Computer linked successfully!"
end)

ACF.RegisterClassUnlink("acf_computer", "acf_gun", function(Computer, Target)
	if Computer.Weapons[Target] or Target.Computer == Computer then
		Computer.Weapons[Target] = nil
		Target.Computer = nil

		Computer:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Computer unlinked successfully!"
	end

	return false, "This computer is not linked to this weapon."
end)

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

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
	local Inputs     = {}
	local Outputs    = { "Entity (The computer itself.) [ENTITY]" }

	local function VerifyData(Data)
		if not Data.Computer then
			Data.Computer = Data.Component or Data.Id
		end

		local Class = Classes.GetGroup(Components, Data.Computer)

		if not Class or Class.Entity ~= "acf_computer" then
			Data.Computer = "CPR-LSR"

			Class = Classes.GetGroup(Components, "CPR-LSR")
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			hook.Run("ACF_OnVerifyData", "acf_computer", Data, Class)
		end
	end

	local function UpdateComputer(Entity, Data, Class, Computer)
		Entity.ACF = Entity.ACF or {}

		Contraption.SetModel(Entity, Computer.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		if Entity.OnLast then
			Entity:OnLast()
		end

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name         = Computer.Name
		Entity.ShortName    = Entity.Computer
		Entity.EntType      = Class.Name
		Entity.ClassData    = Class
		Entity.OnUpdate     = Computer.OnUpdate or Class.OnUpdate
		Entity.OnLast       = Computer.OnLast or Class.OnLast
		Entity.OverlayTitle = Computer.OnOverlayTitle or Class.OnOverlayTitle
		Entity.OverlayBody  = Computer.OnOverlayBody or Class.OnOverlayBody
		Entity.OnDamaged    = Computer.OnDamaged or Class.OnDamaged
		Entity.OnEnabled    = Computer.OnEnabled or Class.OnEnabled
		Entity.OnDisabled   = Computer.OnDisabled or Class.OnDisabled
		Entity.OnThink      = Computer.OnThink or Class.OnThink

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Computer)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Computer)

		Entity:SetNWString("WireName", "ACF " .. Computer.Name)
		Entity:SetNW2String("ID", Entity.Computer)

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Computer.Mass)

		if Entity.OnUpdate then
			Entity:OnUpdate(Data, Class, Computer)
		end

		if Entity.OnDamaged then
			Entity:OnDamaged()
		end
	end

	hook.Add("ACF_OnSetupInputs", "ACF Computer Inputs", function(Entity, List, _, _, Computer)
		if Entity:GetClass() ~= "acf_computer" then return end
		if not Computer.Inputs then return end

		local Count = #List

		for I, Input in ipairs(Computer.Inputs) do
			List[Count + I] = Input
		end
	end)

	hook.Add("ACF_OnSetupOutputs", "ACF Computer Outputs", function(Entity, List, _, _, Computer)
		if Entity:GetClass() ~= "acf_computer" then return end
		if not Computer.Outputs then return end

		local Count = #List

		for I, Output in ipairs(Computer.Outputs) do
			List[Count + I] = Output
		end
	end)

	-------------------------------------------------------------------------------

	function ACF.MakeComputer(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Components, Data.Computer)
		local Computer = Class.Lookup[Data.Computer]
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end

		local CanSpawn = hook.Run("ACF_PreSpawnEntity", "acf_computer", Player, Data, Class, Computer)
		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_computer")

		if not IsValid(Entity) then return end

		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Player:AddCleanup("acf_computer", Entity)
		Player:AddCount(Limit, Entity)

		Entity.Weapons   = {}
		Entity.DataStore = Entities.GetArguments("acf_computer")

		UpdateComputer(Entity, Data, Class, Computer)

		if Class.OnSpawn then
			Class.OnSpawn(Entity, Data, Class, Computer)
		end

		hook.Run("ACF_OnSpawnEntity", "acf_computer", Entity, Data, Class, Computer)

		duplicator.ClearEntityModifier(Entity, "mass")

		timer.Create("ACF Computer Clock " .. Entity:EntIndex(), 3, 0, function()
			if not IsValid(Entity) then return end

			CheckDistantLinks(Entity, "Weapons")
		end)

		return Entity
	end

	Entities.Register("acf_opticalcomputer", ACF.MakeComputer, "Computer") -- Backwards compatibility
	Entities.Register("acf_computer", ACF.MakeComputer, "Computer")

	ACF.RegisterLinkSource("acf_computer", "Weapons")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Class    = Classes.GetGroup(Components, Data.Computer)
		local Computer = Class.Lookup[Data.Computer]
		local OldClass = self.ClassData

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		hook.Run("ACF_OnEntityLast", "acf_computer", self, OldClass)

		ACF.SaveEntity(self)

		UpdateComputer(self, Data, Class, Computer)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Computer)
		end

		hook.Run("ACF_OnUpdateEntity", "acf_computer", self, Data, Class, Computer)

		return true, "Computer updated successfully!"
	end
end

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	--self.Spread = ACF.MaxDamageInaccuracy * (1 - math.Round(self.ACF.Health / self.ACF.MaxHealth, 2))
	if self.OnDamaged then
		self:OnDamaged()
	end

	return HitRes
end

function ENT:Enable()
	if self.OnEnabled then
		self:OnEnabled()
	end
end

function ENT:Disable()
	if self.OnDisabled then
		self:OnDisabled()
	end
end

function ENT:ACF_UpdateOverlayState(State)
	if self.OverlayTitle then
		self:OverlayTitle(State)
	else
		State:AddSuccess("Idle")
	end

	if self.OverlayBody then
		self:OverlayBody(State)
	end
end

function ENT:Think()
	if self.OnThink then
		self:OnThink()
	end

	self:NextThink(Clock.CurTime)

	return true
end

function ENT:PreEntityCopy()
	if next(self.Weapons) then
		local Entities = {}

		for Weapon in pairs(self.Weapons) do
			Entities[#Entities + 1] = Weapon:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFWeapons", Entities)
	end

	-- wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	local EntMods = Ent.EntityMods

	if EntMods.ACFWeapons then
		for _, EntID in pairs(EntMods.ACFWeapons) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.ACFWeapons = nil
	end

	-- Wire dupe info
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	local OldClass = self.ClassData

	if OldClass.OnLast then
		OldClass.OnLast(self, OldClass)
	end

	hook.Run("ACF_OnEntityLast", "acf_computer", self, OldClass)

	for Weapon in pairs(self.Weapons) do
		self:Unlink(Weapon)
	end

	if self.OnLast then
		self:OnLast()
	end

	timer.Remove("ACF Computer Clock " .. self:EntIndex())

	WireLib.Remove(self)
end
