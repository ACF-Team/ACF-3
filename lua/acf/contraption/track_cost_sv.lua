local ACF			= ACF
local Contraption	= ACF.Contraption
local Objects		= ACF.Contraption.Objects
local CubicInchToM3	= ACF.InchToMCu
Contraption.CostSystem	= {}
local CostSystem	= Contraption.CostSystem
-- Thank you for most of the base cost logic liddul <3

do
	do	-- Cost Metric Registration
	CostSystem.MainFilter			= {}
	CostSystem.CostSingle			= {}
	CostSystem.CalcBulk				= {}
	CostSystem.BulkOperations		= {}
	CostSystem.PostBulkOperations	= {}

	--[[
		Any entity that is iterated over that does not match these filters AND has ENT:GetCost() defined will still be added to the final cost

		For bulk calculations, assign an identifier to a class using RegisterClassBulk
		Then, make a bulk calculation and assign it to the identifier using RegisterBulkOperation
			- Post should be true ONLY if you need to calculate using the whole list of entities that match this, as it is the last to be done
	]]

	---Registers a class to be in the main filter, doesn't necessarily have a static cost
	---@param Class	string	The class to register
	function CostSystem.RegisterClass(Class)
		CostSystem.MainFilter[Class] = true
	end

	---Registers a class to have a single cost per each of these
	---@param Class	string	The class to register
	---@param Cost	number	The amount per entity matching this class
	function CostSystem.RegisterClassSingle(Class, Cost)
		CostSystem.RegisterClass(Class)

		CostSystem.CostSingle[Class] = Cost or 0
	end

	---Registers a class to have a bulk calculation, using an identifier
	---@param Class			string	The class to register
	---@param Identifier	string	The ID to associate the class to
	function CostSystem.RegisterClassBulk(Class, Identifier)
		CostSystem.RegisterClass(Class)

		CostSystem.CalcBulk[Class] = Identifier
	end

	---Registers a function to be used for bulk calculations, using an identifier
	---@param Identifier	string	The ID for classes to match to
	---@alias Post
	---|true	# Provides a table of all of the entities that match the identifier to PostBulkOperations, after cost calculations are performed
	---|false	# Provides an entity that matches the identifier to BulkOperations, during cost calculations
	---@param Post			boolean
	---@param BulkOperation	function	A function that has a different type parameter depending on the value of Post
	function CostSystem.RegisterBulkOperation(Identifier, Post, BulkOperation)
		if Post then
			CostSystem.PostBulkOperations[Identifier] = BulkOperation
		else
			CostSystem.BulkOperations[Identifier] = BulkOperation
		end
	end
end
end

do	-- Actual registration for known things
	do	-- Armor registration
		local ArmorTypes = ACF.Classes.ArmorTypes

		CostSystem.RegisterBulkOperation("armor", false, function(entity)
			local MeshData = entity.ACF_Volumetric_Mesh

			if MeshData then
				local Cost = 0

				for _, Convex in ipairs(MeshData.Convexes) do
					local ArmorType = ArmorTypes.Get(Convex.Material) or ArmorTypes.Get("Default")

					Cost = Cost + Convex.Volume * CubicInchToM3 * ArmorType.CostMul -- Convex.Volume is in^3, CostMul is points/m^3
				end

				return Cost
			end
		end)

		CostSystem.RegisterClassBulk("prop_physics", "armor")
		CostSystem.RegisterClassBulk("primitive_shape", "armor")
		CostSystem.RegisterClassBulk("primitive_staircase", "armor")
		CostSystem.RegisterClassBulk("primitive_ladder", "armor")
		CostSystem.RegisterClassBulk("primitive_rail_slider", "armor")
		CostSystem.RegisterClassBulk("primitive_airfoil", "armor")
		CostSystem.RegisterClassBulk("primitive_convex_hull", "armor")
		CostSystem.RegisterClassBulk("starfall_prop", "armor")
		CostSystem.RegisterClassBulk("acf_baseplate", "armor")
	end

	do	-- Script registration, allows up to FreeChips for free before costing more, with a scaling cost
		local FreeChips = 3

		CostSystem.RegisterBulkOperation("script", true, function(entlist)
			local Cost		= 0
			local Crisps	= #entlist - FreeChips

			if Crisps > 0 then
				Cost = math.Round(math.max(0.75, (Crisps * 0.75) ^ 1.5), 2)
			end

			return Cost
		end)

		CostSystem.RegisterClassBulk("gmod_wire_expression2", "script")
		CostSystem.RegisterClassBulk("starfall_processor", "script")
	end
end

--------------------------------------------------------------------------------

local CostFilter = {}
CostFilter["acf_radar"] = function(E)
	local ID = E.ShortName

	if CostSystem.ACFRadars[ID] then
		return CostSystem.ACFRadars[ID]
	else
		return 50
	end
end

--------------------------------------------------------------------------------

