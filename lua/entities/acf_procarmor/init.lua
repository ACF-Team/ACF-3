AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF = ACF

function ENT.ACF_OnVerifyClientData(ClientData)
	-- We create a Size vector from your specific variables
	-- Note: Ensure these names match your ENT.ACF_UserVars exactly
	if not ClientData then return end
	ClientData.ProcSize = Vector(ClientData.ProcLength or 36, ClientData.ProcWidth or 36, ClientData.ProcHeight or 36)
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	-- This handles the physical scaling of the entity
	local ArmorType = self:ACF_GetUserVar("ArmorType")
	local Density = ArmorType.Density or 7.84e-3 -- Fallback to RHA if nil

	-- Volume in cubic inches (GMod units)
	local L = ClientData.ProcLength or 36
	local W = ClientData.ProcWidth or 36
	local H = ClientData.ProcHeight or 36
	local VolumeInches = L * W * H

	-- Convert Cubic Inches to Cubic Centimeters (1 in³ ≈ 16.387 cm³)
	local VolumeCM3 = VolumeInches * 16.387

	-- Mass = Volume (cm³) * Density (g/cm³) / 1000 (to get kg)
	local Mass = (VolumeCM3 * Density * 1000) / 1000 -- Effectively VolumeCM3 * Density
	-- Note: Since your density is 7.84e-3, if that's kg/cm³, just multiply:
	-- Mass = VolumeCM3 * Density 

	self:SetSize(ClientData.ProcSize)
	ACF.Contraption.SetMass(self, Mass)

	print("Updated " .. ArmorType.Name .. " Armor. Mass: " .. math.Round(Mass, 2) .. "kg")
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/holograms/cube.mdl")
	self:SetMaterial("hunter/myplastic")
end

function ENT:ACF_PostSpawn(Owner, _, _, ClientData)
	print("test")
end

function ENT:ACF_PostMenuSpawn()
	ACF.DropToFloor(self)
end

function ENT:ACF_UpdateOverlayState(State)
	local ArmorType = self:ACF_GetUserVar("ArmorType")
	local L = self:ACF_GetUserVar("ProcLength")
	local W = self:ACF_GetUserVar("ProcWidth")
	local H = self:ACF_GetUserVar("ProcHeight")

	State:AddKeyValue("Material", ArmorType.Name)
	State:AddKeyValue("Dimensions", string.format("%.1f x %.1f x %.1f", L, W, H))
	State:AddHealth("Health", self.ACF.Health, self.ACF.MaxHealth)

	-- Display Density
	-- If density is 7.84e-3 kg/cm³, multiply by 1,000,000 for kg/m³
	local DisplayDensity = (ArmorType.Density or 0) * 1000000
	State:AddNumber("Density", math.Round(DisplayDensity), "kg/m³")

	local Phys = self:GetPhysicsObject()
	if IsValid(Phys) then
		State:AddNumber("Mass", math.Round(Phys:GetMass(), 1), "kg")
	end
end

ACF.Classes.Entities.Register()