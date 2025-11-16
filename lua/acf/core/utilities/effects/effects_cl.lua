local ACF     = ACF
local Effects = ACF.Utilities.Effects

Effects.MaterialColors = {
	Default        = Color(120, 110, 100),
	[MAT_GRATE]    = Color(170, 160, 144),
	[MAT_CLIP]     = Color(170, 160, 144),
	[MAT_METAL]    = Color(170, 160, 144),
	[MAT_COMPUTER] = Color(170, 160, 144),
	[MAT_CONCRETE] = Color(180, 172, 158),
	[MAT_DIRT]     = Color(95, 80, 63),
	[MAT_GRASS]    = Color(114, 100, 80),
	[MAT_SLOSH]    = Color(104, 90, 70),
	[MAT_SNOW]     = Color(154, 140, 110),
	[MAT_FOLIAGE]  = Color(104, 90, 70),
	[MAT_TILE]     = Color(150, 146, 141),
	[MAT_SAND]     = Color(180, 155, 100),
}

do -- Resupply effect
	local render   = render
	local Distance = ACF.SupplyDistance
	local SupplyColor = Color(255, 255, 150, 10) -- Soft yellow color for supply effect

	local Supplies = {}
	Effects.Supplies = Supplies

	local function DrawSpheres(bDrawingDepth, _, isDraw3DSkybox)
		if bDrawingDepth or isDraw3DSkybox then return end
		render.SetColorMaterial()

		for Entity in pairs(Supplies) do
			local Pos = Entity:GetPos()

			render.DrawSphere(Pos, Distance, 50, 50, SupplyColor)
			render.DrawSphere(Pos, -Distance, 50, 50, SupplyColor)
		end
	end

	local function Remove(Entity)
		if not IsValid(Entity) then return end

		Supplies[Entity] = nil

		Entity:RemoveCallOnRemove("ACF_Supply")

		if not next(Supplies) then
			hook.Remove("PostDrawOpaqueRenderables", "ACF_Supply")
		end
	end

	local function Add(Entity)
		if not IsValid(Entity) then return end

		if not next(Supplies) then
			hook.Add("PostDrawOpaqueRenderables", "ACF_Supply", DrawSpheres)
		end

		Supplies[Entity] = true

		Entity:CallOnRemove("ACF_Supply", Remove)
	end

	net.Receive("ACF_SupplyEffect", function()
		local Entity = net.ReadEntity()

		Add(Entity)
	end)

	net.Receive("ACF_StopSupplyEffect", function()
		local Entity = net.ReadEntity()

		Remove(Entity)
	end)
end