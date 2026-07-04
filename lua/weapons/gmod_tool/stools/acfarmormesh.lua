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
	{ name = "reload0", stage = 0 },
}

TOOL.ClientConVar["material"] = "RHA"

AddCSLuaFile("armormeshmodules/armor_trace.lua")
AddCSLuaFile("armormeshmodules/recursive_trace.lua")
AddCSLuaFile("armormeshmodules/grid_scan.lua")
AddCSLuaFile("armormeshmodules/contraption_readout.lua")

include("armormeshmodules/contraption_readout.lua")

if CLIENT then
	language.Add("tool.acfarmormesh.name", "ACF Armor Mesh")
	language.Add("tool.acfarmormesh.desc", "Applies armor materials to individual convexes of an ACF volumetric mesh")
	language.Add("tool.acfarmormesh.left0", "Apply the selected material to the convex under your crosshair (Shift: apply to all convexes)")
	language.Add("tool.acfarmormesh.right0", "Copy the material of the convex under your crosshair")
	language.Add("tool.acfarmormesh.reload0", "Show contraption readout (Shift: cost breakdown, Ctrl: recursive armor trace, Ctrl+Shift: orthographic armor scan)")

	local ThicknessMin, ThicknessMax           = 0, 1000
	local SphereRadiusMin, SphereRadiusMax     = 0, 2000
	local AlphaMin, AlphaMax                   = 0, 255
	local ScanResolutionMin, ScanResolutionMax = 4, 64
	local ScanSizeMin, ScanSizeMax             = 10, 10000

	local SphereRadius      = CreateClientConVar("acfarmormesh_sphere_radius", 0, false, true, "", SphereRadiusMin, SphereRadiusMax)
	CreateClientConVar("acfarmormesh_thickness", 0, false, true, "", ThicknessMin, ThicknessMax)
	local AlphaConVar       = CreateClientConVar("acfarmormesh_alpha", 50, false, true, "", AlphaMin, AlphaMax)
	local ClassFilter       = CreateClientConVar("acfarmormesh_class_filter", "", false, true)
	CreateClientConVar("acfarmormesh_ignore_elevation", 0, false, true, "", 0, 1)

	local function GetClassFilter()
		local Filter = {}
		for Class in ClassFilter:GetString():gmatch("[^,]+") do
			Filter[Class] = true
		end
		return Filter
	end

	local function SetClassFilter(Class, Enabled)
		local Filter = GetClassFilter()
		Filter[Class] = Enabled or nil
		local Parts = {}
		for K in pairs(Filter) do
			Parts[#Parts + 1] = K
		end
		RunConsoleCommand("acfarmormesh_class_filter", table.concat(Parts, ","))
	end

	local ArmorTrace            = include("armormeshmodules/armor_trace.lua")
	local DoRecursiveArmorTrace = include("armormeshmodules/recursive_trace.lua")(ArmorTrace, GetClassFilter)
	local DoArmorScan           = include("armormeshmodules/grid_scan.lua")(ArmorTrace, GetClassFilter, ScanResolutionMin, ScanResolutionMax, ScanSizeMin, ScanSizeMax)

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(Trace)
		local Owner       = self:GetOwner()
		local Ctrl, Shift = Owner:KeyDown(IN_DUCK), Owner:KeyDown(IN_SPEED)
		-- Runs the trace/scan directly client-side to avoid a server round-trip. In true singleplayer
		-- this branch never actually fires (see the SERVER TOOL:Reload below), so no duplication occurs.
		if Ctrl and Shift then return DoArmorScan(self, Trace) end
		if Ctrl then return DoRecursiveArmorTrace(self, Trace) end
		if Shift then return self:GetContraptionReadout(Trace, true) end
		return self:GetContraptionReadout(Trace, false)
	end

	-- Only used as a true-singleplayer fallback (see SERVER TOOL:Reload below): prediction never runs
	-- this file's CLIENT TOOL:Reload there, so the server nets Ctrl key state here instead.
	net.Receive("ACF_ArmorMesh_Reload", function()
		local Shift = net.ReadBool()
		local Tool  = LocalPlayer():GetTool("acfarmormesh")
		if not Tool then return end
		local Trace = LocalPlayer():GetEyeTrace()
		if Shift then return DoArmorScan(Tool, Trace) end
		return DoRecursiveArmorTrace(Tool, Trace)
	end)

	local function CreateArmorMeshMenu(Panel)
		local ArmorTypes = ACF.Classes.ArmorTypes
		local Menu = ACF.InitMenuBase(Panel, "ArmorMeshMenu", "acf_reload_armor_mesh_menu")

		local Materials = Menu:AddComboBox()

		Menu:AddHelp("The material that will be applied to the convex under your crosshair.")

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

		local ThicknessSlider = Menu:AddSlider("Thickness", ThicknessMin, ThicknessMax, 0)
		ThicknessSlider:SetConVar("acfarmormesh_thickness")
		Menu:AddHelp("If set to a non zero value, left/right click will set/get the thickness of the primitive entity you are looking at, instead of changing its material.")

		local SphereRadiusSlider = Menu:AddSlider("#tool.acfarmormesh.sphere_search_radius", SphereRadiusMin, SphereRadiusMax, 0)
		SphereRadiusSlider:SetConVar("acfarmormesh_sphere_radius")
		Menu:AddHelp("#tool.acfarmormesh.sphere_search_radius_desc")

		local AlphaSlider = Menu:AddSlider("Convex Overlay Alpha", AlphaMin, AlphaMax, 0)
		AlphaSlider:SetConVar("acfarmormesh_alpha")

		Menu:AddCheckBox("Ignore camera elevation", "acfarmormesh_ignore_elevation")
		Menu:AddHelp("When enabled, the recursive armor trace fires horizontally toward the hit point, as if the camera had no pitch angle.")

		local ScanSection = Menu:AddCollapsible("Orthographic Armor Scan", false)

		local ScanResolutionSlider = ScanSection:AddSlider("Scan Resolution", ScanResolutionMin, ScanResolutionMax, 0)
		ScanResolutionSlider:SetConVar("acfarmormesh_scan_resolution")
		ScanSection:AddHelp("Number of cells per side in the orthographic scan grid.")

		local ScanSizeSlider = ScanSection:AddSlider("Scan Area Size (in)", ScanSizeMin, ScanSizeMax, 0)
		ScanSizeSlider:SetConVar("acfarmormesh_scan_size")
		ScanSection:AddHelp("Total side length of the scan area in world inches.")

		local FilterSection = Menu:AddCollapsible("Recursive Armor Class Filter", false)
		FilterSection:AddHelp("When enabled, entities of the selected classes will not stop the recursive armor trace.")

		local function AddFilterCheckBox(Class)
			local Check = FilterSection:AddCheckBox(Class)
			Check:SetValue(GetClassFilter()[Class] or false)
			function Check:OnChange(Val) SetClassFilter(Class, Val) end
		end

		AddFilterCheckBox("acf_gearbox")
		AddFilterCheckBox("acf_fueltank")
		AddFilterCheckBox("acf_gun")
		AddFilterCheckBox("acf_missile")
		AddFilterCheckBox("acf_rack")
		AddFilterCheckBox("acf_turret")
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

			draw.SimpleTextOutlined("ACF Stats", "torchfont", 128, 48, ScreenText, Center, Center, 4, ScreenBlack)

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

	local White = Color(255, 255, 255, 50)

	-- Draws every convex of the mesh as a translucent quad: white normally, colored if highlighted.
	-- Runs every frame instead of using debugoverlay so the visualization doesn't flicker.
	local function DrawConvexes(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		White.a = AlphaConVar:GetInt()

		render.SetColorMaterial()

		for Index, Convex in ipairs(MeshData.Convexes) do
			local IsHighlighted = Index == HighlightID
			local Col

			if IsHighlighted then
				Col = HSVToColor((Index * 47) % 360, 1, 1)
				Col.a = AlphaConVar:GetInt()
			else
				Col = White
			end

			for _, Tri in ipairs(Convex.Tris) do
				local A = Entity:LocalToWorld(Tri[1])
				local B = Entity:LocalToWorld(Tri[2])
				local C = Entity:LocalToWorld(Tri[3])

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

	hook.Add("PostDrawTranslucentRenderables", "ACF_ArmorMesh_Visualizer", function(bDrawingDepth, bDrawingSkybox, _)
		if bDrawingDepth or bDrawingSkybox then return end

		local _, Weapon, Trace, Entity = GetMeshTraceTarget()

		if IsValid(HiddenEntity) and HiddenEntity ~= Entity then
			HiddenEntity:SetNoDraw(false)
			HiddenEntity = nil
		end

		if not Entity then return end

		Entity:SetNoDraw(true)
		HiddenEntity = Entity

		local Dir         = LocalPlayer():GetAimVector()
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
		local Radius = SphereRadius:GetFloat()
		if Radius <= 0 then return end

		local Pos = Player:GetEyeTrace().HitPos

		render.SetColorMaterial()
		render.DrawSphere(Pos, Radius, 20, 20, GreenSphere)
		render.DrawWireframeSphere(Pos, Radius, 20, 20, GreenFrame, true)
	end)
elseif SERVER then
	local Notify = ACF.Utilities.Notify
	local PrimitiveThickness = include("armormeshmodules/primitive_thickness.lua")()

	util.AddNetworkString("ACF_ArmorMesh_Reload")

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
	-- were always uniformly RHA. Set ACF_Volumetric_Material_Override so ProcessConvexes applies RHA to all
	-- convexes regardless of count (hollow cube primitives reinitialize from 1 convex to 6, so per-convex
	-- data set at this point would be incomplete). The override is runtime-only; if the entity is re-duplicated
	-- it goes through the normal pipeline with whatever ACF_Volumetric_Materials is set at that time.
	duplicator.RegisterEntityModifier("ACF_Armor", function(_, Entity, Data)
		if not Data then return end

		duplicator.ClearEntityModifier(Entity, "ACF_Armor")

		if Entity.ACF_PreventArmoring then return end

		Entity.ACF_Volumetric_Material_Override = "RHA"

		Entity.ACF_Armor_Legacy_Thickness = Data.Thickness

		if not Entity.ACF_Volumetric_Mesh then return end
		for ConvexID in ipairs(Entity.ACF_Volumetric_Mesh.Convexes) do
			if Material then ACF.SetConvexMaterial(Entity, ConvexID, "RHA") end
		end
	end)

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

			local Dir = Player:GetAimVector()
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

		local Thickness = tonumber(self:GetClientInfo("thickness"))
		if Thickness and Thickness ~= 0 then
			local Player = self:GetOwner()

			if Entity:GetClass() ~= "primitive_shape" then
				Notify.WarningToPlayer(Player, "Cannot set thickness", "This is not a primitive entity.")
				return false
			end

			local Apply = PrimitiveThickness.GetThicknessApply(Entity:GetPrimTYPE())
			if not Apply then
				Notify.WarningToPlayer(Player, "Cannot set thickness", "This primitive shape does not support a thickness.")
				return false
			end

			Apply(Entity, Thickness / 25.4, Trace.HitNormal, Player)

			return true
		end

		if not ACF.Check(Entity) then return false end
		if not Entity.ACF_Volumetric_Mesh then return false end

		if Entity.ACF_PreventArmoring then
			ACF.Utilities.Messages.SendChat(self:GetOwner(), "Error", "This entity's armor material cannot be changed.")
			return false
		end

		local Material = self:GetClientInfo("material")

		local Player = self:GetOwner()
		if Player:KeyDown(IN_SPEED) then
			for ConvexID in ipairs(Entity.ACF_Volumetric_Mesh.Convexes) do
				ACF.SetConvexMaterial(Entity, ConvexID, Material, Player)
			end
		else
			local Dir       = Player:GetAimVector()
			local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
			if not ConvexHit then return false end

			if ACF.SetConvexMaterial(Entity, ConvexHit.ConvexID, Material, Player) == false then return false end
		end

		return true
	end

	-- Eyedropper: copies the material of the convex under the crosshair into the tool's selection.
	function TOOL:RightClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return false end

		local Thickness = tonumber(self:GetClientInfo("thickness"))
		if Thickness and Thickness ~= 0 then
			if Entity:GetClass() ~= "primitive_shape" then return false end

			local Value = PrimitiveThickness.GetThickness(Entity, Trace.HitNormal)
			if not Value then return false end

			self:GetOwner():ConCommand("acfarmormesh_thickness " .. math.Round(Value * 25.4, 1))

			return true
		end

		if not Entity.ACF_Volumetric_Mesh then return false end

		local Dir       = self:GetOwner():GetAimVector()
		local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
		if not ConvexHit then return false end

		local Convex = Entity.ACF_Volumetric_Mesh.Convexes[ConvexHit.ConvexID]

		self:GetOwner():ConCommand("acfarmormesh_material " .. Convex.Material)

		return true
	end

	function TOOL:Reload(Trace)
		local Owner = self:GetOwner()
		local Ctrl, Shift = Owner:KeyDown(IN_DUCK), Owner:KeyDown(IN_SPEED)
		if Ctrl then
			-- Client side predictions fails in singleplayer, so notify the client.
			if game.SinglePlayer() then
				net.Start("ACF_ArmorMesh_Reload")
					net.WriteBool(Shift)
				net.Send(Owner)
			end
			return false
		end
		if Shift then return self:GetContraptionReadout(Trace, true) end
		return self:GetContraptionReadout(Trace, false)
	end
end

