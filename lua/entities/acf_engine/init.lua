AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ACF.RegisterClassLink("acf_engine", "acf_fueltank", function(Engine, Target)
	if Engine.FuelType ~= "Multifuel" and Engine.FuelType ~= Target.FuelType then return false, "Cannot link because fuel type is incompatible." end
	if Target.NoLinks then return false, "This fuel tank doesn't allow linking." end
	if Engine.FuelTanks[Target] then return false, "This engine is already linked to this fuel tank!" end

	Engine.FuelTanks[Target] = true
	Target.Engines[Engine] = true

	Engine:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Engine linked successfully!"
end)

ACF.RegisterClassUnlink("acf_engine", "acf_fueltank", function(Engine, Target)
	if not Engine.FuelTanks[Target] then
		return false, "This engine is not linked to this fuel tank."
	end

	Engine.FuelTanks[Target] = nil
	Target.Engines[Engine] = nil

	Engine:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Engine unlinked successfully!"
end)

ACF.RegisterClassLink("acf_engine", "acf_gearbox", function(Engine, Target)
	if Engine.Gearboxes[Target] then return false, "This engine is already linked to this gearbox." end

	-- make sure the angle is not excessive
	local InPos = Target:LocalToWorld(Target.In)
	local OutPos = Engine:LocalToWorld(Engine.Out)
	local Direction

	if Engine.IsTrans then
		Direction = -Engine:GetRight()
	else
		Direction = Engine:GetForward()
	end

	if (OutPos - InPos):GetNormalized():Dot(Direction) < 0.7 then
		return false, "Cannot link due to excessive driveshaft angle!"
	end

	local Rope

	if tobool(Engine.Owner:GetInfoNum("ACF_MobilityRopeLinks", 1)) then
		Rope = constraint.CreateKeyframeRope(OutPos, 1, "cable/cable2", nil, Engine, Engine.Out, 0, Target, Target.In, 0)
	end

	local Link = {
		Rope = Rope,
		RopeLen = (OutPos - InPos):Length(),
		ReqTq = 0
	}

	Engine.Gearboxes[Target]	= Link
	Target.Engines[Engine]	= true

	Engine:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Engine linked successfully!"
end)

ACF.RegisterClassUnlink("acf_engine", "acf_gearbox", function(Engine, Target)
	if not Engine.Gearboxes[Target] then
		return false, "This engine is not linked to this gearbox."
	end

	local Rope = Engine.Gearboxes[Target].Rope

	if IsValid(Rope) then Rope:Remove() end

	Engine.Gearboxes[Target]	= nil
	Target.Engines[Engine]	= nil

	Engine:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Engine unlinked successfully!"
end)

local CheckLegal  = ACF_CheckLegal
local ClassLink	  = ACF.GetClassLink
local ClassUnlink = ACF.GetClassUnlink
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"

local function GetNextFuelTank(Engine)
	if not next(Engine.FuelTanks) then return end

	local Current = Engine.FuelTank
	local NextKey = (IsValid(Current) and Engine.FuelTanks[Current]) and Current or nil
	local Select = next(Engine.FuelTanks, NextKey) or next(Engine.FuelTanks)
	local Start = Select

	repeat
		if Select.Active and Select.Fuel > 0 then
			return Select
		end

		Select = next(Engine.FuelTanks, Select) or next(Engine.FuelTanks)
	until Select == Start

	return (Select.Active and Select.Fuel > 0) and Select or nil
end

local function CheckDistantFuelTanks(Engine)
	local EnginePos = Engine:GetPos()

	for Tank in pairs(Engine.FuelTanks) do
		if EnginePos:DistToSqr(Tank:GetPos()) > 262144 then
			Engine:EmitSound(UnlinkSound:format(math.random(1, 3)), 500, 100)

			Engine:Unlink(Tank)
		end
	end
end

local function CheckGearboxes(Engine)
	for Ent, Link in pairs(Engine.Gearboxes) do
		local OutPos = Engine:LocalToWorld(Engine.Out)
		local InPos = Ent:LocalToWorld(Ent.In)

		-- make sure it is not stretched too far
		if OutPos:Distance(InPos) > Link.RopeLen * 1.5 then
			Engine:Unlink(Ent)
			continue
		end

		-- make sure the angle is not excessive
		local Direction

		if Engine.IsTrans then
			Direction = -Engine:GetRight()
		else
			Direction = Engine:GetForward()
		end

		if (OutPos - InPos):GetNormalized():Dot(Direction) < 0.7 then
			Engine:Unlink(Ent)
		end
	end
