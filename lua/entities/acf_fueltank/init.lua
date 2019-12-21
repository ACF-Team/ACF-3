AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local CheckLegal  = ACF_CheckLegal
local ClassLink	  = ACF.GetClassLink
local ClassUnlink = ACF.GetClassUnlink

local Inputs = {
	Active = function(Entity, Value)
		Entity.Active = tobool(Value)
	end,
	["Refuel Duty"] = function(Entity, Value)
		Entity.SupplyFuel = tobool(Value)
	end
}

function MakeACF_FuelTank(Owner, Pos, Angle, Id, Data1, Data2)
	if not Owner:CheckLimit("_acf_misc") then return end

	local FuelData = list.Get("ACFEnts").FuelTanks[Data1]

	if not FuelData then return end

	local Tank = ents.Create("acf_fueltank")

	if not IsValid(Tank) then return end

	Tank:SetModel(FuelData.model)
	Tank:SetPlayer(Owner)
	Tank:SetAngles(Angle)
	Tank:SetPos(Pos)
	Tank:Spawn()

	Tank:PhysicsInit(SOLID_VPHYSICS)
	Tank:SetMoveType(MOVETYPE_VPHYSICS)

	Owner:AddCount("_acf_misc", Tank)
	Owner:AddCleanup("acfmenu", Tank)

	Tank:UpdateFuelTank(Data1, Data2)

	Tank.Id = Id
	Tank.Owner = Owner
	Tank.SizeId = Data1
	Tank.Model = FuelData.model
	Tank.SpecialHealth = true
	Tank.SpecialDamage = true
	Tank.Engines = {}
	Tank.Active = true
	Tank.Leaking = 0
	Tank.CanUpdate = true
	Tank.LastThink = 0

	Tank.Inputs = WireLib.CreateInputs(Tank, { "Active", "Refuel Duty" })
	Tank.Outputs = WireLib.CreateOutputs(Tank, { "Fuel", "Capacity", "Leaking", "Entity [ENTITY]" })

	WireLib.TriggerOutput(Tank, "Entity", Tank)

	ACF.FuelTanks[Tank] = true

	local PhysObj = Tank:GetPhysicsObject()
	local Fuel = Tank.FuelType == "Electric" and Tank.Liters or Tank.Fuel
	local Mass = math.floor(Tank.EmptyMass + Fuel * Tank.FuelDensity)

	if IsValid(PhysObj) then
		PhysObj:SetMass(Mass)

		Tank.Mass = Mass
	end

	ACF_Activate(Tank)

	Tank.ACF.LegalMass = Tank.Mass
	Tank.ACF.Model	   = Tank.Model

	CheckLegal(Tank)

	return Tank
end

list.Set("ACFCvars", "acf_fueltank", {"id", "data1", "data2"})
duplicator.RegisterEntityClass("acf_fueltank", MakeACF_FuelTank, "Pos", "Angle", "Id", "SizeId", "FuelType")
ACF.RegisterLinkSource("acf_fueltank", "Engines")

function ENT:UpdateFuelTank(Data1, Data2)
	local FuelData = list.Get("ACFEnts").FuelTanks[Data1]
	local Percentage = 1 --how full is the tank?

	--if updating existing tank, keep fuel level
	if self.Capacity and self.Capacity ~= 0 then
		Percentage = self.Fuel / self.Capacity
	end

	local PhysObj = self:GetPhysicsObject()
	local Area = PhysObj:GetSurfaceArea()
	local Wall = 0.03937 --wall thickness in inches (1mm)

	self.FuelType = Data2
	self.FuelDensity = ACF.FuelDensity[Data2]
	self.Volume = PhysObj:GetVolume() - (Area * Wall) -- total volume of tank (cu in), reduced by wall thickness
	self.Capacity = self.Volume * ACF.CuIToLiter * ACF.TankVolumeMul * 0.4774 --internal volume available for fuel in liters, with magic realism number
	self.EmptyMass = (Area * Wall) * 16.387 * (7.9 / 1000) -- total wall volume * cu in to cc * density of steel (kg/cc)
	self.IsExplosive = self.FuelType ~= "Electric" and FuelData.explosive
	self.NoLinks = FuelData.nolinks == true

	if self.FuelType == "Electric" then
		self.Liters = self.Capacity --batteries capacity is different from internal volume
		self.Capacity = self.Capacity * ACF.LiIonED
	end

	self.Fuel = Percentage * self.Capacity

	self:UpdateMass()
	self:UpdateOverlay()

	WireLib.TriggerOutput(self, "Capacity", math.Round(self.Capacity, 2))
