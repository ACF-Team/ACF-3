local ACF          = ACF
local Classes      = ACF.Classes
local Utilities    = ACF.Utilities
local WireIO       = Utilities.WireIO
local WireLib      = WireLib
local Crates       = Classes.Crates
local Entities     = Classes.Entities
local AmmoTypes    = Classes.AmmoTypes
local Weapons      = Classes.Weapons
local ActiveCrates = ACF.AmmoCrates
local TimerCreate  = timer.Create
local TimerExists  = timer.Exists
local HookRun      = hook.Run

local Inputs = {
	"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
}

local Outputs = {
	"Loading (Whether or not weapons can use rounds from this crate.)",
	"Ammo (Rounds left in this ammo crate.)",
	"Entity (The ammo crate itself.) [ENTITY]",
}

WireLib.AddInputAlias("Active", "Load")
WireLib.AddOutputAlias("Munitions", "Ammo")

ACF.AddInputAction("acf_ammo", "Load", function(Entity, Value)
	Entity.Load = tobool(Value)

	WireLib.TriggerOutput(Entity, "Loading", Entity:CanConsume() and 1 or 0)
end)

local function NetworkAmmoData(Entity, Player)
	if IsValid(Entity) and Entity.ExtraData then
		net.Start("ACF_RequestAmmoData")
			net.WriteEntity(Entity)

			local ExtraData = Entity.ExtraData
			local Enabled = ExtraData.Enabled
			net.WriteBool(Enabled)

			if Enabled then
				-- Send stored projectile counts for client rendering
				local CountX = Entity.CrateProjectilesX or 3
				local CountY = Entity.CrateProjectilesY or 3
				local CountZ = Entity.CrateProjectilesZ or 3

				net.WriteUInt(ExtraData.Capacity or 0, 25)
				net.WriteBool(ExtraData.IsRound or false)
				net.WriteVector(ExtraData.RoundSize or vector_origin)
				net.WriteAngle(ExtraData.LocalAng or angle_zero)
				net.WriteVector(Vector(CountX, CountY, CountZ)) -- Send stored projectile counts
				net.WriteFloat(ExtraData.Spacing or 0)
				net.WriteUInt(ExtraData.MagSize or 0, 10)
				net.WriteUInt(ExtraData.AmmoStage or 0, 5)
				net.WriteBool(ExtraData.IsBelted or false)

				local HasModel = ExtraData.RoundModel ~= nil

				net.WriteBool(HasModel)

				if HasModel then
					net.WriteString(ExtraData.RoundModel)
					net.WriteVector(ExtraData.RoundOffset)
				end
			end

		if Player then
			net.Send(Player)
		else
			net.Broadcast()
		end
	end
end

local function UpdateCrate(Entity, Data, Class, Weapon, Ammo)
	local Name, ShortName, WireName = Ammo:GetCrateName()
	local Scalable    = Class.IsScalable
	local Caliber     = Scalable and Data.Caliber or Weapon.Caliber
	local WeaponName  = Scalable and Caliber .. "mm " .. Class.Name or Weapon.Name
	local WeaponShort = Scalable and Caliber .. "mm" .. Class.ID or Weapon.ID
	local Rounds      = UpdateCrateSize(Entity, Data, Class, Weapon, Ammo)
	local OldAmmo     = Entity.RoundData

	if OldAmmo then
		if OldAmmo.OnLast then
			OldAmmo:OnLast(Entity)
		end

		HookRun("ACF_OnAmmoLast", OldAmmo, Entity)
	end

	Entity.RoundData  = Ammo
	Entity.BulletData = Ammo:ServerConvert(Data)
	Entity.BulletData.Crate = Entity:EntIndex()

	if Ammo.OnFirst then
		Ammo:OnFirst(Entity)
	end

	HookRun("ACF_OnAmmoFirst", Ammo, Entity, Data, Class, Weapon)

	Ammo:Network(Entity, Entity.BulletData)

	for _, V in ipairs(Entity.DataStore) do
		Entity[V] = Data[V]
	end

	Entity.Name       = Name or WeaponName .. " " .. Ammo.Name
	Entity.ShortName  = ShortName or WeaponShort .. " " .. Ammo.ID
	Entity.EntType    = "Ammo Crate"
	Entity.ClassData  = Class
	Entity.Shape      = "Box"
	Entity.Class      = Class.ID
	Entity.WeaponData = Weapon
	Entity.Caliber    = Caliber
	Entity.AmmoStage  = Data.AmmoStage
	Entity.UnitMass   = Entity.BulletData.CartMass

	WireIO.SetupInputs(Entity, Inputs, Data, Class, Weapon, Ammo)
	WireIO.SetupOutputs(Entity, Outputs, Data, Class, Weapon, Ammo)

		Entity.WireAmountName = "Ammo"

	Entity:SetNWString("WireName", "ACF " .. (WireName or WeaponName .. " Ammo Crate"))

	local Percentage = Entity.Capacity and Entity.Amount / Entity.Capacity or 1
	local MagSize    = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon) or 0

	Entity.Capacity = Rounds
	Entity.MagSize  = MagSize
	Entity:SetAmount(math.floor(Entity.Capacity * Percentage))
	Entity:SetNWInt("Ammo", Entity.Amount)

	Entity.ExtraData = CalculateExtraData(Entity, Data, Class, Weapon)

	NetworkAmmoData(Entity)

	if next(Entity.Weapons) then
		local Unloaded

		for K in pairs(Entity.Weapons) do
			if K.CurrentCrate == Entity then
				Unloaded = true

				K:Unload()
			end
		end

		if Unloaded then
			ACF.SendNotify(Entity.Owner, false, "Crate updated while weapons were loaded with its ammo. Weapons unloaded.")
		end
	end

	ACF.Activate(Entity, true)

	Entity.ACF.Model = Entity:GetModel()

	Entity:UpdateMass(true)
