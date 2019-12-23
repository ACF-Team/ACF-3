AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local function CheckLoopedGearbox(This, Target)
	local Queued = { [Target] = true }
	local Checked = {}
	local Entity

	while next(Queued) do
		Entity = next(Queued)

		if Entity == This then
			return true
		end

		Checked[Entity] = true
		Queued[Entity]  = nil

		for Gearbox in pairs(Entity.GearboxOut) do
			if not Checked[Gearbox] then
				Queued[Gearbox] = true
			end
		end
	end

	return false
end

local function GenerateLinkTable(Entity, Target)
	local InPos = Target.In or Vector()
	local InPosWorld = Target:LocalToWorld(InPos)
	local OutPos, Side

	if Entity:WorldToLocal(InPosWorld).y < 0 then
		OutPos = Entity.OutL
		Side = 0
	else
		OutPos = Entity.OutR
		Side = 1
	end

	local OutPosWorld = Entity:LocalToWorld(OutPos)
	local DrvAngle = (OutPosWorld - InPosWorld):GetNormalized():Dot((Entity:GetRight() * OutPos.y):GetNormalized())

	if DrvAngle < 0.7 then return end

	local Rope

	if Entity.Owner:GetInfoNum("ACF_MobilityRopeLinks", 1) ~= 0 then
		Rope = constraint.CreateKeyframeRope(OutPosWorld, 1, "cable/cable2", nil, Entity, OutPos, 0, Target, InPos, 0)
	end

	local Phys = Target:GetPhysicsObject()
	local Axis = Phys:WorldToLocalVector(Entity:GetRight())
	local Inertia = (Axis * Phys:GetInertia()):Length()

	return {
		Side = Side,
		Axis = Axis,
		Inertia = Inertia,
		Rope = Rope,
		RopeLen = (OutPosWorld - InPosWorld):Length(),
		Output = OutPos,
		ReqTq = 0,
		Vel = 0
	}
end

local function LinkWheel(Gearbox, Wheel)
	if Gearbox.Wheels[Wheel] then return false, "This wheel is already linked to this gearbox!" end

	local Link = GenerateLinkTable(Gearbox, Wheel)

	if not Link then return false, "Cannot link due to excessive driveshaft angle!" end

	Gearbox.Wheels[Wheel] = Link

	Wheel:CallOnRemove("ACF_GearboxUnlink" .. Gearbox:EntIndex(), function()
		if IsValid(Gearbox) then
			Gearbox:Unlink(Wheel)
		end
	end)

	return true, "Wheel linked successfully!"
end

local function LinkGearbox(Gearbox, Target)
	if Gearbox.GearboxOut[Target] then return false, "These gearboxes are already linked to each other!" end
	if Target.GearboxIn[Gearbox] then return false, "These gearboxes are already linked to each other!" end
	if CheckLoopedGearbox(Gearbox, Target) then return false, "You cannot link gearboxes in a loop!" end

	local Link = GenerateLinkTable(Gearbox, Target)

	if not Link then return false, "Cannot link due to excessive driveshaft angle!" end

	Gearbox.GearboxOut[Target] = Link
	Target.GearboxIn[Gearbox]  = true

	return true, "Gearbox linked successfully!"
end

ACF.RegisterClassLink("acf_gearbox", "prop_physics", LinkWheel)
ACF.RegisterClassLink("acf_gearbox", "acf_gearbox", LinkGearbox)
ACF.RegisterClassLink("acf_gearbox", "tire", LinkWheel)

local function UnlinkWheel(Gearbox, Wheel)
	if Gearbox.Wheels[Wheel] then
		local Link = Gearbox.Wheels[Wheel]

		if IsValid(Link.Rope) then
			Link.Rope:Remove()
		end

		Link = nil

		Wheel:RemoveCallOnRemove("ACF_GearboxUnlink" .. Gearbox:EntIndex())

		return true, "Wheel unlinked successfully!"
	end

	return false, "This wheel is not linked to this gearbox!"
end