end

local function SetActive(Entity, Value)
	if Entity.Active == tobool(Value) then return end

	if not Entity.Active then
		local HasFuel

		if not Entity.RequiresFuel then
			HasFuel = true
		else
			for Tank in pairs(Entity.FuelTanks) do
				if Tank.Active and Tank.Fuel > 0 then
					HasFuel = true
					break
				end
			end
		end

		if HasFuel then
			Entity.Active = true

			if Entity.SoundPath ~= "" then
				Entity.Sound = CreateSound(Entity, Entity.SoundPath)
				Entity.Sound:PlayEx(0.5, 100)
			end

			Entity:CalcMassRatio()

			Entity.LastThink = CurTime()
			Entity.Torque = Entity.PeakTorque
			Entity.FlyRPM = Entity.IdleRPM * 1.5
		end
	else
		Entity.Active = false
		Entity.FlyRPM = 0
		Entity.RPM = { Entity.IdleRPM }

		if Entity.Sound then
			Entity.Sound:Stop()

			Entity.Sound = nil
		end

		WireLib.TriggerOutput(Entity, "RPM", 0)
		WireLib.TriggerOutput(Entity, "Torque", 0)
		WireLib.TriggerOutput(Entity, "Power", 0)
		WireLib.TriggerOutput(Entity, "Fuel Use", 0)
	end
end

local Inputs = {
	Throttle = function(Entity, Value)
		Entity.Throttle = math.Clamp(Value, 0, 100) / 100
	end,
	Active = function(Entity, Value)
		SetActive(Entity, tobool(Value))
	end
}

function MakeACF_Engine(Owner, Pos, Angle, Id)
	if not Owner:CheckLimit("_acf_misc") then return end

	local EngineData = list.Get("ACFEnts").Mobility[Id]

	if not EngineData then return end

	local Engine = ents.Create("acf_engine")

	if not IsValid(Engine) then return end

	Engine:SetModel(EngineData.model)
	Engine:SetPlayer(Owner)
	Engine:SetAngles(Angle)
	Engine:SetPos(Pos)
	Engine:Spawn()

	Engine:PhysicsInit(SOLID_VPHYSICS)
	Engine:SetMoveType(MOVETYPE_VPHYSICS)

	Owner:AddCount("_acf_misc", Engine)
	Owner:AddCleanup("acfmenu", Engine)

	Engine.Id = Id
	Engine.Owner = Owner
	Engine.Model = EngineData.model
	Engine.SoundPath = EngineData.sound
	Engine.SoundPitch = EngineData.pitch or 1
	Engine.Mass = EngineData.weight
	Engine.SpecialHealth = true
	Engine.SpecialDamage = true
	Engine.CanUpdate = true
	Engine.Active = false
	Engine.Gearboxes = {} -- a "Link" has these components: Rope, RopeLen, ReqTq
	Engine.FuelTanks = {}
	Engine.LastThink = 0
	Engine.MassRatio = 1

	Engine.PeakTorque = EngineData.torque
	Engine.PeakTorqueHeld = EngineData.torque
	Engine.IdleRPM = EngineData.idlerpm
	Engine.PeakMinRPM = EngineData.peakminrpm
	Engine.PeakMaxRPM = EngineData.peakmaxrpm
	Engine.LimitRPM = EngineData.limitrpm
	Engine.Inertia = EngineData.flywheelmass * 3.1416 ^ 2
	Engine.IsElectric = EngineData.iselec
	Engine.FlywheelOverride = EngineData.flywheeloverride
	Engine.IsTrans = EngineData.istrans -- driveshaft outputs to the side
	Engine.FuelType = EngineData.fuel or "Petrol"
	Engine.EngineType = EngineData.enginetype or "GenericPetrol"
	Engine.RequiresFuel = EngineData.requiresfuel
	Engine.TorqueMult = 1
	Engine.TorqueScale = ACF.TorqueScale[Engine.EngineType]
	Engine.FuelUsage = 0
	Engine.Throttle = 0
	Engine.FlyRPM = 0
	Engine.RPM = {}
	Engine.Out = Engine:WorldToLocal(Engine:GetAttachment(Engine:LookupAttachment("driveshaft")).Pos)

	Engine.Inputs = WireLib.CreateInputs(Engine, { "Active", "Throttle" })
	Engine.Outputs = WireLib.CreateOutputs(Engine, { "RPM", "Torque", "Power", "Fuel Use", "Entity [ENTITY]", "Mass", "Physical Mass" })

	--calculate boosted peak kw
	if Engine.EngineType == "Turbine" or Engine.EngineType == "Electric" then
		Engine.peakkw = (Engine.PeakTorque * (1 + Engine.PeakMaxRPM / Engine.LimitRPM)) * Engine.LimitRPM / (4 * 9548.8) --adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
		Engine.PeakKwRPM = math.floor(Engine.LimitRPM / 2)
	else
		Engine.peakkw = Engine.PeakTorque * Engine.PeakMaxRPM / 9548.8
		Engine.PeakKwRPM = Engine.PeakMaxRPM
	end

	--calculate base fuel usage
	if Engine.EngineType == "Electric" then
		Engine.FuelUse = ACF.ElecRate / (ACF.Efficiency[Engine.EngineType] * 60 * 60) --elecs use current power output, not max
	else
		Engine.FuelUse = ACF.TorqueBoost * ACF.FuelRate * ACF.Efficiency[Engine.EngineType] * Engine.peakkw / (60 * 60)
	end

	local PhysObj = Engine:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:SetMass(Engine.Mass)

		Engine.ModelInertia = 0.99 * PhysObj:GetInertia() / PhysObj:GetMass() -- giving a little wiggle room
	end

	Engine:SetNWString("WireName", EngineData.name)

	WireLib.TriggerOutput(Engine, "Entity", Engine)

	Engine:UpdateOverlay()

	ACF_Activate(Engine)

	Engine.ACF.LegalMass = Engine.Mass
	Engine.ACF.Model     = Engine.Model

	CheckLegal(Engine)

	timer.Create("ACF Engine Clock " .. Engine:EntIndex(), 3, 0, function()
		if IsValid(Engine) then
			CheckGearboxes(Engine)
			CheckDistantFuelTanks(Engine)

			Engine:CalcMassRatio()
		else
			timer.Stop("ACF Engine Clock " .. Engine:EntIndex())
		end
	end)

	return Engine
