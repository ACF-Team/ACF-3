AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--------

local ACF = ACF


function ENT:Enable() end
function ENT:Disable() end

do -- Spawning and updating
	local Turrets = ACF.Classes.TurretTypes

	local function CreateInputs(Entity, Data, Class)
		local List = { "Active" }

		if Class.SetupInputs then
			Class:SetupInputs(List, Entity, Data, Class)
		end

		hook.Run("ACF_OnSetupInputs", "acf_turret", List, Entity, Data, Class)

		if Entity.Inputs then
			Entity.Inputs = WireLib.AdjustInputs(Entity, List)
		else
			Entity.Inputs = WireLib.CreateInputs(Entity, List)
		end
	end

	local function CreateOutputs(Entity, Data, Class, Weapon)
		local List = { }

		if Class.SetupOutputs then
			Class.SetupOutputs(List, Entity, Data, Class, Weapon)
		end

		hook.Run("ACF_OnSetupOutputs", "acf_turret", List, Entity, Data, Class, Weapon)

		if Entity.Outputs then
			Entity.Outputs = WireLib.AdjustOutputs(Entity, List)
		else
			Entity.Outputs = WireLib.CreateOutputs(Entity, List)
		end
	end

	local function GetMass(Model)
		return math.Round(ACF.GetModelVolume(Model) * 7.84 * ACF.gCmToKgIn)
	end

	local function VerifyData(Data)
		Data.Diameter = ACF.CheckNumber(Data.PlateSizeX, 24)
	end

	local function UpdateTurret(Entity, Data, Class)
		local Model    = Class.Model
		local Diameter = Data.Diameter

		Entity.ACF.Model = Model
		Entity:SetScale(Diameter / Entity:GetOriginalSize().x)

		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name      = Diameter .. "\" " .. Class.Name
		Entity.ShortName = Diameter .. "\" TD"
		Entity.EntType   = Class.Name
		Entity.Class     = Class.Id
		Entity.Diameter  = Diameter

		CreateInputs(Entity, Data, Class)
		CreateOutputs(Entity, Data, Class)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)
		Entity:SetNWString("Class", Entity.Class)

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj

		if IsValid(PhysObj) then
			local Mass = GetMass(Model, PhysObj, Class)

			Entity.ACF.LegalMass = Mass

			PhysObj:SetMass(Mass)
		end

		Entity:UpdateOverlay()
	end

	function MakeACF_Turret(Player, Pos, Angle, Data)
		VerifyData(Data)

		if not Player:CheckLimit("_acf_turret") then return false end

		local Entity = ents.Create("acf_turret")

		if not IsValid(Entity) then return end

		local Class = Turrets[Data.Class]

		Player:AddCount("_acf_turret", Entity)
		Player:AddCleanup("_acf_turret", Entity)

		Entity:SetModel(Class.Model)
		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.Owner     = Player -- MUST be stored on ent for PP
		Entity.DataStore = ACF.GetEntityArguments("acf_turret")
		Entity.ACF       = {}
		Entity.Class     = Data.Class

		UpdateTurret(Entity, Data, Class)
		print("aa" .. Data.Class)

		if Class.OnSpawn then
			Class:OnSpawn(Entity, Data)
		end

		hook.Run("ACF_OnEntitySpawn", "acf_turret", Entity, Data, Class)

		do -- Mass entity mod removal
			local EntMods = Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		return Entity
	end

	ACF.RegisterEntityClass("acf_turret", MakeACF_Turret, "Type", "Diameter")

	function ENT:Update(Data)
		VerifyData(Data)

		local Turret    = Turrets[Data.Class]
		local OldTurret = self.Turret

		if OldTurret.OnLast then
			OldTurret:OnLast(self)
		end

		hook.Run("ACF_OnEntityLast", "acf_turret", self, OldClass)

		ACF.SaveEntity(self)

		UpdatePlate(self, Data, Turret)

		ACF.RestoreEntity(self)

		if Turret.OnUpdate then
			Turret:OnUpdate(Plate, Data)
		end

		hook.Run("ACF_OnEntityUpdate", "acf_turret", self, Data, Turret)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Turret drive updated successfully!"
	end
end

do -- Overlay
	function ENT:UpdateOverlayText()
		return " "
	end
end