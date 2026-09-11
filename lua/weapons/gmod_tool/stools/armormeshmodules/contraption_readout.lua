-- Runs on both realms: attaches TOOL:GetContraptionReadout directly onto the global TOOL table set up
-- by the stool loader, so no explicit return/wiring is needed from the main file.
local Contraption = ACF.Contraption
local Messages    = ACF.Utilities.Messages

-- Filters a raw entity list into a pseudo-contraption and delegates tally/mass work to CalcMassRatioFromContraption.
-- Owner tracking stays here because it has no equivalent in the shared contraption path.
local function ProcessList(Entities)
	local ValidEnts  = {}
	local ValidCount = 0
	local OtherNum   = 0
	local SeenOwners = {}
	local Owners     = {}
	local OwnerNum   = 0

	for _, Ent in ipairs(Entities) do
		if not ACF.Check(Ent) then
			if not Ent:IsWeapon() then OtherNum = OtherNum + 1 end
		elseif not (Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot()) then
			ValidCount            = ValidCount + 1
			ValidEnts[ValidCount] = Ent

			local Owner = Ent:CPPIGetOwner() or game.GetWorld()

			if (IsValid(Owner) or Owner:IsWorld()) and not SeenOwners[Owner] then
				local Name           = Owner:GetName()
				OwnerNum             = OwnerNum + 1
				Owners[OwnerNum]     = Name ~= "" and Name or "World"
				SeenOwners[Owner]    = true
			end
		end
	end

	local PseudoCon = ACF.EntitiesToPseudoContraption(ValidEnts)
	local Power, Fuel, PhysNum, ParNum, ConNum, ExtraOther, Total, PhysTotal = Contraption.CalcMassRatioFromContraption(PseudoCon, true)
	local Name = next(Owners) and table.concat(Owners, ", ") or "None"

	return Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum + ExtraOther, Total, PhysTotal
end

local Modes = {
	Default = {
		CanCheck = function(_, Trace)
			local Ent = Trace.Entity

			if not IsValid(Ent) then return false end
			if Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot() then return false end

			return true
		end,
		GetResult = function(_, Trace)
			local Ent = Trace.Entity
			local Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum = Contraption.CalcMassRatio(Ent, true)

			return Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Ent.acftotal, Ent.acfphystotal
		end,
		GetCost = function(_, Trace)
			if not IsValid(Trace.Entity) then return 0, {} end

			local Contraption_ = Trace.Entity:CFW_GetContraption()
			if Contraption_ then
				return Contraption.CostSystem.CalcCostsFromContraption(Contraption_)
			else
				return Contraption.CostSystem.CalcCostsFromEnts({Trace.Entity})
			end
		end
	},
	Sphere = {
		CanCheck = function(Tool)
			return Tool:GetClientNumber("sphere_radius") > 0
		end,
		-- TODO: The old armor tool's ProcessList walked every entity in the sphere individually to
		-- build this readout; it was dated and unoptimized, so it hasn't been ported yet.
		GetResult = function(Tool, Trace)
			local Ents = ents.FindInSphere(Trace.HitPos, Tool:GetClientNumber("sphere_radius"))
			return ProcessList(Ents)
		end,
		GetCost = function(Tool, Trace)
			local Ents = ents.FindInSphere(Trace.HitPos, Tool:GetClientNumber("sphere_radius"))
			return Contraption.CostSystem.CalcCostsFromEnts(Ents)
		end
	}
}

local function GetReadoutMode(Tool)
	if Modes.Sphere.CanCheck(Tool) then return Modes.Sphere end

	return Modes.Default
end

local Text1 = "--- Contraption Readout (Owner: %s) ---"
local Text2 = "Mass: %s kg total | %s kg physical (%s%%) | %s kg parented"
local Text3 = "Mobility: %s hp/ton @ %s hp | %s liters of fuel"
local Text4 = "Entities: %s (%s physical, %s parented, %s other entities) | %s constraints"
local Text5 = "Name: %s | Type: %s"
local Text6 = "Cost: %s | Ammo: %s"

-- Total up mass of constrained ents
function TOOL:GetContraptionReadout(Trace, UseCostBreakdown)
	local Mode = GetReadoutMode(self)

	if not Mode.CanCheck(self, Trace) then return false end
	if CLIENT then return true end

	local Cost, Breakdown = Mode.GetCost(self, Trace)
	if UseCostBreakdown then
		local Player = self:GetOwner()

		local NiceBreakdown = {}
		for item, cost in pairs(Breakdown) do
			table.insert(NiceBreakdown, {name = item, cost = cost})
		end

		table.sort(NiceBreakdown, function(a, b)
			return a.cost > b.cost
		end)

		Messages.SendChat(Player, nil, "--- Contraption Cost Breakdown ---")

		for _, Item in ipairs(NiceBreakdown) do
			Messages.SendChat(Player, nil, "| " .. Item.name .. ": " .. math.Round(Item.cost, 2))
		end

		Messages.SendChat(Player, nil, "TOTAL COST: ", math.Round(Cost, 2))
	else
		local Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Total, PhysTotal = Mode.GetResult(self, Trace)
		local HorsePower = math.Round(Power / math.max(Total * 0.001, 0.001), 1)
		local PhysRatio = math.Round(100 * PhysTotal / math.max(Total, 0.001))
		local ParentTotal = Total - PhysTotal
		local Player = self:GetOwner()
		local BaseplateName, BaseplateType, AmmoTypes = Contraption.GetMiscInfo(Trace.Entity)
		local AmmoList = next(AmmoTypes) and table.concat(AmmoTypes, ", ") or "N/A"

		Messages.SendChat(Player, nil, Text1:format(Name))
		Messages.SendChat(Player, nil, Text2:format(math.Round(Total, 2), math.Round(PhysTotal, 2), PhysRatio, math.Round(ParentTotal, 2)))
		Messages.SendChat(Player, nil, Text3:format(HorsePower, math.Round(Power), math.Round(Fuel)))
		Messages.SendChat(Player, nil, Text4:format(PhysNum + ParNum + OtherNum, PhysNum, ParNum, OtherNum, ConNum))
		Messages.SendChat(Player, nil, Text5:format(BaseplateName, BaseplateType))
		Messages.SendChat(Player, nil, Text6:format(math.Round(Cost, 2), AmmoList))
	end

	return true
end
