include("shared.lua")
local CrewPoses = ACF.Classes.CrewPoses

-- Deals with crew linking to non crew entities
net.Receive("ACF_Crew_Links", function()
	local EntIndex1 = net.ReadUInt(16)
	local EntIndex2 = net.ReadUInt(16)
	local State = net.ReadBool()

	local Ent = Entity(EntIndex1)
	Ent.Targets = Ent.Targets or {}

	if Ent.Targets == nil then return end
	if State then Ent.Targets[EntIndex2] = true else Ent.Targets[EntIndex2] = nil end
end)

net.Receive("ACF_Crew_Space", function()
	local Ent = net.ReadEntity()
	local Box = net.ReadVector()
	local Offset = net.ReadVector()

	if not IsValid(Ent) then return end

	Ent.Box = Box + Ent:OBBMaxs() - Ent:OBBMins()
	Ent.Offset = Offset
end)

-- Received after crew spawns
net.Receive("ACF_Crew_Spawn", function()
	local Ent = net.ReadEntity()
	local ModelID = net.ReadString()
	local PoseID = net.ReadString()
	local PlayerModel = net.ReadString()
	local PlayerModelBodygroups = net.ReadString()
	local PlayerModelSkin = net.ReadUInt(6)
	if not IsValid(Ent) then return end

	Ent.ModelID = ModelID
	Ent.PoseID = PoseID
	Ent.PlayerModel = PlayerModel
	Ent.PlayerModelBodygroups = PlayerModelBodygroups
	Ent.PlayerModelSkin = PlayerModelSkin

	Ent:CreateCrewHolo(ModelID, PoseID)
end)

function ENT:CreateCrewHolo(ModelID, PoseID)
	local ClassData = CrewPoses.GetItem(ModelID, PoseID)
	if self.CrewHolo then self.CrewHolo:Remove() end -- Remove existing crew holo if it exists
	if not ClassData then return end
	self.CrewHolo = ClientsideModel(self.PlayerModel)
	self.CrewHolo:SetPos(self:LocalToWorld(ClassData.Position))
	self.CrewHolo:SetAngles(self:LocalToWorldAngles(ClassData.Angle))
	self.CrewHolo:Spawn()
	self.CrewHolo:SetBodyGroups(self.PlayerModelBodygroups)
	self.CrewHolo:SetSkin(self.PlayerModelSkin)
	self.CrewHolo:SetParent(self)
	self.CrewHolo:ResetSequence(self.CrewHolo:LookupSequence(ClassData.ID))
	self.CrewHolo:SetCycle(0)
	self.CrewHolo:SetPlaybackRate(1)
end

-- Remove crew holo when the crew entity is removed
function ENT:OnRemove()
	if self.CrewHolo then self.CrewHolo:Remove() end
end

-- Initialize the crew holo if it doesn't already exist (PVS stuff)
-- hook.Add("NetworkEntityCreated", "CrewClientModel", function(Entity)
-- 	if not IsValid(Entity) or Entity:GetClass() ~= "acf_crew" then return end
-- 	if Entity.PoseID and not Entity.CrewHolo then Entity:CreateCrewHolo(Entity.PoseID) end
-- end)

local green = Color(0, 255, 0, 100)
local purple = Color(255, 0, 255, 100)
function ENT:DrawOverlay()
	if self.Targets then
		for Target in pairs(self.Targets) do
			local Target = Entity(Target)
			if not IsValid(Target) then continue end
			render.DrawWireframeBox(Target:GetPos(), Target:GetAngles(), Target:OBBMins(), Target:OBBMaxs(), green, true)
		end
	end

	if IsValid(self) and self.Box then
		render.DrawWireframeBox(self:LocalToWorld(self.Offset), self:GetAngles(), -self.Box / 2, self.Box / 2, purple, true)
		render.DrawWireframeSphere(self:LocalToWorld(self.Offset), 2, 10, 10, purple, true)
	end
end