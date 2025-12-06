AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Mobility    = ACF.Mobility
local MobilityObj = Mobility.Objects
local Sounds      = ACF.Utilities.Sounds

local function GenerateLinkTable(Entity, Target)
	local InPos = Target.In and Target.In.Pos or Vector()
	local InPosWorld = Target:LocalToWorld(InPos)
	local OutPos, Side

	local Plane
	if Entity:WorldToLocal(InPosWorld).y < 0 then
		Plane = Entity.OutL
		OutPos = Entity.OutL.Pos
		Side = 0
	else
		Plane = Entity.OutR
		OutPos = Entity.OutR.Pos
		Side = 1
	end

	local OutPosWorld = Entity:LocalToWorld(OutPos)
	local Excessive, Angle = ACF.IsDriveshaftAngleExcessive(Target, Target.In, Entity, Plane)
	if Excessive then return nil, Angle end

	local Link	= MobilityObj.Link(Entity, Target)

	Link:SetOrigin(OutPos)
	Link:SetTargetPos(InPos)
	Link:SetAxis(Target.In and Plane.Dir or Target:GetPhysicsObject():WorldToLocalVector(Entity:GetRight()))
	Link.OutDirection = Plane.Dir
	Link.Side = Side
	Link.RopeLen = (OutPosWorld - InPosWorld):Length()

	return Link, Angle
end

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.WaterjetSize = math.Clamp(ClientData.WaterjetSize or 1, 0.5, 1)
	ClientData.Size = Vector(ClientData.WaterjetSize, ClientData.WaterjetSize, ClientData.WaterjetSize)
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/maxofs2d/hover_propeller.mdl")
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetScale(ClientData.Size)

	self.SlewRatePitch = 5
	self.SlewRateYaw = 5
	self.ArcPitch = 5
	self.ArcYaw = 5
	self.Pitch = 0
	self.Yaw = 0
	self.TargetPitch = 0
	self.TargetYaw = 0

	self.CQ = 10 				-- Torque coefficient
	self.CT = 0.025 			-- Force coefficient
	self.Rho = 1000 			-- Density of water in kg/m^3
	self.Diameter = ClientData.WaterjetSize * 10 * ACF.InchToMeter -- Convert from inches to meters (model is 10u in diameter by default)

	self.Gearboxes = {}
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
end

ACF.RegisterClassLink("acf_waterjet", "acf_gearbox", function(This, Gearbox)
	if Gearbox.Effectors[This] then return false, "This waterjet is already connected to this gearbox!" end

	local Link, DriveshaftAngle = GenerateLinkTable(Gearbox, This)

	if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(DriveshaftAngle) .. " deg)" end

	Gearbox.Effectors[This] = Link
	This.Gearboxes[Gearbox] = Link

	Gearbox:InvalidateClientInfo()

	return true, "Waterjet linked successfully."
end)

ACF.RegisterClassUnlink("acf_waterjet", "acf_gearbox", function(This, Gearbox)
	if not Gearbox.Effectors[This] then return false, "This waterjet is not connected to this gearbox!" end

	Gearbox.Effectors[This] = nil
	This.Gearboxes[Gearbox] = nil

	return true, "Waterjet unlinked successfully."
end)

ACF.AddInputAction("acf_waterjet", "Pitch", function(Entity, Value)
	Value = math.Clamp(Value, -1, 1)
	Entity.TargetPitch = Value
end)

ACF.AddInputAction("acf_waterjet", "Yaw", function(Entity, Value)
	Value = math.Clamp(Value, -1, 1)
	Entity.TargetYaw = Value
end)

