AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

util.AddNetworkString("ACF_BlowoutPanel_Debris")

DEFINE_BASECLASS("acf_base_scalable")

local ACF         = ACF
local Classes     = ACF.Classes
local Debug       = ACF.Debug
local Contraption = ACF.Contraption
local TraceLine   = util.TraceLine

local MODEL        = "models/holograms/cube.mdl"
local MATERIAL     = "hunter/myplastic" -- Same as the baseplate
local REACH_TRACES = 16 -- Lines from a crate to the panel; the clear ones say how much of the panel its gas reaches
local EXIT_GRID    = 3 -- Lines per side straight out of the panel, which must find nothing of the vehicle
local EXIT_RANGE   = 240 -- gmu, how far out the way must be clear
local BLOW_SPEED   = 600 -- gmu/s the panel is thrown off at, whatever its size
local MAX_DISTANCE = ACF.LinkDistance * ACF.LinkDistance

local DEBUG_LIFE    = 4
local COLOR_CLEAR   = Color(80, 220, 80)
local COLOR_BLOCKED = Color(255, 60, 60)

Contraption.CostSystem.RegisterClassBulk("acf_blowout_panel", "armor") -- Priced like the armor it's made of

-- Scalable entities can't be armored, so the mass the armor would have is set here
local function UpdatePlateMass(Entity)
	local Size      = Entity:GetSize()
	local ArmorType = Classes.GetSubtypeByName("ACF.ArmorTypes.BaseArmorType", "ACF.ArmorTypes." .. Entity.ConvexMaterial)

	Contraption.SetMass(Entity, Size.x * Size.y * Size.z * ArmorType.Density * ACF.gCmToKgIn)
end

do -- MARK: Spawning
	function ENT:ACF_PreSpawn()
		self:SetScaledModel(MODEL)
		self:SetMaterial(MATERIAL)
	end

	function ENT:ACF_PostUpdateEntityData()
		self:SetSize(Vector(self:ACF_GetUserVar("PanelLength"), self:ACF_GetUserVar("PanelWidth"), self:ACF_GetUserVar("PanelThickness") * ACF.MmToInch))

		if not self:IsBlownOut() then UpdatePlateMass(self) end

		self:ACF_SetEntityName("ACF Blow-out Panel")
	end
end

do -- MARK: Links
	ACF.RegisterClassLink("acf_blowout_panel", "acf_ammo", function(Panel, Crate)
		local Crates = Panel:ACF_GetUserVar("AmmoCrates")

		if Crates[Crate] then return false, "This panel is already linked to this crate." end
		if Crate:GetPos():DistToSqr(Panel:GetPos()) > MAX_DISTANCE then return false, "This crate is too far from the panel." end

		Crates[Crate] = true

		Crate.BlowoutPanels = Crate.BlowoutPanels or {}
		Crate.BlowoutPanels[Panel] = true

		Panel:UpdateOverlay(true)

		return true, "Panel linked successfully."
	end)

	ACF.RegisterClassUnlink("acf_blowout_panel", "acf_ammo", function(Panel, Crate)
		local Crates = Panel:ACF_GetUserVar("AmmoCrates")

		if not Crates[Crate] then return false, "This panel isn't linked to this crate." end

		Crates[Crate] = nil

		if Crate.BlowoutPanels then Crate.BlowoutPanels[Panel] = nil end

		Panel:UpdateOverlay(true)

		return true, "Panel unlinked successfully."
	end)

	ACF.RegisterClassLinkCheck("acf_blowout_panel", "acf_ammo", function(Panel, Crate)
		if Crate:GetPos():DistToSqr(Panel:GetPos()) > MAX_DISTANCE then return false, "This crate is too far from the panel." end

		return true
	end)

	function ENT:OnRemove(...)
		for Crate in pairs(self:ACF_GetUserVar("AmmoCrates") or {}) do
			if IsValid(Crate) and Crate.BlowoutPanels then Crate.BlowoutPanels[self] = nil end
		end

		BaseClass.OnRemove(self, ...)
	end
end

