local ACF = ACF
local IsValid = IsValid

local CubicInchToM3 = ACF.InchToMCu

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
	language.Add("tool.acfarmormesh.class_filter", "Recursive Armor Class Filter")
	language.Add("tool.acfarmormesh.class_filter_desc", "When enabled, entities of the selected classes will be excluded from recursive armor application.")
	language.Add("tool.acfarmormesh.filter_acf_gearbox", "acf_gearbox")
	language.Add("tool.acfarmormesh.filter_acf_fuel", "acf_fuel")

	local SphereSearch  = CreateClientConVar("acfarmormesh_sphere_search", 0, false, true, "", 0, 1)
	local SphereRadius  = CreateClientConVar("acfarmormesh_sphere_radius", 0, false, true, "", 0, 10000)
	local ClassFilter = CreateClientConVar("acfarmormesh_class_filter", "{}", false, true)

	local function GetClassFilter()
		return util.JSONToTable(ClassFilter:GetString()) or {}
	end

	local function SetClassFilter(Class, Enabled)
		local Filter = GetClassFilter()
		Filter[Class] = Enabled or nil
		RunConsoleCommand("acfarmormesh_class_filter", util.TableToJSON(Filter))
	end

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(Trace)
		if self:GetOwner():KeyDown(IN_DUCK) then return true end
		return self:GetContraptionReadout(Trace, self:GetOwner():KeyDown(IN_SPEED))
	end

	local function CreateArmorMeshMenu(Panel)
		local ArmorTypes = ACF.Classes.ArmorTypes
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
		local MatCost     = Base:AddLabel()

		function Materials:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected       = Data

			MatName:SetText(Data.Name)
			MatDesc:SetText(Data.Description)
			MatDensity:SetText(string.format("Density: %g kg/m^3", Data.Density))
			MatHealth:SetText(string.format("Health Multiplier: %gx", Data.HealthMul))
			MatKinetic:SetText(string.format("Kinetic Multiplier: %gx", Data.KineticMul))
			MatChemical:SetText(string.format("Chemical Multiplier: %gx", Data.ChemicalMul))
			MatCost:SetText(string.format("Cost: %g points/m^3", Data.CostMul))

			RunConsoleCommand("acfarmormesh_material", Data.ID)
		end

		ACF.LoadSortedList(Materials, ArmorTypes.GetEntries(), "Name")

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

		local SphereCheck = Menu:AddCheckBox("#tool.acfarmormesh.sphere_search", "acfarmormesh_sphere_search")
		Menu:AddHelp("#tool.acfarmormesh.sphere_search_desc")

		local SphereRadiusSlider = Menu:AddSlider("#tool.acfarmormesh.sphere_search_radius", 0, 2000, 0)
		SphereRadiusSlider:SetConVar("acfarmormesh_sphere_radius")
		Menu:AddHelp("#tool.acfarmormesh.sphere_search_radius_desc")

		function SphereCheck:OnChange(Bool)
			SphereRadiusSlider:SetEnabled(Bool)
		end

		SphereRadiusSlider:SetEnabled(SphereCheck:GetChecked())

		local FilterSection = Menu:AddCollapsible("#tool.acfarmormesh.class_filter", false)
		FilterSection:AddHelp("#tool.acfarmormesh.class_filter_desc")

		local function AddFilterCheckBox(LangKey, Class)
			local Check = FilterSection:AddCheckBox(LangKey)
			Check:SetValue(GetClassFilter()[Class] or false)
			function Check:OnChange(Val) SetClassFilter(Class, Val) end
		end

		AddFilterCheckBox("#tool.acfarmormesh.filter_acf_gearbox", "acf_gearbox")
		AddFilterCheckBox("#tool.acfarmormesh.filter_acf_fuel", "acf_fuel")
	end

	ACF.CreateArmorMeshMenu = CreateArmorMeshMenu
	TOOL.BuildCPanel = CreateArmorMeshMenu

	-- "torchfont" is created by the cutting torch's clientside file; it always loads alongside this tool, and
	-- DrawToolScreen only runs at render time, well after every file has loaded, so the font is guaranteed to exist.
	local ScreenText = Color(224, 224, 255)
	local ScreenBG   = Color(200, 200, 200)
	local ScreenRed  = Color(200, 50, 50)
	local ScreenBlack = Color(0, 0, 0)
	local Center      = TEXT_ALIGN_CENTER

	-- Draws the targeted entity's total health bar on the toolgun screen. Per-convex armor and health stats are
	-- shown on the world tip instead, so only the total health bar is drawn here.
	function TOOL:DrawToolScreen()
		local Weapon    = self.Weapon
		local Health    = math.Round(Weapon:GetNWFloat("EntHealth", 0), 1)
		local MaxHealth = math.Round(Weapon:GetNWFloat("EntMaxHealth", 0), 1)

		cam.Start2D()
			render.Clear(0, 0, 0, 0)

			surface.SetDrawColor(ScreenBlack)
			surface.DrawRect(0, 0, 256, 256)

			draw.SimpleTextOutlined("#tool.acfarmormesh.armor_stats", "torchfont", 128, 48, ScreenText, Center, Center, 4, ScreenBlack)

			if MaxHealth > 0 then
				draw.SimpleTextOutlined("#acf.menu.health", "torchfont", 128, 120, ScreenText, Center, Center, 4, ScreenBlack)
				draw.RoundedBox(6, 10, 145, 236, 64, ScreenBG)
				draw.RoundedBox(6, 15, 150, math.Clamp(Health / MaxHealth, 0, 1) * 226, 54, ScreenRed)
				draw.SimpleTextOutlined(Health .. " / " .. MaxHealth, "torchfont", 128, 177, ScreenText, Center, Center, 4, ScreenBlack)
			else
				draw.SimpleTextOutlined("#acf.torch.no_target", "torchfont", 128, 140, ScreenText, Center, Center, 4, ScreenBlack)
			end
		cam.End2D()
	end

	local White = Color(255, 255, 255, Alpha)

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
		local ConvexHit   = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
		local HighlightID = ConvexHit and ConvexHit.ConvexID

		DrawConvexes(Entity, HighlightID)

		if HighlightID and Weapon:GetNWInt("ConvexID", -1) == HighlightID then
			local Material  = Weapon:GetNWString("ConvexMaterial", "")
			local Health    = Weapon:GetNWFloat("ConvexHealth", 0)
			local MaxHealth = Weapon:GetNWFloat("ConvexMaxHealth", 0)
			local Volume    = Entity.ACF_Volumetric_Mesh.Convexes[HighlightID].Volume

			local ArmorType  = ACF.Classes.ArmorTypes.Get(Material) or ACF.Classes.ArmorTypes.Get("Default")
			local Mass       = Volume * CubicInchToM3 * ArmorType.Density -- Volume is in^3, Density is kg/m^3
			local NominalHit = ACF.GetConvexHit(Entity, Trace.HitPos, -Trace.HitNormal, true)
			local Nominal    = NominalHit and NominalHit.GeoThick or 0

			local EffKE = ConvexHit.GeoThick * ArmorType.KineticMul
			local EffCE = ConvexHit.GeoThick * ArmorType.ChemicalMul

			local Text = string.format("Mat: %s\nNominal (mm): %.2f\nEff (mm): %.2f (KE) %.2f (CE)\nHP: %.2f / %.2f\nVolume (in^3): %.2f\nMass (kg): %.2f", Material, Nominal, EffKE, EffCE, Health, MaxHealth, Volume, Mass)
			AddWorldTip(Entity, Text, nil, Trace.HitPos)
		end
	end)

	-- Draws the contraption readout's sphere search area, when enabled.
	local GreenSphere = Color(0, 200, 0, 50)
	local GreenFrame  = Color(0, 200, 0, 100)

	hook.Add("PostDrawOpaqueRenderables", "ACF_ArmorMesh_SearchSphere", function(bDrawingDepth, _, bDrawingSkybox)
		if bDrawingDepth or bDrawingSkybox then return end

		local Player = LocalPlayer()
		local Weapon = Player:GetActiveWeapon()
		if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return end

		local Tool = Player:GetTool()
		if not Tool or Tool ~= Player:GetTool("acfarmormesh") then return end
		if not SphereSearch:GetBool() then return end

		local Radius = SphereRadius:GetFloat()
		if Radius <= 0 then return end

		local Pos = Player:GetEyeTrace().HitPos

		render.SetColorMaterial()
		render.DrawSphere(Pos, Radius, 20, 20, GreenSphere)
		render.DrawWireframeSphere(Pos, Radius, 20, 20, GreenFrame, true)
	end)