end

util.AddNetworkString("ACF_RequestAmmoData")

net.Receive("ACF_RequestAmmoData", function(_, Player)
	local Entity = net.ReadEntity()

	NetworkAmmoData(Entity, Player)
end)

function ACF.MakeAmmo(Player, Pos, Ang, Data)
	if not Player:CheckLimit("_acf_ammo") then return end

	VerifyData(Data)

	local Source = Classes[Data.Destiny]
	local Class  = Classes.GetGroup(Source, Data.Weapon)
	local Weapon = Source.GetItem(Class.ID, Data.Weapon)
	local Ammo   = AmmoTypes.Get(Data.AmmoType)
	local Model  = "models/holograms/hq_rcube_thin.mdl"

	local CanSpawn = HookRun("ACF_PreSpawnEntity", "acf_ammo", Player, Data, Class, Weapon, Ammo)

	if CanSpawn == false then return false end

	local Crate = ents.Create("acf_ammo")

	if not IsValid(Crate) then return end

	Player:AddCleanup("acf_ammo", Crate)
	Player:AddCount("_acf_ammo", Crate)

	Crate.ACF       = Crate.ACF or {}
	Crate.ACF.Model = Model

	Crate:SetMaterial("phoenix_storms/Future_vents")
	Crate:SetScaledModel(Model)
	Crate:SetAngles(Ang)
	Crate:SetPos(Pos)
	Crate:Spawn()

	Crate.IsExplosive = true
	Crate.Weapons     = {}
	Crate.DataStore	  = Entities.GetArguments("acf_ammo")

	UpdateCrate(Crate, Data, Class, Weapon, Ammo)

	if Class.OnSpawn then
		Class.OnSpawn(Crate, Data, Class, Weapon, Ammo)
	end

	HookRun("ACF_OnSpawnEntity", "acf_ammo", Crate, Data, Class, Weapon, Ammo)

	if Data.Offset then
		local Position = Crate:LocalToWorld(Data.Offset)

		ACF.SaveEntity(Crate)

		Crate:SetPos(Position)

		ACF.RestoreEntity(Crate)

		if Data.BuildDupeInfo then
			Data.BuildDupeInfo.PosReset = Position
		end
	end

	Crate:TriggerInput("Load", 1)

	ActiveCrates[Crate] = true

	return Crate
end

Entities.Register("acf_ammo", ACF.MakeAmmo, "Weapon", "Caliber", "AmmoType", "Size", "AmmoStage", "CrateProjectilesX", "CrateProjectilesY", "CrateProjectilesZ")

ACF.RegisterLinkSource("acf_ammo", "Weapons")

