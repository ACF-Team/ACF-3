AddCSLuaFile("shared.lua")

include("shared.lua")

include("modules/spawning.lua")
include("modules/supply.lua")
include("modules/cost.lua")

util.AddNetworkString("ACF_SupplyEffect")
util.AddNetworkString("ACF_StopSupplyEffect")