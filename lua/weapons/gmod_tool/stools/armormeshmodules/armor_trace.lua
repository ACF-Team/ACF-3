local function GetTraceDir(Tool)
	local Dir = LocalPlayer():GetAimVector()
	if tobool(Tool:GetClientInfo("ignore_elevation")) then
		local Ang = Dir:Angle()
		Ang.p = 0
		Dir = Ang:Forward()
	end
	return Dir
end

local MaxTraceDist = 32768

-- Gathers every meshed entity along the ray in one FindAlongRay pass and resolves their convex
-- stacks together, like the test_trace concommand in volumetrics_sh.lua.
-- Stops at the first non-filtered ACF entity hit, which is only shown as the "End" marker. A
-- filtered ACF entity's armor is still counted as a layer, it just doesn't stop the scan.
local function GetArmorLayers(StartTrace, Dir, Filter)
	local Layers = {}
	local Start  = StartTrace.HitPos - Dir * 2 -- same backoff ACF.GetConvexHits uses

	local FoundEnts = ents.FindAlongRay(Start, Start + Dir * MaxTraceDist)

	local Intersections = {}
	for _, Entity in ipairs(FoundEnts) do
		local Hits = ACF.RayIntersectMesh(Entity, Start, Dir, true)
		for _, Hit in ipairs(Hits) do
			Intersections[#Intersections + 1] = Hit
		end
	end

	local Hits = ACF.ResolveConvexStack(Intersections, Dir)

	local TerminalEntity
	for _, Hit in ipairs(Hits) do
		-- The first non-filtered ACF entity hit ends the scan and is not added as an armor layer.
		if Hit.Entity.IsACFEntity and not Filter[Hit.Entity:GetClass()] then
			TerminalEntity = Hit.Entity
			break
		end

		local Convex = Hit.Entity.ACF_Volumetric_Mesh.Convexes[Hit.ConvexID]

		table.insert(Layers, {
			Terminal = false,
			Entity   = Hit.Entity,
			Material = Convex.Material,
			GeoThick = Hit.GeoThick,
			EffKE    = Hit.GeoThick * Hit.ArmorType.KineticMul,
			EffCE    = Hit.GeoThick * Hit.ArmorType.ChemicalMul,
		})
	end

	if TerminalEntity then
		table.insert(Layers, { Terminal = true, Entity = TerminalEntity })
	end

	local TotalKE, TotalCE = 0, 0
	for _, Layer in ipairs(Layers) do
		if not Layer.Terminal then
			TotalKE = TotalKE + Layer.EffKE
			TotalCE = TotalCE + Layer.EffCE
		end
	end

	return Layers, TotalKE, TotalCE
end

return {
	GetTraceDir    = GetTraceDir,
	GetArmorLayers = GetArmorLayers,
}
