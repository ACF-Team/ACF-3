local Classes = ACF.Classes

-- Ammo types are V2 classes (ACF.Ammunition.*) with no short ID field; derive the legacy short id (the
-- FQN suffix, e.g. "AP") used as the controller's ammo-type key.
local function AmmoID(Crate)
	local Round = Crate.RoundData
	return Round and Classes.GetTypeName(Round:GetType())
end

local function Init(Entity)
	Entity.PrimaryAmmoCountsByType = {}
end

-- Ammo related
do
	net.Receive("ACF_Controller_Ammo", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local SelectAmmoType = net.ReadString()
		local ForceReload = net.ReadBool()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end

		local PrimaryGun = Entity.Primary
		if not IsValid(PrimaryGun) then return end
		for Crate, _ in pairs(PrimaryGun.Crates) do
			if IsValid(Crate) then
				local AmmoType = AmmoID(Crate)
				Crate:TriggerInput("Load", AmmoType == SelectAmmoType and 1 or 0)
			end
		end
		if ForceReload then PrimaryGun:TriggerInput("Reload", 1) end
	end)

	function ENT:ProcessAmmo(SelfTbl)
		local Contraption = self:CFW_GetContraption()
		if Contraption == nil then return end

		-- Determine current counts
		local PrimaryGun = SelfTbl.Primary
		if not IsValid(PrimaryGun) then return end

		local PrimaryAmmoCountsByType = {}
		for Crate, _ in pairs(PrimaryGun.Crates) do
			if IsValid(Crate) then
				local AmmoType = AmmoID(Crate)
				if AmmoType then
					PrimaryAmmoCountsByType[AmmoType] = (PrimaryAmmoCountsByType[AmmoType] or 0) + (Crate.Amount or 0)
				end
			end
		end

		for AmmoType, Count in pairs(PrimaryAmmoCountsByType) do
			if SelfTbl.PrimaryAmmoCountsByType[AmmoType] ~= Count then
				SelfTbl.PrimaryAmmoCountsByType[AmmoType] = Count
				net.Start("ACF_Controller_Ammo")
				net.WriteEntity(self)
				net.WriteString(AmmoType)
				net.WriteInt(Count, 16)
				net.Send(self.Driver)
			end
		end
	end
end

return Init