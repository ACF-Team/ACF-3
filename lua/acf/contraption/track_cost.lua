-- Thank you for most of the base cost logic liddul <3
ACF.CostSystem = {}

local CostSystem = ACF.CostSystem
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

--[[	These are no longer required, but will be left as reference for now
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
]]

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

--------------------------------------------------------------------------------

local CostFilter = {}
CostFilter["acf_rack"] = function(E)
	if CostSystem.SpecialModelFilter[E:GetModel()] then
		return CostSystem.SpecialModelFilter[E:GetModel()]
	else
		return 10
	end
end
CostFilter["acf_radar"] = function(E)
	local ID = E.ShortName

	if CostSystem.ACFRadars[ID] then
		return CostSystem.ACFRadars[ID]
	else
		return 50
	end
end

local ArmorCalc = function(E)
	local phys = E:GetPhysicsObject()

	if IsValid(phys) then
		return 0.1 + math.max(0.01, phys:GetMass() / 250)
	else
		return 1
	end
end

CostFilter["prop_physics"] = ArmorCalc
CostFilter["primitive_shape"] = ArmorCalc
CostFilter["gmod_wire_gate"] = ArmorCalc
CostFilter["acf_baseplate"] = ArmorCalc

--------------------------------------------------------------------------------

-- Calculates the cost of a single entity
function CostSystem.CalcCost(E)
	if E.GetCost then return E:GetCost() end

	local Class = E:GetClass()
	if not CostSystem.CalcSingleFilter[Class] then return 0 end
	local Cost = CostSystem.CalcSingleFilter[Class] or 1

	if CostFilter[Class] then
		Cost = CostFilter[Class](E)
	end

	return Cost
end

--- Computes cost and breakdown given a contraption
function CostSystem.CalcCostsFromContraption(Contraption)
	if not Contraption then return 0, {} end
	return CostSystem.CalcCostsFromEntsByClass(Contraption.entsbyclass)
end

--- Computes cost and breakdown given a list of entities
function CostSystem.CalcCostsFromEnts(Ents)
	if not Ents then return 0, {} end
	local EntsByClass = {}
	for _, Ent in pairs(Ents) do
		local Class = Ent:GetClass()
		EntsByClass[Class] = EntsByClass[Class] or {}
		EntsByClass[Class][Ent] = true
	end
	return CostSystem.CalcCostsFromEntsByClass(EntsByClass)
end

--- Computes cost and breakdown given a LUT matching Contraption.entsbyclass
function CostSystem.CalcCostsFromEntsByClass(EntsByClass)
	if not EntsByClass then return 0, {} end
	local TotalCost = 0
	local CostBreakdown = {}

	for Class, Ents in pairs(EntsByClass) do
		if CostSystem.CalcSingleFilter[Class] then
			local ClassCost = 0
			for Ent, _ in pairs(Ents) do
				local EntCost = CostSystem.CalcCost(Ent)
				ClassCost = ClassCost + EntCost
			end
			CostBreakdown[Class] = ClassCost
			TotalCost = TotalCost + ClassCost
		end
	end

	return TotalCost, CostBreakdown
end

--------------------------------------------------------------------------------

-- Custom information to track on contraptions
-- Not all of this is directly related to cost
hook.Add("cfw.contraption.created", "ACF_CFW_CostTrack", function(Contraption)
	-- print("cfw.contraption.created", Contraption)
	Contraption.AmmoTypes = {} -- Index ammo types (Estimate of firepower)
	Contraption.MaxNominal = 0 -- Track max nominal (Estimate of armor)
end)

hook.Add("cfw.contraption.entityAdded", "ACF_CFW_CostTrack", function(Contraption, Entity)
	-- print("cfw.contraption.entityAdded", Contraption, Entity)
	if Entity.IsACFEntity then
		if Entity.IsACFAmmoCrate then
			Contraption.AmmoTypes[Entity.AmmoType] = true
		end
	elseif Entity.ACF then
		Contraption.MaxNominal = math.max(Contraption.MaxNominal or 0, math.Round(Entity.ACF.Armour or 0))
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