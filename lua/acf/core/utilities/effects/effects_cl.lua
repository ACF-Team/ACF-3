local ACF     = ACF
local Effects = ACF.Utilities.Effects

do -- Resupply effect (applies to ammo and fuel)
	local render   = render
	local Distance = ACF.RefillDistance

	local Refills = {}
	Effects.Refills = Refills

	local function DrawSpheres(bDrawingDepth, _, isDraw3DSkybox)
		if bDrawingDepth or isDraw3DSkybox then return end
		render.SetColorMaterial()

		for Entity in pairs(Refills) do
			local Pos = Entity:GetPos()
			local RefillColor

			if Entity:GetClass() == "acf_fueltank" then
				RefillColor = ACF.FuelRefillColor
			else
				RefillColor = ACF.AmmoRefillColor
			end

			render.DrawSphere(Pos, Distance, 50, 50, RefillColor)
			render.DrawSphere(Pos, -Distance, 50, 50, RefillColor)
		end
	end

	local function Remove(Entity)
		if not IsValid(Entity) then return end

		Refills[Entity] = nil

		Entity:RemoveCallOnRemove("ACF_Refill")

		if not next(Refills) then
			hook.Remove("PostDrawOpaqueRenderables", "ACF_Refill")
		end
	end

	local function Add(Entity)
		if not IsValid(Entity) then return end

		if not next(Refills) then
			hook.Add("PostDrawOpaqueRenderables", "ACF_Refill", DrawSpheres)
		end

		Refills[Entity] = true

		Entity:CallOnRemove("ACF_Refill", Remove)
	end

	net.Receive("ACF_RefillEffect", function()
		local Entity = net.ReadEntity()

		Add(Entity)
	end)

	net.Receive("ACF_StopRefillEffect", function()
		local Entity = net.ReadEntity()

		Remove(Entity)
	end)
end