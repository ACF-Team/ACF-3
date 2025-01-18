AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local ACF      = ACF
local Classes  = ACF.Classes
local Entities = Classes.Entities

ENT.ACF_Limit = 16
ENT.ACF_UserWeighable = true

do -- Random timer crew stuff
	function ENT:UpdateAccuracyMod(cfg)
		self.CrewsByType = self.CrewsByType or {}
		local Sum1, Count1 = ACF.WeightedLinkSum(self.CrewsByType.Gunner or {}, function(Crew) return Crew.TotalEff end)
		local Sum2, Count2 = ACF.WeightedLinkSum(self.CrewsByType.Commander or {}, function(Crew) return Crew.TotalEff end)
		local Sum, Count = Sum1 + Sum2, Count1 + Count2
		local Val = (Count > 0) and (Sum / Count) or 0
		self.AccuracyCrewMod = math.Clamp(Val, ACF.CrewFallbackCoef, 1)
		return self.AccuracyCrewMod
	end

	function ENT:UpdateFuelMod(cfg)
		self.CrewsByType = self.CrewsByType or {}
		local Sum, Count = ACF.WeightedLinkSum(self.CrewsByType.Driver or {}, function(Crew) return Crew.TotalEff end)
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
	ACF.AugmentedTimer(function(cfg) self:UpdateAccuracyMod(cfg) end, function() return IsValid(self) end, nil, {MinTime = 0.5, MaxTime = 1})
	ACF.AugmentedTimer(function(cfg) self:UpdateFuelMod(cfg) end, function() return IsValid(self) end, nil, {MinTime = 1, MaxTime = 2})
end

do
	-- Maintain a record in the contraption of its current crew
	hook.Add("cfw.contraption.entityAdded", "baseaddindex", function(contraption, ent)
		if ent:GetClass() == "acf_baseplate" then
			contraption.Base = ent
		end
	end)

	hook.Add("cfw.contraption.entityRemoved", "baseremoveindex", function(contraption, ent)
		if ent:GetClass() == "acf_baseplate" then
			contraption.Base = nil
		end
	end)
end

do
	ACF.RegisterLinkSource("acf_baseplate", "Seat")

	ACF.RegisterClassLink("acf_baseplate", "prop_vehicle_prisoner_pod", function(self, Seat, _)
		if self.Seat == Seat then return false, "This baseplate is already linked to this seat" end
		if IsValid(self.Seat) then return false, "This baseplate is already linked to a seat" end

		self.Seat = Seat

		Seat._IsInvisible = true

		hook.Add("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. self:EntIndex(), function(ply, veh, role)
			if veh == Seat then ply:GodEnable() end -- Block damage if they're in the seat
		end)
		hook.Add("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. self:EntIndex(), function(ply, veh)
			if veh == Seat then ply:GodDisable() end -- Block damage if they're in the seat
		end)

		return true, "Seat linked successfully"
	end)

	ACF.RegisterClassUnlink("acf_baseplate", "prop_vehicle_prisoner_pod", function(self, Seat, _)
		if IsValid(self.Seat) then
			self.Seat = nil

			Seat._IsInvisible = false
			hook.Remove("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. self:EntIndex())
			hook.Remove("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. self:EntIndex())
			self:CPPIGetOwner():GodDisable()

			return true, "Seat unlinked successfully"
		end

		return false, "This seat is not linked to this baseplate"
	end)

	local Clock       = ACF.Utilities.Clock
	local MaxDistance = ACF.LinkDistance ^ 2
	local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
	function ENT:Think()
		if IsValid(self.Seat) then
			local OutOfRange = self:GetPos():DistToSqr(self.Seat:GetPos()) > MaxDistance			-- Check distance limit
			local DiffAncestors = self:GetContraption() ~= self.Seat:GetContraption()	-- Check same contraption
			if OutOfRange or DiffAncestors then
				local Sound = UnlinkSound:format(math.random(1, 3))
				self.Seat:EmitSound(Sound, 70, 100, ACF.Volume)
				self:EmitSound(Sound, 70, 100, ACF.Volume)
				self:Unlink(self.Seat)
				ACF.SendNotify(self:CPPIGetOwner(), false, "Seat unlinked from Baseplate because they are too far or on separate contraptions.")
			end
		end

		self:NextThink(Clock.CurTime + math.Rand(1, 2))
		return true
	end
end

local Text = "Baseplate Size: %.1f x %.1f x %.1f"
function ENT:UpdateOverlayText()
	return Text:format(self.Size[1], self.Size[2], self.Size[3])
end

Entities.Register()