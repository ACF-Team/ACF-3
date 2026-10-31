local Classes = ACF.Classes

local NUM_WEAPONS = ENT.NUM_WEAPONS

local function Init(Entity)
	Entity.AmmoCountsByWeaponAndName = {}
	for WeaponSlot = 1, NUM_WEAPONS do
		Entity.AmmoCountsByWeaponAndName[WeaponSlot] = {}
	end
end

-- Rounds sharing an ammo type can still differ in penetration, so entries are named after both.
-- MaxPen is not stored on BulletData, it only exists in the display data.
-- Ammo types are V2 classes with no short ID field, so the display label uses the FQN's last segment
-- ("ACF.Ammunition.AP" to "AP") while the fully qualified name is what goes over the wire.
-- Names are cached by bullet data, which crates rebuild whenever their rounds change.
local NameCache = setmetatable({}, { __mode = "k" })

local function GetAmmoName(BulletData, Ammo)
	local Cached = NameCache[BulletData]
	if Cached then return Cached[1], Cached[2], Cached[3] end

	local Type    = Classes.GetTypeName(Ammo:GetType())
	local Display = Ammo:GetDisplayData(BulletData)
	local MaxPen  = math.max(math.Round(Display.MaxPen or 0), 0)
	local Short   = string.match(Type, "[^.]+$") or Type
	local Name    = MaxPen > 0 and Short .. " " .. MaxPen .. "mm" or Short

	NameCache[BulletData] = { Name, Type, MaxPen }

	return Name, Type, MaxPen
end

-- Ammo related
do
	net.Receive("ACF_Controller_Ammo", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local WeaponSlot = net.ReadUInt(2)
		local SelectAmmoName = net.ReadString()
		local ForceReload = net.ReadBool()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end

		local Gun = Entity:GetWeapon(WeaponSlot)
		if not IsValid(Gun) then return end

		local function IsSelected(BulletData, Ammo) return GetAmmoName(BulletData, Ammo) == SelectAmmoName end

		-- Crates loaded with the selected round feed only that round, the rest stop feeding
		for Crate, _ in pairs(Gun.Crates) do
			if IsValid(Crate) then
				local HasRound = false

				for _, Kind in ipairs(Crate:GetRoundCounts()) do
					if IsSelected(Kind.BulletData, Kind.Ammo) then HasRound = true break end
				end

				Crate:SetRoundFilter(HasRound and IsSelected or nil)
				Crate:TriggerInput("Load", HasRound and 1 or 0)
			end
		end
		if ForceReload then Gun:TriggerInput("Reload", 1) end
	end)

	function ENT:ProcessAmmo(SelfTbl)
		local Contraption = self:CFW_GetContraption()
		if Contraption == nil then return end

		for WeaponSlot = 1, NUM_WEAPONS do
			local Gun = self:GetWeapon(WeaponSlot)
			if not IsValid(Gun) then continue end

			local AmmoByName = {}
			for Crate, _ in pairs(Gun.Crates) do
				if IsValid(Crate) then
					for _, Kind in ipairs(Crate:GetRoundCounts()) do
						local AmmoName, RoundID, MaxPen = GetAmmoName(Kind.BulletData, Kind.Ammo)
						local Ammo = AmmoByName[AmmoName]
						if not Ammo then
							Ammo = {RoundID = RoundID, MaxPen = MaxPen, Count = 0}
							AmmoByName[AmmoName] = Ammo
						end
						Ammo.Count = Ammo.Count + Kind.Count
					end
				end
			end

			local Counts = SelfTbl.AmmoCountsByWeaponAndName[WeaponSlot]
			for AmmoName, Ammo in pairs(AmmoByName) do
				if Counts[AmmoName] ~= Ammo.Count then
					Counts[AmmoName] = Ammo.Count
					net.Start("ACF_Controller_Ammo")
					net.WriteEntity(self)
					net.WriteUInt(WeaponSlot, 2)
					net.WriteString(AmmoName)
					net.WriteString(Ammo.RoundID)
					net.WriteUInt(Ammo.MaxPen, 16)
					net.WriteUInt(Ammo.Count, 16)
					net.Send(self.Driver)
				end
			end
		end
	end
end

return Init