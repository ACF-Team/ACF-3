AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Damage      = ACF.Damage
local Contraption = ACF.Contraption
local Objects     = Damage.Objects
local ActiveTanks = ACF.FuelTanks
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock
local Sounds      = Utilities.Sounds
local RefillDist  = ACF.RefillDistance * ACF.RefillDistance
local TimerCreate = timer.Create
local TimerExists = timer.Exists
local Clamp       = math.Clamp
local Round       = math.Round
local HookRun     = hook.Run

local function CanRefuel(Refill, Tank, Distance)
	if Refill == Tank then return false end
	if Refill.FuelType ~= Tank.FuelType then return false end
	if Tank.Disabled then return false end
	if Tank.SupplyFuel then return false end
	if Tank.Fuel >= Tank.Capacity then return false end

	return Distance <= RefillDist
end

--===============================================================================================--

do -- Spawn and Update functions
	local Classes   = ACF.Classes
	local WireIO    = Utilities.WireIO
	local Entities  = Classes.Entities
	local FuelTanks = Classes.FuelTanks
	local FuelTypes = Classes.FuelTypes

	local Inputs = {
		"Active (If set to a non-zero value, it'll allow engines to consume fuel from this fuel tank.)",
		"Refuel Duty (If set to a non-zero value, this fuel tank will refill surrounding tanks that contain the same fuel type.)",
	}
	local Outputs = {
		"Activated (Whether or not this fuel tank is able to be used by an engine.)",
		"Fuel (Amount of fuel currently in the tank, in liters or kWh)",
		"Capacity (Total amount of fuel the tank can hold, in liters or kWh)",
		"Leaking (Returns 1 if the fuel tank is currently losing fuel.)",
		"Entity (The fuel tank itself.) [ENTITY]"
	}

	local function VerifyData(Data)
		if not isstring(Data.FuelTank) then
			Data.FuelTank = Data.SizeId or Data.Id
		end

		local Class = Classes.GetGroup(FuelTanks, Data.FuelTank)

		if not Class then
			Data.FuelTank = "Box"

			Class = FuelTanks.Get("Box")
		elseif FuelTanks.IsAlias(Data.FuelTank) then
			Data.FuelTank = Class.ID
		end

		if Class.IsScalable then
			local FuelTank = FuelTanks.GetItem(Class.ID, Data.FuelTank)

			if FuelTank and FuelTank.Size then
				Data.FuelTank = Class.ID
				Data.Size     = Vector(FuelTank.Size)
			elseif not isvector(Data.Size) then
				local X = ACF.CheckNumber(Data.TankSizeX, 24)
				local Y = ACF.CheckNumber(Data.TankSizeY, 24)
				local Z = ACF.CheckNumber(Data.TankSizeZ, 24)

				Data.Size = Vector(X, Y, Z)
			end

			do -- Clamping size
				local Min  = ACF.FuelMinSize
				local Max  = ACF.FuelMaxSize
				local Size = Data.Size

				Size.x = Clamp(Round(Size.x), Min, Max)
				Size.y = Clamp(Round(Size.y), Min, Max)
				Size.z = Clamp(Round(Size.z), Min, Max)
			end
		else
			Data.Size = nil
		end

		-- Making sure to provide a valid fuel type
		if not FuelTypes.Get(Data.FuelType) then
			Data.FuelType = "Petrol"
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			HookRun("ACF_VerifyData", "acf_fueltank", Data, Class)
		end
	end

	local function UpdateFuelTank(Entity, Data, Class, FuelTank, FuelType)
		-- If updating, keep the same fuel level
		local Percentage = Entity.Capacity and Entity.Fuel / Entity.Capacity or 1

		Entity.ACF = Entity.ACF or {}
		Entity.ACF.Model = FuelTank and FuelTank.Model or Class.Model -- Must be set before changing model
		Entity.ClassData = Class

		if Class.IsScalable then
			Entity:SetSize(Data.Size)
		else
			Contraption.SetModel(Entity, Entity.ACF.Model)
			Entity:PhysicsInit(SOLID_VPHYSICS, true)
			Entity:SetMoveType(MOVETYPE_VPHYSICS)
		end

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		local Volume, Area
		local Wall = ACF.FuelArmor * ACF.MmToInch -- Wall thickness in inches

		if Class.CalcVolume then
			Volume, Area = Class.CalcVolume(Data.Size, Wall)
		else -- Default to finding surface area/volume based off physics object instead
			local PhysObj = Entity:GetPhysicsObject()

			Area = PhysObj:GetSurfaceArea()
			Volume = PhysObj:GetVolume() - (Area * Wall) -- Total volume of tank (cu in), reduced by wall thickness
		end

		local NameType = " " .. (Class.NameType or FuelTank.Name)

		Entity.Name        = Entity.FuelType .. NameType
		Entity.ShortName   = Entity.FuelType
		Entity.EntType     = Class.Name
		Entity.FuelDensity = FuelType.Density
		Entity.Capacity    = Volume * ACF.gCmToKgIn * ACF.TankVolumeMul -- Internal volume available for fuel in liters
		Entity.EmptyMass   = (Area * Wall) * 16.387 * 0.0079 -- Total wall volume * cu in to cc * density of steel (kg/cc)
		Entity.IsExplosive = FuelTank and FuelTank.IsExplosive or Class.IsExplosive
		Entity.NoLinks     = FuelTank and FuelTank.Unlinkable or Class.Unlinkable
		Entity.Shape       = FuelTank and FuelTank.Shape or Class.Shape

		WireIO.SetupInputs(Entity, Inputs, Data, Class, FuelTank, FuelType)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, FuelTank, FuelType)

		if Entity.FuelType == "Electric" then
			Entity.Name = "Electric Battery"
			Entity.Liters = Entity.Capacity -- Batteries capacity is different from internal volume
			Entity.Capacity = Entity.Capacity * ACF.LiIonED
		end

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		Entity.Fuel = Percentage * Entity.Capacity

		ACF.Activate(Entity, true)

		Entity:UpdateMass(true)

		WireLib.TriggerOutput(Entity, "Fuel", Entity.Fuel)
		WireLib.TriggerOutput(Entity, "Capacity", Entity.Capacity)
	end

	hook.Add("ACF_CanUpdateEntity", "ACF Fuel Tank Size Update", function(Entity, Data)
		if not Entity.IsACFFuelTank then return end
		if Data.Size then return end -- The menu won't send it like this

		Data.Size      = Entity:GetSize()
		Data.TankSizeX = nil
		Data.TankSizeY = nil
		Data.TankSizeZ = nil
	end)

	function MakeACF_FuelTank(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class    = Classes.GetGroup(FuelTanks, Data.FuelTank)
		local FuelTank = FuelTanks.GetItem(Class.ID, Data.FuelTank)
		local FuelType = FuelTypes.Get(Data.FuelType)
		local Limit    = Class.LimitConVar.Name
		local Model    = Class.Model or FuelTank and FuelTank.Model
		local Material = Class.Material or FuelTank and FuelTank.Model

		if not Player:CheckLimit(Limit) then return end

		local CanSpawn = HookRun("ACF_PreEntitySpawn", "acf_fueltank", Player, Data, Class, FuelTank)

		if CanSpawn == false then return end

		local Tank = ents.Create("acf_fueltank")

		if not IsValid(Tank) then return end

		Tank.ACF		= Tank.ACF or {}

		Tank:SetPlayer(Player)
		Tank:SetScaledModel(Model)
		if Material then
			Tank:SetMaterial(Material)
		end
		Tank:SetAngles(Angle)
		Tank:SetPos(Pos)
		Tank:Spawn()

		Player:AddCleanup("acf_fueltank", Tank)
		Player:AddCount(Limit, Tank)

		Tank.Owner         = Player -- MUST be stored on ent for PP
		Tank.Engines       = {}
		Tank.Leaking       = 0
		Tank.LastThink     = 0
		Tank.LastFuel      = 0
		Tank.LastActivated = 0
		Tank.DataStore     = Entities.GetArguments("acf_fueltank")

		UpdateFuelTank(Tank, Data, Class, FuelTank, FuelType)

		WireLib.TriggerOutput(Tank, "Entity", Tank)

		if Class.OnSpawn then
			Class.OnSpawn(Tank, Data, Class, FuelTank)
		end

		HookRun("ACF_OnEntitySpawn", "acf_fueltank", Tank, Data, Class, FuelTank)

		Tank:UpdateOverlay(true)

		do -- Mass entity mod removal
			local EntMods = Data and Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		-- Fuel tanks should be active by default
		Tank:TriggerInput("Active", 1)

		ActiveTanks[Tank] = true

		ACF.CheckLegal(Tank)

		return Tank
	end

	Entities.Register("acf_fueltank", MakeACF_FuelTank, "FuelTank", "FuelType", "Size")

	ACF.RegisterLinkSource("acf_fueltank", "Engines")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Class    = Classes.GetGroup(FuelTanks, Data.FuelTank)
		local FuelTank = FuelTanks.GetItem(Class.ID, Data.FuelTank)
		local FuelType = FuelTypes.Get(Data.FuelType)
		local OldClass = self.ClassData
		local Feedback = ""

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_fueltank", self, Data, Class, FuelTank)
		if CanUpdate == false then return CanUpdate, Reason end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_fueltank", self, OldClass)

		ACF.SaveEntity(self)

		UpdateFuelTank(self, Data, Class, FuelTank, FuelType)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, FuelTank)
		end

		HookRun("ACF_OnEntityUpdate", "acf_fueltank", self, Data, Class, FuelTank)

		if next(self.Engines) then
			local Fuel    = self.FuelType
			local NoLinks = self.NoLinks
			local Count, Total = 0, 0

			for Engine in pairs(self.Engines) do
				if NoLinks or not Engine.FuelTypes[Fuel] then
					self:Unlink(Engine)

					Count = Count + 1
				end

				Total = Total + 1
			end

			if Count == Total then
				Feedback = "\nUnlinked from all engines due to fuel type or model change."
			elseif Count > 0 then
				local Text = "\nUnlinked from %s out of %s engines due to fuel type or model change."

				Feedback = Text:format(Count, Total)
			end
		end

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Fuel tank updated successfully!" .. Feedback
	end