end

list.Set("ACFCvars", "acf_engine", { "id" })
duplicator.RegisterEntityClass("acf_engine", MakeACF_Engine, "Pos", "Angle", "Id")
ACF.RegisterLinkSource("acf_engine", "FuelTanks")
ACF.RegisterLinkSource("acf_engine", "Gearboxes")

function ENT:Enable()
	self.Disabled      = nil
	self.DisableReason = nil

	local Active

	if self.Inputs.Active.Path then
		Active = tobool(self.Inputs.Active.Value)
	else
		Active = true
	end

	SetActive(self, Active)

	self:UpdateOverlay()

	CheckLegal(self)
end

function ENT:Disable()
	self.Disabled = true

	SetActive(self, false) -- Turn off the engine

	self:UpdateOverlay()

	timer.Simple(ACF.IllegalDisableTime, function()
		if IsValid(self) then
			self:Enable()
		end
	end)
end

function ENT:Update(ArgsTable)
	-- That table is the player data, as sorted in the ACFCvars above, with player who shot, 
	-- and pos and angle of the tool trace inserted at the start
	if self.Active then return false, "Turn off the engine before updating it!" end
	if ArgsTable[1] ~= self.Owner then return false, "You don't own that engine!" end -- Argtable[1] is the player that shot the tool
	local Id = ArgsTable[4] -- Argtable[4] is the engine ID
	local Lookup = list.Get("ACFEnts").Mobility[Id]
	if Lookup.model ~= self.Model then return false, "The new engine must have the same model!" end
	local Feedback = ""

	if Lookup.fuel ~= self.FuelType then
		Feedback = " Fuel type changed, fuel tanks unlinked."

		for Tank in pairs(self.FuelTanks) do
			self:Unlink(Tank)
		end
	end

	self.Id = Id
	self.SoundPath = Lookup.sound
	self.Mass = Lookup.weight
	self.PeakTorque = Lookup.torque
	self.PeakTorqueHeld = Lookup.torque
	self.IdleRPM = Lookup.idlerpm
	self.PeakMinRPM = Lookup.peakminrpm
	self.PeakMaxRPM = Lookup.peakmaxrpm
	self.LimitRPM = Lookup.limitrpm
	self.Inertia = Lookup.flywheelmass * 3.1416 ^ 2
	self.IsElectric = Lookup.iselec -- is the engine electric?
	self.FlywheelOverride = Lookup.flywheeloverride -- modifies rpm drag on IsElectric==true
	self.IsTrans = Lookup.istrans
	self.FuelType = Lookup.fuel
	self.EngineType = Lookup.enginetype
	self.RequiresFuel = Lookup.requiresfuel
	self.SoundPitch = Lookup.pitch or 1
	self.SpecialHealth = true
	self.SpecialDamage = true
	self.TorqueMult = self.TorqueMult or 1
	self.FuelTank = nil
	self.TorqueScale = ACF.TorqueScale[self.EngineType]

	--calculate boosted peak kw
	if self.EngineType == "Turbine" or self.EngineType == "Electric" then
		self.peakkw = (self.PeakTorque * (1 + self.PeakMaxRPM / self.LimitRPM)) * self.LimitRPM / (4 * 9548.8) --adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
		self.PeakKwRPM = math.floor(self.LimitRPM / 2)
	else
		self.peakkw = self.PeakTorque * self.PeakMaxRPM / 9548.8
		self.PeakKwRPM = self.PeakMaxRPM
	end

	--calculate base fuel usage
	if self.EngineType == "Electric" then
		self.FuelUse = ACF.ElecRate / (ACF.Efficiency[self.EngineType] * 60 * 60) --elecs use current power output, not max
	else
		self.FuelUse = ACF.TorqueBoost * ACF.FuelRate * ACF.Efficiency[self.EngineType] * self.peakkw / (60 * 60)
	end

	self:SetModel(self.Model)
	self.Out = self:WorldToLocal(self:GetAttachment(self:LookupAttachment("driveshaft")).Pos)
	local PhysObj = self:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:SetMass(self.Mass)
	end

	self:SetNWString("WireName", Lookup.name)
	self:UpdateOverlay()

	ACF_Activate(self)

	self.ACF.LegalMass = self.Mass

	return true, "Engine updated successfully!" .. Feedback
