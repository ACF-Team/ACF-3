AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

include "modules/activation.lua"
include "modules/cfw.lua"
include "modules/damage.lua"
include "modules/spawning.lua"
include "modules/state.lua"
include "modules/wiremod.lua"

ACF.Classes.Entities.Register()