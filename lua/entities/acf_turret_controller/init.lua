AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF
local Contraption	= ACF.Contraption
local Classes		= ACF.Classes

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local DefaultType = "ACF.Turrets.Controller.Lightweight"

do -- Spawning
	--- Resolves the controller class a spawn request is asking for.
	local function GetSpawnClass(Data)
		local ID = Data and Data.Controller

		if istable(ID) then ID = ID.Type end

		return (isstring(ID) and Classes.GetTypeByName(ID)) or Classes.GetTypeByName(DefaultType)
	end

	-- Remote and Lightweight controllers share this entity but keep separate spawn limits,
	-- so the cap depends on which one is being spawned rather than on the entity class.
	function ENT.ACF_CheckSpawnLimit(Player, _, Data)
		local Class = GetSpawnClass(Data)
		local Limit = Class and Class.LimitConVar

		if not Limit then return true end

		return Player:CheckLimit(Limit.Name)
	end

	function ENT:ACF_PreSpawn(_, _, _, Data)
		self.ACF = {}

		Contraption.SetModel(self, GetSpawnClass(Data).Model)
	end

	function ENT:ACF_OnSpawn(Player, _, _, Data)
		self.Active = true

		-- The generic spawn path only counts against "_acf_turret_controller", so the per-type
		-- convar checked above has to be incremented here or it would never fill up.
		local Class = GetSpawnClass(Data)
		local Limit = Class and Class.LimitConVar

		if IsValid(Player) and Limit then
			Player:AddCount(Limit.Name, self)
		end
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		local Controller = self:ACF_GetUserVar("Controller")
		local Class      = Controller:GetType()
		local Group      = Classes.GetBaseClass(Class)

		Contraption.SetModel(self, Class.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self.Name       = Class.Name
		self.ShortName  = Class.ID
		self.EntType    = Group.Name
		self.ClassData  = Group
		self.Class      = Group.ID
		self.Controller = Class.ID
		self.IsRemote   = Class.IsRemote and true or false
		self.Active     = true

		self:SetNWString("WireName", "ACF " .. self.Name)
		self:SetNWString("Class", self.Class)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)

		Contraption.SetMass(self, Class.Mass)
	end
end

do	-- Metamethods
	do	-- Overlay stuff
		function ENT:ACF_UpdateOverlayState(State)
			if self.IsRemote then
				State:AddKeyValue("Linked to", IsValid(self.Crew) and tostring(self.Crew) or "Not linked")
			else
				State:AddKeyValue("Linked to", IsValid(self.Turret) and tostring(self.Turret) or "Not linked")
			end

			if self.Active then
				State:AddKeyValue("Status", "Active")
			else
				State:AddError("Inactive: " .. self.InactiveReason)
			end
		end
	end

	do	-- ACF Funcs
		function ENT:Enable()
			self:SetActive(true, "")
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Active	= false
			self:SetActive(false, "")
			self:UpdateOverlay()
		end

		function ENT:ACF_PostDamage()
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)
		end

		function ENT:ACF_OnRepaired()
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)
		end

		function ENT:SetActive(Active, Reason)
			local Trigger = (self.Active ~= Active) or (self.InactiveReason ~= Reason)
			if not Active then
				self.InactiveReason = Reason
				self.Active = false
			else
				self.InactiveReason = ""
				self.Active = true
			end

			if Trigger then self:UpdateOverlay(true) end
		end

		-- Whether this controller is currently providing its benefit
		function ENT:IsActive()
			if self.Disabled then return false end

			local Linked = self.IsRemote and self.Crew or self.Turret
			if not IsValid(Linked) then self:SetActive(false, "") return false end

			if (self.ACF.Health / self.ACF.MaxHealth) <= 0.25 then
				self:SetActive(false, "Too damaged!")
				return false
			end

			if self.Active == false then self:SetActive(true, "") end
			return true
		end

		function ENT:GetCost()
			return self.IsRemote and 70 or 5
		end
	end

	do	-- Dupe support
		-- Only the Remote variant's crew link is handled here. The Lightweight variant's
		-- turret link is instead re-established by acf_turret's own dupe support, the same
		-- way it already handles its motor/gyro links, since acf_turret is the side without
		-- a periodic Check gate that could reject a paste-time relink before contraption/mass
		-- data has settled
		function ENT:PreEntityCopy()
			if self.IsRemote and IsValid(self.Crew) then
				duplicator.StoreEntityModifier(self, "ACFCrew", {self.Crew:EntIndex()})
			end

			-- Wire dupe info
			self.BaseClass.PreEntityCopy(self)
		end

		function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
			local EntMods = Ent.EntityMods

			if EntMods.ACFCrew then
				self:Link(CreatedEntities[EntMods.ACFCrew[1]])

				EntMods.ACFCrew = nil
			end

			self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		end
	end
