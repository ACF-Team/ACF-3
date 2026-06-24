local ACF			= ACF
local Contraption	= ACF.Contraption
local Objects		= ACF.Contraption.Objects
local CubicInchToM3	= ACF.InchToMCu
Contraption.CostSystem	= {}
local CostSystem	= Contraption.CostSystem
-- Thank you for most of the base cost logic liddul <3

--[[	These are no longer required, but will be left as reference for now
CostSystem.CalcSingleFilter = {
	gmod_wire_expression2	= 0.75,
	starfall_processor		= 0.75,
	acf_piledriver			= 5,
	acf_rack				= 10,
	acf_engine				= 1,
	acf_gearbox				= 0,
	acf_fueltank			= 0,
	prop_physics			= 1,
	acf_gun					= 1,
	acf_ammo				= 1,
	acf_radar				= 10,
	gmod_wire_gate			= 1,
	primitive_shape			= 1,
	acf_turret				= 0,
	acf_turret_motor		= 1,
	acf_turret_gyro			= 1,
	acf_turret_computer		= 5,
	acf_baseplate			= 1,
	acf_controller			= 0.75,
	acf_crew				= 1,
	acf_groundloader		= 20,
}


CostSystem.ACFGunCost = { -- anything not on here costs 1
	SB	= 1, -- old smoothbores, leaving
	C	= 0.4,
	SC	= 0.275,
	AC	= 1.1,
	LAC	= 1,
	HW	= 0.5,
	MO	= 0.35,
	RAC	= 1.75,
	SA	= 0.55,
	AL	= 0.6,
	GL	= 0.5,
	MG	= 0.25,
	SL	= 0.02,
	FGL	= 0.125
}

CostSystem.ACFAmmoModifier = { -- Anything not in here is 0.2
	AP		= 0.3,
	APCR	= 0.5,
	APDS	= 0.9,
	APFSDS	= 1.2,
	APHE	= 0.4,
	HE		= 0.35,
	HEAT	= 0.5,
	HEATFS	= 1.1,
	FL		= 0.2,
	HP		= 0.1,
	SM		= 0.1,
	GLATGM	= 1.5,
	FLR		= 0.05,
}


CostSystem.ACFMissileModifier = { -- Default 5
	ATGM	= 8,
	AAM		= 5,
	ARM		= 2.5,
	ARTY	= 6,
	BOMB	= 4, -- Dumb bomb
	FFAR	= 1,
	GBOMB	= 5, -- Glide bomb
	GBU		= 6, -- Guided bomb
	SAM		= 2,
	UAR		= 3,
}

CostSystem.ACFRadars = { -- Should be prohibitively expensive, defaults to 50
	-- Missile detecting radars
	["LargeDIR-AM"]		= 30,
	["MediumDIR-AM"]	= 15,
	["SmallDIR-AM"]		= 5,

	["LargeOMNI-AM"]	= 50,
	["MediumOMNI-AM"]	= 30,
	["SmallOMNI-AM"]	= 15,

	-- Contraption detecting radars
	["LargeDIR-TGT"]	= 60,
	["MediumDIR-TGT"]	= 35,
	["SmallDIR-TGT"]	= 15,

	["LargeOMNI-TGT"]	= 80,
	["MediumOMNI-TGT"]	= 50,
	["SmallOMNI-TGT"]	= 30,
}

CostSystem.SpecialModelFilter = { -- any missile rack not in here costs 10 points
	-- These small racks Im just going to compare against 70mm and scale cost, per missile slot

	["models/missiles/launcher7_40mm.mdl"]	= 4,
	["models/failz/ub_16.mdl"]		= 13,
	["models/failz/ub_32.mdl"]		= 26,
	["models/missiles/launcher7_70mm.mdl"]	= 7,
	["models/failz/lau_61.mdl"]		= 19,
	["models/failz/b8.mdl"]			= 22.8,

	["models/ghosteh/lau10.mdl"]	= 15,

	["models/missiles/rk3uar.mdl"]	= 9,

	["models/spg9/spg9.mdl"]		= 5,

	["models/kali/weapons/kornet/parts/9m133 kornet tube.mdl"] = 12.5,
	["models/missiles/9m120_rk1.mdl"]	= 15,
	["models/missiles/at3rs.mdl"]		= 4,
	["models/missiles/at3rk.mdl"]		= 4,

	-- BIG rack, can hold lots of boom
	["models/missiles/6pod_rk.mdl"]		= 20,

	-- YUGE fuckin tube, launches a 380mm rocket
	["models/launcher/rw61.mdl"]		= 30,

	["models/missiles/agm_114_2xrk.mdl"]	= 10,
	["models/missiles/agm_114_4xrk.mdl"]	= 20,

	["models/missiles/bgm_71e_round.mdl"]	= 5,
	["models/missiles/bgm_71e_2xrk.mdl"]	= 10,
	["models/missiles/bgm_71e_4xrk.mdl"]	= 20,

	["models/missiles/fim_92_1xrk.mdl"]		= 2.5,
	["models/missiles/fim_92_2xrk.mdl"]		= 5,
	["models/missiles/fim_92_4xrk.mdl"]		= 10,

	["models/missiles/9m31_rk1.mdl"]	= 7.5,
	["models/missiles/9m31_rk2.mdl"]	= 15,
	["models/missiles/9m31_rk4.mdl"]	= 30,

	["models/missiles/bomb_3xrk.mdl"]	= 9,

	["models/missiles/rkx1_sml.mdl"]	= 3,
	["models/missiles/rkx1.mdl"]		= 3,
	["models/missiles/rack_double.mdl"]	= 6,
	["models/missiles/rack_quad.mdl"]	= 12
}
]]

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

	-- hook.Add("cfw.contraption.entityRemoved", "ACF_CFW_CostTrack", function(Contraption, Entity)
	-- 	-- print("cfw.contraption.entityRemoved", Contraption, Entity)
	-- end)

	-- hook.Add("cfw.contraption.merged", "ACF_CFW_CostTrack", function(Contraption, MergedInto)
	-- 	-- print("cfw.contraption.merged", Contraption, MergedInto)
	-- end)

	-- hook.Add("cfw.contraption.removed", "ACF_CFW_CostTrack", function(Contraption)
	-- 	-- print("cfw.contraption.removed", Contraption)
	-- end)
end