end

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
	self.ACF.Mass = self.Mass
	self.ACF.Density = (PhysObj:GetMass() * 1000) / self.ACF.Volume
	self.ACF.Type = "Prop"
end

function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor, _, Type)
	local Mul = Type == "HEAT" and ACF.HEATMulFuel or 1 --Heat penetrators deal bonus damage to fuel
	local HitRes = ACF_PropDamage(Entity, Energy, FrArea * Mul, Angle, Inflictor) --Calling the standard damage prop function
	local NoExplode = self.FuelType == "Diesel" and not (Type == "HE" or Type == "HEAT")

	if self.Exploding or NoExplode or not self.IsExplosive then return HitRes end

	if HitRes.Kill then
		if hook.Run("ACF_FuelExplode", self) == false then return HitRes end

		self.Exploding = true

		if IsValid(Inflictor) and Inflictor:IsPlayer() then
			self.Inflictor = Inflictor
		end

		ACF_ScaledExplosion(self)

		return HitRes
	end

	local Ratio = (HitRes.Damage / self.ACF.Health) ^ 0.75 --chance to explode from sheer damage, small shots = small chance
	local ExplodeChance = (1 - (self.Fuel / self.Capacity)) ^ 0.75 --chance to explode from fumes in tank, less fuel = more explodey

	--it's gonna blow
	if math.Rand(0, 1) < (ExplodeChance + Ratio) then
		if hook.Run("ACF_FuelExplode", self) == false then return HitRes end

		self.Inflictor = Inflictor
		self.Exploding = true

		ACF_ScaledExplosion(self)
	else --spray some fuel around
		self.Leaking = self.Leaking + self.Fuel * ((HitRes.Damage / self.ACF.Health) ^ 1.5) * 0.25

		self:NextThink(CurTime() + 0.1)
	end

	return HitRes
end

function ENT:Update(ArgsTable)
	if ArgsTable[1] ~= self.Owner then return false, "You don't own that fuel tank!" end

	local Feedback = ""

	if self.FuelType ~= ArgsTable[6] then
		for Engine in pairs(self.Engines) do
			self:Unlink(Engine)
		end

		Feedback = " New fuel type loaded, fuel tank unlinked."
	end

	self:UpdateFuelTank(ArgsTable[5], ArgsTable[6])

	return true, "Fuel tank successfully updated." .. Feedback
end

function ENT:Enable()
	self.Disabled 		= nil
	self.DisableReason 	= nil

	CheckLegal(self)
end

function ENT:Disable()
	self.Disabled = true

	self:UpdateOverlay()

	timer.Simple(ACF.IllegalDisableTime, function()
		if IsValid(self) then
			self:Enable()
		end
	end)
end

function ENT:Link(Target)
	if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
	if self == Target then return false, "Can't link a fuel tank to itself." end

	local Function = ClassLink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Fuel tanks can't be linked to '" .. Target:GetClass() .. "'."
end

function ENT:Unlink(Target)
	if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
	if self == Target then return false, "Can't unlink a fuel tank from itself." end

	local Function = ClassUnlink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Fuel tanks can't be unlinked from '" .. Target:GetClass() .. "'."
end

