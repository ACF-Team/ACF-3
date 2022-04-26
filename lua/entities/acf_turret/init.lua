AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--------

local ACF   = ACF
local VEC_0 = Vector()

ACF.AddParentDetour("acf_turret", "rotator")

function ENT:Enable() end
function ENT:Disable() end

do -- Spawning and updating
	local Turrets = ACF.Classes.TurretTypes

	local function CreateInputs(Entity, Data, Class)
		local List = { "Active (Toggle the drive on or off)", "Angle (Desired angle to aim towards) [ANGLE]"}

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
		return math.Round(ACF.ModelData.GetModelVolume(Model) * 7.84 * ACF.gCmToKgIn)
	end

	local function VerifyData(Data)
		Data.Diameter = ACF.CheckNumber(Data.PlateSizeX, 24)
	end

	local function UpdateTurret(Entity, Data, Class)
		local Model    = Class.Model
		local Diameter = Data.Diameter
		local ratio    = Diameter / Entity:GetOriginalSize().x
		Entity.ACF.Model = Model

		Entity:SetScale(Vector(ratio, ratio, ratio * 0.25))

		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name      = Diameter .. "\" " .. Class.Name
		Entity.ShortName = Diameter .. "\" TD"
		Entity.EntType   = Class.Name
		Entity.Class     = Class.Id
		Entity.Diameter  = Diameter

		Entity.desiredAngle = Entity.desiredAngle or Angle(0, 0, 0)
		Entity.currentAngle = Entity.currentAngle or Angle(0, 0, 0)

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

	function MakeACF_Turret(Player, Pos, Ang, Data)
		VerifyData(Data)

		if not Player:CheckLimit("_acf_turret") then return false end

		local Entity  = ents.Create("acf_turret")
		if not IsValid(Entity) then return end

		local rotator = ents.Create("acf_turret_rotator")

		if not IsValid(rotator) then
			Entity:Remove()
			return
		end

		local Class = Turrets[Data.Class]

		Player:AddCount("_acf_turret", Entity)
		Player:AddCleanup("_acf_turret", Entity)

		Entity:SetModel(Class.Model)
		Entity:SetPlayer(Player)
		Entity:SetAngles(Ang)
		Entity:SetPos(Pos)
		Entity:Spawn()

		rotator:SetPos(Entity:GetPos())
		rotator:SetAngles(Entity:GetAngles())
		rotator:SetParent(Entity)
		rotator:SetModel("models/sprops/misc/origin.mdl")
		rotator:Spawn()

		Entity.Owner     = Player -- MUST be stored on ent for PP
		Entity.DataStore = ACF.GetEntityArguments("acf_turret")
		Entity.ACF       = {}
		Entity.Class     = Data.Class

		Entity.rotator   = rotator

		Entity.slewRate  = 0 -- Internal value for motor speeds
		--Entity.slewMax   = 40 * engine.TickInterval()  -- Degrees per second (Unused)
		--Entity.slewAccel = 5 * engine.TickInterval()  -- Degrees per second per second (Unused)
		Entity.Active	 = false -- If true, the motor is active and the turret is attempting to point to the required angle
		-- If false, the motor slows to a stop and no aiming happens

		UpdateTurret(Entity, Data, Class)

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

	function ENT:OnRemove()
		if IsValid(self.rotator) then
			self.rotator:Remove()
		end
	end
end

do -- Wire io
	ACF.AddInputAction("acf_turret", "Active", function(Ent, Value)
		if not IsValid(Ent) then return end
		Ent.Active = Value == 1 and true or false
		print(Ent.Active)
	end)

	ACF.AddInputAction("acf_turret", "Angle", function(Ent, Value)
		if not IsValid(Ent) then return end

		local p, y, r = Value[1], Value[2], Value[3]

		Ent.desiredAngle = Angle(p, y, r)
	end)
end

do -- Movement
	local function clampAngle(a, mins, maxs)

	end

	function ENT:Think()
		local tick = engine.TickInterval()
		local bearing = self.rotator:WorldToLocalAngles(self.desiredAngle).yaw * (self.Active and 1 or 0) -- Get the bearing (relative yaw) of the desired angle from the current angle
		local slewMax = 72 * tick -- replace 72 with a value for total motor speed
		local slewAccel = 1 * tick -- replace 1 with a value for motor acceleration

		local sign            = bearing < 0 and -1 or 1
		local distance        = math.abs(bearing)
		local finalAccel	  = math.Clamp(bearing / 2,-slewAccel,slewAccel) -- a somewhat successful effort at getting rid of the "vibrating" when the gun settles
		local brakingDistance = self.slewRate^2 / math.abs(finalAccel) / 2

		--self.slewRate = math.Clamp(bearing, -slewMax, slewMax) -- old calculation, kept for reference or whatever
		if self.Active then self.slewRate = math.Clamp(self.slewRate + (math.abs(finalAccel) * ((distance + (self.slewRate * 2 * -sign)) > brakingDistance and sign or -sign)), -slewMax, slewMax)
		elseif not self.Active and self.slewRate ~= 0 then
			self.slewRate = self.slewRate - (math.min(slewAccel,math.abs(self.slewRate)) * (self.slewRate >= 0 and 1 or -1))
		end

		self.currentAngle = self.currentAngle + Angle(0, self.slewRate, 0)

		self.rotator:SetAngles(self:LocalToWorldAngles(self.currentAngle))

		self:NextThink(CurTime())
		return true
	end
end

do -- Overlay
	function ENT:UpdateOverlayText()
		return ""
	end
end

function ENT:GetChildren()
	return self.rotator:GetChildren()
end
