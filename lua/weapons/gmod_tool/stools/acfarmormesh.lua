local ACF = ACF

TOOL.Category   = (ACF and ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name       = "#tool.acfarmormesh.name"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "left0", stage = 0 },
	{ name = "right0", stage = 0 },
}

TOOL.ClientConVar["material"] = "RHA"

local Alpha = 50

if CLIENT then
	language.Add("tool.acfarmormesh.name", "ACF Armor Mesh")
	language.Add("tool.acfarmormesh.desc", "Applies armor materials to individual convexes of an ACF volumetric mesh")
	language.Add("tool.acfarmormesh.left0", "Apply the selected material to the convex under your crosshair")
	language.Add("tool.acfarmormesh.right0", "Copy the material of the convex under your crosshair")
	language.Add("tool.acfarmormesh.material_desc", "The material that will be applied to the convex under your crosshair.")
	language.Add("tool.acfarmormesh.armor_stats", "ACF Stats")

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end

	local function CreateArmorMeshMenu(Panel)
		local ProcArmorTypes = ACF.Classes.ProcArmorTypes
		local Menu = ACF.InitMenuBase(Panel, "ArmorMeshMenu", "acf_reload_armor_mesh_menu")

		local Materials = Menu:AddComboBox()

		Menu:AddHelp("#tool.acfarmormesh.material_desc")

		local Base = Menu:AddCollapsible("Material Info", true)
		local MatName     = Base:AddTitle()
		local MatDesc     = Base:AddLabel()
		local MatDensity  = Base:AddLabel()
		local MatHealth   = Base:AddLabel()
		local MatKinetic  = Base:AddLabel()
		local MatChemical = Base:AddLabel()

		function Materials:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected       = Data

			MatName:SetText(Data.Name)
			MatDesc:SetText(Data.Description)
			MatDensity:SetText(string.format("Density: %g g/cm^3", Data.Density * 1000))
			MatHealth:SetText(string.format("Health Multiplier: %gx", Data.HealthMul))
			MatKinetic:SetText(string.format("Kinetic Multiplier: %gx", Data.KineticMul))
			MatChemical:SetText(string.format("Chemical Multiplier: %gx", Data.ChemicalMul))

			RunConsoleCommand("acfarmormesh_material", Data.ID)
		end

		ACF.LoadSortedList(Materials, ProcArmorTypes.GetEntries(), "Name")

		-- Keeps the combo box and info panel in sync when the material is sampled via right-click.
		cvars.AddChangeCallback("acfarmormesh_material", function(_, _, New)
			local Choices = Materials.ListData and Materials.ListData.Choices
			if not Choices then return end

			for Index, Data in ipairs(Choices) do
				if Data.ID == New then
					Materials:ChooseOptionID(Index)
					break
				end
			end
		end, "ACF_ArmorMeshMenu")
	end

	ACF.CreateArmorMeshMenu = CreateArmorMeshMenu
	TOOL.BuildCPanel = CreateArmorMeshMenu

	local White   = Color(255, 255, 255, Alpha)
	local TextGray = Color(224, 224, 255)
	local BGGray   = Color(200, 200, 200)
	local Red      = Color(200, 50, 50)
	local Blue     = Color(50, 200, 200)
	local Black    = Color(0, 0, 0)

	-- Toolgun screen: total entity health and the nominal thickness of the convex under the crosshair.
	function TOOL:DrawToolScreen()
		local Player = self:GetOwner()
		local Trace  = Player:GetEyeTrace()
		local Entity = Trace.Entity
		local Weapon = self.Weapon

		local Health    = math.Round(Weapon:GetNWFloat("EntityHealth", 0))
		local MaxHealth = math.Round(Weapon:GetNWFloat("EntityMaxHealth", 0))

		local Armor = 0
		if IsValid(Entity) and Entity.ACF_Volumetric_Mesh then
			local Dir       = (Trace.HitPos - Trace.StartPos):GetNormalized()
			local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir)

			if ConvexHit then
				Armor = math.Round(ConvexHit.GeoThick, 2)
			end
		end

		cam.Start2D()
			render.Clear(0, 0, 0, 0)

			surface.SetDrawColor(Black)
			surface.DrawRect(0, 0, 256, 256)
			surface.SetFont("torchfont")

			draw.SimpleTextOutlined("#tool.acfarmormesh.armor_stats", "torchfont", 128, 30, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)

			draw.RoundedBox(6, 10, 83, 236, 64, BGGray)
			draw.RoundedBox(6, 15, 88, 226, 54, Blue)
			draw.SimpleTextOutlined("Convex Armor", "torchfont", 128, 100, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
			draw.SimpleTextOutlined(Armor .. " mm", "torchfont", 128, 130, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)

			draw.RoundedBox(6, 10, 183, 236, 64, BGGray)
			if Health ~= 0 and MaxHealth ~= 0 then
				draw.RoundedBox(6, 15, 188, Health / MaxHealth * 226, 54, Red)
			end
			draw.SimpleTextOutlined("Total Health", "torchfont", 128, 200, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
			draw.SimpleTextOutlined(Health .. "/" .. MaxHealth, "torchfont", 128, 230, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
		cam.End2D()
	end

	-- Draws every convex of the mesh as a translucent quad: white normally, colored if highlighted.
	-- Runs every frame instead of using debugoverlay so the visualization doesn't flicker.
	local function DrawConvexes(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts = MeshData.Verts

		render.SetColorMaterial()

		for Index, Convex in ipairs(MeshData.Convexes) do
			local IsHighlighted = Index == HighlightID
			local Col

			if IsHighlighted then
				Col = HSVToColor((Index * 47) % 360, 1, 1)
				Col.a = 120
			else
				Col = White
			end

			for _, Tri in ipairs(Convex.Tris) do
				local A = Entity:LocalToWorld(Verts[Tri[1]])
				local B = Entity:LocalToWorld(Verts[Tri[2]])
				local C = Entity:LocalToWorld(Verts[Tri[3]])

				render.DrawQuad(A, B, C, C, Col)
			end
		end
	end

	-- Returns the entity under the crosshair if the armor mesh tool is active and it has a volumetric mesh.
	local function GetMeshTraceTarget()
		local Player = LocalPlayer()
		local Weapon = Player:GetActiveWeapon()
		if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return end

		local Tool = Player:GetTool()
		if not Tool or Tool ~= Player:GetTool("acfarmormesh") then return end

		local Trace  = Player:GetEyeTrace()
		local Entity = Trace.Entity
		if not IsValid(Entity) or not Entity.ACF_Volumetric_Mesh then return end

		return Player, Weapon, Trace, Entity
	end

	-- The targeted prop is hidden while its convexes are being drawn, so it doesn't occlude or z-fight with the overlay.
	-- SetNoDraw only takes effect on the following frame's opaque pass, so the prop is unhidden again as soon as it
	-- stops being the target.
	local HiddenEntity

	hook.Add("PostDrawOpaqueRenderables", "ACF_ArmorMesh_Visualizer", function(bDrawingDepth, _, bDrawingSkybox)
		if bDrawingDepth or bDrawingSkybox then return end

		local _, Weapon, Trace, Entity = GetMeshTraceTarget()

		if IsValid(HiddenEntity) and HiddenEntity ~= Entity then
			HiddenEntity:SetNoDraw(false)
			HiddenEntity = nil
		end

		if not Entity then return end

		Entity:SetNoDraw(true)
		HiddenEntity = Entity

		local Dir         = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local ConvexHit   = ACF.GetConvexHit(Entity, Trace.HitPos, Dir)
		local HighlightID = ConvexHit and ConvexHit.ConvexID

		DrawConvexes(Entity, HighlightID)

		if HighlightID and Weapon:GetNWInt("ConvexID", -1) == HighlightID then
			local Material  = Weapon:GetNWString("ConvexMaterial", "")
			local Health    = Weapon:GetNWFloat("ConvexHealth", 0)
			local MaxHealth = Weapon:GetNWFloat("ConvexMaxHealth", 0)
			local Volume    = Entity.ACF_Volumetric_Mesh.Convexes[HighlightID].Volume

			local Text = string.format("Mat: %s\nHP: %.2f / %.2f\nVol: %.2f cm^3", Material, Health, MaxHealth, Volume)
			AddWorldTip(Entity, Text, nil, Trace.HitPos)
		end
	end)
elseif SERVER then
	-- Keeps the toolgun's NW vars in sync with the convex under the player's crosshair, for client-side display.
	function TOOL:Think()
		local Player = self:GetOwner()
		local Trace  = Player:GetEyeTrace()
		local Entity = Trace.Entity
		local Weapon = self.Weapon

		local EntACF = IsValid(Entity) and Entity.ACF
		Weapon:SetNWFloat("EntityHealth", EntACF and EntACF.Health or 0)
		Weapon:SetNWFloat("EntityMaxHealth", EntACF and EntACF.MaxHealth or 0)

		local ConvexHit
		if IsValid(Entity) and Entity.ACF_Volumetric_Mesh then
			local Dir = (Trace.HitPos - Trace.StartPos):GetNormalized()
			ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir)
		end

		if not ConvexHit then
			Weapon:SetNWInt("ConvexID", -1)
			return
		end

		local Convex = Entity.ACF_Volumetric_Mesh.Convexes[ConvexHit.ConvexID]

		Weapon:SetNWInt("ConvexID", ConvexHit.ConvexID)
		Weapon:SetNWString("ConvexMaterial", Convex.Material)
		Weapon:SetNWFloat("ConvexHealth", Convex.Health)
		Weapon:SetNWFloat("ConvexMaxHealth", Convex.MaxHealth)
	end

	function TOOL:LeftClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return false end
		if not ACF.Check(Entity) then return false end
		if not Entity.ACF_Volumetric_Mesh then return false end

		local Dir       = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir)
		if not ConvexHit then return false end

		ACF.SetConvexMaterial(Entity, ConvexHit.ConvexID, self:GetClientInfo("material"))

		return true
	end

	-- Eyedropper: copies the material of the convex under the crosshair into the tool's selection.
	function TOOL:RightClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return false end
		if not Entity.ACF_Volumetric_Mesh then return false end

		local Dir       = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir)
		if not ConvexHit then return false end

		local Convex = Entity.ACF_Volumetric_Mesh.Convexes[ConvexHit.ConvexID]

		self:GetOwner():ConCommand("acfarmormesh_material " .. Convex.Material)

		return true
	end

	function TOOL:Reload(_) return true end
end
