AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ACF.RegisterClassLink("acf_gun", "acf_ammo", function(Weapon, Target)
	if Weapon.Crates[Target] then return false, "This weapon is already linked to this crate." end
	if Target.Weapons[Weapon] then return false, "This weapon is already linked to this crate." end
	if Weapon.Id ~= Target.BulletData.Id then return false, "Wrong ammo type for this weapon." end

	Weapon.Crates[Target]  = true
	Target.Weapons[Weapon] = true

	Weapon:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Weapon linked successfully."
end)

ACF.RegisterClassUnlink("acf_gun", "acf_ammo", function(Weapon, Target)
	if Weapon.Crates[Target] or Target.Weapons[Weapon] then
		Weapon.Crates[Target]  = nil
		Target.Weapons[Weapon] = nil

		Weapon:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Weapon unlinked successfully."
	end


	if not Weapon.Crates[Target] then return false, "This weapon is not linked to this crate." end
end)

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local AttemptFire
local ACF_RECOIL  = CreateConVar("acf_recoilpush", 1, FCVAR_ARCHIVE, "Whether or not ACF guns apply recoil", 0, 1)
local Trace		  = util.TraceLine
local TraceData	  = {start = true, endpos = true, filter = true, mask = MASK_SOLID}
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local CheckLegal  = ACF_CheckLegal
local ClassLink	  = ACF.GetClassLink
local ClassUnlink = ACF.GetClassUnlink
local WireTable	  = {
	gmod_wire_adv_pod = true,
	gmod_wire_joystick = true,
	gmod_wire_expression2 = true,
	gmod_wire_joystick_multi = true,
	gmod_wire_pod = function(_, Input)
		if Input.Pod then
			return Input.Pod:GetDriver()
		end
	end,
	gmod_wire_keyboard = function(_, Input)
		if Input.ply then
			return Input.ply
		end
	end,
}

WireTable.gmod_wire_adv_pod			= WireTable.gmod_wire_pod
WireTable.gmod_wire_joystick		= WireTable.gmod_wire_pod
WireTable.gmod_wire_joystick_multi	= WireTable.gmod_wire_pod
WireTable.gmod_wire_expression2		= function(This, Input)
	if Input.Inputs.Fire then
		return This:GetUser(Input.Inputs.Fire.Src)
	elseif Input.Inputs.Shoot then
		return This:GetUser(Input.Inputs.Shoot.Src)
	elseif Input.Inputs then
		for _, V in pairs(Input.Inputs) do
			if V.Src and WireTable[V.Src:GetClass()] then
				return This:GetUser(V.Src)
			end
		end
	end
end

local TriggerTable = {
	Fire = function(This, Bool)
		This.Firing = Bool

		if Bool then
			This.User = This:GetUser(This.Inputs.Fire.Src) or This.Owner

			AttemptFire(This) -- Attempt to fire the gun
		end
	end,
	Fuze = function(This, Bool, Value)
		This.SetFuze = Bool and math.abs(Value) + math.Rand(-0.05, 0.05) or nil
	end,
	Unload = function(This, Bool)
		if Bool and This.State == "Loaded" then
			This:Unload()
		end
	end,
	Reload = function(This, Bool)
		if Bool and This.State ~= "Reloading" then
			This:Reload(true)
		end
	end,
}

-----

local function FindNextCrate(Gun)
	if not next(Gun.Crates) then return end

	-- Find the next available crate to pull ammo from --
	local Current = Gun.CurrentCrate
	local NextKey = (IsValid(Current) and Gun.Crates[Current]) and Current or nil
	local Select = next(Gun.Crates, NextKey) or next(Gun.Crates)
	local Start  = Select

	repeat
		if Select.Load then return Select end -- Return select

		Select = next(Gun.Crates, Select) or next(Gun.Crates)
	until
		Select == Start

	return Select.Load and Select
end

