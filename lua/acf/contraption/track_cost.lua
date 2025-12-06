-- Thank you for most of the base cost logic liddul <3
ACF.CostSystem = {}
ACF.CostSystem.CalcSingleFilter = {
	gmod_wire_expression2	= 0.75,
	starfall_processor		= 0.75,
	acf_piledriver			= 5,
	acf_rack				= 10,
	acf_engine				= 1,
	acf_gearbox				= 0,
	acf_fueltank			= 0,
	prop_physics			= 1,
	acf_armor				= 1,
	acf_gun					= 1,
	acf_ammo				= 1,
	acf_radar				= 10,
	gmod_wire_gate			= 1,
	primitive_shape			= 1,
	acf_turret				= 0,
	acf_turret_motor		= 1,
	acf_turret_gyro			= 1,
	acf_turret_computer		= 1,
	acf_baseplate			= 1,
	acf_controller			= 0.75,
	acf_crew				= 1,
	acf_groundloader		= 1,
}

ACF.CostSystem.ACFGunCost = { -- anything not on here costs 1
	SB	= 1, -- old smoothbores, leaving
	C	= 0.5,
	SC	= 0.3,
	AC	= 1.2,
	LAC	= 1.1,
	HW	= 0.75,
	MO	= 0.75,
	RAC	= 2,
	SA	= 1,
	AL	= 0.8,
	GL	= 0.5,
	MG	= 0.25,
	SL	= 0.02,
	FGL	= 0.125
}

ACF.CostSystem.ACFAmmoModifier = { -- Anything not in here is 0.2
	AP		= 0.4,
	APCR	= 0.6,
	APDS	= 0.8,
	APFSDS	= 1,
	APHE	= 0.5,
	HE		= 0.35,
	HEAT	= 0.65,
	HEATFS	= 0.85,
	FL		= 0.25,
	HP		= 0.1,
	SM		= 0.1,
	GLATGM	= 1.5,
	FLR		= 0.05,
}

ACF.CostSystem.ACFMissileModifier = { -- Default 5
	ATGM	= 8,
	AAM		= 5,
	ARM		= 2.5,
	ARTY	= 6,
	BOMB	= 4, -- Dumb bomb
	FFAR	= 2,
	GBOMB	= 5, -- Glide bomb
	GBU		= 7.5, -- Guided bomb
	SAM		= 2.5,
	UAR		= 3,
}

