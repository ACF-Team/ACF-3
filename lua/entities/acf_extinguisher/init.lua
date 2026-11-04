AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

DEFINE_BASECLASS("acf_base_scalable")

local ACF           = ACF
local Damage        = ACF.Damage
local Fire          = Damage.Fire
local Debug         = ACF.Debug
local Contraption   = ACF.Contraption
local Sounds        = ACF.Utilities.Sounds
local Extinguishers = ACF.Extinguishers

local MODEL        = "models/acf/core/s_ammo_cyl.mdl"
local MATERIAL     = "phoenix_storms/mat/mat_phx_metallic"
local COLOR        = Color(170, 25, 25)
local REACH_SHRINK = 0.8 -- Share of the way out to its corners the lines to a target aim, so they land inside it rather than graze it
local IDLE_THINK   = 1 -- Seconds between checks while nothing is pending
local SOUND        = "ambient/machines/steam_release_2.wav"
local MAX_DISTANCE = ACF.LinkDistance * ACF.LinkDistance

local DEBUG_LIFE    = 4
local COLOR_AGENT   = Color(120, 200, 255)
local COLOR_BLOCKED = Color(255, 60, 60)

local function GetAgentMass(Entity)
	return Entity:ACF_GetUserVar("AgentMass")
end

-- A bottle is either full (1) or empty (0), so it's never left with a sliver of agent; supply crates refill it whole
local function SetFilled(Entity, Amount)
	Entity.Amount = math.Clamp(Amount, 0, Entity.Capacity)

	Contraption.SetMass(Entity, ACF.GetExtinguisherMass(GetAgentMass(Entity), Entity.Amount))
end

do -- MARK: Spawning
	function ENT:ACF_PreSpawn()
		self:SetScaledModel(MODEL)
		self:SetMaterial(MATERIAL)
		self:SetColor(COLOR)
	end

	function ENT:ACF_PostUpdateEntityData()
		self:SetSize(ACF.GetExtinguisherSize(GetAgentMass(self)))

		self.Capacity = 1

		SetFilled(self, self.Amount or self.Capacity) -- Fresh and duped bottles come full

		Extinguishers[self] = true

		self:InvalidateClientInfo()

		self:ACF_SetEntityName("ACF Fire Extinguisher")
	end

	function ENT:GetCost()
		return GetAgentMass(self) * ACF.ExtinguisherCost
	end
end

do -- MARK: Links
	for Class in pairs(ENT.ACF_WatchedClasses) do
		ACF.RegisterClassLink("acf_extinguisher", Class, function(Extinguisher, Target)
			local Watched = Extinguisher:ACF_GetUserVar("Watched")

			if Watched[Target] then return false, "This extinguisher is already linked to this entity." end
			if Target:GetPos():DistToSqr(Extinguisher:GetPos()) > MAX_DISTANCE then return false, "This entity is too far from the extinguisher." end

			Watched[Target] = true

			Extinguisher:InvalidateClientInfo()
			Extinguisher:UpdateOverlay(true)

			return true, "Extinguisher linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_extinguisher", Class, function(Extinguisher, Target)
			local Watched = Extinguisher:ACF_GetUserVar("Watched")

			if not Watched[Target] then return false, "This extinguisher isn't linked to this entity." end

			Watched[Target] = nil

			Extinguisher:InvalidateClientInfo()
			Extinguisher:UpdateOverlay(true)

			return true, "Extinguisher unlinked successfully."
		end)

		ACF.RegisterClassLinkCheck("acf_extinguisher", Class, function(Extinguisher, Target)
			if Target:GetPos():DistToSqr(Extinguisher:GetPos()) > MAX_DISTANCE then return false, "This entity is too far from the extinguisher." end

			return true
		end)
	end

	--- @return boolean # Whether the bottle is set off when the entity catches fire or gets too hot: itself, or one linked to it.
	function ENT:IsWatching(Entity)
		return Entity == self or (self:ACF_GetUserVar("Watched") or {})[Entity] == true
	end

	function ENT:OnRemove(...)
		Extinguishers[self] = nil

		BaseClass.OnRemove(self, ...)
	end
end