do -- MARK: Venting
	local Result    = {}
	local TraceData = { start = Vector(), endpos = Vector(), output = Result }
	local Trace     = {} -- The panel, crate and vehicle being traced for, kept here so the filters aren't rebuilt for every line

	-- Racks of ammo stand in the gas's way without holding it back
	local function ReachFilter(Entity)
		if Entity == Trace.Panel or Entity == Trace.Crate or Entity:IsPlayer() or ACF.IsInvisibleToTrace(Entity) then return false end

		local Class = Entity:GetClass()

		return Class ~= "acf_ammo" and Class ~= "acf_autoloader"
	end

	-- Only the vehicle's own parts can block the way out, and not ones already blown off
	local function ExitFilter(Entity)
		return Entity ~= Trace.Panel and not ACF.IsInvisibleToTrace(Entity) and Trace.Contraption ~= nil and Entity:CFW_GetContraption() == Trace.Contraption
	end

	local function RandomPoint(Entity)
		local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
		local Center     = (Mins + Maxs) * 0.5
		local Point      = Vector(math.Rand(Mins.x, Maxs.x), math.Rand(Mins.y, Maxs.y), math.Rand(Mins.z, Maxs.z))

		return Entity:LocalToWorld(Center + (Point - Center) * 0.8)
	end

	-- The thin side facing away from the crate is the one that gives way: 1 for the panel's top, -1 for its bottom
	local function GetSide(Panel, Crate)
		return (Panel:WorldSpaceCenter() - Crate:WorldSpaceCenter()):Dot(Panel:GetUp()) >= 0 and 1 or -1
	end

	-- Fraction of the panel the crate's gas reaches, by lines between random points in each
	local function GetReach(Panel, Crate)
		local Clear = 0
		local Draw  = Debug.SetDeveloperLevel(2)

		Trace.Panel, Trace.Crate = Panel, Crate
		TraceData.filter = ReachFilter

		for _ = 1, REACH_TRACES do
			TraceData.start  = RandomPoint(Crate)
			TraceData.endpos = RandomPoint(Panel)

			TraceLine(TraceData)

			if not Result.Hit then Clear = Clear + 1 end
			if Draw then Debug.Line(TraceData.start, Result.HitPos, DEBUG_LIFE, Result.Hit and COLOR_BLOCKED or COLOR_CLEAR) end
		end

		return Clear / REACH_TRACES
	end

	-- A panel opening onto the vehicle's own armor would let the gas out into it, not out of the vehicle
	local function IsExitClear(Panel, Side)
		local Mins, Maxs = Panel:OBBMins(), Panel:OBBMaxs()
		local Face       = Side > 0 and Maxs.z or Mins.z
		local Outward    = Panel:GetUp() * Side

		Trace.Panel, Trace.Contraption = Panel, Panel:CFW_GetContraption()
		TraceData.filter = ExitFilter

		local Draw = Debug.SetDeveloperLevel(2)

		for I = 1, EXIT_GRID do
			for J = 1, EXIT_GRID do
				local Local = Vector(Lerp((I - 0.5) / EXIT_GRID, Mins.x, Maxs.x), Lerp((J - 0.5) / EXIT_GRID, Mins.y, Maxs.y), Face)
				local Start = Panel:LocalToWorld(Local)

				TraceData.start  = Start
				TraceData.endpos = Start + Outward * EXIT_RANGE

				TraceLine(TraceData)

				local Blocked = Result.Hit and not Result.HitWorld

				if Draw then Debug.Line(Start, Result.HitPos, DEBUG_LIFE, Blocked and COLOR_BLOCKED or COLOR_CLEAR) end
				if Blocked then return false end
			end
		end

		return true
	end

	--- @param Reach number|nil Share of the panel the crate's gas reaches, if a survey already found it; traced here if not.
	--- @return number # Area in m² the panel opens for a crate's cookoff, 0 if it can't blow out for it.
	--- One already blown out or shot away adds nothing here, the survey already finds the opening it left.
	function ENT:GetVentArea(Crate, Reach)
		if self:IsBlownOut() or ACF.IsDestroyed(self) or not IsExitClear(self, GetSide(self, Crate)) then return 0 end

		local Size = self:GetSize()

		return Size.x * Size.y * ACF.InchToMeter ^ 2 * (Reach or GetReach(self, Crate))
	end

	--- Holds a cookoff's gas until it opens, whatever its armor; its opening is counted on its own.
	function ENT:ACF_HoldsGas()
		return not self:IsBlownOut()
	end

	--- Throws the panel off the vehicle, leaving the opening a crate's cookoff vents through.
	--- The entity stays, hidden, weightless and passed through by everything but traces, so the torch can find it
	--- and a full repair can put it back.
	function ENT:BlowOut(Crate)
		if self:IsBlownOut() then return end

		self.ACF.Health           = 0
		self.ACF_InvisibleToTrace = true
		self.ACF_FittedCollision  = self:GetCollisionGroup()

		self:SetNW2Bool("ACF_BlownOut", true)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD) -- Players and props go through it, traces still hit it

		Contraption.SetMass(self, ACF.MinimumMass)

		if Debug.SetDeveloperLevel(1) then Debug.EntityText(self, 0, "Blown out", DEBUG_LIFE, COLOR_CLEAR) end

		net.Start("ACF_BlowoutPanel_Debris")
		net.WriteEntity(self)
		net.WriteVector(self:GetUp() * GetSide(self, Crate) * BLOW_SPEED + self:GetAncestor():GetVelocity())
		net.SendPVS(self:GetPos())

		ACF.RefreshCondition(self)

		self:UpdateOverlay(true)
	end

	-- Refitted once fully repaired
	function ENT:ACF_OnRepaired()
		if not self:IsBlownOut() or self.ACF.Health < self.ACF.MaxHealth then return end

		self.ACF_InvisibleToTrace = nil

		self:SetNW2Bool("ACF_BlownOut", false)
		self:SetCollisionGroup(self.ACF_FittedCollision or COLLISION_GROUP_NONE)

		UpdatePlateMass(self)

		self:UpdateOverlay(true)
	end

	function ENT:ACF_UpdateOverlayState(State)
		local Size    = self:GetSize()
		local Crates  = self:ACF_GetUserVar("AmmoCrates") or {}
		local Linked  = 0
		local Blocked = false
		local Reach   = 0

		for Crate in pairs(Crates) do
			if IsValid(Crate) then
				Linked = Linked + 1
				Reach  = Reach + GetReach(self, Crate)

				if not IsExitClear(self, GetSide(self, Crate)) then Blocked = true end
			end
		end

		State:AddKeyValue("Thickness", ("%s mm RHA"):format(self:ACF_GetUserVar("PanelThickness")))
		State:AddKeyValue("Area", ("%s m²"):format(math.Round(Size.x * Size.y * ACF.InchToMeter ^ 2, 2)))
		State:AddKeyValue("Linked Crates", Linked)

		if self:IsBlownOut() then
			State:AddWarning("Blown out, repair it fully with the torch to refit it")
		elseif Linked == 0 then
			State:AddWarning("Not linked to any ammo crate")
		elseif Blocked then
			State:AddWarning("The vehicle is in the way outside, it can't blow out")
		else
			State:AddKeyValue("Gas Reaching It", ("%s%%"):format(math.Round(Reach / Linked * 100)))
		end
	end
end
