AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local CheckLegal  = ACF_CheckLegal
local FuelTanks	  = ACF.Classes.FuelTanks
local FuelTypes	  = ACF.Classes.FuelTypes
local ActiveTanks = ACF.FuelTanks
local RefillDist  = ACF.RefillDistance * ACF.RefillDistance
local TimerCreate = timer.Create
local TimerExists = timer.Exists
local HookRun     = hook.Run
local Wall		  = 0.03937 --wall thickness in inches (1mm)

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
	local function VerifyData(Data)
		if not Data.FuelTank then
			Data.FuelTank = Data.SizeId or Data.Id or "Jerry_Can"
		end

		local Class = ACF.GetClassGroup(FuelTanks, Data.FuelTank)

		if not Class then
			Data.FuelTank = "Jerry_Can"

			Class = ACF.GetClassGroup(FuelTanks, "Jerry_Can")
		end

		-- Making sure to provide a valid fuel type
		if not (Data.FuelType and FuelTypes[Data.FuelType]) then
			Data.FuelType = "Petrol"
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			HookRun("ACF_VerifyData", "acf_fueltank", Data, Class)
		end
	end

	local function UpdateFuelTank(Entity, Data, Class, FuelTank)
		local FuelData = FuelTypes[Data.FuelType]
		local Percentage = 1

		Entity:SetModel(FuelTank.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		local PhysObj = Entity:GetPhysicsObject()
		local Area = PhysObj:GetSurfaceArea()

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		-- If updating, keep the same fuel level
		if Entity.Capacity then
			Percentage = Entity.Fuel / Entity.Capacity
		end

		Entity.Name        = FuelTank.Name
		Entity.ShortName   = Entity.FuelTank
		Entity.EntType     = Class.Name
		Entity.ClassData   = Class
		Entity.FuelDensity = FuelData.Density
		Entity.Volume      = PhysObj:GetVolume() - (Area * Wall) -- total volume of tank (cu in), reduced by wall thickness
		Entity.Capacity    = Entity.Volume * ACF.CuIToLiter * ACF.TankVolumeMul * 0.4774 --internal volume available for fuel in liters, with magic realism number
		Entity.EmptyMass   = (Area * Wall) * 16.387 * (7.9 / 1000) -- total wall volume * cu in to cc * density of steel (kg/cc)
		Entity.IsExplosive = FuelTank.IsExplosive
		Entity.NoLinks     = FuelTank.Unlinkable
		Entity.HitBoxes = {
			Main = {
				Pos = Entity:OBBCenter(),
				Scale = (Entity:OBBMaxs() - Entity:OBBMins()) - Vector(0.5, 0.5, 0.5),
			}
		}

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		if Entity.FuelType == "Electric" then
			Entity.Liters = Entity.Capacity --batteries capacity is different from internal volume
			Entity.Capacity = Entity.Capacity * ACF.LiIonED
		end

		Entity.Fuel = Percentage * Entity.Capacity

		ACF.Activate(Entity, true)

		Entity.ACF.Model = FuelTank.Model

		Entity:UpdateMass(true)

		WireLib.TriggerOutput(Entity, "Fuel", Entity.Fuel)
		WireLib.TriggerOutput(Entity, "Capacity", Entity.Capacity)
	end

	function MakeACF_FuelTank(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = ACF.GetClassGroup(FuelTanks, Data.FuelTank)
		local FuelTank = Class.Lookup[Data.FuelTank]
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return end

		local Tank = ents.Create("acf_fueltank")

		if not IsValid(Tank) then return end

		Tank:SetPlayer(Player)
		Tank:SetAngles(Angle)
		Tank:SetPos(Pos)
		Tank:Spawn()

		Player:AddCleanup("acf_fueltank", Tank)
		Player:AddCount(Limit, Tank)

		Tank.Owner		= Player -- MUST be stored on ent for PP
		Tank.Engines	= {}
		Tank.Leaking	= 0
		Tank.LastThink	= 0
		Tank.Inputs		= WireLib.CreateInputs(Tank, { "Active", "Refuel Duty" })
		Tank.Outputs	= WireLib.CreateOutputs(Tank, { "Activated", "Fuel", "Capacity", "Leaking", "Entity [ENTITY]" })
		Tank.DataStore	= ACF.GetEntityArguments("acf_fueltank")

		WireLib.TriggerOutput(Tank, "Entity", Tank)

		UpdateFuelTank(Tank, Data, Class, FuelTank)

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

		CheckLegal(Tank)

		return Tank
	end

	ACF.RegisterEntityClass("acf_fueltank", MakeACF_FuelTank, "FuelTank", "FuelType")
	ACF.RegisterLinkSource("acf_fueltank", "Engines")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Class = ACF.GetClassGroup(FuelTanks, Data.FuelTank)
		local FuelTank = Class.Lookup[Data.FuelTank]
		local OldClass = self.ClassData
		local Feedback = ""

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_fueltank", self, OldClass)

		ACF.SaveEntity(self)

		UpdateFuelTank(self, Data, Class, FuelTank)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, FuelTank)
		end

		HookRun("ACF_OnEntityUpdate", "acf_fueltank", self, Data, Class, FuelTank)

		if next(self.Engines) then
			local FuelType = self.FuelType
			local NoLinks = self.NoLinks
			local Count, Total = 0, 0

			for Engine in pairs(self.Engines) do
				if NoLinks or not Engine.FuelTypes[FuelType] then
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
	local PhysObj = self.ACF.PhysObj

	if not self.ACF.Area then
		self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
	end

	if not self.ACF.Volume then
		self.ACF.Volume = PhysObj:GetVolume() * 1
	end

	local Armour = self.EmptyMass * 1000 / self.ACF.Area / 0.78 --So we get the equivalent thickness of that prop in mm if all it's weight was a steel plate
	local Health = self.ACF.Volume / ACF.Threshold --Setting the threshold of the prop Area gone 
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Health = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour = Armour * (0.5 + Percent / 2)
	self.ACF.MaxArmour = Armour
	self.ACF.Type = "Prop"
end

function ENT:ACF_OnDamage(Energy, FrArea, Angle, Inflictor, _, Type)
	local Mul = Type == "HEAT" and ACF.HEATMulFuel or 1 --Heat penetrators deal bonus damage to fuel
	local HitRes = ACF.PropDamage(self, Energy, FrArea * Mul, Angle, Inflictor) --Calling the standard damage prop function
	local NoExplode = self.FuelType == "Diesel" and not (Type == "HE" or Type == "HEAT")

	if self.Exploding or NoExplode or not self.IsExplosive then return HitRes end

	if HitRes.Kill then
		if HookRun("ACF_FuelExplode", self) == false then return HitRes end

		if IsValid(Inflictor) and Inflictor:IsPlayer() then
			self.Inflictor = Inflictor
		end

		self:Detonate()

		return HitRes
	end

	local Ratio = (HitRes.Damage / self.ACF.Health) ^ 0.75 --chance to explode from sheer damage, small shots = small chance
	local ExplodeChance = (1 - (self.Fuel / self.Capacity)) ^ 0.75 --chance to explode from fumes in tank, less fuel = more explodey

	--it's gonna blow
	if math.random() < (ExplodeChance + Ratio) then
		if HookRun("ACF_FuelExplode", self) == false then return HitRes end

		self.Inflictor = Inflictor

		self:Detonate()
	else --spray some fuel around
		self.Leaking = self.Leaking + self.Fuel * ((HitRes.Damage / self.ACF.Health) ^ 1.5) * 0.25

		WireLib.TriggerOutput(self, "Leaking", self.Leaking > 0 and 1 or 0)

		self:NextThink(ACF.CurTime + 0.1)
	end

	return HitRes
end

function ENT:Detonate()
	if self.Exploding then return end

	self.Exploding = true -- Prevent multiple explosions

	local Pos		 	= self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
	local ExplosiveMass = (math.max(self.Fuel, self.Capacity * 0.0025) / self.FuelDensity) * 0.1

	ACF_KillChildProps(self, Pos, ExplosiveMass)
	ACF_HE(Pos, ExplosiveMass, ExplosiveMass * 0.5, self.Inflictor, {self}, self)

	local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetNormal(Vector(0, 0, -1))
		Effect:SetScale(math.max(ExplosiveMass ^ 0.33 * 8 * 39.37, 1))
		Effect:SetRadius(0)

	util.Effect("ACF_Explosion", Effect)

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
	local function UpdateMass(Entity)
		local Fuel = Entity.FuelType == "Electric" and Entity.Liters or Entity.Fuel
		local Mass = math.floor(Entity.EmptyMass + Fuel * Entity.FuelDensity)
		local PhysObj = Entity.ACF.PhysObj

		Entity.ACF.LegalMass = Mass
		Entity.ACF.Density = Mass * 1000 / Entity.ACF.Volume

		if IsValid(PhysObj) then
			PhysObj:SetMass(Mass)
		end
	end

	function ENT:UpdateMass(Instant)
		if Instant then
			return UpdateMass(self)
		end

		if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

		TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 1, 1, function()
			if not IsValid(self) then return end

			UpdateMass(self)
		end)
	end