end

function ENT:UpdateOutputs()
	if timer.Exists("ACF Output Buffer" .. self:EntIndex()) then return end

	timer.Create("ACF Output Buffer" .. self:EntIndex(), 0.1, 1, function()
		if not IsValid(self) then return end

		local SmoothRPM = 0

		-- Then we calc a smoothed RPM value for the sound effects
		table.remove(self.RPM, 10)
		table.insert(self.RPM, 1, self.FlyRPM)

		for _, RPM in pairs(self.RPM) do
			SmoothRPM = SmoothRPM + (RPM or 0)
		end

		SmoothRPM = SmoothRPM / 10

		local Power = self.Torque * SmoothRPM / 9548.8

		WireLib.TriggerOutput(self, "Fuel Use", self.FuelUsage)
		WireLib.TriggerOutput(self, "Torque", math.floor(self.Torque))
		WireLib.TriggerOutput(self, "Power", math.floor(Power))
		WireLib.TriggerOutput(self, "RPM", self.FlyRPM)

		if self.Sound then
			self.Sound:ChangePitch(math.min(20 + (SmoothRPM * self.SoundPitch) / 50, 255), 0)
			self.Sound:ChangeVolume(0.25 + (0.1 + 0.9 * ((SmoothRPM / self.LimitRPM) ^ 1.5)) * self.Throttle / 1.5, 0)
		end
	end)
end

function ENT:UpdateOverlay()
	if timer.Exists("ACF Overlay Buffer" .. self:EntIndex()) then return end

	timer.Create("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
		if not IsValid(self) then return end

		local Boost = self.RequiresFuel and ACF.TorqueBoost or 1
		local PowerbandMin = self.IsElectric and self.IdleRPM or self.PeakMinRPM
		local PowerbandMax = self.IsElectric and math.floor(self.LimitRPM / 2) or self.PeakMaxRPM

		local text = "Power: " .. math.Round(self.peakkw * Boost) .. " kW / " .. math.Round(self.peakkw * Boost * 1.34) .. " hp\n"
		text = text .. "Torque: " .. math.Round(self.PeakTorque * Boost) .. " Nm / " .. math.Round(self.PeakTorque * Boost * 0.73) .. " ft-lb\n"
		text = text .. "Powerband: " .. PowerbandMin .. " - " .. PowerbandMax .. " RPM\n"
		text = text .. "Redline: " .. self.LimitRPM .. " RPM"

		if self.DisableReason then
			text = text .. "\nDisabled: " .. self.DisableReason
		end

		self:SetOverlayText(text)
	end)