function ENT:Update(Data)
	VerifyData(Data)

	local Source     = Classes[Data.Destiny]
	local Class      = Classes.GetGroup(Source, Data.Weapon)
	local Weapon     = Source.GetItem(Class.ID, Data.Weapon)
	local Caliber    = Weapon and Weapon.Caliber or Data.Caliber
	local OldClass   = self.ClassData
	local OldWeapon  = self.Weapon
	local OldCaliber = self.Caliber
	local Ammo       = AmmoTypes.Get(Data.AmmoType)
	local Blacklist  = Ammo.Blacklist
	local Extra      = ""

	local CanUpdate, Reason = HookRun("ACF_PreUpdateEntity", "acf_ammo", self, Data, Class, Weapon, Ammo)
	if CanUpdate == false then return CanUpdate, Reason end

	if OldClass.OnLast then
		OldClass.OnLast(self, OldClass)
	end

	HookRun("ACF_OnEntityLast", "acf_ammo", self, OldClass)

	ACF.SaveEntity(self)

	UpdateCrate(self, Data, Class, Weapon, Ammo)

	ACF.RestoreEntity(self)

	if Class.OnUpdate then
		Class.OnUpdate(self, Data, Class, Weapon, Ammo)
	end

	HookRun("ACF_OnUpdateEntity", "acf_ammo", self, Data, Class, Weapon, Ammo)

	if Data.Weapon ~= OldWeapon or Caliber ~= OldCaliber or self.Unlinkable then
		for Entity in pairs(self.Weapons) do
			self:Unlink(Entity)
		end

		Extra = " All weapons have been unlinked."
	else
		local Count = 0
		for Entity in pairs(self.Weapons) do
			if Blacklist[Entity.Class] then
				self:Unlink(Entity)

				Entity:Unload()

				Count = Count + 1
			end
		end

		if Count > 0 then
			Extra = " Unlinked " .. Count .. " weapons from this crate."
		end
	end

	return true, "Crate updated successfully." .. Extra
end

function ENT:OnRemove()
	local Class = self.ClassData

	if Class.OnLast then
		Class.OnLast(self, Class)
	end

	HookRun("ACF_OnEntityLast", "acf_ammo", self, Class)

	ActiveCrates[self] = nil

	if self.RoundData and self.RoundData.OnLast then
		self.RoundData:OnLast(self)
	end

	if self.Damaged then
		timer.Remove("ACF Crate Cookoff " .. self:EntIndex())

		self:Detonate()
	end

	for K in pairs(self.Weapons) do
		self:Unlink(K)
	end

	if self.BaseClass.OnRemove then
		self.BaseClass.OnRemove(self)
	end
end

do
	local Text = "%s\n\nStorage: %sx%sx%s\n\nContents: %s ( %s / %s )%s%s%s"
	local BulletText = "\nCartridge Mass: %s kg\nProjectile Mass: %s kg"

	function ENT:UpdateOverlayText()
		local Tracer = self.BulletData.Tracer ~= 0 and "-T" or ""
		local AmmoType = self.BulletData.Type .. Tracer
		local AmmoInfo = self.RoundData:GetCrateText(self.BulletData)
		local ExtraInfo = ACF.GetOverlayText(self)
		local BulletInfo = ""
		local Status

		if next(self.Weapons) then
			Status = self:CanConsume() and "Providing Ammo" or (self.Amount ~= 0 and "Idle" or "Empty")
		else
			Status = "Not linked to a weapon!"
		end

		local CountX = self.CrateProjectilesX or 1
		local CountY = self.CrateProjectilesY or 1
		local CountZ = self.CrateProjectilesZ or 1

		local Projectile = math.Round(self.BulletData.ProjMass, 2)
		local Cartridge  = math.Round(self.BulletData.CartMass, 2)

		BulletInfo = BulletText:format(Cartridge, Projectile)

		if AmmoInfo and AmmoInfo ~= "" then
			AmmoInfo = "\n\n" .. AmmoInfo
		end

		return Text:format(Status, CountX, CountY, CountZ, AmmoType, self.Amount, self.Capacity, BulletInfo, AmmoInfo, ExtraInfo)
	end
end

function ENT:Enable()
	WireLib.TriggerOutput(self, "Loading", self:CanConsume() and 1 or 0)

	self:UpdateMass(true)
end

function ENT:Disable()
	WireLib.TriggerOutput(self, "Loading", 0)

	self:UpdateMass(true)
end