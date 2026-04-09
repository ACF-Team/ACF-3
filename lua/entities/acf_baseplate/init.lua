AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:ConfigureLuaSeat(Pod, Player)
	ACF.ConfigureLuaSeat(self, Pod, Player)
	self.ACF_LiveData.LuaSeat = Pod

	hook.Add("PlayerEnteredVehicle", self, function(_, Ply, Veh)
		if Veh == Pod then Ply:SetNoDraw(true) end
	end)

	-- Make the player visible and vulnerable when they leave the seat
	hook.Add("PlayerLeaveVehicle", self, function(_, Ply, Veh)
		if Veh == Pod then Ply:SetNoDraw(false) end
	end)

	-- Allow players to enter the seat externally by pressing walk + use on a prop on the same contraption as the baseplate
	hook.Add("PlayerUse", self, function(self, Ply, Ent)
		if not Ply:KeyDown(IN_WALK) then return end
		if IsValid(Ent) then
			local Contraption = Ent:GetContraption()
			local MyContraption = self:GetContraption()
			if Contraption and MyContraption and Contraption == MyContraption and IsValid(Pod) and Pod:GetDriver() ~= Ply and not self.ACF_LiveData.DisableAltE then
				Ply:EnterVehicle(Pod)
			end
		end
	end)
end

function ENT:ACF_PostUpdateEntityData()
	self:SetSize(self.ACF_LiveData.Size)
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/holograms/cube.mdl")
	self:SetMaterial("hunter/myplastic")
	self:SetUseType(SIMPLE_USE)
end

function ENT:ACF_PostSpawn(Owner, _, _, _, _)
	-- Add seat if it was never created
	if not self.ACF_LiveData.LuaSeat then
		local Pod = ACF.GenerateLuaSeat(self, Owner, self:GetPos(), self:GetAngles(), self:GetModel(), true)
		self:ConfigureLuaSeat(Pod, Owner)
	end
end

function ENT:PostEntityPaste(Owner, _, _, _)
	-- If we had a seat before duplication, find it and reconfigure it.
	local Pod = self.ACF_LiveData.LuaSeat
	if not IsValid(Pod) then -- Repair if the seat wasn't duplicated correctly
		Pod = ACF.GenerateLuaSeat(self, Owner, self:GetPos(), self:GetAngles(), self:GetModel(), true)
	end
	self:ConfigureLuaSeat(Pod, Owner)
end

function ENT:ACF_PostMenuSpawn()
	self:SetAngles(Angle(0, 90, 0))
end

function ENT:UpdateOverlay()
	local DisplayStr = ""
	for _, DataVarName in ipairs(ACF.DataVarScopesOrdered.ACF_baseplate or {}) do
		DisplayStr = DisplayStr .. DataVarName .. ": " .. tostring(self.ACF_LiveData[DataVarName]) .. "\n"
	end
	self:SetOverlayText(DisplayStr)
end

function ENT:Think()
	self:UpdateOverlay()
end

ACF.AutoRegister(ENT)