end

do -- Overlay Update
	local Text = "%s\n\nFuel Type: %s\n%s"

	function ENT:UpdateOverlayText()
		local Status, Content

		if self.Leaking > 0 then
			Status = "Leaking"
		else
			Status = self:CanConsume() and "Providing Fuel" or "Idle"
		end

		if self.FuelType == "Electric" then -- TODO: Replace hardcoded stuff
			local KiloWatt = math.Round(self.Fuel, 1)
			local Joules = math.Round(self.Fuel * 3.6, 1)

			Content = "Charge Level: " .. KiloWatt .. " kWh / " .. Joules .. " MJ"
		else
			local Liters = math.Round(self.Fuel, 1)
			local Gallons = math.Round(self.Fuel * 0.264172, 1)

			Content = "Fuel Remaining: " .. Liters .. " liters / " .. Gallons .. " gallons"
		end

		return Text:format(Status, self.FuelType, Content)
	end
end

ACF.AddInputAction("acf_fueltank", "Active", function(Entity, Value)
	Entity.Active = tobool(Value)

	WireLib.TriggerOutput(Entity, "Activated", Entity:CanConsume() and 1 or 0)
end)

ACF.AddInputAction("acf_fueltank", "Refuel Duty", function(Entity, Value)
	Entity.SupplyFuel = tobool(Value) or nil
end)

