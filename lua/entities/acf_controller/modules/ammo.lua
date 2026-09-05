local function Init(Entity)
	Entity.PrimaryAmmoCountsByName = {}
end

-- Crates sharing an ammo type can still differ in penetration, so entries are named after both.
-- MaxPen is not stored on BulletData, it only exists in the display data.
local function GetAmmoName(Crate)
	local Ammo    = Crate.RoundData
	local Display = Ammo:GetDisplayData(Crate.BulletData)
	local MaxPen  = math.max(math.Round(Display.MaxPen or 0), 0)
	local Name    = MaxPen > 0 and Ammo.ID .. " " .. MaxPen .. "mm" or Ammo.ID

	return Name, Ammo.ID, MaxPen
end

-- Ammo related
do
	net.Receive("ACF_Controller_Ammo", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local SelectAmmoName = net.ReadString()
		local ForceReload = net.ReadBool()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end

		local PrimaryGun = Entity.Primary
		if not IsValid(PrimaryGun) then return end
		for Crate, _ in pairs(PrimaryGun.Crates) do
			if IsValid(Crate) then
				local AmmoName = GetAmmoName(Crate)
				Crate:TriggerInput("Load", AmmoName == SelectAmmoName and 1 or 0)
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

		local PrimaryAmmoByName = {}
		for Crate, _ in pairs(PrimaryGun.Crates) do
			if IsValid(Crate) then
				local AmmoName, RoundID, MaxPen = GetAmmoName(Crate)
				local Ammo = PrimaryAmmoByName[AmmoName]
				if not Ammo then
					Ammo = {RoundID = RoundID, MaxPen = MaxPen, Count = 0}
					PrimaryAmmoByName[AmmoName] = Ammo
				end
				Ammo.Count = Ammo.Count + (Crate.Amount or 0)
			end
		end

		for AmmoName, Ammo in pairs(PrimaryAmmoByName) do
			if SelfTbl.PrimaryAmmoCountsByName[AmmoName] ~= Ammo.Count then
				SelfTbl.PrimaryAmmoCountsByName[AmmoName] = Ammo.Count
				net.Start("ACF_Controller_Ammo")
				net.WriteEntity(self)
				net.WriteString(AmmoName)
				net.WriteString(Ammo.RoundID)
				net.WriteUInt(Ammo.MaxPen, 16)
				net.WriteUInt(Ammo.Count, 16)
				net.Send(self.Driver)
			end
		end
	end
end

return Init