function ENT:UpdateSound(SelfTbl)
	SelfTbl = SelfTbl or self:GetTable()

	local Path      = self:ACF_GetUserVar("SoundPath")
	local LastSound = SelfTbl.LastSound

	if Path ~= LastSound and LastSound ~= nil then
		self:DestroySound()

		SelfTbl.LastSound = Path
	end

	if Path == "" then return end

	local Pitch = 100 * self:ACF_GetUserVar("SoundPitch")
	local Volume = self:ACF_GetUserVar("SoundVolume")

	if SelfTbl.Sound then
		Sounds.SendAdjustableSound(self, false, Pitch, Volume)
	else
		Sounds.CreateAdjustableSound(self, Path, Pitch, Volume)
		SelfTbl.Sound = true
	end
end

function ENT:DestroySound()
	Sounds.SendAdjustableSound(self, true)

	self.LastSound  = nil
	self.Sound      = nil
end

-- Calculates the required torque for the waterjet to function
function ENT:Calc(InputRPM)
	local SelfTbl = self:GetTable()

	if not SelfTbl.InWater then return 0 end
	if not IsValid(SelfTbl.Ancestor) then return 0 end

	local HealthRatio = SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth
	local N = InputRPM / (2 * math.pi) -- Rotation rate (Rad/s)
	local CQ, Rho, D = SelfTbl.CQ, SelfTbl.Rho, SelfTbl.Diameter
	local Q_req = CQ * Rho * N * N * D * D * D * D -- Required torque to rotate

	return Q_req / HealthRatio
end

-- Applies torque to the waterjet
function ENT:Act(Torque, _, MassRatio, FlyRPM)
	local SelfTbl = self:GetTable()
	self:SetNW2Float("ACF_WaterjetRPM", FlyRPM)

	if not SelfTbl.InWater then return end
	if not IsValid(SelfTbl.Ancestor) then return end

	local HealthRatio = SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth
	local N = FlyRPM / (2 * math.pi) -- Rotation rate (Rad/s)
	local CT, Rho, D = SelfTbl.CT, SelfTbl.Rho, SelfTbl.Diameter
	local T = CT * Rho * N * N * D * D * D * D -- Force generated

	local Phys = self.AncestorPhys
	local Sign = Torque >= 0 and 1 or -1
	local Ang = Angle(SelfTbl.Pitch * SelfTbl.ArcPitch, 0, SelfTbl.Yaw * SelfTbl.ArcYaw)
	local Dir = -self:LocalToWorldAngles(Ang):Up()

	Phys:ApplyForceOffset(Dir * T * Sign * MassRatio * HealthRatio, self:GetPos())
	self:UpdateSound(SelfTbl)
end

function ENT:Think()
	local SelfTbl = self:GetTable()

	if SelfTbl.Sound and self:GetNW2Float("ACF_WaterjetRPM", 0) == 0 then
		self:DestroySound()
	end

	self:SetNW2Float("ACF_WaterjetRPM", 0)
	local Center = self:GetPos()
	SelfTbl.InWater = bit.band(util.PointContents(Center), CONTENTS_WATER) == CONTENTS_WATER

	SelfTbl.Pitch = math.Clamp(SelfTbl.Pitch + (SelfTbl.TargetPitch - SelfTbl.Pitch) * SelfTbl.SlewRatePitch * 0.1, -1, 1)
	SelfTbl.Yaw = math.Clamp(SelfTbl.Yaw + (SelfTbl.TargetYaw - SelfTbl.Yaw) * SelfTbl.SlewRateYaw * 0.1, -1, 1)

	-- Cache ancestor
	local Ancestor = self:GetAncestor()
	if IsValid(Ancestor) then
		SelfTbl.Ancestor = Ancestor
		SelfTbl.AncestorPhys = Ancestor:GetPhysicsObject()
	end

	self:NextThink(CurTime() + 0.1)

	return true
end

function ENT:ACF_UpdateOverlayState(State)
	State:AddNumber("Scale", self:ACF_GetUserVar("WaterjetSize"))
	State:AddNumber("Pitch", self.Pitch)
	State:AddNumber("Yaw", self.Yaw)
end

ACF.Classes.Entities.Register()