end

do	-- Lightweight Turret Controllers link to acf_turret directly, no crew involved
	local MaxDistance = 24 * 24 -- Only close-proximity linking is allowed, tighter than standard ACF.LinkDistance

	ACF.RegisterLinkSource("acf_turret_controller", "Turret")

	ACF.RegisterClassPreLinkCheck("acf_turret_controller", "acf_turret", function(This)
		if This.IsRemote then return false, "Remote Turret Controllers link to crew, not turrets. Link the crew member instead." end
		if IsValid(This.Turret) then return false, "This controller is already linked to a turret." end
		return true
	end)

	ACF.RegisterClassLinkCheck("acf_turret_controller", "acf_turret", function(This, Turret)
		-- ACF.PerformClassLink runs the Check role (this function) before PreLinkCheck, so the
		-- wrong-variant rejection has to be repeated here too, or a Remote controller linking to
		-- a turret could fail with a misleading distance/mass error instead of the real reason
		if This.IsRemote then return false, "Remote Turret Controllers link to crew, not turrets. Link the crew member instead." end

		if This:GetPos():DistToSqr(Turret:GetPos()) > MaxDistance then return false, "This turret is too far from the controller." end

		-- A freshly pasted entity's contraption isn't assigned yet at the moment a paste-time
		-- relink runs, so only reject on an actual mismatch, not on either side still being nil.
		-- Matches the same guard acf_crew's periodic contraption check uses for the same reason
		local ThisContraption = This:CFW_GetContraption()
		local TurretContraption = Turret:CFW_GetContraption()
		if ThisContraption ~= nil and TurretContraption ~= nil and ThisContraption ~= TurretContraption then
			return false, "This controller and turret are not part of the same contraption."
		end

		local CarriedMass = (Turret.TurretData and Turret.TurretData.TotalMass or 0) + (Turret.ACF and Turret.ACF.Mass or 0)
		if CarriedMass > ACF.LightweightTurretMassLimit then return false, "This turret is too heavy for a Lightweight Turret Controller." end

		return true
	end)

	ACF.RegisterClassLink("acf_turret_controller", "acf_turret", function(This, Turret)
		This.Turret = Turret

		Turret.LightweightControllers = Turret.LightweightControllers or {}
		Turret.LightweightControllers[This] = true

		This:UpdateOverlay(true)
		Turret:UpdateOverlay()

		return true, "Lightweight Turret Controller linked successfully."
	end)

	ACF.RegisterClassUnlink("acf_turret_controller", "acf_turret", function(This, Turret)
		if This.Turret ~= Turret then return false, "This controller isn't linked to this turret." end

		This.Turret = nil

		if Turret.LightweightControllers then Turret.LightweightControllers[This] = nil end

		This:UpdateOverlay(true)
		Turret:UpdateOverlay()

		return true, "Lightweight Turret Controller unlinked successfully."
	end)
end