local function BarrelCheck(Gun)
	TraceData.start	 = Gun:GetPos()
	TraceData.endpos = Gun:LocalToWorld(Gun.Muzzle)
	TraceData.filter = Gun.BarrelFilter

	local Res = Trace(TraceData)

	if Res.Hit and Res.Entity:CPPIGetOwner() == Gun.Owner then
		Gun.BarrelFilter[#Gun.BarrelFilter + 1] = Res.Entity

		return BarrelCheck(Gun)
	end

	return Res.HitPos
end

local function SetState(Gun, State)
	Gun.State = State

	Gun:UpdateOverlay()

	WireLib.TriggerOutput(Gun, "Status", State)
end

local function CanFire(Gun)
	if not IsValid(Gun) then return false end
	if Gun.Disabled then return false end
	if Gun.State ~= "Loaded" then
		if Gun.State == "Empty" then
			Gun:Reload()
		end

		return false
	end

	if hook.Run("ACF_FireShell", Gun) == false then return end

	return CheckLegal(Gun)
end

AttemptFire = function(Gun)
	if CanFire(Gun) then
		Gun:Shoot()
	elseif not Gun.Retry and Gun.State ~= "Reloading" then -- Dont bother trying again when loading/unloading, gun will try again when finished
		Gun:EmitSound("weapons/pistol/pistol_empty.wav", 500, 100) -- Click!
		Gun.Retry = true

		timer.Simple(1, function()
			if IsValid(Gun) then
				Gun.Retry = nil

				if Gun.Firing then
					AttemptFire(Gun)
				end
			end
		end)
	end
end

local function GetSpread(Entity)
	local SpreadScale = ACF.SpreadScale
	local IaccMult    = math.Clamp(((1 - SpreadScale) / 0.5) * ((Entity.ACF.Health / Entity.ACF.MaxHealth) - 1) + 1, 1, SpreadScale)

	return Entity.Accuracy * ACF.GunInaccuracyScale * IaccMult
end

local function Recoil(Entity)
	if not ACF_RECOIL:GetBool() then return end

	local MassCenter = Entity:LocalToWorld(Entity:GetPhysicsObject():GetMassCenter())

	ACF_KEShove(Entity, MassCenter, -Entity:GetForward(), Entity.BulletData.ProjMass * Entity.BulletData.MuzzleVel * 39.37 + Entity.BulletData.PropMass * 3000 * 39.37)
end

local function MuzzleEffect(Entity)
	local Effect = EffectData()
		Effect:SetEntity(Entity)
		Effect:SetScale(Entity.BulletData.PropMass)
		Effect:SetMagnitude(Entity.ReloadTime)
		Effect:SetSurfaceProp(ACF.RoundTypes[Entity.BulletData.Type].netid)

	util.Effect("acf_muzzleflash", Effect, true, true)
end

local function ReloadEffect(Entity)
	local Effect = EffectData()
		Effect:SetEntity(Entity)
		Effect:SetScale(0)
		Effect:SetMagnitude(Entity.ReloadTime)
		Effect:SetSurfaceProp(ACF.RoundTypes[Entity.BulletData.Type].netid)

	util.Effect("acf_muzzleflash", Effect, true, true)
end

--===============================================================================================--

function MakeACF_Gun(Player, Pos, Angle, Id)
	local List   = list.Get("ACFEnts")
	local EID    = List.Guns[Id] and Id or "50mmC"
	local Lookup = List.Guns[EID]
	local Ext  = Lookup.gunclass == "SL" and "_acf_smokelauncher" or "_acf_gun"

	if not Player:CheckLimit(Ext) then return false end -- Check gun spawn limits

	local Gun = ents.Create("acf_gun")

	if not IsValid(Gun) then return end

	Player:AddCleanup("acfmenu", Gun)
	Player:AddCount(Ext, Gun)

	Gun:SetModel(Lookup.model)
	Gun:SetPlayer(Player)
	Gun:SetAngles(Angle)
	Gun:SetPos(Pos)
	Gun:Spawn()

	Gun:PhysicsInit(SOLID_VPHYSICS)
	Gun:SetMoveType(MOVETYPE_VPHYSICS)

	Gun.ReloadTime   = 2
	Gun.BarrelFilter = { Gun }
	Gun.State        = "Empty"
	Gun.Crates       = {}
	Gun.Id           = Id -- MUST be stored on ent to be duped
	Gun.Owner        = Player -- MUST be stored on ent for PP
	Gun.Inputs  	 = WireLib.CreateInputs(Gun, { "Fire", "Unload", "Reload", "Fuze" } )
	Gun.Outputs 	 = WireLib.CreateOutputs(Gun, { "Status [STRING]", "Entity [ENTITY]", "Shots Left", "Rate of Fire", "Reload Time", "Projectile Mass", "Muzzle Velocity" })

	local ClassData = list.Get("ACFClasses").GunClass[Lookup.gunclass]

	-- ACF Specific vars
	Gun.Caliber        = Lookup.caliber
	Gun.Class          = Lookup.gunclass
	Gun.MagReload      = Lookup.magreload
	Gun.MagSize        = Lookup.magsize or 1
	Gun.CurrentShot    = 0
	Gun.Muzzle         = Gun:WorldToLocal(Gun:GetAttachment(Gun:LookupAttachment("muzzle")).Pos)
	Gun.Accuracy       = ClassData.spread
	Gun.MinLengthBonus = 0.75 * 3.1416 * (Gun.Caliber / 2) ^ 2 * Lookup.round.maxlength
	Gun.Muzzleflash    = ClassData.muzzleflash
	Gun.PGRoFmod       = math.max(0.01, Lookup.rofmod or 1)
	Gun.RoFmod         = ClassData.rofmod
	Gun.Sound          = ClassData.sound
	Gun.BulletData = { Type = "Empty", PropMass = 0, ProjMass = 0, Tracer = 0 }
	-- Set NWvars
	Gun:SetNWString("Sound", Gun.Sound)
	Gun:SetNWString("WireName", Lookup.name)
	Gun:SetNWString("ID", Gun.Id)
	Gun:SetNWString("Class", Gun.Class)
	-- Adjustable barrel length
	local Long = ClassData.longbarrel

	if Long ~= nil then
		--need to wait until after the property is actually set
		timer.Simple(0.25, function()
			if Gun:GetBodygroup(Long.index) == Long.submodel then
				Gun.Muzzle = Gun:WorldToLocal(Gun:GetAttachment(Gun:LookupAttachment(Long.newpos)).Pos)
			end
		end)
	end
	------------------------

	WireLib.TriggerOutput(Gun, "Status", "Empty")
	WireLib.TriggerOutput(Gun, "Entity", Gun)
	WireLib.TriggerOutput(Gun, "Projectile Mass", 1000)
	WireLib.TriggerOutput(Gun, "Muzzle Velocity", 1000)

	local Mass = Lookup.weight
	local Phys = Gun:GetPhysicsObject()
	if IsValid(Phys) then Phys:SetMass(Mass) end

	ACF_Activate(Gun)

	Gun.ACF.LegalMass     = Mass
	Gun.ACF.Model         = Lookup.model

	Gun:UpdateOverlay()

	CheckLegal(Gun)

	return Gun
end

list.Set("ACFCvars", "acf_gun", {"id"} )
duplicator.RegisterEntityClass("acf_gun", MakeACF_Gun, "Pos", "Angle", "Id")
ACF.RegisterLinkSource("acf_gun", "Crates")

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:Enable()
	self.Disabled	   = nil
	self.DisableReason = nil

	CheckLegal(self)
end

function ENT:Disable()
	self.Disabled = true
	self.Firing   = false -- Stop firing

	self:Unload() -- Unload the gun for being a big baddie
	self:UpdateOverlay()

	timer.Simple(ACF.IllegalDisableTime, function()
		if IsValid(self) then
			self:Enable()
		end
	end)
end

function ENT:GetUser(Input)
	if not Input then return end

	local Class = Input:GetClass()

	if WireTable[Class] then
		return WireTable[Class](self, Input)
	end
end

function ENT:TriggerInput(Input, Value)
	if self.Disabled then return end -- Ignore all input if the gun is disabled

	local Bool = tobool(Value)

	if TriggerTable[Input] then
		TriggerTable[Input](self, Bool, Value)
	end
end

function ENT:Link(Target)
	if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
	if self == Target then return false, "Can't link a weapon to itself." end

	local Function = ClassLink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Guns can't be linked to '" .. Target:GetClass() .. "'."
end

function ENT:Unlink(Target)
	if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
	if self == Target then return false, "Can't unlink a weapon from itself." end

	local Function = ClassUnlink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Guns can't be unlinked from '" .. Target:GetClass() .. "'."
end

function ENT:Shoot()
	local Cone = math.tan(math.rad(GetSpread(self)))
	local randUnitSquare = (self:GetUp() * (2 * math.random() - 1) + self:GetRight() * (2 * math.random() - 1))
	local Spread = randUnitSquare:GetNormalized() * Cone * (math.random() ^ (1 / ACF.GunInaccuracyBias))
	local Dir = (self:GetForward() + Spread):GetNormalized()

	self.BulletData.Owner  = self.User -- Must be updated on every shot
	self.BulletData.Gun	   = self      -- because other guns share this table
	self.BulletData.Pos    = BarrelCheck(self)
	self.BulletData.Flight = Dir * self.BulletData.MuzzleVel * 39.37 + ACF_GetAncestor(self):GetVelocity()

	ACF.RoundTypes[self.BulletData.Type].create(self, self.BulletData) -- Spawn projectile

	self.CurrentShot = self.CurrentShot - 1

	MuzzleEffect(self)
	Recoil(self)

	self:Reload()
end

function ENT:Reload(ForceReload)
	if self.Disabled then return end

	local Crate = FindNextCrate(self)

	if IsValid(Crate) then -- Have a crate, start reloading
		SetState(self, "Reloading")

		self.CurrentCrate = Crate
		self.CurrentCrate:Consume()

		self.BulletData = Crate.BulletData
		self.BulletData.Fuze = self.SetFuze

		--ReloadEffect(self)

		local Adj = self.BulletData.LengthAdj or 1 --FL firerate bonus adjustment
		self.ReloadTime = ((math.max(self.BulletData.RoundVolume, self.MinLengthBonus * Adj) / 500) ^ 0.60) * self.RoFmod * self.PGRoFmod

		-- Are we reloading mag or individual rounds? --
		local Time, Reload

		if ForceReload or self.CurrentShot == 0 then -- if ForceReload or (self.MagReload and self.CurrentShot == 0) then
			Time = self.MagReload or self.ReloadTime
			Reload = true

			WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)
		else
			Time = self.ReloadTime
		end

		------------------------------------------------

		timer.Simple(Time, function() -- Reload timer
			if IsValid(self) then
				SetState(self, "Loaded")

				if Reload then self.CurrentShot = self.MagSize end

				ReloadEffect(self)

				WireLib.TriggerOutput(self, "Reload Time", self.ReloadTime)
				WireLib.TriggerOutput(self, "Rate of Fire", 60 / self.ReloadTime)
				WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)
				WireLib.TriggerOutput(self, "Projectile Mass", math.Round(self.BulletData.ProjMass * 1000, 2))
				WireLib.TriggerOutput(self, "Muzzle Velocity", math.Round(self.BulletData.MuzzleVel * ACF.VelScale, 2))

				if self.Firing then AttemptFire(self) end
			end
		end)
	else -- No available crate to pull ammo from, out of ammo!
		self.CurrentShot = 0
		self.BulletData = {
			Type = "Empty",
			PropMass = 0,
			ProjMass = 0,
			Tracer = 0,
		}

		SetState(self, "Empty")

		WireLib.TriggerOutput(self, "Shots Left", 0)
	end
