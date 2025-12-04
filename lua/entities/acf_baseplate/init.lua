AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

ENT.ACF_UserWeighable             = true
ENT.ACF_KillableButIndestructible = true
ENT.ACF_HealthUpdatesWireOverlay  = true

-- Might be a good idea to put this somewhere else later
ACF.ActiveBaseplatesTable = ACF.ActiveBaseplatesTable or {}
ACF.ActiveBaseplatesArray = ACF.ActiveBaseplatesArray or {}

include("modules/crew.lua")
include("modules/overlay.lua")
include("modules/repulsion.lua")
include("modules/seats.lua")
include("modules/spawning.lua")
include("modules/state.lua")

ACF.Classes.Entities.Register()