AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local ACF      		= ACF
local Classes  		= ACF.Classes
local Entities 		= Classes.Entities
local Utilities   	= ACF.Utilities
local WireIO      	= Utilities.WireIO

ENT.ACF_Limit                     = 16
ENT.ACF_UserWeighable             = true
ENT.ACF_KillableButIndestructible = true
ENT.ACF_HealthUpdatesWireOverlay  = true

local Outputs = {
	"Entity (The entity itself) [ENTITY]",
	"Vehicles (Seat for this entity, compatible with wire) [ARRAY]",
}

do -- Random timer crew stuff
	function ENT:UpdateAccuracyMod()
		self.CrewsByType = self.CrewsByType or {}
		local Sum1, Count1 = ACF.WeightedLinkSum(self.CrewsByType.Gunner or {}, function(Crew) return Crew.TotalEff end)
		local Sum2, Count2 = ACF.WeightedLinkSum(self.CrewsByType.Commander or {}, function(Crew) return Crew.TotalEff end)
		local Sum3, Count3 = ACF.WeightedLinkSum(self.CrewsByType.Pilot or {}, function(Crew) return Crew.TotalEff end)
		local Sum, Count = Sum1 + Sum2 + Sum3, Count1 + Count2 + Count3
		local Val = (Count > 0) and (Sum / Count) or 0
		self.AccuracyCrewMod = math.Clamp(Val, ACF.CrewFallbackCoef, 1)
		return self.AccuracyCrewMod
	end

	function ENT:UpdateFuelMod()
		self.CrewsByType = self.CrewsByType or {}
		local Sum1, Count1 = ACF.WeightedLinkSum(self.CrewsByType.Driver or {}, function(Crew) return Crew.TotalEff end)
		local Sum2, Count2 = ACF.WeightedLinkSum(self.CrewsByType.Pilot or {}, function(Crew) return Crew.TotalEff end)
		local Sum, Count = Sum1 + Sum2, Count1 + Count2
		local Val = (Count > 0) and (Sum / Count) or 0
		self.FuelCrewMod = math.Clamp(Val, ACF.CrewFallbackCoef, 1)
		return self.FuelCrewMod
	end
end

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.Size = Vector(ClientData.Length, ClientData.Width, ClientData.Thickness)
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetSize(ClientData.Size)
end

function ENT:ACF_PreSpawn(_, _, _, _)
	self:SetScaledModel("models/holograms/cube.mdl")
	self:SetMaterial("hunter/myplastic")
end

function ENT:ACF_PostSpawn(_, _, _, ClientData)
	local EntMods = ClientData.EntityMods
	if EntMods and EntMods.mass then
		ACF.Contraption.SetMass(self, self.ACF.Mass or 1)
	else
		ACF.Contraption.SetMass(self, 1000)
	end

	WireIO.SetupOutputs(self, Outputs, ClientData)

	WireLib.TriggerOutput(self, "Entity", self)


	-- Add seat support for baseplates
	local Pod = ents.Create("prop_vehicle_prisoner_pod")
	if IsValid(Pod) then
		self:SetUseType(SIMPLE_USE) -- Avoid running activator function constantly...
		self.Pod = Pod
		Pod:SetAngles(self:GetAngles())
		Pod:SetModel("models/vehicles/pilot_seat.mdl")
		Pod:SetPos(self:GetPos())
		Pod:Spawn()
		Pod:SetParent(self)
		Pod:CPPISetOwner(self:GetOwner())
		Pod.Owner = self:GetOwner()
		Pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt") 	-- I don't know what this does, but for good measure...
		Pod:SetKeyValue("limitview", 0)											-- Let the player look around
		Pod:SetNoDraw(true)														-- Don't render the seat
		Pod:SetMoveType(MOVETYPE_NONE)
		Pod:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		Pod.Vehicle = self
		Pod.ACF = Pod.ACF or {}
		Pod.ACF.LegalSeat = true
		Pod.DoNotDuplicate = true												-- Don't duplicate cause baseplate will generate one on spawn
		Pod.ACF_InvisibleToBallistics = true									-- Baseplate seat

		-- Make the player invisible and invincible while in the seat
		hook.Add("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. self:EntIndex(), function(Ply, Veh)
			if Veh == Pod then
				Ply:GodEnable() -- Remove this if aliases are removed?
				Ply:SetNoDraw(true)
			end
		end)

		-- Make the player visible and vulnerable when they leave the seat
		hook.Add("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. self:EntIndex(), function(Ply, Veh)
			if Veh == Pod then
				Ply:GodDisable() -- Remove this if aliases are removed?
				Ply:SetNoDraw(false)
			end
		end)

		-- Allow players to enter the seat externally by pressing use on a prop on the same contraption as the baseplate
		hook.Add("PlayerUse", "ACFBaseplateSeatEnterExternal" .. self:EntIndex(), function(Ply, Ent)
			if not Ply:KeyDown(IN_SPEED) then return end
			if IsValid(Ent) then
				local Contraption = Ent:GetContraption()
				if Contraption then
					local Base = Contraption.Base
					if Base == self and Pod:GetDriver() ~= Ply then
						Ply:EnterVehicle(Pod)
					end
				end
			end
		end)

		-- Cleanup hooks and stuff when the baseplate is removed
		self:CallOnRemove("ACF_RemoveVehiclePod", function(Ent)
			hook.Remove("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. self:EntIndex())
			hook.Remove("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. self:EntIndex())
			hook.Remove( "PlayerUse", "ACFBaseplateSeatEnterExternal" .. self:EntIndex())

			local Owner = self:CPPIGetOwner()
			if IsValid(Owner) then Owner:GodDisable() end

			SafeRemoveEntity(Ent.Pod)
		end)

		WireLib.TriggerOutput(self, "Vehicles", {Pod})
	end

	ACF.AugmentedTimer(function(cfg) self:UpdateAccuracyMod(cfg) end, function() return IsValid(self) end, nil, {MinTime = 0.5, MaxTime = 1})
	ACF.AugmentedTimer(function(cfg) self:UpdateFuelMod(cfg) end, function() return IsValid(self) end, nil, {MinTime = 1, MaxTime = 2})
end

function ENT:Use(Activator)
	if not IsValid(Activator) then return end
	Activator:EnterVehicle(self.Pod)
end

do
	-- Maintain a record in the contraption of its current crew
	hook.Add("cfw.contraption.entityAdded", "ACF_CFWBaseIndex", function(contraption, ent)
		if ent:GetClass() == "acf_baseplate" then
			contraption.Base = ent
		end
	end)

	hook.Add("cfw.contraption.entityRemoved", "ACF_CFWBaseUnIndex", function(contraption, ent)
		if ent:GetClass() == "acf_baseplate" then
			contraption.Base = nil
		end
	end)
end

function ENT:CFW_OnParentedTo(_, NewEntity)
	if IsValid(NewEntity) then
		local Owner = self:CPPIGetOwner()
		if IsValid(Owner) then
			ACF.SendNotify(Owner, false, "Cannot parent an ACF baseplate to another entity.")
		end
	end

	return false
end

local Text = "Baseplate Size: %.1f x %.1f x %.1f\nBaseplate Health: %.1f%%"
function ENT:UpdateOverlayText()
	local h, mh = self.ACF.Health, self.ACF.MaxHealth
	return Text:format(self.Size[1], self.Size[2], self.Size[3], (h / mh) * 100)
end

Entities.Register()