end

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:ACF_Activate(Recalc)
	local PhysObj = self:GetPhysicsObject()
	local Area    = PhysObj:GetSurfaceArea() * 6.45
	local Armour  = self.EmptyMass * 1000 / Area / 0.78 * ACF.ArmorMod -- So we get the equivalent thickness of that prop in mm if all it's weight was a steel plate
	local Health  = Area / ACF.Threshold
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Area      = Area
	self.ACF.Health    = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armour
	self.ACF.Type      = "Prop"
end

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes    = Damage.doPropDamage(self, DmgResult, DmgInfo) -- Calling the standard prop damage function
	local NoExplode = self.FuelType == "Diesel" and not (Type == "HE" or Type == "HEAT")

	if self.Exploding or NoExplode or not self.IsExplosive then return HitRes end

	if HitRes.Kill then
		if HookRun("ACF_FuelExplode", self) == false then return HitRes end

		local Inflictor = DmgInfo:GetInflictor()

		if IsValid(Inflictor) and Inflictor:IsPlayer() then
			self.Inflictor = Inflictor
		end

		self:Detonate()

		return HitRes
	end

	local Ratio = (HitRes.Damage / self.ACF.Health) ^ 0.75 -- Chance to explode from sheer damage, small shots = small chance
	local ExplodeChance = (1 - (self.Fuel / self.Capacity)) ^ 0.75 -- Chance to explode from fumes in tank, less fuel = more explodey

	-- It's gonna blow
	if math.random() < (ExplodeChance + Ratio) then
		if HookRun("ACF_FuelExplode", self) == false then return HitRes end

		self.Inflictor = Inflictor

		self:Detonate()
	else -- Spray some fuel around
		self.Leaking = self.Leaking + self.Fuel * ((HitRes.Damage / self.ACF.Health) ^ 1.5) * 0.25

		WireLib.TriggerOutput(self, "Leaking", self.Leaking > 0 and 1 or 0)

		self:NextThink(Clock.CurTime + 0.1)
	end

	return HitRes