elseif SERVER then
	-- Stores the entity's convex materials as an entity modifier so they persist through duplication.
	local function SaveConvexMaterials(Entity)
		duplicator.StoreEntityModifier(Entity, "ACF_ArmorMesh", { Materials = Entity.ACF_Volumetric_Materials })
	end

	-- ProcessConvexes reads Entity.ACF_Volumetric_Materials whenever it (re)computes the mesh, so attaching it
	-- here is enough to survive any future rebuilds (e.g. primitives reinitializing their physics). Convexes
	-- that already exist at restore time still need their materials applied directly.
	duplicator.RegisterEntityModifier("ACF_ArmorMesh", function(_, Entity, Data)
		if not Data or not Data.Materials then return end
		if Entity.ACF_PreventArmoring then return end

		Entity.ACF_Volumetric_Materials = Data.Materials

		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		for ConvexID in ipairs(MeshData.Convexes) do
			local Material = Data.Materials[ConvexID]
			if Material then
				ACF.SetConvexMaterial(Entity, ConvexID, Material)
			end
		end
	end)

	-- Backwards compatibility: entities duplicated with the old armor system's "ACF_Armor" entity modifier
	-- were always RHA. Convert them to the new per-convex material system, then clear the deprecated
	-- modifier so this conversion only happens once.
	duplicator.RegisterEntityModifier("ACF_Armor", function(_, Entity, Data)
		if not Data then return end
		if Entity.ACF_Volumetric_Materials then return end

		duplicator.ClearEntityModifier(Entity, "ACF_Armor")

		if Entity.ACF_PreventArmoring then return end

		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Materials = {}
		for ConvexID in ipairs(MeshData.Convexes) do
			Materials[ConvexID] = "RHA"
			ACF.SetConvexMaterial(Entity, ConvexID, "RHA")
		end

		Entity.ACF_Volumetric_Materials = Materials
		SaveConvexMaterials(Entity)
	end)

	local function GetFilteredClasses(Player)
		return util.JSONToTable(Player:GetInfo("acfarmormesh_class_filter")) or {}
	end

	local function DoRecursiveArmorTrace(Tool, InitialTrace)
		local Player     = Tool:GetOwner()
		local Messages   = ACF.Utilities.Messages
		local ArmorTypes = ACF.Classes.ArmorTypes
		local Filter     = GetFilteredClasses(Player)
		local Layers    = {}
		local Dir       = (InitialTrace.HitPos - InitialTrace.StartPos):GetNormalized()
		local Skipped   = {}  -- entities fully traversed, never hit again
		local Processed = {}  -- [Entity] = { [ConvexID] = true }
		local Current   = InitialTrace

		for _ = 1, 30 do
			local Entity = Current.Entity
			if not IsValid(Entity) then break end

			local Class = Entity:GetClass()

			if Entity.IsACFEntity or Filter[Class] then
				table.insert(Layers, {
					Terminal = true,
					Entity   = Entity,
				})
				break
			end

			if not Entity.ACF_Volumetric_Mesh then break end

			local ConvexHit = ACF.GetConvexHit(Entity, Current.HitPos, Dir, true)
			local NewStart

			if ConvexHit then
				local EntProcessed = Processed[Entity]

				if EntProcessed and EntProcessed[ConvexHit.ConvexID] then
					-- Ray has looped back to an already-recorded convex; entity is done.
					Skipped[Entity] = true
					NewStart = Current.HitPos + Dir * 0.5
				else
					if not EntProcessed then
						EntProcessed = {}
						Processed[Entity] = EntProcessed
					end
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

					-- Advance past this convex's exit face.
					-- ACF uses 1 Source unit = 1 inch = 25.4 mm, so GeoThick (mm) / 25.4 = inches.
					NewStart = Current.HitPos + Dir * (ConvexHit.GeoThick / 25.4 + 0.5)
				end
			else
				Skipped[Entity] = true
				NewStart = Current.HitPos + Dir * 0.5
			end

			Current = util.TraceLine({
				start  = NewStart,
				endpos = NewStart + Dir * 32768,
				filter = function(Ent) return not Skipped[Ent] end,
				mask   = MASK_SOLID,
			})
		end

		if #Layers == 0 then
			Messages.SendChat(Player, "Info", "No armor layers found along the trace.")
			return true
		end

		local TotalEffKE, TotalEffCE = 0, 0

		Messages.SendChat(Player, nil, "--- Recursive Armor Trace ---")

		for Index, Layer in ipairs(Layers) do
			local Ent    = Layer.Entity
			local EntStr = string.format("%s [%d]", Ent:GetClass(), Ent:EntIndex())

			if Layer.Terminal then
				Messages.SendChat(Player, nil, string.format("End: %s", EntStr))
			else
				Messages.SendChat(Player, nil, string.format(
					"L%d: %s | %s | %.1f mm KE | %.1f mm CE",
					Index, EntStr, Layer.Material, Layer.EffKE, Layer.EffCE
				))
				TotalEffKE = TotalEffKE + Layer.EffKE
				TotalEffCE = TotalEffCE + Layer.EffCE
			end
		end

		Messages.SendChat(Player, nil, string.format(
			"Total: %.1f mm effective (KE) | %.1f mm effective (CE)",
			TotalEffKE, TotalEffCE
		))

		return true
	end

	-- Keeps the toolgun's NW vars in sync with the convex under the player's crosshair, for client-side display.
	function TOOL:Think()
		local Player = self:GetOwner()
		local Trace  = Player:GetEyeTrace()
		local Entity = Trace.Entity
		local Weapon = self.Weapon

		if IsValid(Entity) then ACF.Check(Entity) end

		local EntHealth, EntMaxHealth = 0, 0
		local ConvexHit
		if IsValid(Entity) and Entity.ACF_Volumetric_Mesh then
			EntHealth, EntMaxHealth = ACF.GetEntityHealth(Entity)

			local Dir = (Trace.HitPos - Trace.StartPos):GetNormalized()
			ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
		end

		Weapon:SetNWFloat("EntHealth", EntHealth)
		Weapon:SetNWFloat("EntMaxHealth", EntMaxHealth)

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

		if Entity.ACF_PreventArmoring then
			ACF.Utilities.Messages.SendChat(self:GetOwner(), "Error", "This entity's armor material cannot be changed.")
			return false
		end

		local Dir       = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
		if not ConvexHit then return false end

		local Material = self:GetClientInfo("material")

		ACF.SetConvexMaterial(Entity, ConvexHit.ConvexID, Material)

		Entity.ACF_Volumetric_Materials = Entity.ACF_Volumetric_Materials or {}
		Entity.ACF_Volumetric_Materials[ConvexHit.ConvexID] = Material

		SaveConvexMaterials(Entity)

		return true
	end

	-- Eyedropper: copies the material of the convex under the crosshair into the tool's selection.
	function TOOL:RightClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return false end
		if not Entity.ACF_Volumetric_Mesh then return false end

		local Dir       = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
		if not ConvexHit then return false end

		local Convex = Entity.ACF_Volumetric_Mesh.Convexes[ConvexHit.ConvexID]

		self:GetOwner():ConCommand("acfarmormesh_material " .. Convex.Material)

		return true
	end

	function TOOL:Reload(Trace)
		print(self:GetOwner():KeyDown(IN_DUCK))
		if self:GetOwner():KeyDown(IN_DUCK) then return DoRecursiveArmorTrace(self, Trace) end
		return self:GetContraptionReadout(Trace, self:GetOwner():KeyDown(IN_SPEED))
	end
