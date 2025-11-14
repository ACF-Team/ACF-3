AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF      		= ACF
local Mobility    = ACF.Mobility
local MobilityObj = Mobility.Objects

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

function ENT:ACF_PreSpawn(_, _, _, _)
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
	self.Diameter = ClientData.WaterjetSize * 10 * 0.0254 -- Convert from inches to meters (model is 10u in diameter by default)

	self.Gearboxes = {}
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
	self:SetAngles(self:GetAngles() + Angle(0, 0, 0))
end

ACF.RegisterClassLink("acf_waterjet", "acf_gearbox", function(This, Gearbox)
	if Gearbox.Effectors[This] then return false, "This waterjet is already connected to this gearbox!" end

	local Link, DriveshaftAngle = GenerateLinkTable(Gearbox, This)

	if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(DriveshaftAngle) .. " deg)" end

	Gearbox.Effectors[This] = Link
	This.Gearboxes[Gearbox] = Link

	Gearbox:InvalidateClientInfo()

	return true, "Weapon linked successfully."
end)

ACF.RegisterClassUnlink("acf_waterjet", "acf_gearbox", function(This, Gearbox)
	if not Gearbox.Effectors[This] then return false, "This waterjet is not connected to this gearbox!" end

	Gearbox.Effectors[This] = nil
	This.Gearboxes[Gearbox] = nil

	return true, "Weapon unlinked successfully."
end)

ACF.AddInputAction("acf_waterjet", "Pitch", function(Entity, Value)
	Value = math.Clamp(Value, -1, 1)
	Entity.TargetPitch = Value
end)

ACF.AddInputAction("acf_waterjet", "Yaw", function(Entity, Value)
	Value = math.Clamp(Value, -1, 1)
	Entity.TargetYaw = Value
end)


-- Calculates the required torque for the waterjet to function
function ENT:Calc(InputRPM, InputInertia)
	if not self.InWater then return 0 end
	if not IsValid(self.Ancestor) then return 0 end

	local SelfTbl = self:GetTable()
	local HealthRatio = (SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth)
	local n = InputRPM / (2 * 3.14)         		-- Rotation rate (Rad/s)
	local CQ, Rho, D = SelfTbl.CQ, SelfTbl.Rho, SelfTbl.Diameter
	local Q_req = CQ * Rho * n * n * D * D * D * D 	-- Required torque to rotate
	return Q_req * HealthRatio
end

-- Applies torque to the waterjet
function ENT:Act(Torque, DeltaTime, MassRatio, FlyRPM)
	self:SetNW2Float("ACF_WaterjetRPM", FlyRPM)

	if not self.InWater then return end
	if not IsValid(self.Ancestor) then return end

	local SelfTbl = self:GetTable()
	local HealthRatio = (SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth)
	local n = FlyRPM / (2 * 3.14)         	-- Rotation rate (Rad/s)
	local CT, Rho, D = SelfTbl.CT, SelfTbl.Rho, SelfTbl.Diameter
	local T = CT * Rho * n * n * D * D * D * D  -- Force generated

	local Phys = self.AncestorPhys
	local Sign = Torque >= 0 and 1 or -1
	local Ang = Angle(SelfTbl.Pitch * SelfTbl.ArcPitch, 0, SelfTbl.Yaw * SelfTbl.ArcYaw)
	local Dir = -self:LocalToWorldAngles(Ang):Up()
	Phys:ApplyForceOffset(Dir * T * Sign * MassRatio * HealthRatio, self:GetPos())
end

function ENT:Think()
	self:SetNW2Float("ACF_WaterjetRPM", 0)
	local SelfTbl = self:GetTable()
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

local Text = "%s"
function ENT:UpdateOverlayText()
	return Text:format("LOL")
end

ACF.Classes.Entities.Register()