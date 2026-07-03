local IsValid = IsValid

local function GetTraceDir(Tool)
	local Dir = LocalPlayer():GetAimVector()
	if tobool(Tool:GetClientInfo("ignore_elevation")) then
		local Ang = Dir:Angle()
		Ang.p = 0
		Dir = Ang:Forward()
	end
	return Dir
end

local function GetArmorLayers(StartTrace, Dir, Filter)
	local ArmorTypes = ACF.Classes.ArmorTypes
	local Layers     = {}
	local Skipped    = {}
	local Processed  = {}
	local Current    = StartTrace

	for _ = 1, 30 do
		local Entity = Current.Entity
		if not IsValid(Entity) then break end

		local Class = Entity:GetClass()

		if Entity.IsACFEntity and not Filter[Class] then
			table.insert(Layers, { Terminal = true, Entity = Entity })
			break
		end

		if not Entity.ACF_Volumetric_Mesh then break end

		local EntProcessed = Processed[Entity]
		if not EntProcessed then
			EntProcessed      = {}
			Processed[Entity] = EntProcessed
		end

		local ConvexHit = ACF.GetConvexHit(Entity, Current.HitPos, Dir, true, EntProcessed)

		if ConvexHit then
			EntProcessed[ConvexHit.ConvexID] = true

			local Convex    = Entity.ACF_Volumetric_Mesh.Convexes[ConvexHit.ConvexID]
			local ArmorType = ArmorTypes.Get(Convex.Material) or ArmorTypes.Get("Default")

			table.insert(Layers, {
				Terminal = false,
				Entity   = Entity,
				Material = Convex.Material,
				GeoThick = ConvexHit.GeoThick,
				EffKE    = ConvexHit.GeoThick * ArmorType.KineticMul,
				EffCE    = ConvexHit.GeoThick * ArmorType.ChemicalMul,
			})
		else
			Skipped[Entity] = true
			Current = util.TraceLine({
				start  = Current.HitPos,
				endpos = Current.HitPos + Dir * 32768,
				filter = function(Ent) return not Skipped[Ent] end,
				mask   = MASK_SOLID,
			})
		end
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
