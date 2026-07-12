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

-- Gathers every meshed entity along the whole ray in one FindAlongRay pass (same shape as the
-- test_trace concommand in volumetrics_sh.lua) and resolves their convex stacks together, instead
-- of walking one physically-traced entity at a time. A non-filtered IsACFEntity found along the
-- ray still cuts the scan short at its OBB entry point, same as before; anything else without a
-- mesh is just transparent to the scan now rather than acting as a silent hard stop.
local function GetArmorLayers(StartTrace, Dir, Filter)
	local Layers = {}
	local Start  = StartTrace.HitPos - Dir * 2 -- same backoff ACF.GetConvexHits uses

	local FoundEnts = ents.FindAlongRay(Start, Start + Dir * MaxTraceDist)

	local Intersections = {}
	local TerminalEntity, TerminalT

	for _, Entity in ipairs(FoundEnts) do
		local Class = Entity:GetClass()

		if Entity.IsACFEntity and not Filter[Class] then
			local HitPos = util.IntersectRayWithOBB(Start, Dir * MaxTraceDist, Entity:GetPos(), Entity:GetAngles(), Entity:OBBMins(), Entity:OBBMaxs())

			if HitPos then
				local T = (HitPos - Start):Dot(Dir)

				if not TerminalT or T < TerminalT then
					TerminalT      = T
					TerminalEntity = Entity
				end
			end
		elseif Entity.ACF_Volumetric_Mesh then
			local Hits = ACF.RayIntersectMesh(Entity, Start, Dir, true)

			for _, Hit in ipairs(Hits) do
				Intersections[#Intersections + 1] = Hit
			end
		end
	end

	local Hits = ACF.ResolveConvexStack(Intersections, Dir)

	for _, Hit in ipairs(Hits) do
		if TerminalT and (Hit.EntryPos - Start):Dot(Dir) >= TerminalT then break end

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