ACF.CostSystem.ACFRadars = { -- Should be prohibitively expensive, defaults to 50
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

ACF.CostSystem.SpecialModelFilter = { -- any missile rack not in here costs 10 points
	["models/failz/b8.mdl"]			= 20,
	["models/failz/lau_61.mdl"]		= 15,
	["models/failz/ub_16.mdl"]		= 15,
	["models/failz/ub_32.mdl"]		= 20,
	["models/ghosteh/lau10.mdl"]	= 15,

	["models/missiles/rk3uar.mdl"]	= 15,

	["models/spg9/spg9.mdl"]		= 7.5,

	["models/kali/weapons/kornet/parts/9m133 kornet tube.mdl"] = 15,
	["models/missiles/9m120_rk1.mdl"]	= 15,
	["models/missiles/at3rs.mdl"]		= 10,
	["models/missiles/at3rk.mdl"]		= 10,

	-- BIG rack, can hold lots of boom
	["models/missiles/6pod_rk.mdl"]		= 25,

	-- YUGE fuckin tube, launches a 380mm rocket
	["models/launcher/rw61.mdl"]		= 35,

	["models/missiles/agm_114_2xrk.mdl"]	= 15,
	["models/missiles/agm_114_4xrk.mdl"]	= 20,

	["models/missiles/launcher7_40mm.mdl"]	= 12,
	["models/missiles/launcher7_70mm.mdl"]	= 16,

	["models/missiles/bgm_71e_round.mdl"]	= 15,
	["models/missiles/bgm_71e_2xrk.mdl"]	= 17.5,
	["models/missiles/bgm_71e_4xrk.mdl"]	= 20,

	["models/missiles/fim_92_1xrk.mdl"]		= 7.5,
	["models/missiles/fim_92_2xrk.mdl"]		= 10,
	["models/missiles/fim_92_4xrk.mdl"]		= 15,

	["models/missiles/9m31_rk1.mdl"]	= 10,
	["models/missiles/9m31_rk2.mdl"]	= 15,
	["models/missiles/9m31_rk4.mdl"]	= 20,

	["models/missiles/bomb_3xrk.mdl"]	= 20,

	["models/missiles/rkx1_sml.mdl"]	= 10,
	["models/missiles/rkx1.mdl"]		= 10,
	["models/missiles/rack_double.mdl"]	= 15,
	["models/missiles/rack_quad.mdl"]	= 20
}

local CostFilter = {}
CostFilter["acf_gun"] = function(E) return (ACF.CostSystem.ACFGunCost[E.Class] or 1) * E.Caliber end
CostFilter["acf_engine"] = function(E) return math.max(5, (E.PeakTorque / 160) + (E.PeakPower / 80)) end
CostFilter["acf_rack"] = function(E)
	if ACF.CostSystem.SpecialModelFilter[E:GetModel()] then
		return ACF.CostSystem.SpecialModelFilter[E:GetModel()]
	else
		return 10
	end
end
CostFilter["acf_radar"] = function(E)
	local ID = E.ShortName

	if ACF.CostSystem.ACFRadars[ID] then
		return ACF.CostSystem.ACFRadars[ID]
	else
		return 50
	end
end
CostFilter["acf_ammo"] = function(E)
	if E.AmmoType == "Refill" then
		return E.Capacity * 0.05
	elseif E.IsMissileAmmo then -- Only present on crates that actually hold ACF-3 Missiles ammo, courtesy of a hook intercept in ACF-3 Missiles
		return E.Capacity * (ACF.CostSystem.ACFAmmoModifier[E.AmmoType] or 0.2) * (ACF.CostSystem.ACFMissileModifier[E.Class] or 10) * math.max(1,(E.Caliber / 100) ^ 1.5)
	else
		return E.Capacity * (ACF.CostSystem.ACFAmmoModifier[E.AmmoType] or 0.2) * ((E.Caliber / 100) ^ 2) * (ACF.CostSystem.ACFGunCost[E.Class] or 1)
	end
end

CostFilter["acf_turret_motor"] = function(E)
	return E.CompSize * 2
end
CostFilter["acf_turret_gyro"] = function(E)
	return E.IsDual and 8 or 4
end
CostFilter["acf_turret_computer"] = function() return 5 end

CostFilter["acf_groundloader"] = function() return 20 end

local ArmorCalc = function(E)
	local phys = E:GetPhysicsObject()

	if IsValid(phys) then
		return 0.1 + math.max(0.01, phys:GetMass() / 500)
	else
		return 1
	end
end

CostFilter["acf_armor"] = ArmorCalc
CostFilter["prop_physics"] = ArmorCalc
CostFilter["primitive_shape"] = ArmorCalc
CostFilter["gmod_wire_gate"] = ArmorCalc
CostFilter["acf_baseplate"] = ArmorCalc

function ACF.CostSystem.CalcCost(E)
	local Class = E:GetClass()
	if not ACF.CostSystem.CalcSingleFilter[Class] then return 0 end
	local Cost = ACF.CostSystem.CalcSingleFilter[Class] or 1

	if CostFilter[Class] then
		Cost = CostFilter[Class](E)
	end

	return Cost
end

function ACF.CostSystem.CalcCostFromContraption(Contraption)

end

function ACF.CostSystem.CalcCostsFromEnts(Ents)

end

function ACF.CostSystem.CalcCostsFromEntsByClass(EntsByClass)

end


hook.Add("cfw.contraption.created", "ACF_CFW_CostTrack", function(Contraption)
	-- print("cfw.contraption.created", Contraption)
	Contraption.AmmoTypes = {}
	Contraption.MaxPen = 0
	Contraption.MaxNominal = 0
end)

hook.Add("cfw.contraption.entityAdded", "ACF_CFW_CostTrack", function(Contraption, Entity)
	-- print("cfw.contraption.entityAdded", Contraption, Entity)
	if Entity.IsACFEntity then
		if Entity.IsACFAmmoCrate then
			Contraption.AmmoTypes[Entity.AmmoType] = true
		elseif Entity.IsACFEngine then
			Contraption.HorsePower = (Contraption.HorsePower or 0) + Entity.PeakPower
		end
	else
		if Entity.ACF then
			Contraption.MaxNominal = math.max(Contraption.MaxNominal or 0, math.Round(Entity.ACF.Armour or 0))
		end
	end
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_CFW_CostTrack", function(Contraption, Entity)
	-- print("cfw.contraption.entityRemoved", Contraption, Entity)
end)

hook.Add("cfw.contraption.merged", "ACF_CFW_CostTrack", function(Contraption, MergedInto)
	-- print("cfw.contraption.merged", Contraption, MergedInto)
end)

hook.Add("cfw.contraption.removed", "ACF_CFW_CostTrack", function(Contraption)
	-- print("cfw.contraption.removed", Contraption)
end)