AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Code has been moved to their respective modules: --

include("modules/linking.lua")
include("modules/networking.lua")
include("modules/overlay.lua")
include("modules/spawning.lua")
include("modules/state.lua")