end

function ENT:Detonate()
	if self.Exploding then return end

	self.Exploding = true -- Prevent multiple explosions

	local Position  = self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
	local Explosive = (math.max(self.Fuel, self.Capacity * 0.0025) / self.FuelDensity) * 0.1
	local DmgInfo   = Objects.DamageInfo(self, self.Inflictor)

	ACF.KillChildProps(self, Position, Explosive)

	Damage.createExplosion(Position, Explosive, Explosive * 0.5, { self }, DmgInfo)
	Damage.explosionEffect(Position, nil, Explosive)

	constraint.RemoveAll(self)
	self:Remove()
end

function ENT:Enable()
	WireLib.TriggerOutput(self, "Activated", self:CanConsume() and 1 or 0)
end

function ENT:Disable()
	WireLib.TriggerOutput(self, "Activated", 0)
end

do -- Mass Update
	local function UpdateMass(Entity, SelfTbl)
		SelfTbl = SelfTbl or Entity:GetTable()
		local Fuel    = SelfTbl.FuelType == "Electric" and SelfTbl.Liters or SelfTbl.Fuel
		local Mass    = math.floor(SelfTbl.EmptyMass + Fuel * SelfTbl.FuelDensity)

		Contraption.SetMass(Entity, Mass)
	end

	function ENT:UpdateMass(Instant, SelfTbl)
		SelfTbl = SelfTbl or self:GetTable()
		if Instant then
			return UpdateMass(self, SelfTbl)
		end

		if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

		TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 1, 1, function()
			if not IsValid(self) then return end

			UpdateMass(self, SelfTbl)
		end)
	end
end