end

function ENT:Unload()
	if self.Disabled then return end

	SetState(self, "Reloading")

	self.CurrentShot = 0
	self:EmitSound("weapons/357/357_reload4.wav", 500, 100)

	timer.Simple(self.ReloadTime * 0.5, function()
		if IsValid(self) then
			SetState(self, "Empty")
		end
	end)
end

function ENT:Think()
	if next(self.Crates) then
		local Pos = self:GetPos()

		for Crate in pairs(self.Crates) do
			if Crate:GetPos():DistToSqr(Pos) > 62500 then -- 250 unit radius
				self:Unlink(Crate)

				self:EmitSound(UnlinkSound:format(math.random(1, 3)), 500, 100)
				Crate:EmitSound(UnlinkSound:format(math.random(1, 3)), 500, 100)
			end
		end
	end

	self:NextThink(CurTime() + 1)

	return true -- Required to override think time
end

function ENT:UpdateOverlay()
	if timer.Exists("ACF Overlay Buffer" .. self:EntIndex()) then return end

	timer.Create("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
		if IsValid(self) then
			local Status

			if self.DisableReason then
				Status = "Disabled: " .. self.DisableReason
			elseif not next(self.Crates) then
				Status = "Not linked to an ammo crate!"
			else
				Status = self.State
			end

			local AmmoType = self.BulletData.Type .. (self.BulletData.Tracer ~= 0 and "-T" or "")
			local Firerate = math.floor(60 / self.ReloadTime)

			self:SetOverlayText(string.format("%s\n\nStatus: %s\nRate of Fire: %s rpm\nShots Left: %s", AmmoType, Status, Firerate, self.CurrentShot))
		end
	end)