do -- MARK: Discharging
	local Ignore = {}
	local Trace  = {} -- What the line being traced is for, so its visitor isn't rebuilt for every line

	-- Components stand in the agent's way without holding it back; armor and closed blow-out panels hold it in
	local function Visit(Result)
		local Hit = Result.Entity

		if Hit == Trace.Target then return true end
		if Hit:CFW_GetContraption() ~= Trace.Contraption or ACF.IsInvisibleToTrace(Hit) then return end

		if (Hit.ACF_HoldsGas and Hit:ACF_HoldsGas()) or (Fire.IsStructure(Hit) and Damage.GetSolidArmor(Hit, Result.HitPos, Trace.Direction) > 0) then
			Trace.Blocked = true

			return true
		end
	end

	-- The target's middle, then its eight corners; the same points every time, so what the bottle is shown to reach is
	-- what it does reach
	local function GetAimPoint(Entity, Index)
		local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
		local Center     = (Mins + Maxs) * 0.5

		if Index == 1 then return Entity:LocalToWorld(Center) end

		local Corner = Index - 2
		local Point  = Vector(Corner % 2 == 0 and Mins.x or Maxs.x, Corner % 4 < 2 and Mins.y or Maxs.y, Corner < 4 and Mins.z or Maxs.z)

		return Entity:LocalToWorld(Center + (Point - Center) * REACH_SHRINK)
	end

	-- Whether agent let out of the bottle gets to the target: close enough, and with a way to it walls don't close off
	local function Reaches(Bottle, Center, Range, Target, Draw)
		if Target:NearestPoint(Center):DistToSqr(Center) > Range * Range then return false end

		Ignore[1] = Bottle
		Trace.Target, Trace.Contraption = Target, Bottle:CFW_GetContraption()

		for I = 1, 9 do
			local Point = GetAimPoint(Target, I)

			Trace.Direction, Trace.Blocked = (Point - Center):GetNormalized(), false

			Damage.PierceLine(Center, Point, Ignore, Visit, true)

			if Draw then Debug.Line(Center, Point, DEBUG_LIFE, Trace.Blocked and COLOR_BLOCKED or COLOR_AGENT) end
			if not Trace.Blocked then return true end
		end

		return false
	end

	local function GetTargets(Bottle)
		local Owner = Bottle:CFW_GetContraption()

		return Owner and Owner.ACF_Entities or {}
	end

	--- Floods the space around the bottle with agent: every fire it reaches that agent can put out goes out, and what it
	--- reached can't catch fire again for a while. It reaches as far as the agent fills at its design concentration,
	--- wherever walls don't close the way off.
	--- @param Agent number kg of agent released.
	function ENT:Release(Agent)
		local Center = self:WorldSpaceCenter()
		local Range  = ACF.GetExtinguisherReach(Agent)
		local Inert  = CurTime() + ACF.ExtinguisherHoldTime
		local Draw   = Debug.SetDeveloperLevel(1)

		for Target in pairs(GetTargets(self)) do
			if Target ~= self and IsValid(Target) and Fire.IsSuppressible(Target) and Reaches(self, Center, Range, Target, Draw) then
				Target.ACF_InertUntil = Inert

				Fire.Extinguish(Target)
			end
		end

		Sounds.SendSound(self, SOUND, 75, 100, 1)

		if Draw then
			Debug.Sphere(Center, Range, DEBUG_LIFE, COLOR_AGENT)
			Debug.EntityText(self, 0, ("Discharged %.1f kg"):format(Agent), DEBUG_LIFE, COLOR_AGENT)
		end
	end

	--- @return boolean # Whether a fire its agent can put out still burns within its reach. Bottles discharge one after
	--- another, so once one has put a fire out the rest set off by it find nothing left and keep their agent.
	function ENT:FindFire()
		local Center = self:WorldSpaceCenter()
		local Range  = ACF.GetExtinguisherReach(GetAgentMass(self))

		for Target in pairs(GetTargets(self)) do
			if Target ~= self and IsValid(Target) and Fire.IsBurning(Target) and Fire.IsSuppressible(Target) and Reaches(self, Center, Range, Target) then
				return true
			end
		end

		return false
	end

	--- @return boolean # Whether anything on the bottle's vehicle still burns, whatever it is and wherever it is.
	--- The heat that set a bottle off was read before other bottles had their turn, so it only still counts if a fire
	--- is left to give it off.
	function ENT:IsFireLeft()
		local Owner = self:CFW_GetContraption()

		if not Owner then return false end

		for Entity in pairs(Fire.Burning) do
			if IsValid(Entity) and Entity:CFW_GetContraption() == Owner then return true end
		end

		return false
	end

	--- @return boolean # Whether the bottle's agent would get to the entity if it were on fire. Only fires on the
	--- bottle's own vehicle are put out.
	function ENT:CanReach(Target)
		if not IsValid(Target) or Target:CFW_GetContraption() ~= self:CFW_GetContraption() then return false end

		return Reaches(self, self:WorldSpaceCenter(), ACF.GetExtinguisherReach(GetAgentMass(self)), Target)
	end

	--- @return boolean # Whether the bottle still holds its agent and can let it out.
	function ENT:IsReady()
		return self.Amount > 0 and ACF.IsOperational(self)
	end

	--- Lets the agent out, if the bottle still holds it.
	--- @return boolean # Whether it discharged.
	function ENT:Discharge()
		if not self:IsReady() then return false end

		SetFilled(self, 0)

		self:Release(GetAgentMass(self))
		self:UpdateOverlay()

		return true
	end

	--- Sets the bottle off. It decides on its next think, as this is called while fires tick and heat spreads, and
	--- putting fires out in the middle of that would leave them half counted.
	--- @param Entity entity What it noticed: itself, or a component linked to it.
	--- @param Flux number|nil W/m² heating it, nil when it caught fire.
	function ENT:Detect(Entity, Flux)
		if not self:IsReady() then return end

		-- Heat this close to flames sets it off even with no fire it can put out, as it would its own detector
		if Entity == self and Flux and Flux >= ACF.ExtinguisherOverrideFlux then self.Overheated = true end

		if self.Alarmed then return end

		self.Alarmed = true

		self:NextThink(CurTime())
	end

	-- A destroyed bottle lets out its agent at once
	hook.Add("ACF_OnEntityDestroyed", "ACF_Extinguisher", function(Entity)
		if not Entity.IsACFExtinguisher or Entity.Amount <= 0 then return end

		Entity.Ruptured = true

		Entity:NextThink(CurTime())
	end)

	function ENT:Think()
		if self.Ruptured then
			self.Ruptured, self.Alarmed, self.Overheated = nil, nil, nil

			SetFilled(self, 0)

			self:Release(GetAgentMass(self))
			self:UpdateOverlay()
		elseif self.Alarmed then
			local Overheated = self.Overheated

			self.Alarmed, self.Overheated = nil, nil

			if (Overheated and self:IsFireLeft()) or self:FindFire() then self:Discharge() end
		end

		self:NextThink(CurTime() + IDLE_THINK)

		return true
	end

	-- Agent supply crates hand over, a whole bottle at a time
	function ENT:GetUnitMass()
		return GetAgentMass(self)
	end

	function ENT:Consume(Amount)
		SetFilled(self, self.Amount - Amount)

		self:UpdateOverlay()
	end
