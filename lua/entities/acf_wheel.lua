DEFINE_BASECLASS "acf_base_simple"
AddCSLuaFile()

ENT.PrintName     = "ACF Wheel"
ENT.WireDebugName = "ACF Wheel"
ENT.PluralName    = "ACF Wheels"
ENT.ACF_PreventArmoring = false
ENT.IsACFEntity = false

ENT.ACF_UserVars = {
    ["PhysRadius"] = {Type = "Number",       Min = 4,    Max = 80,  Default = 9,    Decimals = 2, ClientData = true},
    ["Baseplate"]  = {Type = "LinkedEntity", Classes = {acf_baseplate = true}},
}

local ACF      		= ACF
local Classes  		= ACF.Classes
local Entities 		= Classes.Entities

local Inputs = {
    "Angle (Controls the wheels direction, local to the forward direction of the baseplate)",
    "Brake (If != 0, locks the wheels angular velocity)",
}
function ENT:SetPlayer() end
if SERVER then
    ACF.RegisterClassLink("acf_wheel", "acf_baseplate", function(Wheel, Baseplate)
        Wheel:ACF_SetUserVar("Baseplate", Baseplate)
        Wheel:SetBaseplate(Baseplate)
        return true
    end)
end

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "WheelAngle")
    self:NetworkVar("Entity", 0, "Baseplate")
end

if CLIENT then
    function ENT:GetVisualModel()
        return "models/xqm/airplanewheel1.mdl"
    end

    function ENT:CreateDecoy()
        self:RemoveDecoy()

        local ModelName = self:GetVisualModel()
        if ModelName == nil or #ModelName == 0 then return end

        self.Decoy = ClientsideModel(ModelName)

        self:CallOnRemove("ACF_CleanUpDecoy", function(ent)
            ent:RemoveDecoy()
        end)
        self.Decoy:SetColor(self:GetColor())

        return self.Decoy
    end

    function ENT:Think()
        self:SetNextClientThink(CurTime() + (1 / 60))

        local Decoy = self.Decoy
        local Wheel = self
        local BP    = self:GetBaseplate()

        local Decoy_Valid = IsValid(Decoy)
        local Wheel_Valid = IsValid(Wheel)
        local BP_Valid    = IsValid(BP)

        if Wheel_Valid and not Decoy_Valid then
            Decoy = self:CreateDecoy()
            Decoy_Valid = IsValid(Decoy)
        end

        if Decoy_Valid and Wheel_Valid and BP_Valid then
            Decoy:SetPos(Wheel:GetPos())

            local WheelForward = Wheel:GetAngles():Forward()
            local RightAxis = BP:GetRight()

            local ProjectedForward = WheelForward - RightAxis * WheelForward:Dot(RightAxis)
            ProjectedForward:Normalize()

            local AncestorForward = BP:GetForward()
            local ProjectedAncestorForward = AncestorForward - RightAxis * AncestorForward:Dot(RightAxis)
            ProjectedAncestorForward:Normalize()

            local DotProduct = ProjectedForward:Dot(ProjectedAncestorForward)
            local Angle = math.deg(math.acos(math.Clamp(DotProduct, -1, 1)))

            if ProjectedForward:Cross(ProjectedAncestorForward):Dot(RightAxis) < 0 then
                Angle = -Angle
            end

            local BaseAng = BP:LocalToWorldAngles(_G.Angle(0, 90, 0) + _G.Angle(0, self:GetWheelAngle(), Angle))
            Decoy:SetAngles(BaseAng)
        else
            self:SetNextClientThink(CurTime() + (1 / 10))
        end

        return true
    end

    function ENT:RemoveDecoy()
        if IsValid(self.Decoy) then self.Decoy:Remove() end
        self:RemoveCallOnRemove("ACF_CleanUpDecoy")
    end
end

