include("shared.lua")

function ENT:Initialize()
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:EnableCustomCollisions()
end

-- We don't want players to accidentally click on this
function ENT:TestCollision()
	return false
end

do	-- Netsurfing!
	local Queued	= {}

	local AliasModel

	local function RequestVehicleInfo(Vehicle)
		if Queued[Vehicle] then return end

		Queued[Vehicle] = true

		timer.Simple(5,function() if IsValid(Vehicle) and Queued[Vehicle] then Queued[Vehicle] = nil end end)

		net.Start("ACF.RequestVehicleInfo")
			net.WriteEntity(Vehicle)
		net.SendToServer()
	end

	local function CleanupOverlay(Ent)
		if not IsValid(Ent) then return end
		if not IsValid(AliasModel) then return end
		AliasModel:Remove()
	end

	local function VehicleAliasOverlay(Ent)
		if not Ent.HasData then RequestVehicleInfo(Ent) return end
		local AliasInfo = Ent._Alias
		if not IsValid(AliasModel) or AliasModel:GetParent() ~= Ent then
			if IsValid(AliasModel) then AliasModel:Remove() end

			AliasModel = ClientsideModel(AliasInfo.Model)
			AliasModel:SetMaterial("models/wireframe")
			AliasModel:SetPos(Ent:LocalToWorld(AliasInfo.Pos))
			AliasModel:SetAngles(Ent:LocalToWorldAngles(AliasInfo.Ang))
			AliasModel:SetParent(Ent)
		end
	end

	net.Receive("ACF.RequestVehicleInfo",function()
		local Ent = net.ReadEntity()
		if not IsValid(Ent) then return end

		local AliasInfo = {}
		AliasInfo.Model	= net.ReadString()
		AliasInfo.Pos	= net.ReadVector()
		AliasInfo.Ang	= net.ReadAngle()

		Ent._Alias	= AliasInfo
		Ent.HasData	= true
		Ent.DrawOverlay	= VehicleAliasOverlay
		Ent.CleanupOverlay = CleanupOverlay

		if Queued[Ent] then Queued[Ent] = nil end
	end)

	net.Receive("ACF.VehicleSpawned",function()
		local Ent	= net.ReadEntity()
		if not IsValid(Ent) then return end

		Ent.DrawOverlay = VehicleAliasOverlay
		Ent.CleanupOverlay = CleanupOverlay
	end)
end