function ENT:CanConsume()
	if self.Disabled then return false end
	if not self.Active then return false end

	return self.Fuel > 0
end

function ENT:Consume(Amount)
	self.Fuel = math.Clamp(self.Fuel - Amount, 0, self.Capacity)

	self:UpdateOverlay()
	self:UpdateMass()

	WireLib.TriggerOutput(self, "Fuel", self.Fuel)
	WireLib.TriggerOutput(self, "Activated", self:CanConsume() and 1 or 0)
end

function ENT:Think()
	self:NextThink(ACF.CurTime + 1)

	if self.Leaking > 0 then
		self:Consume(self.Leaking)

		self.Leaking = math.Clamp(self.Leaking - (1 / math.max(self.Fuel, 1)) ^ 0.5, 0, self.Fuel) --fuel tanks are self healing

		WireLib.TriggerOutput(self, "Leaking", self.Leaking > 0 and 1 or 0)

		self:NextThink(ACF.CurTime + 0.25)
	end

	--refuelling
	if self.SupplyFuel and self:CanConsume() then
		local DeltaTime = ACF.CurTime - self.LastThink
		local Position = self:GetPos()

		for Tank in pairs(ACF.FuelTanks) do
			if CanRefuel(self, Tank, Position:DistToSqr(Tank:GetPos())) then
				local Exchange = math.min(DeltaTime * ACF.RefuelSpeed * ACF.FuelRate, self.Fuel, Tank.Capacity - Tank.Fuel)

				if HookRun("ACF_CanRefuel", self, Tank, Exchange) == false then continue end

				self:Consume(Exchange)
				Tank:Consume(-Exchange)

				if self.FuelType == "Electric" then
					self:EmitSound("ambient/energy/newspark04.wav", 70, 100, 0.5 * ACF.Volume)
					Tank:EmitSound("ambient/energy/newspark04.wav", 70, 100, 0.5 * ACF.Volume)
				else
					self:EmitSound("vehicles/jetski/jetski_no_gas_start.wav", 70, 120, 0.5 * ACF.Volume)
					Tank:EmitSound("vehicles/jetski/jetski_no_gas_start.wav", 70, 120, 0.5 * ACF.Volume)
				end
			end
		end
	end

	self.LastThink = ACF.CurTime

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
