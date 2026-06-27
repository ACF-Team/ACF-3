
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

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
	local Inputs     = {}
	local Outputs    = { "Entity (The computer itself.) [ENTITY]" }

	ENT.ACF_StaticWireInputs  = Inputs
	ENT.ACF_StaticWireOutputs = Outputs

	-- Components are V2 classes (ACF.Components.*) with no CLASS.ID; addressed by FQN suffix.
	local function GetComponentClass(ID)
		local Direct = Classes.GetSubtypeByName("ACF.Components.BaseComponent", ID)
		if Direct then return Direct end

		for _, Class in ipairs(Classes.GetSubtypesAsList("ACF.Components.BaseComponent")) do
			if Classes.GetTypeName(Class):match("[^.]+$") == ID then return Class end
		end
	end

	local function ComponentShortID(Class)
		return Classes.GetTypeName(Class):match("[^.]+$")
	end

	-- Resolve the component class and run its class-level verify (runs on raw client/dupe data).
	function ENT.ACF_OnVerifyClientData(ClientData)
		-- The shared components menu writes the selected item to "Component"; the entity field is "Computer".
		ClientData.Computer = ClientData.Computer or ClientData.Component

		local ID = ClientData.Computer
		if istable(ID) then ID = ID.Type end

		local Class = GetComponentClass(ID) or Classes.GetTypeByName("ACF.Components.LaserGuidanceComputer")
		if Class and Class.VerifyData then Class.VerifyData(ClientData, Class) end
	end

	function ENT.ACF_CheckSpawnLimit(Player)
		return Player:CheckLimit("_acf_computer")
	end

	local function UpdateComputer(Entity)
		local Computer = Entity:GetComputer()
		local Class    = Classes.GetBaseClass(Computer:GetType())

		Entity.ACF = Entity.ACF or {}

		Contraption.SetModel(Entity, Computer.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		local ComputerID = ComponentShortID(Computer)

		-- The component item inherits its group's handlers, so a single lookup covers both.
		Entity.Computer     = ComputerID
		Entity.Name         = Computer.Name
		Entity.ShortName    = ComputerID
		Entity.EntType      = Class and Class.Name or Computer.Name
		Entity.ClassData    = Class
		Entity.OnUpdate     = Computer.OnUpdate
		Entity.OnLast       = Computer.OnLast
		Entity.OverlayTitle = Computer.OnOverlayTitle
		Entity.OverlayBody  = Computer.OnOverlayBody
		Entity.OnDamaged    = Computer.OnDamaged
		Entity.OnEnabled    = Computer.OnEnabled
		Entity.OnDisabled   = Computer.OnDisabled
		Entity.OnThink      = Computer.OnThink

		-- Wire IO is (re)built by AutoRegisterV2's ACF_SetupWireFunctions after this runs (see ACF_SetupWireIO).

		Entity:SetNWString("WireName", "ACF " .. Computer.Name)
		Entity:SetNW2String("ID", ComputerID)

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Computer.Mass)

		if Entity.OnUpdate then Entity:OnUpdate(nil, Class, Computer) end
		if Entity.OnDamaged then Entity:OnDamaged() end
	end

	-- Dynamic wire IO contributed by the selected component (was the ACF_OnSetup* hooks).
	function ENT:ACF_SetupWireIO(WireInputs, WireOutputs)
		local Computer = self:GetComputer()
		if not Computer then return end

		if Computer.Inputs then
			for _, Input in ipairs(Computer.Inputs) do WireInputs[#WireInputs + 1] = Input end
		end

		if Computer.Outputs then
			for _, Output in ipairs(Computer.Outputs) do WireOutputs[#WireOutputs + 1] = Output end
		end
	end

	function ENT:ACF_PreSpawn()
		self.ACF     = {}
		self.Weapons = {}

		duplicator.ClearEntityModifier(self, "mass")
	end

	-- Runs before each reconfigure (and on remove) while the OLD component config is live.
	function ENT:ACF_OnEntityLast()
		if self.OnLast then self:OnLast() end
	end

	function ENT:ACF_PostUpdateEntityData()
		UpdateComputer(self)
	end

	function ENT:ACF_PostSpawn()
		local Computer = self:GetComputer()
		local Class    = Classes.GetBaseClass(Computer:GetType())

		if Class and Class.OnSpawn then Class.OnSpawn(self, nil, Class, Computer) end

		timer.Create("ACF Computer Clock " .. self:EntIndex(), 3, 0, function()
			if not IsValid(self) then return end

			CheckDistantLinks(self, "Weapons")
		end)
	end

	ACF.RegisterLinkSource("acf_computer", "Weapons")
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

	-- AutoRegisterV2 wraps this as the original PreEntityCopy and handles the wire/base dupe info.
end

function ENT:PostEntityPaste(_, Ent, CreatedEntities)
	local EntMods = Ent.EntityMods

	if EntMods.ACFWeapons then
		for _, EntID in pairs(EntMods.ACFWeapons) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.ACFWeapons = nil
	end

	-- AutoRegisterV2 wraps this as the original PostEntityPaste and handles the wire/base dupe info.
end

-- Remove-only teardown. Captured by AutoRegisterV2 as OrigOnRemove; the generated OnRemove runs
-- ACF_OnEntityLast (which fires the component's OnLast) + WireLib cleanup around this.
function ENT:OnRemove(IsFullUpdate)
	if IsFullUpdate then return end

	for Weapon in pairs(self.Weapons) do
		self:Unlink(Weapon)
	end

	timer.Remove("ACF Computer Clock " .. self:EntIndex())
end