end

do -- MARK: Overlay
	-- What stands between the bottle and its linked components can change without the bottle changing, so its overlay
	-- is worked out afresh whenever someone starts looking at it
	function ENT:GetOverlayState()
		self:UpdateOverlay(true)

		return BaseClass.GetOverlayState(self)
	end

	function ENT:ACF_UpdateOverlayState(State)
		local AgentMass = GetAgentMass(self)
		local Linked    = 0
		local Unreached = 0

		for Target in pairs(self:ACF_GetUserVar("Watched") or {}) do
			if IsValid(Target) then
				Linked = Linked + 1

				if not self:CanReach(Target) then Unreached = Unreached + 1 end
			end
		end

		State:AddHealth("Agent", AgentMass * self.Amount, AgentMass, " kg")

		-- Each a short line; holding the context menu key explains it
		local function AddWarning(Id)
			local Title = ACF.Diagnostics.Describe(Id)

			State:AddWarning(Title, Id)
		end

		if self.Amount <= 0 and not ACF.IsDestroyed(self) then AddWarning("extinguisher_empty") end

		State:AddKeyValue("Radius", ("%s m"):format(math.Round(ACF.GetExtinguisherReach(AgentMass) * ACF.InchToMeter, 2)))
		State:AddKeyValue("Linked Components", Linked)

		if Unreached > 0 then AddWarning("extinguisher_unreached") end
	end
end

do -- MARK: Client info
	util.AddNetworkString("ACF_RequestExtinguisherInfo")
	util.AddNetworkString("ACF_InvalidateExtinguisherInfo")

	function ENT:InvalidateClientInfo()
		net.Start("ACF_InvalidateExtinguisherInfo")
			net.WriteEntity(self)
		net.Broadcast()
	end

	-- What the menu tool draws while the bottle is looked at: how far its agent reaches and what sets it off
	net.Receive("ACF_RequestExtinguisherInfo", function(_, Ply)
		local Entity = net.ReadEntity()

		if not IsValid(Entity) or not Entity.IsACFExtinguisher then return end

		local Watched = {}

		for Target in pairs(Entity:ACF_GetUserVar("Watched") or {}) do
			if IsValid(Target) then Watched[#Watched + 1] = Target end
		end

		local Count = math.min(#Watched, 255)

		net.Start("ACF_RequestExtinguisherInfo")
			net.WriteEntity(Entity)
			net.WriteFloat(ACF.GetExtinguisherReach(GetAgentMass(Entity)))
			net.WriteUInt(Count, 8)

			for I = 1, Count do
				net.WriteUInt(Watched[I]:EntIndex(), MAX_EDICT_BITS)
				net.WriteBool(Entity:CanReach(Watched[I]))
			end
		net.Send(Ply)
	end)
end