if SERVER then
    local Utilities   	= ACF.Utilities
    local WireIO      	= Utilities.WireIO

    ENT.ACF_Limit                     = 8
    ENT.ACF_KillableButIndestructible = true

    function ENT:ACF_PreSpawn(_, _, _, _)
        self.ACF = {}
        self.ACF.Model = "models/sprops/rectangles/size_2/rect_12x24x3.mdl"
        self:SetModel(self.ACF.Model)
    end

    function ENT:ACF_PostSpawn(_, _, _, _)
        WireIO.SetupInputs(self, Inputs)
    end

    function ENT:ACF_PostMenuSpawn(Trace)
        self:SetPos(Trace.HitPos + (Trace.HitNormal * (10 + self.PhysRadius)))
        self:SetAngles(self:GetAngles() + Angle(0, -90, 0))
    end

    function ENT:ACF_PostUpdateEntityData(ClientData)
        self.PhysRadius = ClientData.PhysRadius
        self:PhysicsInitSphere(24, "phx_tire_normal")
    end

    function ENT:IsSystemValid()
        return IsValid(self.Wheel) and IsValid(self.RopeV) and IsValid(self.RopeH1) and IsValid(self.RopeH2) and IsValid(self.RopeH3)
    end

    function ENT:GetUserParams()
        local SelfTable = self:GetTable()

        local InAngle = SelfTable.IN_Angle or 0
        local OutAngle = SelfTable.OUT_Angle or 0
        local Delta = InAngle - OutAngle

        local Rate = 45 * engine.TickInterval()

        if math.abs(Delta) <= Rate then
            OutAngle = InAngle
        else
            OutAngle = OutAngle + Rate * (Delta > 0 and 1 or Delta < 0 and -1 or 0)
        end

        if SelfTable.OUT_Angle ~= OutAngle then
            self:SetWheelAngle(OutAngle)
        end
        SelfTable.OUT_Angle = OutAngle

        return OutAngle, SelfTable.IN_Brake
    end

    local LockingForce = 0.02
    local BrakingForce = 0.15
    function ENT:Think()
        local Ancestor = self:ACF_GetUserVar("Baseplate")
        if not IsValid(Ancestor) then
            self:NextThink(CurTime() + 0.5)
            return true
        end

        local AncestorPhys = Ancestor:GetPhysicsObject()
        if not IsValid(AncestorPhys) then
            self:NextThink(CurTime() + 0.5)
            return true
        end

        local Wheel     = self
        local WheelPhys = Wheel:GetPhysicsObject()
        if not IsValid(WheelPhys) then
            self:NextThink(CurTime() + 0.5)
            return true
        end

        local CurAngle, Brake = self:GetUserParams()
        local WorldAngVel = WheelPhys:LocalToWorldVector(WheelPhys:GetAngleVelocity())
        local LocalAngVel = AncestorPhys:WorldToLocalVector(WorldAngVel)

        local a = math.rad(CurAngle)
        local cosA, sinA = math.cos(a), math.sin(a)

        local lx, ly, lz = LocalAngVel.x, LocalAngVel.y, LocalAngVel.z
        local rx = lx * cosA + ly * sinA
        local ry = -lx * sinA + ly * cosA
        local rz = lz

        rx = rx * LockingForce
        rz = rz * LockingForce
        if Brake then
            ry = rx * BrakingForce
        end

        LocalAngVel.x = rx * cosA - ry * sinA
        LocalAngVel.y = rx * sinA + ry * cosA
        LocalAngVel.z = rz

        local AllowedWorldAngVel = AncestorPhys:LocalToWorldVector(LocalAngVel)
        local NewLocalAngVel = WheelPhys:WorldToLocalVector(AllowedWorldAngVel)

        WheelPhys:SetAngleVelocity(NewLocalAngVel)

        self:NextThink(CurTime())
        return true
    end
end

if SERVER then
    ACF.AddInputAction("acf_wheel", "Angle", function(Entity, Value)
        Entity.IN_Angle = -math.Clamp(Value, -45, 45)
    end)
    ACF.AddInputAction("acf_wheel", "Brake", function(Entity, Value)
        Entity.IN_Brake = tobool(Value)
    end)
end

Entities.Register()