end

--------------------------------------------------------------------------------------------------------------

do -- Contraption Readout
	local Contraption = ACF.Contraption
	local Messages    = ACF.Utilities.Messages

	-- Emulates the stuff done by ACF.CalcMassRatio except with a given set of entities
	local function ProcessList(Entities)
		local SeenConstraints, Owners, SeenOwners = {}, {}, {}
		local OwnerNum, Power, Fuel, PhysNum, ParNum, ConNum, OtherNum, Total, PhysTotal = 0, 0, 0, 0, 0, 0, 0, 0, 0

		for _, Ent in ipairs(Entities) do
			if not ACF.Check(Ent) then
				if not Ent:IsWeapon() then OtherNum = OtherNum + 1 end -- We don't want to count weapon entities
			elseif not (Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot()) then -- These will pass the ACF check, but we don't want them either
				local Owner   = Ent:CPPIGetOwner() or game.GetWorld()
				local PhysObj = Ent.ACF.PhysObj
				local Class   = Ent:GetClass()
				local Mass    = PhysObj:GetMass()
				local IsPhys  = false

				if (IsValid(Owner) or Owner:IsWorld()) and not SeenOwners[Owner] then
					local Name = Owner:GetName()
					OwnerNum = OwnerNum + 1
					Owners[OwnerNum] = Name ~= "" and Name or "World"
					SeenOwners[Owner] = true
				end

				if Class == "acf_engine" then Power = Power + Ent.PeakPower * ACF.KwToHp
				elseif Class == "acf_fueltank" then Fuel = Fuel + Ent.Capacity end

				-- If it has any valid constraint then it's a physical entity
				for _, Con in pairs(Ent.Constraints or {}) do
					if IsValid(Con) and Con.Type ~= "NoCollide" then -- Nocollides don't count
						IsPhys = true
						if not SeenConstraints[Con] then
							SeenConstraints[Con] = true
							ConNum = ConNum + 1
						end
					end
				end

				-- If it has no valid constraints but also no valid parent, then it's a physical entity
				if not (IsPhys or IsValid(Ent:GetParent())) then IsPhys = true end

				if IsPhys then
					PhysTotal = PhysTotal + Mass
					PhysNum = PhysNum + 1
				else
					ParNum = ParNum + 1
				end

				Total = Total + Mass
			end
		end

		local Name = next(Owners) and table.concat(Owners, ", ") or "None"

		return Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Total, PhysTotal
	end

	local Modes = {
		Default = {
			CanCheck = function(_, Trace)
				local Ent = Trace.Entity

				if not IsValid(Ent) then return false end
				if Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot() then return false end

				return true
			end,
			GetResult = function(_, Trace)
				local Ent = Trace.Entity
				local Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum = Contraption.CalcMassRatio(Ent, true)

				return Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Ent.acftotal, Ent.acfphystotal
			end,
			GetCost = function(_, Trace)
				if not IsValid(Trace.Entity) then return 0, {} end

				local Contraption_ = Trace.Entity:CFW_GetContraption()
				if Contraption_ then
					return Contraption.CostSystem.CalcCostsFromContraption(Contraption_)
				else
					return Contraption.CostSystem.CalcCostsFromEnts({Trace.Entity})
				end
			end
		},
		Sphere = {
			CanCheck = function(Tool)
				return Tool:GetClientNumber("sphere_radius") > 0
			end,
			-- TODO: The old armor tool's ProcessList walked every entity in the sphere individually to
			-- build this readout; it was dated and unoptimized, so it hasn't been ported yet.
			GetResult = function(Tool, Trace)
				local Ents = ents.FindInSphere(Trace.HitPos, Tool:GetClientNumber("sphere_radius"))
				return ProcessList(Ents)
			end,
			GetCost = function(Tool, Trace)
				local Ents = ents.FindInSphere(Trace.HitPos, Tool:GetClientNumber("sphere_radius"))
				return Contraption.CostSystem.CalcCostsFromEnts(Ents)
			end
		}
	}

	local function GetReadoutMode(Tool)
		if tobool(Tool:GetClientInfo("sphere_search")) then return Modes.Sphere end

		return Modes.Default
	end

	local Text1 = "--- Contraption Readout (Owner: %s) ---"
	local Text2 = "Mass: %s kg total | %s kg physical (%s%%) | %s kg parented"
	local Text3 = "Mobility: %s hp/ton @ %s hp | %s liters of fuel"
	local Text4 = "Entities: %s (%s physical, %s parented, %s other entities) | %s constraints"
	local Text5 = "Name: %s | Type: %s"
	local Text6 = "Cost: %s | Ammo: %s"

	-- Total up mass of constrained ents
	function TOOL:GetContraptionReadout(Trace, UseCostBreakdown)
		local Mode = GetReadoutMode(self)

		if not Mode.CanCheck(self, Trace) then return false end
		if CLIENT then return true end

		local Cost, Breakdown = Mode.GetCost(self, Trace)
		if UseCostBreakdown then
			local Player = self:GetOwner()

			local NiceBreakdown = {}
			for item, cost in pairs(Breakdown) do
				table.insert(NiceBreakdown, {name = item, cost = cost})
			end

			table.sort(NiceBreakdown, function(a, b)
				return a.cost > b.cost
			end)

			Messages.SendChat(Player, nil, "--- Contraption Cost Breakdown ---")

			for _, Item in ipairs(NiceBreakdown) do
				Messages.SendChat(Player, nil, "| " .. Item.name .. ": " .. math.Round(Item.cost, 2))
			end

			Messages.SendChat(Player, nil, "TOTAL COST: ", math.Round(Cost, 2))
		else
			local Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Total, PhysTotal = Mode.GetResult(self, Trace)
			local HorsePower = math.Round(Power / math.max(Total * 0.001, 0.001), 1)
			local PhysRatio = math.Round(100 * PhysTotal / math.max(Total, 0.001))
			local ParentTotal = Total - PhysTotal
			local Player = self:GetOwner()
			local BaseplateName, BaseplateType, AmmoTypes = Contraption.GetMiscInfo(Trace.Entity)
			local AmmoList = next(AmmoTypes) and table.concat(AmmoTypes, ", ") or "N/A"

			Messages.SendChat(Player, nil, Text1:format(Name))
			Messages.SendChat(Player, nil, Text2:format(math.Round(Total, 2), math.Round(PhysTotal, 2), PhysRatio, math.Round(ParentTotal, 2)))
			Messages.SendChat(Player, nil, Text3:format(HorsePower, math.Round(Power), math.Round(Fuel)))
			Messages.SendChat(Player, nil, Text4:format(PhysNum + ParNum + OtherNum, PhysNum, ParNum, OtherNum, ConNum))
			Messages.SendChat(Player, nil, Text5:format(BaseplateName, BaseplateType))
			Messages.SendChat(Player, nil, Text6:format(math.Round(Cost, 2), AmmoList))
		end

		return true
	end
end
