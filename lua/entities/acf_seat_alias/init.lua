DEFINE_BASECLASS("acf_base_simple")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.PhysgunDisabled		= true
ENT.DisableDuplicator	= true
ENT.DoNotDuplicate		= true

local ACF			= ACF
local Contraption	= ACF.Contraption
local Damage		= ACF.Damage

do	-- Spawn functions
	local function UpdateClient(Vehicle,Ply)
		if not Vehicle._Alias then return end
		local AliasInfo = Vehicle._Alias

		net.Start("ACF.RequestVehicleInfo")
			net.WriteEntity(Vehicle)
			net.WriteString(AliasInfo.Model)
			net.WriteVector(AliasInfo.Pos)
			net.WriteAngle(AliasInfo.Ang)
		if IsValid(Ply) then net.Send(Ply) else net.Broadcast() end
	end

	function MakeACF_SeatAlias(Vehicle)
		if not IsValid(Vehicle) then return end
		if not Vehicle._Alias then if IsValid(Vehicle:GetDriver()) then ACF.PrepareAlias(Vehicle, Vehicle:GetDriver()) else return end end
		if Vehicle:GetModel() ~= Vehicle._Alias.SeatModel then Vehicle._Alias = nil ACF.PrepareAlias(Vehicle, Vehicle:GetDriver()) end

		if IsValid(Vehicle.AliasEnt) then
			Vehicle.AliasEnt:Remove()
		end

		local Ent = ents.Create("acf_seat_alias")

		if not IsValid(Ent) then return end

		local AliasInfo = Vehicle._Alias
		Ent.ACF	= {}
		Contraption.SetModel(Ent, AliasInfo.Model)

		Ent:PhysicsInit(SOLID_VPHYSICS)
		Ent:SetMoveType(MOVETYPE_NONE)

		Ent:SetParent(Vehicle)
		Ent:SetPos(Vehicle:LocalToWorld(AliasInfo.Pos))
		Ent:SetAngles(Vehicle:LocalToWorldAngles(AliasInfo.Ang))
		Ent:Spawn()

		Ent:SetCollisionGroup(COLLISION_GROUP_NONE)
		Ent:EnableCustomCollisions()

		local Ply		= Vehicle:GetDriver()
		Ent.Driver		= Ply
		Ent.Seat		= Vehicle
		Ent.AliasInfo	= AliasInfo
		Ent.Owner		= Ply

		Vehicle.AliasEnt	= Ent

		Ent:CPPISetOwner(Ply)
		Ent:SetOwner(Ply)

		UpdateClient(Vehicle)
	end

	util.AddNetworkString("ACF.RequestVehicleInfo")
	net.Receive("ACF.RequestVehicleInfo",function(_,Ply)
		local Ent = net.ReadEntity()
		if not IsValid(Ent) then return end
		if not Ent._Alias then ACF.PrepareAlias(Ent,Ply) end

		UpdateClient(Ent,Ply)
	end)
end

do	-- Metamethods
	function ENT:UpdateTransmitState()
		return TRANSMIT_NEVER
	end

	local Hit = {
		[MASK_SOLID + CONTENTS_AUX] = true,
		[bit.band(MASK_SOLID, MASK_SHOT) + CONTENTS_AUX] = true
	}

	-- Important for preventing everything except ACF traces from hitting this
	function ENT:TestCollision(_,_,_,_,Mask)
		if Hit[Mask] then
			return true
		end

		return false
	end

	function ENT:Think()
		local SelfTbl = self:GetTable()
		if not IsValid(SelfTbl.Seat) then self:Remove() end
		if SelfTbl.Seat.AliasEnt ~= self then self:Remove() end

		if self:GetParent() ~= SelfTbl.Seat then self:Remove() end
		if SelfTbl.Seat:GetModel() ~= SelfTbl.Seat._Alias.SeatModel then self:Remove() end

		self:NextThink(CurTime() + 15)
		return true
	end

	function ENT:ACF_Activate(Recalc)
		local Percent = 1

		if Recalc and self.ACF.Health and self.ACF.MaxHealth then
			Percent = self.ACF.Health / self.ACF.MaxHealth
		end

		self.ACF.Area      = 1
		self.ACF.Armour    = 0
		self.ACF.MaxArmour = 0
		self.ACF.Health    = 100 * Percent
		self.ACF.MaxHealth = 100
		self.ACF.Ductility = 0
		self.ACF.Type      = "Prop"
	end

	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		local Ply = self.Driver
		if not (IsValid(Ply) and IsValid(self.Seat)) then self:Remove() return HitRes end
		local HitRes = Damage.doSquishyDamage(Ply, DmgResult, DmgInfo)

		return HitRes
	end

	function ENT:OnRemove()
		if IsValid(self.Seat) and (self.Seat.AliasEnt == self) then
			self.Seat.AliasEnt = nil
		end

		if IsValid(self.Driver) then
			local Seat = self.Seat
			local Driver = self.Driver
			timer.Simple(0,function() if IsValid(Seat) and IsValid(Driver) then ACF.ApplyAlias(Seat,Driver) end end)
		end
	end
end

do	-- Arrr, there be hooks
	-- This runs BEFORE GM:HandlePlayerDriving has any effect on player animation, so the work is on us
	hook.Add("PlayerEnteredVehicle","ACF.CreateSeatAlias",function(Ply,Vic)
		if not IsValid(Ply) then return end
		if not IsValid(Vic) then return end

		ACF.ApplyAlias(Vic,Ply)
	end)

	hook.Add("PlayerLeaveVehicle","ACF.RemoveSeatAlias",function(_,Vic)
		if not IsValid(Vic) then return end
		if not IsValid(Vic.AliasEnt) then return end

		Vic.AliasEnt:Remove()
	end)

	util.AddNetworkString("ACF.VehicleSpawned")
	hook.Add("PlayerSpawnedVehicle","ACF.SpawnedVehicle",function(_,Vic)
		timer.Simple(0.2,function()
			net.Start("ACF.VehicleSpawned")
				net.WriteEntity(Vic)
			net.Broadcast()
		end)
	end)
end