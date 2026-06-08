AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF
local HookRun = hook.Run
local Classes = ACF.Classes
local Entities = Classes.Entities

local function UpdateArmorMesh(Entity, Data)
	Entity.ACF = Entity.ACF or {}

	local Model = Data and Data.Model or "models/hunter/plates/plate05x05.mdl"
	Entity.ACF.Model = Model
	Entity:SetModel(Model)
	Entity:PhysicsInit(SOLID_VPHYSICS)
	Entity:SetMoveType(MOVETYPE_VPHYSICS)

	Entity:SetNWString("WireName", "ACF Armor Mesh")

	ACF.Activate(Entity, true)
end

function ACF.MakeArmorMesh(Player, Pos, Ang, Data)
	local CanSpawn = HookRun("ACF_PreSpawnEntity", "acf_armor_mesh", Player, Data)
	if CanSpawn == false then return false end

	local Entity = ents.Create("acf_armor_mesh")
	if not IsValid(Entity) then return end

	Entity:SetPlayer(Player)
	Entity:SetAngles(Ang)
	Entity:SetPos(Pos)
	Entity:Spawn()

	Player:AddCleanup("acf_armor_mesh", Entity)
	Player:AddCount("acf_armor_mesh", Entity)

	Entity.Name = "ACF Armor Mesh"
	Entity.ShortName = "ACF Armor Mesh"
	Entity.EntType = "ACF Armor Mesh"

	UpdateArmorMesh(Entity, Data)

	HookRun("ACF_OnSpawnEntity", "acf_armor_mesh", Entity, Data)

	return Entity
end

Entities.Register("acf_armor_mesh", ACF.MakeArmorMesh)