end

function ENT:TriggerInput(Input, Value)
	if self.Disabled then return end

	if Inputs[Input] then
		Inputs[Input](self, Value)
	end
end

function ENT:ACF_Activate()
	--Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local PhysObj = self.ACF.PhysObj
	local Count

	if PhysObj:GetMesh() then
		Count = #PhysObj:GetMesh()
	end

	if IsValid(PhysObj) and Count and Count > 100 then
		if not self.ACF.Area then
			self.ACF.Area = (PhysObj:GetSurfaceArea() * 6.45) * 0.52505066107
		end
	else
		local Size = self:OBBMaxs() - self:OBBMins()

		if not self.ACF.Area then
			self.ACF.Area = ((Size.x * Size.y) + (Size.x * Size.z) + (Size.y * Size.z)) * 6.45
		end
	end

	self.ACF.Ductility = self.ACF.Ductility or 0
	local Area = self.ACF.Area
	local Armour = PhysObj:GetMass() * 1000 / Area / 0.78
	local Health = Area / ACF.Threshold
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Health = Health * Percent * ACF.EngineHPMult[self.EngineType]
	self.ACF.MaxHealth = Health * ACF.EngineHPMult[self.EngineType]
	self.ACF.Armour = Armour * (0.5 + Percent / 2)
	self.ACF.MaxArmour = Armour * ACF.ArmorMod
	self.ACF.Type = nil
	self.ACF.Mass = PhysObj:GetMass()
	self.ACF.Type = "Prop"
end

--This function needs to return HitRes
function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor, _, Type)
	local Mul = Type == "HEAT" and ACF.HEATMulEngine or 1 --Heat penetrators deal bonus damage to engines

	return ACF_PropDamage(Entity, Energy, FrArea * Mul, Angle, Inflictor)
end

function ENT:Think()
	if self.Active then
		self:CalcRPM()
	end

	self.LastThink = CurTime()

	self:NextThink(CurTime())

	return true
end

-- specialized calcmassratio for engines
function ENT:CalcMassRatio()
	local PhysMass = 0
	local TotalMass = 0
	local Physical, Parented = ACF_GetEnts(self)

	for K in pairs(Physical) do
		local Phys = K:GetPhysicsObject() -- Should always exist, but just in case

		if IsValid(Phys) then
			local Mass = Phys:GetMass()

			TotalMass = TotalMass + Mass
			PhysMass = PhysMass + Mass
		end
	end

	for K in pairs(Parented) do
		if not Physical[K] then
			local Phys = K:GetPhysicsObject() -- Should always exist, but just in case

			if IsValid(Phys) then
				TotalMass = TotalMass + Phys:GetMass()
			end
		end
	end

	self.MassRatio = PhysMass / TotalMass

	WireLib.TriggerOutput(self, "Mass", math.Round(TotalMass, 2))
	WireLib.TriggerOutput(self, "Physical Mass", math.Round(PhysMass, 2))
end

