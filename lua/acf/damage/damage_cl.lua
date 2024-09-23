local Damaged   = {}
local Materials = {
	CreateMaterial("ACF_Damaged1", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged1"
	}),
	CreateMaterial("ACF_Damaged2", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged2"
	}),
	CreateMaterial("ACF_Damaged3", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged3"
	})
}

local RenderDamage
do
	local EyePos = EyePos
	local EyeAngles = EyeAngles
	local cam_End3D = cam.End3D
	local cam_Start3D = cam.Start3D
	local render_SetBlend = render.SetBlend
	local render_ModelMaterialOverride = render.ModelMaterialOverride

	RenderDamage = function(bDrawingDepth, _, isDraw3DSkybox)
		if bDrawingDepth or isDraw3DSkybox then return end
		cam_Start3D(EyePos(), EyeAngles())

		for Entity, EntityTable in pairs(Damaged) do
			if IsValid(Entity) then
				render_ModelMaterialOverride(EntityTable.ACF_Material)
				render_SetBlend(EntityTable.ACF_BlendAmount)

				Entity:DrawModel()
			end
		end

		render_ModelMaterialOverride()
		render_SetBlend(1)
		cam_End3D()
	end
end

local function Remove(Entity)
	Entity:RemoveCallOnRemove("ACF_RenderDamage")

	Damaged[Entity] = nil

	if not next(Damaged) then
		hook.Remove("PostDrawOpaqueRenderables", "ACF_RenderDamage")
	end
end

local function Add(Entity)
	if not next(Damaged) then
		hook.Add("PostDrawOpaqueRenderables", "ACF_RenderDamage", RenderDamage)
	end

	Damaged[Entity] = Entity:GetTable()

	Entity:CallOnRemove("ACF_RenderDamage", function()
		Remove(Entity)
	end)
end

do
	local IsValid = IsValid
	local math_Clamp = math.Clamp

	net.Receive("ACF_Damage", function()
		local Entity  = Entity(net.ReadUInt(13))
		local Percent = net.ReadUInt(7) / 100

		if not IsValid(Entity) then return end

		if Percent < 1 then
			Entity.ACF_HealthPercent = Percent
			Entity.ACF_BlendAmount = math_Clamp(1 - Percent, 0, 0.8)

			if Percent > 0.7 then
				Entity.ACF_Material = Materials[1]
			elseif Percent > 0.3 then
				Entity.ACF_Material = Materials[2]
			else
				Entity.ACF_Material = Materials[3]
			end

			Add(Entity)
		else
			Remove(Entity)

			Entity.ACF_HealthPercent = nil
			Entity.ACF_Material      = nil
			Entity.ACF_BlendAmount   = nil
		end
	end)
end