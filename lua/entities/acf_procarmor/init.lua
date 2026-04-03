AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF = ACF

-- 1. Verify Client Data
-- This ensures the data coming from the menu is valid before the entity updates.
function ENT.ACF_OnVerifyClientData(ClientData)
    -- We create a Size vector from your specific variables
    -- Note: Ensure these names match your ENT.ACF_UserVars exactly
    if not ClientData then return end
    ClientData.ProcSize = Vector(ClientData.ProcLength or 36, ClientData.ProcWidth or 36, ClientData.ProcHeight or 36)
    print("Verified Client Data for Proc Armor:", ClientData.ProcSize)
end

-- 2. Post Update Entity Data
-- This runs whenever the player changes settings in the menu/tool.
function ENT:ACF_PostUpdateEntityData(ClientData)
    -- This handles the physical scaling of the entity
    print("Setting Size for Proc Armor:", ClientData.ProcSize)
    self:SetSize(ClientData.ProcSize)

    -- If your ArmorType has a specific initialization hook, call it here
    local ArmorType = self:ACF_GetUserVar("ArmorType")
    if ArmorType and ArmorType.OnInitialize then
        ArmorType.OnInitialize(self)
    end
end

-- 3. Pre-Spawn
-- Sets the default model and material before the entity appears.
function ENT:ACF_PreSpawn()
    self:SetScaledModel("models/holograms/cube.mdl")
    self:SetMaterial("hunter/myplastic")
end

-- 4. Post-Spawn
-- Handles mass and basic cleanup/registration.
function ENT:ACF_PostSpawn(Owner, _, _, ClientData)
    print("test")
end

-- 5. Post Menu Spawn
-- Simple quality of life: drops it to the floor when spawned from the menu.
function ENT:ACF_PostMenuSpawn()
    ACF.DropToFloor(self)
end

ACF.Classes.Entities.Register()