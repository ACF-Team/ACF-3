
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF      		= ACF

function ENT.ACF_OnVerifyClientData(_)
	-- We don't have any client data yet
end

function ENT:ACF_PreSpawn(_, _, _, _)
	self:SetModel("models/hunter/plates/plate025x025.mdl")
end

function ENT:ACF_PostUpdateEntityData(_)
	-- We don't have any entity data yet
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
	self:SetAngles(self:GetAngles() + Angle(0, 0, 0))
end

function ENT:ACF_UpdateOverlayState(State)
	State:AddNumber("Test", 4)
end

function ENT:Compile(Entities)
	print("Compiling controller with entities:")
end

ACF.Classes.Entities.Register()