function ENT:UpdateMass()
	if timer.Exists("ACF Mass Buffer" .. self:EntIndex()) then return end

	timer.Create("ACF Mass Buffer" .. self:EntIndex(), 1, 1, function()
		if not IsValid(self) then return end

		local Fuel = self.FuelType == "Electric" and self.Liters or self.Fuel
		local PhysObj = self.ACF.PhysObj

		self.Mass = math.floor(self.EmptyMass + Fuel * self.FuelDensity)
		self.ACF.LegalMass = self.Mass

		if IsValid(PhysObj) then
			PhysObj:SetMass(self.Mass)
		end
	end)
end

function ENT:UpdateOverlay()
	if timer.Exists("ACF Overlay Buffer" .. self:EntIndex()) then return end

	timer.Create("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
		if not IsValid(self) then return end

		local Text

		if self.DisableReason then
			Text = "Disabled: " .. self.DisableReason
		elseif self.Leaking > 0 then
			Text = "Leaking"
		else
			Text = self.Active and "Providing Fuel" or "Idle"
		end

		Text = Text .. "\n\nFuel Type: " .. self.FuelType

		if self.FuelType == "Electric" then
			local KiloWatt = math.Round(self.Fuel, 1)
			local Joules = math.Round(self.Fuel * 3.6, 1)

			Text = Text .. "\nCharge Level: " .. KiloWatt .. " kWh / " .. Joules .. " MJ"
		else
			local Liters = math.Round(self.Fuel, 1)
			local Gallons = math.Round(self.Fuel * 0.264172, 1)

			Text = Text .. "\nFuel Remaining: " .. Liters .. " liters / " .. Gallons .. " gallons"
		end

		self:SetOverlayText(Text)
	end)
end

function ENT:TriggerInput(Input, Value)
	if self.Disabled then return end

	if Inputs[Input] then
		Inputs[Input](self, Value)
	end
end

function ENT:Think()
	local OldFuel = self.Fuel

	self:NextThink(CurTime() + 2)

	if self.Leaking > 0 then
		self.Fuel = math.max(self.Fuel - self.Leaking, 0)
		self.Leaking = math.Clamp(self.Leaking - (1 / math.max(self.Fuel, 1)) ^ 0.5, 0, self.Fuel) --fuel tanks are self healing

		self:NextThink(CurTime() + 0.25)

		WireLib.TriggerOutput(self, "Leaking", self.Leaking > 0 and 1 or 0)
	end

	--refuelling
	if self.Active and self.SupplyFuel and self.Fuel > 0 then
		local MaxDist = ACF.RefillDistance * ACF.RefillDistance
		local SelfPos = self:GetPos()

		for Tank in pairs(ACF.FuelTanks) do
			if self.FuelType == Tank.FuelType and not Tank.SupplyFuel then
				local Distance = SelfPos:DistToSqr(Tank:GetPos())

				if Distance <= MaxDist and Tank.Capacity - Tank.Fuel > 0.1 then
					local RefillRate = self.FuelType == "Electric" and ACF.ElecRate or ACF.FuelRate
					local DeltaTime = CurTime() - self.LastThink
					local CurrentFuel = Tank.Capacity - Tank.Fuel
					local Exchange = math.min(DeltaTime * ACF.RefillSpeed * RefillRate / 1750, self.Fuel, CurrentFuel)

					self.Fuel = self.Fuel - Exchange
					Tank.Fuel = Tank.Fuel + Exchange

					Tank:UpdateMass()
					Tank:UpdateOverlay()

					if Tank.FuelType == "Electric" then
						Tank:EmitSound("ambient/energy/newspark04.wav", 75, 100, 0.5)
					else
						Tank:EmitSound("vehicles/jetski/jetski_no_gas_start.wav", 75, 120, 0.5)
					end
				end
			end
		end
	end

	self.LastThink = CurTime()

	if self.Fuel ~= OldFuel then
		self:UpdateMass()
		self:UpdateOverlay()

		WireLib.TriggerOutput(self, "Fuel", self.Fuel)
	end

	return true
end

function ENT:OnRemove()
	for Engine in pairs(self.Engines) do
		self:Unlink(Engine)
	end

	ACF.FuelTanks[self] = nil

	WireLib.Remove(self)
end