do	-- Remote Turret Controllers link to a Gunner-role crew member
	local MaxDistance = ACF.LinkDistance ^ 2
	local MaxViewAngle = 60 -- Degrees off the controller's position can be from the crew while still counting as being "in front" of them

	-- Crew entities are positioned at their model origin (feet, or lower torso depending on
	-- model), which is a poor reference point for distance/facing/LOS checks against something
	-- placed near head height. ScanOffsetL is the same per-model body-height offset already used
	-- elsewhere (oxygen checks, G-force tracking, gun/rack/ammo crew-position checks).
	local function GetCrewBodyPos(Crew)
		return Crew:LocalToWorld(Crew.CrewModel.ScanOffsetL)
	end

	local function HasLineOfSight(This, Crew)
		local Trace = util.TraceLine({
			start = This:GetPos(),
			endpos = GetCrewBodyPos(Crew),
			filter = {This, Crew},
			mask = MASK_SOLID_BRUSHONLY
		})

		return not Trace.Hit
	end

	-- "In front of the crew member" means the controller sits within the crew's own forward
	-- view cone, not that the controller prop itself is angled toward the crew. Crew models'
	-- angles are authored such that their actual forward-facing direction is -GetRight(), not
	-- GetForward(); GetForward() points out of their side instead
	local function IsInFront(This, Crew)
		local ToController = (This:GetPos() - GetCrewBodyPos(Crew)):GetNormalized()
		local CrewForward = -Crew:GetRight()

		return ToController:Dot(CrewForward) >= math.cos(math.rad(MaxViewAngle))
	end

	ACF.RegisterLinkSource("acf_turret_controller", "Crew")

	-- Distance/facing/LOS only need checking once, at link time: a shared parent means the
	-- controller and crew move together afterwards, so their relative position never changes
	-- on its own. Only the parent relationship itself needs to keep being checked periodically.
	ACF.RegisterClassPreLinkCheck("acf_turret_controller", "acf_crew", function(This, Crew)
		if not This.IsRemote then return false, "Lightweight Turret Controllers link to turrets, not crew." end
		if IsValid(This.Crew) then return false, "This controller is already linked to a crew member." end
		if Crew.CrewTypeID ~= "Gunner" and Crew.CrewTypeID ~= "Commander" and Crew.CrewTypeID ~= "Pilot" then
			return false, "This controller can only link to Gunners, Commanders, or Pilots."
		end
		if This:GetPos():DistToSqr(GetCrewBodyPos(Crew)) > MaxDistance then return false, "This crew member is too far from the controller." end
		if This:GetParent() ~= Crew:GetParent() then return false, "This controller must share a parent with the crew member." end
		if not IsInFront(This, Crew) then return false, "This crew member must be in front of the controller." end
		if not HasLineOfSight(This, Crew) then return false, "This controller must have line of sight to the crew member." end
		return true
	end)

	ACF.RegisterClassLinkCheck("acf_turret_controller", "acf_crew", function(This, Crew)
		-- ACF.PerformClassLink runs the Check role (this function) before PreLinkCheck, so the
		-- wrong-variant rejection has to be repeated here too, or a Lightweight controller linking
		-- to crew could fail with a misleading parent-mismatch error instead of the real reason
		if not This.IsRemote then return false, "Lightweight Turret Controllers link to turrets, not crew." end

		if This:GetParent() ~= Crew:GetParent() then return false, "This controller must share a parent with the crew member." end
		return true
	end)

	ACF.RegisterClassLink("acf_turret_controller", "acf_crew", function(This, Crew)
		This.Crew = Crew
		Crew.RemoteController = This

		This:UpdateOverlay(true)
		Crew:UpdateOverlay()

		return true, "Remote Turret Controller linked successfully."
	end)

	ACF.RegisterClassUnlink("acf_turret_controller", "acf_crew", function(This, Crew)
		if This.Crew ~= Crew then return false, "This controller isn't linked to this crew member." end

		This.Crew = nil
		if Crew.RemoteController == This then Crew.RemoteController = nil end

		This:UpdateOverlay(true)
		Crew:UpdateOverlay()

		return true, "Remote Turret Controller unlinked successfully."
	end)
end
