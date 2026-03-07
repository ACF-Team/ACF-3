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

local IsValid                      = IsValid
local render_SetBlend              = render.SetBlend
local render_ModelMaterialOverride = render.ModelMaterialOverride

local function GetMaterial(Percent)
	if Percent > 0.7 then return Materials[1] end
	if Percent > 0.3 then return Materials[2] end

	return Materials[3]
end

local function Remove(Entity)
	Entity:RemoveCallOnRemove("ACF_RenderDamage")

	Damaged[Entity] = nil

	if not next(Damaged) then
		hook.Remove("PostDrawOpaqueRenderables", "ACF_RenderDamage")
	end
end

local function RenderDamage(bDrawingDepth, _, isDraw3DSkybox)
	if bDrawingDepth or isDraw3DSkybox then return end

	for Entity, Data in pairs(Damaged) do
		if IsValid(Entity) then
			render_ModelMaterialOverride(Data.Material)
			render_SetBlend(Data.Blend)
			Entity:DrawModel()
		else
			Remove(Entity)
		end
	end

	render_ModelMaterialOverride()
	render_SetBlend(1)
end

local function Add(Entity, Percent)
	local Data = Damaged[Entity]

	if not Data then -- First time this entity has been damaged; register it
		if not next(Damaged) then -- First damaged entity overall; start rendering
			hook.Add("PostDrawOpaqueRenderables", "ACF_RenderDamage", RenderDamage)
		end

		Data = {}
		Damaged[Entity] = Data

		Entity:CallOnRemove("ACF_RenderDamage", function()
			Remove(Entity)
		end)
	end

	-- Update render data (runs for both new and existing entities)
	Data.Material = GetMaterial(Percent)
	Data.Blend    = math.Clamp(1 - Percent, 0, 0.8)

	Entity.ACF_HealthPercent = Percent
end

net.Receive("ACF_Damage", function()
	local Count = net.ReadUInt(8)

	for _ = 1, Count do
		local Entity  = Entity(net.ReadUInt(13))
		local Percent = net.ReadUInt(4) / 10

		if not IsValid(Entity) then continue end

		if Percent < 1 then
			Add(Entity, Percent)
		else
			Remove(Entity)
			Entity.ACF_HealthPercent = nil
		end
	end
end)