do -- Overlay Update
	local Classes = ACF.Classes
	local FuelTypes = Classes.FuelTypes

	local Text = "%s\n\n%sFuel Type: %s\n%s"

	function ENT:UpdateOverlayText()
		local Size = ""
		local Status, Content

		if self.Leaking > 0 then
			Status = "Leaking"
		else
			Status = self:CanConsume() and "Providing Fuel" or "Idle"
		end

		local Class = self.ClassData

		if Class and Class.CalcOverlaySize then
			Size = Class.CalcOverlaySize(self)
		end

		local FuelTypeID = self.FuelType
		local FuelType = FuelTypes.Get(FuelTypeID)
		local Fuel = self.Fuel

		if FuelType and FuelType.FuelTankOverlayText then
			Content = FuelType.FuelTankOverlayText(Fuel)
		else
			local Liters = Round(Fuel, 2)
			local Gallons = Round(Fuel * 0.264172, 2)

			Content = "Fuel Remaining: " .. Liters .. " liters / " .. Gallons .. " gallons"
		end

		return Text:format(Status, Size, FuelTypeID, Content)
	end
end

ACF.AddInputAction("acf_fueltank", "Active", function(Entity, Value)
	Entity.Active = tobool(Value)

	WireLib.TriggerOutput(Entity, "Activated", Entity:CanConsume() and 1 or 0)
end)

ACF.AddInputAction("acf_fueltank", "Refuel Duty", function(Entity, Value)
	Entity.SupplyFuel = tobool(Value) or nil
end)

function ENT:CanConsume(SelfTbl)
	SelfTbl = SelfTbl or self:GetTable()
	if SelfTbl.Disabled then return false end
	if not SelfTbl.Active then return false end

	return SelfTbl.Fuel > 0
end

function ENT:Consume(Amount, SelfTbl)
	SelfTbl = SelfTbl or self:GetTable()
	local Fuel = Clamp(SelfTbl.Fuel - Amount, 0, SelfTbl.Capacity)
	SelfTbl.Fuel = Fuel

	self:UpdateOverlay()
	self:UpdateMass(_, SelfTbl)

	Fuel = Round(Fuel, 2)
	local Activated = self:CanConsume(SelfTbl) and 1 or 0

	if SelfTbl.LastFuel ~= Fuel then
		SelfTbl.LastFuel = Fuel
		WireLib.TriggerOutput(self, "Fuel", Fuel)
	end
	if SelfTbl.LastActivated ~= Activated then
		SelfTbl.LastActivated = Activated
		WireLib.TriggerOutput(self, "Activated", Activated)
	end
end

function ENT:Think()
	self:NextThink(Clock.CurTime + 1)

	local Leaking = self.Leaking

	if Leaking > 0 then
		self:Consume(Leaking)

		local Fuel = self.Fuel
		Leaking = Clamp(Leaking - (1 / math.max(Fuel, 1)) ^ 0.5, 0, Fuel) -- Fuel tanks are self healing
		self.Leaking = Leaking

		WireLib.TriggerOutput(self, "Leaking", Leaking > 0 and 1 or 0)

		self:NextThink(Clock.CurTime + 0.25)
	end

	-- Refuelling
	if self.SupplyFuel and self:CanConsume() then
		local DeltaTime = Clock.CurTime - self.LastThink
		local Position  = self:GetPos()

		for Tank in pairs(ACF.FuelTanks) do
			if CanRefuel(self, Tank, Position:DistToSqr(Tank:GetPos())) then
				local Exchange = math.min(DeltaTime * ACF.RefuelSpeed * ACF.FuelRate, self.Fuel, Tank.Capacity - Tank.Fuel)

				if HookRun("ACF_CanRefuel", self, Tank, Exchange) == false then continue end

				self:Consume(Exchange)
				Tank:Consume(-Exchange)

				if self.FuelType == "Electric" then
					Sounds.SendSound(self, "ambient/energy/newspark04.wav", 70, 100, 0.5)
					Sounds.SendSound(Tank, "ambient/energy/newspark04.wav", 70, 100, 0.5)
				else
					Sounds.SendSound(self, "vehicles/jetski/jetski_no_gas_start.wav", 70, 120, 0.5)
					Sounds.SendSound(Tank, "vehicles/jetski/jetski_no_gas_start.wav", 70, 120, 0.5)
				end
			end
		end
	end

	self.LastThink = Clock.CurTime

	return true
end

function ENT:OnRemove()
	local Class = self.ClassData

	if Class.OnLast then
		Class.OnLast(self, Class)
	end

	HookRun("ACF_OnEntityLast", "acf_fueltank", self, Class)

	for Engine in pairs(self.Engines) do
		self:Unlink(Engine)
	end

	ActiveTanks[self] = nil

	WireLib.Remove(self)
end

function ENT:OnResized(Size)
	do -- Calculate new empty mass
		local Wall = ACF.FuelArmor * ACF.MmToInch -- Wall thickness in inches
		local Class = self.ClassData
		local _, Area = Class.CalcVolume(Size, Wall)

		local Mass = (Area * Wall) * 16.387 * 0.0079 -- Total wall volume * cu in to cc * density of steel (kg/cc)

		self.EmptyMass = Mass
	end

	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = Size,
		}
	}
end