do	-- Actual cost functions
	--- Computes cost and breakdown given a contraption
	function CostSystem.CalcCostsFromContraption(Contraption)
		if not Contraption then ACF.DumpStack("Attempted to calculate contraption cost with no valid contraption.") return 0, {} end

		if not Contraption.CostObj then Objects.Cost(Contraption) end

		return Contraption.CostObj:Compute()
	end

	--- Computes cost and breakdown given a list of entities
	function CostSystem.CalcCostsFromEnts(Ents)
		if not next(Ents) then ACF.DumpStack("Attempted to compute cost without ent list") return 0, {} end

		return CostSystem.CalcCostsFromContraption(ACF.EntitiesToPseudoContraption(Ents))
	end

	local FlatPlayerCost = 20

	--- Single source of truth for a player's point cost: always the flat rate. Whether that cost
	--- should be waived (e.g. a victim killed in a vehicle) is up to the caller, not this function.
	--- @param Player player The player to compute a cost for
	--- @return number Cost The player's point cost
	function CostSystem.GetPlayerCost(Player)
		if not IsValid(Player) or not Player:IsPlayer() then return 0 end

		return FlatPlayerCost
	end

	--- An attacker's point cost: their current contraption's cost while seated in one (a kill made
	--- from a vehicle is worth what the vehicle is worth), otherwise the flat rate.
	--- @param Player player The attacking player to compute a cost for
	--- @return number Cost The attacker's point cost
	function CostSystem.GetAttackerCost(Player)
		if not IsValid(Player) or not Player:IsPlayer() then return 0 end

		local Vehicle = Player:GetVehicle()
		if IsValid(Vehicle) and Vehicle.CFW_GetContraption then
			local Contraption = Vehicle:CFW_GetContraption()
			if Contraption then
				return (CostSystem.CalcCostsFromContraption(Contraption))
			end
		end

		return FlatPlayerCost
	end

	--- Bills a contraption's point value once, to whichever kill entry claims it first.
	--- @param Contraption table The contraption to bill
	--- @param Baseplate entity Carries the claim, since CFW hands entities to new contraption tables on splits
	--- @return number Cost The contraption's cost the first time it's claimed, 0 after that
	function CostSystem.ClaimContraptionCost(Contraption, Baseplate)
		if not Contraption or not IsValid(Baseplate) then return 0 end
		if Baseplate.ACF_CostClaimed then return 0 end

		Baseplate.ACF_CostClaimed = true

		-- ACF_LastCost is the pre-destruction snapshot; recomputing now would undercount removed ents
		return Contraption.ACF_LastCost or (CostSystem.CalcCostsFromContraption(Contraption))
	end

	--- A victim's point cost: their flat cost, plus their contraption's if this death bills it first.
	--- @param Player player The dying player to compute a cost for
	--- @return number Cost The victim's point cost
	function CostSystem.ClaimVictimCost(Player)
		if not IsValid(Player) or not Player:IsPlayer() then return 0 end

		local Cost = CostSystem.GetPlayerCost(Player)
		local Vehicle = Player:GetVehicle()

		if IsValid(Vehicle) and Vehicle.CFW_GetContraption then
			local Contraption = Vehicle:CFW_GetContraption()
			if Contraption then
				Cost = Cost + CostSystem.ClaimContraptionCost(Contraption, Contraption.ACF_Baseplate)
			end
		end

		return Cost
	end
end

--------------------------------------------------------------------------------

do	-- CFW Hooks

	-- Custom information to track on contraptions
	-- Not all of this is directly related to cost
	hook.Add("cfw.contraption.created", "ACF_CFW_CostTrack", function(Contraption)
		-- print("cfw.contraption.created", Contraption)
		Contraption.AmmoTypes = {} -- Index ammo types (Estimate of firepower)

		Contraption.CostObj	= Objects.Cost(Contraption)
	end)

	hook.Add("cfw.contraption.entityAdded", "ACF_CFW_CostTrack", function(Contraption, Entity)
		-- print("cfw.contraption.entityAdded", Contraption, Entity)
		if Entity.IsACFEntity and Entity.IsACFAmmoCrate then
			Contraption.AmmoTypes[Entity.AmmoType] = true
		end
	end)
end

--------------------------------------------------------------------------------

do -- Cost limit enforcement
	local CostLimitSettings = { GroundVehicle = "CostLimitGround", Aircraft = "CostLimitAir" }

	-- Destroys a contraption that exceeds the cost limit for its baseplate type, same as an all-crew-killed death
	function ACF.EnforceCostLimit(Contraption)
		if not Contraption then return end

		local Baseplate = Contraption.ACF_Baseplate
		if not IsValid(Baseplate) then return end

		local BaseplateType = Baseplate:ACF_GetUserVar("BaseplateType")
		local Setting = BaseplateType and CostLimitSettings[BaseplateType.ID]
		if not Setting then return end

		local CostLimit = ACF[Setting]
		if CostLimit == 0 then return end

		local Cost = CostSystem.CalcCostsFromContraption(Contraption)
		if Cost <= CostLimit then return end

		local Owner = Baseplate:CPPIGetOwner()
		if IsValid(Owner) and Owner:IsPlayer() then
			-- Feeds the same fields real damage would set, so the vehicle kill feed picks this up too
			Contraption.ACF_LastDamageAttacker = Owner
			Contraption.ACF_LastCost = Cost
		end

		ACF.DestroyContraption(Contraption, Baseplate:GetPos(), vector_up, 100000)
	end

	-- Contraptions are only worth checking once they've actually been driven
	hook.Add("PlayerEnteredVehicle", "ACF_FlagCostLimitUsed", function(_, Vehicle)
		if not IsValid(Vehicle) then return end

		local Contraption = Vehicle:CFW_GetContraption()
		if not Contraption then return end

		Contraption.ACF_CostLimitUsed = true
	end)

	-- Periodically re-check used contraptions, since cost can change after entering (repairs, respawns, etc)
	ACF.AugmentedTimer(
		function()
			local Contraptions = CFW and CFW.Contraptions or {}
			for Con in pairs(Contraptions) do
				if not Con.ACF_CostLimitUsed then continue end

				ACF.EnforceCostLimit(Con)
			end
		end,
		nil,
		nil,
		{ MinTime = 5, MaxTime = 10 }
	)
end