end

function ENT:CanProperty(_, property)
	if property == "bodygroups" then
		local longbarrel = list.Get("ACFClasses").GunClass[self.Class].longbarrel

		if longbarrel ~= nil then
			--need to wait until after the property is actually set
			timer.Simple(0.25, function()
				if self:GetBodygroup(longbarrel.index) == longbarrel.submodel then
					local Muzzle = self:GetAttachment(self:LookupAttachment(longbarrel.newpos))
					self.Muzzle = self:WorldToLocal(Muzzle.Pos)
				else
					local Muzzle = self:GetAttachment(self:LookupAttachment("muzzle"))
					self.Muzzle = self:WorldToLocal(Muzzle.Pos)
				end
			end)
		end
	end

	return true
end

function ENT:OnRemove()
	for Crate in pairs(self.Crates) do
		self:Unlink(Crate)
	end

	WireLib.Remove(self)
end

--===============================================================================================--
-- Duplicator Support
--===============================================================================================--

function ENT:PreEntityCopy()
	if next(self.Crates) then
		local Entities = {}

		for Crate in pairs(self.Crates) do
			Entities[#Entities + 1] = Crate:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFCrates", Entities)
	end

	-- Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	local Crates = Ent.EntityMods and Ent.EntityMods.ACFCrates

	if Crates and next(Crates) then
		for _, CrateID in pairs(Crates) do
			local Crate = CreatedEntities[CrateID]

			self:Link(Crate)
		end

		Crates = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end