function ENT:CalcRPM()
	local DeltaTime = CurTime() - self.LastThink
	local FuelTank = GetNextFuelTank(self)
	local Boost = 1

	--calculate fuel usage
	if IsValid(FuelTank) then
		local Consumption

		self.FuelTank = FuelTank

		if self.FuelType == "Electric" then
			Consumption = (self.Torque * self.FlyRPM / 9548.8) * self.FuelUse * DeltaTime
		else
			local Load = 0.3 + self.Throttle * 0.7
			Consumption = Load * self.FuelUse * (self.FlyRPM / self.PeakKwRPM) * DeltaTime / ACF.FuelDensity[FuelTank.FuelType]
		end

		Boost = ACF.TorqueBoost

		FuelTank.Fuel = math.max(FuelTank.Fuel - Consumption, 0)

		self.FuelUsage = math.Round(60 * Consumption / DeltaTime, 3)
	elseif self.RequiresFuel then
		SetActive(self, false) --shut off if no fuel and requires it

		return 0
	else
		self.FuelUsage = 0
	end

	--adjusting performance based on damage
	self.TorqueMult = math.Clamp(((1 - self.TorqueScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, self.TorqueScale, 1)
	self.PeakTorque = self.PeakTorqueHeld * self.TorqueMult
	-- Calculate the current torque from flywheel RPM
	self.Torque = Boost * self.Throttle * math.max(self.PeakTorque * math.min(self.FlyRPM / self.PeakMinRPM, (self.LimitRPM - self.FlyRPM) / (self.LimitRPM - self.PeakMaxRPM), 1), 0)
	local Drag

	if self.IsElectric == true then
		Drag = self.PeakTorque * (math.max(self.FlyRPM - self.IdleRPM, 0) / self.FlywheelOverride) * (1 - self.Throttle) / self.Inertia
	else
		Drag = self.PeakTorque * (math.max(self.FlyRPM - self.IdleRPM, 0) / self.PeakMaxRPM) * (1 - self.Throttle) / self.Inertia
	end

	-- Let's accelerate the flywheel based on that torque
	self.FlyRPM = math.max(self.FlyRPM + self.Torque / self.Inertia - Drag, 1)
	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	--local Boxes = table.Count(self.Gearboxes)
	local Boxes = 0
	local TotalReqTq = 0

	-- Get the requirements for torque for the gearboxes (Max clutch rating minus any wheels currently spinning faster than the Flywheel)
	for Ent, Link in pairs(self.Gearboxes) do
		if not Ent.Disabled then
			Boxes = Boxes + 1
			Link.ReqTq = Ent:Calc(self.FlyRPM, self.Inertia)
			TotalReqTq = TotalReqTq + Link.ReqTq
		end
	end

	-- This is the presently available torque from the engine
	local TorqueDiff = math.max(self.FlyRPM - self.IdleRPM, 0) * self.Inertia
	-- Calculate the ratio of total requested torque versus what's available
	local AvailRatio = math.min(TorqueDiff / TotalReqTq / Boxes, 1)

	-- Split the torque fairly between the gearboxes who need it
	for Ent, Link in pairs(self.Gearboxes) do
		if not Ent.Disabled then
			Ent:Act(Link.ReqTq * AvailRatio * self.MassRatio, DeltaTime, self.MassRatio)
		end
	end

	self.FlyRPM = self.FlyRPM - math.min(TorqueDiff, TotalReqTq) / self.Inertia

	self:UpdateOutputs()

	return RPM
end

function ENT:Link(Target)
	if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
	if self == Target then return false, "Can't link an engine to itself." end

	local Function = ClassLink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Engines can't be linked to '" .. Target:GetClass() .. "'."
end

function ENT:Unlink(Target)
	if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
	if self == Target then return false, "Can't unlink an engine from itself." end

	local Function = ClassUnlink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Engines can't be unlinked from '" .. Target:GetClass() .. "'."
end

function ENT:PreEntityCopy()
	if next(self.Gearboxes) then
		local Gearboxes = {}

		for Gearbox in pairs(self.Gearboxes) do
			Gearboxes[#Gearboxes + 1] = Gearbox:EntIndex()

			self:Unlink(Gearbox) -- Unlinking to remove the rope
		end

		duplicator.StoreEntityModifier(self, "ACFGearboxes", Gearboxes)
	end

	if next(self.FuelTanks) then
		local Tanks = {}

		for Tank in pairs(self.FuelTanks) do
			Tanks[#Tanks + 1] = Tank:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFFuelTanks", Tanks)
	end

	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	local EntMods =  Ent.EntityMods

	if EntMods.ACFGearboxes then
		local Gearboxes = EntMods.ACFGearboxes

		for _, EntID in ipairs(Gearboxes) do
			local Gearbox = CreatedEntities[EntID]

			self:Link(Gearbox)
		end

		Gearboxes = nil
	end

	if EntMods.ACFFuelTanks then
		local FuelTanks = EntMods.ACFFuelTanks

		for _, EntID in ipairs(FuelTanks) do
			local Tank = CreatedEntities[EntID]

			self:Link(Tank)
		end

		FuelTanks = nil
	end

	--Wire dupe info
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	if self.Sound then
		self.Sound:Stop()
	end

	for Gearbox in pairs(self.Gearboxes) do
		self:Unlink(Gearbox)
	end

	for Tank in pairs(self.FuelTanks) do
		self:Unlink(Tank)
	end

	WireLib.Remove(self)
end
