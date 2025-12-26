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

	local Supplies = {}
	Effects.Supplies = Supplies

	local function DrawSpheres(bDrawingDepth, _, isDraw3DSkybox)
		if bDrawingDepth or isDraw3DSkybox then return end

		render.SetColorMaterial()

		for Entity, RefillStatuses in pairs(Supplies) do
			local Pos = Entity:GetPos()

			for RefillType, Refilled in pairs(RefillStatuses) do
				if not Refilled then continue end

				local SupplyColor = ACF[RefillType .. "SupplyColor"] or ACF.AmmoSupplyColor

				render.DrawSphere(Pos, Distance, 50, 50, SupplyColor)
				render.DrawSphere(Pos, -Distance, 50, 50, SupplyColor)
			end
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

	local function Add(Entity, RefilledAmmo, RefilledFuel)
		if not IsValid(Entity) then return end

		if not next(Supplies) then
			hook.Add("PostDrawOpaqueRenderables", "ACF_Supply", DrawSpheres)
		end

		Supplies[Entity] = { Ammo = RefilledAmmo, Fuel = RefilledFuel }

		Entity:CallOnRemove("ACF_Supply", Remove)
	end

	net.Receive("ACF_SupplyEffect", function()
		local Entity = net.ReadEntity()
		local RefilledAmmo = net.ReadBool()
		local RefilledFuel = net.ReadBool()

		Add(Entity, RefilledAmmo, RefilledFuel)
	end)

	net.Receive("ACF_StopSupplyEffect", function()
		local Entity = net.ReadEntity()

		Remove(Entity)
	end)
end