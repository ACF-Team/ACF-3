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
	ACF.AugmentedTimer(
		function()
			local CostLimit = ACF.CostLimit
			if CostLimit == 0 then return end

			local Contraptions = CFW and CFW.Contraptions or {}
			for Con in pairs(Contraptions) do
				local Cost     = CostSystem.CalcCostsFromContraption(Con)
				local OverLimit = Cost > CostLimit

				if OverLimit then
					local Baseplate = Con.ACF_Baseplate
					if not IsValid(Baseplate) then continue end

					local Excess = math.Round(Cost - CostLimit)
					ACF.Shame(Baseplate, "exceeding the contraption cost (" .. CostLimit .. ") limit by " .. Excess .. " pts")
				end
			end
		end,
		nil,
		nil,
		{ MinTime = 5, MaxTime = 10 }
	)
end