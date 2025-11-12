AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF      		= ACF

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.WaterjetSize = math.Clamp(ClientData.WaterjetSize or 1, 0.5, 2)
	ClientData.Size = Vector(ClientData.WaterjetSize,ClientData.WaterjetSize,ClientData.WaterjetSize)
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetScale(ClientData.Size)
end

function ENT:ACF_PreSpawn(_, _, _, _)
	self:SetScaledModel("models/maxofs2d/hover_propeller.mdl")
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
	self:SetAngles(self:GetAngles() + Angle(0, 0, 0))
end

ACF.RegisterClassLink("acf_waterjet", "acf_gearbox", function(This, Gearbox)
	if Gearbox.Effectors[This] then return false, "This waterjet is already connected to this gearbox!" end

	Gearbox.Effectors[This] = true
	This.Gearboxes[Gearbox] = true

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

end

function ENT:Act(Torque, DeltaTime, MassRatio)

end

function ENT:Think()
	local Center = self:GetPos()
	if bit.band(util.PointContents(Center), CONTENTS_WATER) == CONTENTS_WATER then end
	self:NextThink(CurTime())
	return true
end

local Text = "%s"
function ENT:UpdateOverlayText()
	return Text:format("LOL")
end

ACF.Classes.Entities.Register()