local function UnlinkGearbox(Gearbox, Target)
	if Gearbox.GearboxOut[Target] or Target.GearboxIn[Gearbox] then
		local Link = Gearbox.GearboxOut[Target]

		if IsValid(Link.Rope) then
			Link.Rope:Remove()
		end

		Gearbox.GearboxOut[Target] = nil
		Target.GearboxIn[Gearbox]  = nil

		return true, "Gearbox unlinked successfully!"
	end

	return false, "That gearboxes are not linked to each other!"
end

ACF.RegisterClassUnlink("acf_gearbox", "prop_physics", UnlinkWheel)
ACF.RegisterClassUnlink("acf_gearbox", "acf_gearbox", UnlinkGearbox)
ACF.RegisterClassUnlink("acf_gearbox", "tire", UnlinkWheel)

local CheckLegal  = ACF_CheckLegal
local ClassLink	  = ACF.GetClassLink
local ClassUnlink = ACF.GetClassUnlink
local Clamp		  = math.Clamp

local function CreateInputsOutputs(Gearbox)
	local Inputs = { "Gear", "Gear Up", "Gear Down" }

	if Gearbox.CVT then
		Inputs[#Inputs + 1] = "CVT Ratio"
	elseif Gearbox.DoubleDiff then
		Inputs[#Inputs + 1] = "Steer Rate"
	elseif Gearbox.Auto then
		Inputs[#Inputs + 1] = "Hold Gear"
		Inputs[#Inputs + 1] = "Shift Speed Scale"

		Gearbox.Hold = false
	end

	if Gearbox.Dual then
		Inputs[#Inputs + 1] = "Left Clutch"
		Inputs[#Inputs + 1] = "Right Clutch"
		Inputs[#Inputs + 1] = "Left Brake"
		Inputs[#Inputs + 1] = "Right Brake"
	else
		Inputs[#Inputs + 1] = "Clutch"
		Inputs[#Inputs + 1] = "Brake"
	end

	local Outputs = { "Ratio", "Entity [ENTITY]", "Current Gear" }

	if Gearbox.CVT then
		Outputs[#Outputs + 1] = "Min Target RPM"
		Outputs[#Outputs + 1] = "Max Target RPM"
	end

	Gearbox.Inputs = WireLib.CreateInputs(Gearbox, Inputs)
	Gearbox.Outputs = WireLib.CreateOutputs(Gearbox, Outputs)

	WireLib.TriggerOutput(Gearbox, "Entity", Gearbox)
end

local function ChangeGear(Entity, Value)
	Value = Clamp(math.floor(Value), 0, Entity.Gears)

	if Entity.Gear == Value then return end

	Entity.Gear = Value
	Entity.GearRatio = (Entity.GearTable[Entity.Gear] or 0) * Entity.GearTable.Final
	Entity.ChangeFinished = CurTime() + Entity.SwitchTime
	Entity.InGear = false

	Entity:EmitSound("buttons/lever7.wav", 250, 100)
	Entity:UpdateOverlay()

	WireLib.TriggerOutput(Entity, "Current Gear", Entity.Gear)
	WireLib.TriggerOutput(Entity, "Ratio", Entity.GearRatio)
end

--handles gearing for automatics; 0=neutral, 1=forward autogearing, 2=reverse
local function ChangeDrive(Entity, Value)
	Value = Clamp(math.floor(Value), 0, 2)

	if Entity.Drive == Value then return end

	Entity.Drive = Value

	ChangeGear(Entity, Entity.Drive == 2 and Entity.Reverse or Entity.Drive)
end

local function UpdateGearboxData(Entity, GearboxData, Id, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	if Entity.Id ~= Id then
		Entity.Id = Id
		Entity.Name = GearboxData.name
		Entity.Model = GearboxData.model
		Entity.Mass = GearboxData.weight
		Entity.SwitchTime = GearboxData.switch
		Entity.MaxTorque = GearboxData.maxtq
		Entity.Gears = GearboxData.gears
		Entity.Dual = GearboxData.doubleclutch
		Entity.CVT = GearboxData.cvt
		Entity.DoubleDiff = GearboxData.doublediff
		Entity.Auto = GearboxData.auto
		Entity.LClutch = Entity.MaxTorque
		Entity.RClutch = Entity.MaxTorque

		CreateInputsOutputs(Entity)

		local PhysObj = Entity:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:SetMass(Entity.Mass)
		end
	end

	Entity.GearTable = GearboxData.geartable
	Entity.GearTable.Final = Data10
	Entity.GearTable[1] = Data1
	Entity.GearTable[2] = Data2
	Entity.GearTable[3] = Data3
	Entity.GearTable[4] = Data4
	Entity.GearTable[5] = Data5
	Entity.GearTable[6] = Data6
	Entity.GearTable[7] = Data7
	Entity.GearTable[8] = Data8
	Entity.GearTable[9] = Data9
	Entity.GearTable[0] = GearboxData.geartable[0]
	Entity.Gear0 = Data10
	Entity.Gear1 = Data1
	Entity.Gear2 = Data2
	Entity.Gear3 = Data3
	Entity.Gear4 = Data4
	Entity.Gear5 = Data5
	Entity.Gear6 = Data6
	Entity.Gear7 = Data7
	Entity.Gear8 = Data8
	Entity.Gear9 = Data9
	Entity.GearRatio = (Entity.GearTable[0] or 0) * Entity.GearTable.Final

	if Entity.CVT then
		Entity.TargetMinRPM = Data3
		Entity.TargetMaxRPM = math.max(Data4, Data3 + 100)
		Entity.CVTRatio = nil

		WireLib.TriggerOutput(Entity, "Min Target RPM", Entity.TargetMinRPM)
		WireLib.TriggerOutput(Entity, "Max Target RPM", Entity.TargetMaxRPM)

	elseif Entity.Auto then
		Entity.ShiftPoints = {}

		for part in string.gmatch(Data9, "[^,]+") do
			Entity.ShiftPoints[#Entity.ShiftPoints + 1] = tonumber(part)
		end

		Entity.ShiftPoints[0] = -1
		Entity.Reverse = Entity.Gears + 1
		Entity.GearTable[Entity.Reverse] = Data8
		Entity.Drive = 1
		Entity.ShiftScale = 1
	end

	if Entity.Dual or Entity.DoubleDiff then
		Entity:SetBodygroup(1, 1)
	else
		Entity:SetBodygroup(1, 0)
	end

	ChangeGear(Entity, 1)

	Entity:SetNWString("WireName", Entity.Name)
	Entity:UpdateOverlay()

	ACF_Activate(Entity)

	Entity.ACF.LegalMass = Entity.Mass
	Entity.ACF.Model     = Entity.Model
end

local function CheckRopes(Entity, Target)
	if not next(Entity[Target]) then return end

	for Ent, Link in pairs(Entity[Target]) do
		local OutPos = Entity:LocalToWorld(Link.Output)
		local InPos = Ent.IsGeartrain and Ent:LocalToWorld(Ent.In) or Ent:GetPos()

		-- make sure it is not stretched too far
		if OutPos:Distance(InPos) > Link.RopeLen * 1.5 then
			Entity:Unlink(Ent)
			continue
		end

		-- make sure the angle is not excessive
		local DrvAngle = (OutPos - InPos):GetNormalized():Dot((Entity:GetRight() * Link.Output.y):GetNormalized())

		if DrvAngle < 0.7 then
			Entity:Unlink(Ent)
		end
	end
end

local function CalcWheel(Entity, Link, Wheel, SelfWorld)
	local WheelPhys = Wheel:GetPhysicsObject()
	local VelDiff = WheelPhys:LocalToWorldVector(WheelPhys:GetAngleVelocity()) - SelfWorld
	local BaseRPM = VelDiff:Dot(WheelPhys:LocalToWorldVector(Link.Axis))

	Link.Vel = BaseRPM

	if Entity.GearRatio == 0 then return 0 end

	-- Reported BaseRPM is in angle per second and in the wrong direction, so we convert and add the gearratio
	return BaseRPM / Entity.GearRatio / -6
end

local function ActWheel(Link, Wheel, Torque, Brake, DeltaTime)
	local Phys = Wheel:GetPhysicsObject()
	local TorqueAxis = Phys:LocalToWorldVector(Link.Axis)
	local BrakeMult = 0

	if Brake > 0 then
		BrakeMult = Link.Vel * Link.Inertia * Brake / 5
	end

	Phys:ApplyTorqueCenter(TorqueAxis * Clamp(math.deg(-Torque * 1.5 - BrakeMult) * DeltaTime, -500000, 500000))
end

local Inputs = {
	Gear = function(Entity, Value)
		if Entity.Auto then
			ChangeDrive(Entity, Value)
		else
			ChangeGear(Entity, Value)
		end
	end,
	["Gear Up"] = function(Entity, Value)
		if Value == 0 then return end

		if Entity.Auto then
			ChangeDrive(Entity, Entity.Drive + 1)
		else
			ChangeGear(Entity, Entity.Gear + 1)
		end
	end,
	["Gear Down"] = function(Entity, Value)
		if Value == 0 then return end

		if Entity.Auto then
			ChangeDrive(Entity, Entity.Drive - 1)
		else
			ChangeGear(Entity, Entity.Gear - 1)
		end
	end,
	Clutch = function(Entity, Value)
		Entity.LClutch = Clamp(1 - Value, 0, 1) * Entity.MaxTorque
		Entity.RClutch = Clamp(1 - Value, 0, 1) * Entity.MaxTorque
	end,
	Brake = function(Entity, Value)
		Entity.LBrake = Clamp(Value, 0, 100)
		Entity.RBrake = Clamp(Value, 0, 100)
	end,
	["Left Brake"] = function(Entity, Value)
		Entity.LBrake = Clamp(Value, 0, 100)
	end,
	["Right Brake"] = function(Entity, Value)
		Entity.RBrake = Clamp(Value, 0, 100)
	end,
	["Left Clutch"] = function(Entity, Value)
		Entity.LClutch = Clamp(1 - Value, 0, 1) * Entity.MaxTorque
	end,
	["Right Clutch"] = function(Entity, Value)
		Entity.RClutch = Clamp(1 - Value, 0, 1) * Entity.MaxTorque
	end,
	["CVT Ratio"] = function(Entity, Value)
		Entity.CVTRatio = Clamp(Value, 0, 1)
	end,
	["Steer Rate"] = function(Entity, Value)
		Entity.SteerRate = Clamp(Value, -1, 1)
	end,
	["Hold Gear"] = function(Entity, Value)
		Entity.Hold = Value ~= 0
	end,
	["Shift Speed Scale"] = function(Entity, Value)
		Entity.ShiftScale = Clamp(Value, 0.1, 1.5)
	end
}

--===============================================================================================--

function MakeACF_Gearbox(Owner, Pos, Angle, Id, ...)
	if not Owner:CheckLimit("_acf_misc") then return end

	local GearboxData = list.Get("ACFEnts").Mobility[Id]

	if not GearboxData then return end

	local Gearbox = ents.Create("acf_gearbox")

	if not IsValid(Gearbox) then return end

	Gearbox:SetModel(GearboxData.model)
	Gearbox:SetPlayer(Owner)
	Gearbox:SetAngles(Angle)
	Gearbox:SetPos(Pos)
	Gearbox:Spawn()

	Gearbox:PhysicsInit(SOLID_VPHYSICS)
	Gearbox:SetMoveType(MOVETYPE_VPHYSICS)

	Owner:AddCount("_acf_misc", Gearbox)
	Owner:AddCleanup("acfmenu", Gearbox)

	UpdateGearboxData(Gearbox, GearboxData, Id, ...)

	Gearbox.Owner = Owner
	Gearbox.IsGeartrain = true
	Gearbox.Engines = {}
	Gearbox.Wheels = {} -- a "Link" has these components: Ent, Side, Axis, Rope, RopeLen, Output, ReqTq, Vel
	Gearbox.GearboxIn = {}
	Gearbox.GearboxOut = {}
	Gearbox.TotalReqTq = 0
	Gearbox.LBrake = 0
	Gearbox.RBrake = 0
	Gearbox.SteerRate = 0
	Gearbox.Gear = 0
	Gearbox.ChangeFinished = 0
	Gearbox.InGear = false
	Gearbox.CanUpdate = true
	Gearbox.LastActive = 0

	Gearbox.In = Gearbox:WorldToLocal(Gearbox:GetAttachment(Gearbox:LookupAttachment("input")).Pos)
	Gearbox.OutL = Gearbox:WorldToLocal(Gearbox:GetAttachment(Gearbox:LookupAttachment("driveshaftL")).Pos)
	Gearbox.OutR = Gearbox:WorldToLocal(Gearbox:GetAttachment(Gearbox:LookupAttachment("driveshaftR")).Pos)

	CheckLegal(Gearbox)

	timer.Create("ACF Gearbox Clock " .. Gearbox:EntIndex(), 3, 0, function()
		if IsValid(Gearbox) then
			CheckRopes(Gearbox, "GearboxOut")
			CheckRopes(Gearbox, "Wheels")
		else
			timer.Stop("ACF Engine Clock " .. Gearbox:EntIndex())
		end
	end)

	return Gearbox
end

list.Set("ACFCvars", "acf_gearbox", {"id", "data1", "data2", "data3", "data4", "data5", "data6", "data7", "data8", "data9", "data10"})
duplicator.RegisterEntityClass("acf_gearbox", MakeACF_Gearbox, "Pos", "Angle", "Id", "Gear1", "Gear2", "Gear3", "Gear4", "Gear5", "Gear6", "Gear7", "Gear8", "Gear9", "Gear0")
ACF.RegisterLinkSource("acf_gearbox", "GearboxIn")
ACF.RegisterLinkSource("acf_gearbox", "GearboxOut")
ACF.RegisterLinkSource("acf_gearbox", "Engines")
ACF.RegisterLinkSource("acf_gearbox", "Wheels")

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:Enable()
	self.Disabled	   = nil
	self.DisableReason = nil

	if self.Auto then
		ChangeDrive(self, self.OldGear)
	else
		ChangeGear(self, self.OldGear)
	end

	self.OldGear = nil

	self:UpdateOverlay()

	CheckLegal(self)
end

function ENT:Disable()
	self.Disabled = true
	self.OldGear  = self.Auto and self.Drive or self.Gear

	if self.Auto then
		ChangeDrive(self, 0)
	else
		ChangeGear(self, 0)
	end

	ChangeGear(self, 0)

	self:UpdateOverlay()

	timer.Simple(ACF.IllegalDisableTime, function()
		if IsValid(self) then
			self:Enable()
		end
	end)
end

function ENT:Update(ArgsTable)
	if ArgsTable[1] ~= self.Owner then return false, "You don't own that gearbox!" end

	local Id = ArgsTable[4] -- Argtable[4] is the engine ID
	local GearboxData = list.Get("ACFEnts").Mobility[Id]

	if not GearboxData then return false, "Invalid gearbox type!" end
	if GearboxData.model ~= self.Model then return false, "The new gearbox must have the same model!" end

	UpdateGearboxData(self, GearboxData, unpack(ArgsTable, 4, 14))

	return true, "Gearbox updated successfully!"
end

function ENT:UpdateOverlay()
	if timer.Exists("ACF Overlay Buffer" .. self:EntIndex()) then return end

	timer.Create("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
		if not IsValid(self) then return end

		local Text

		if self.DisableReason then
			Text = "Disabled: " .. self.DisableReason
		else
			Text = "Current Gear: " .. self.Gear
		end

		Text = Text .. "\n\n" .. self.Name .. "\n"

		if self.CVT then
			Text = "Reverse Gear: " .. math.Round(self.GearTable[2], 2) ..
					"\nTarget: " .. math.Round(self.TargetMinRPM) .. " - " .. math.Round(self.TargetMaxRPM) .. " RPM\n"
		elseif self.Auto then
			for i = 1, self.Gears do
				Text = Text .. "Gear " .. i .. ": " .. math.Round(self.GearTable[i], 2) ..
						", Upshift @ " .. math.Round(self.ShiftPoints[i] / 10.936, 1) .. " kph / " ..
						math.Round(self.ShiftPoints[i] / 17.6, 1) .. " mph\n"
			end

			Text = Text .. "Reverse gear: " .. math.Round(self.GearTable[self.Reverse], 2) .. "\n"
		else
			for i = 1, self.Gears do
				Text = Text .. "Gear " .. i .. ": " .. math.Round(self.GearTable[i], 2) .. "\n"
			end
		end

		Text = Text .. "Final Drive: " .. math.Round(self.Gear0, 2) .. "\n"
		Text = Text .. "Torque Rating: " .. self.MaxTorque .. " Nm / " .. math.Round(self.MaxTorque * 0.73) .. " ft-lb"

		self:SetOverlayText(Text)
	end)
end

-- prevent people from changing bodygroup
function ENT:CanProperty(_, Property)
	return Property ~= "bodygroups"
end

function ENT:TriggerInput(Input, Value)
	if self.Disabled then return end

	if Inputs[Input] then
		Inputs[Input](self, Value)
	end
end

function ENT:Calc(InputRPM, InputInertia)
	if self.Disabled then return 0 end
	if self.LastActive == CurTime() then return math.min(self.TotalReqTq, self.MaxTorque) end

	if self.ChangeFinished < CurTime() then
		self.InGear = true
	end

	local BoxPhys = self:GetPhysicsObject()
	local SelfWorld = BoxPhys:LocalToWorldVector(BoxPhys:GetAngleVelocity())

	if self.CVT and self.Gear == 1 then
		if self.CVTRatio and self.CVTRatio > 0 then
			self.GearTable[1] = Clamp(self.CVTRatio, 0.01, 1)
		else
			self.GearTable[1] = Clamp((InputRPM - self.TargetMinRPM) / ((self.TargetMaxRPM - self.TargetMinRPM) or 1), 0.05, 1)
		end

		self.GearRatio = (self.GearTable[1] or 0) * self.GearTable.Final
		WireLib.TriggerOutput(self, "Ratio", self.GearRatio)
	end

	if self.Auto and self.Drive == 1 and self.InGear then
		local vel = BoxPhys:GetVelocity():Length()

		if vel > (self.ShiftPoints[self.Gear] * self.ShiftScale) and not (self.Gear == self.Gears) and not self.Hold then
			ChangeGear(self, self.Gear + 1)
		elseif vel < (self.ShiftPoints[self.Gear - 1] * self.ShiftScale) then
			ChangeGear(self, self.Gear - 1)
		end
	end

	self.TotalReqTq = 0

	for Ent, Link in pairs(self.GearboxOut) do
		local Clutch = Link.Side == 0 and self.LClutch or self.RClutch

		Link.ReqTq = 0

		if not Ent.Disabled then
			local Inertia = 0

			if self.GearRatio ~= 0 then
				Inertia = InputInertia / self.GearRatio
			end

			Link.ReqTq = math.min(Clutch, math.abs(Ent:Calc(InputRPM * self.GearRatio, Inertia) * self.GearRatio))

			self.TotalReqTq = self.TotalReqTq + math.abs(Link.ReqTq)
		end
	end

	for Wheel, Link in pairs(self.Wheels) do
		local Clutch = Link.Side == 0 and self.LClutch or self.RClutch

		Link.ReqTq = 0

		local RPM = CalcWheel(self, Link, Wheel, SelfWorld)

		if self.GearRatio ~= 0 and ((InputRPM > 0 and RPM < InputRPM) or (InputRPM < 0 and RPM > InputRPM)) then
			if self.DoubleDiff then
				local NTq = math.min(Clutch, (InputRPM - RPM) * InputInertia)
				local Sign = 0

				if self.SteerRate ~= 0 then
					Sign = self.SteerRate / math.abs(self.SteerRate)
				end

				if Link.Side == 0 then
					local DTq = Clamp((self.SteerRate * ((InputRPM * (math.abs(self.SteerRate) + 1)) - (RPM * Sign))) * InputInertia, -self.MaxTorque, self.MaxTorque)

					Link.ReqTq = NTq + DTq
				else
					local DTq = Clamp((self.SteerRate * ((InputRPM * (math.abs(self.SteerRate) + 1)) + (RPM * Sign))) * InputInertia, -self.MaxTorque, self.MaxTorque)

					Link.ReqTq = NTq - DTq
				end
			else
				Link.ReqTq = math.min(Clutch, (InputRPM - RPM) * InputInertia)
			end

			self.TotalReqTq = self.TotalReqTq + math.abs(Link.ReqTq)
		end
	end

	return math.min(self.TotalReqTq, self.MaxTorque)
end

function ENT:Act(Torque, DeltaTime, MassRatio)
	if self.Disabled then return end

	local Loss = Clamp(((1 - 0.4) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, 0.4, 1) --internal torque loss from damaged
	local Slop = self.Auto and 0.9 or 1 --internal torque loss from inefficiency
	local ReactTq = 0
	-- Calculate the ratio of total requested torque versus what's avaliable, and then multiply it but the current gearratio
	local AvailTq = 0

	if Torque ~= 0 and self.GearRatio ~= 0 then
		AvailTq = math.min(math.abs(Torque) / self.TotalReqTq, 1) / self.GearRatio * -(-Torque / math.abs(Torque)) * Loss * Slop
	end

	for Ent, Link in pairs(self.GearboxOut) do
		Ent:Act(Link.ReqTq * AvailTq, DeltaTime, MassRatio)
	end

	for Ent, Link in pairs(self.Wheels) do
		local Brake = Link.Side == 0 and self.LBrake or self.RBrake

		ActWheel(Link, Ent, Link.ReqTq * AvailTq, Brake, DeltaTime)

		ReactTq = ReactTq + Link.ReqTq * AvailTq
	end

	local BoxPhys = ACF_GetAncestor(self):GetPhysicsObject()

	if IsValid(BoxPhys) and ReactTq ~= 0 then
		BoxPhys:ApplyTorqueCenter(self:GetRight() * Clamp(2 * math.deg(ReactTq * MassRatio) * DeltaTime, -500000, 500000))
	end

	self.LastActive = CurTime()
end

function ENT:Link(Target)
	if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
	if self == Target then return false, "Can't link a gearbox to itself." end

	local Function = ClassLink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Gearboxes can't be linked to '" .. Target:GetClass() .. "'."
end

function ENT:Unlink(Target)
	if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
	if self == Target then return false, "Can't unlink a gearbox from itself." end

	local Function = ClassUnlink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Gearboxes can't be unlinked from '" .. Target:GetClass() .. "'."
end

function ENT:PreEntityCopy()
	if next(self.Wheels) then
		local Wheels = {}

		for Ent in pairs(self.Wheels) do
			Wheels[#Wheels + 1] = Ent:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFWheels", Wheels)
	end

	if next(self.GearboxOut) then
		local Gearboxes = {}

		for Ent in pairs(self.GearboxOut) do
			Gearboxes[#Gearboxes + 1] = Ent:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFGearboxes", Gearboxes)
	end

	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	local EntMods = Ent.EntityMods

	if EntMods.ACFWheels then
		local Wheel

		for _, EntID in ipairs(EntMods.ACFWheels) do
			Wheel = CreatedEntities[EntID]

			self:Link(Wheel)
		end

		EntMods.ACFWheels = nil
	end

	if EntMods.ACFGearboxes then
		local Gearbox

		for _, EntID in ipairs(EntMods.ACFGearboxes) do
			Gearbox = CreatedEntities[EntID]

			self:Link(Gearbox)
		end

		EntMods.ACFGearboxes = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	for Engine in pairs(self.Engines) do
		self:Unlink(Engine)
	end

	for Wheel in pairs(self.Wheels) do
		self:Unlink(Wheel)
	end

	for Gearbox in pairs(self.GearboxIn) do
		Gearbox:Unlink(self)
	end

	for Gearbox in pairs(self.GearboxOut) do
		self:Unlink(Gearbox)
	end

	WireLib.Remove(self)
end
