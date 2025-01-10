AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local ACF      = ACF
local Classes  = ACF.Classes
local Entities = Classes.Entities

ENT.ACF_Limit = 16
ENT.ACF_UserWeighable = true

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
end

do
	ACF.RegisterLinkSource("acf_baseplate", "prop_vehicle_prisoner_pod")

	ACF.RegisterClassLink("acf_baseplate", "prop_vehicle_prisoner_pod", function(This, Seat, FromChip)
		if This.Seat == Seat then return false, "This baseplate is already linked to this seat" end
		if This.Seat then return false, "This baseplate is already linked to a seat" end

		This.Seat = Seat

		Seat._IsInvisible = true
		print(Seat._IsInvisible)
		hook.Add("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. This:EntIndex(), function(ply, veh, role)
			if veh == Seat then ply:GodEnable() end -- Block damage if they're in the seat
		end)
		hook.Add("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. This:EntIndex(), function(ply, veh)
			if veh == Seat then ply:GodDisable() end -- Block damage if they're in the seat
		end)

		return true, "Seat linked successfully"
	end)

	ACF.RegisterClassUnlink("acf_baseplate", "prop_vehicle_prisoner_pod", function(This, Seat, FromChip)
		if This.Seat then
			This.Seat = nil

			Seat._IsInvisible = false
			hook.Remove("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. This:EntIndex())
			hook.Remove("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. This:EntIndex())
			This:CPPIGetOwner():GodDisable()

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