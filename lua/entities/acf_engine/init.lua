AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Code has been moved into their respective modules: --
include("modules/spawning.lua")   -- Linking and engine spawn/deletion functionality.
include("modules/state.lua")      -- Overlay and main state logic.
include("modules/cfw.lua")        -- CFW related stuff.
include("modules/sounds.lua")     -- Sounds. 
include("modules/networking.lua") -- Networking for the overlay.
include("modules/damage.lua")     -- Damage handling.
-- include("modules/thermals.lua") -- :eyes: