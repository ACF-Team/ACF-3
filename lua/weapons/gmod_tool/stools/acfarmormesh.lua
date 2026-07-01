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

if CLIENT then
	language.Add("tool.acfarmormesh.name", "ACF Armor Mesh")
	language.Add("tool.acfarmormesh.desc", "Applies armor materials to individual convexes of an ACF volumetric mesh")
	language.Add("tool.acfarmormesh.left0", "Apply the selected material to the convex under your crosshair (Shift: apply to all convexes)")
	language.Add("tool.acfarmormesh.right0", "Copy the material of the convex under your crosshair")
	language.Add("tool.acfarmormesh.reload0", "Show contraption readout (Shift: cost breakdown, Ctrl: recursive armor trace, Ctrl+Shift: orthographic armor scan)")

	local SphereSearch      = CreateClientConVar("acfarmormesh_sphere_search", 0, false, true, "", 0, 1)
	local SphereRadius      = CreateClientConVar("acfarmormesh_sphere_radius", 0, false, true, "", 0, 10000)
	local AlphaConVar       = CreateClientConVar("acfarmormesh_alpha", 50, false, true, "", 0, 255)
	local ClassFilter       = CreateClientConVar("acfarmormesh_class_filter", "", false, true)
	CreateClientConVar("acfarmormesh_ignore_elevation", 0, false, true, "", 0, 1)
	CreateClientConVar("acfarmormesh_scan_resolution", 16, false, true, "", 4, 64)
	CreateClientConVar("acfarmormesh_scan_size", 160, false, true, "", 10, 10000)
	local ScanPen           = CreateClientConVar("acfarmormesh_scan_pen", 100, false, true, "", 0, 1500)
	local ScanTransparency  = CreateClientConVar("acfarmormesh_scan_transparency", 50, false, true, "", 0, 100)

	local ScanViewParams
	local ScanRTPending = false
	local ScanRT_Size   = 512
	local ScanRT = GetRenderTarget("ACF_ArmorScan_BG", ScanRT_Size, ScanRT_Size)
	local ScanRTMat

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

	local function DoRecursiveArmorTrace(Tool, InitialTrace)
		local Messages                 = ACF.Utilities.Messages
		local Dir                      = GetTraceDir(Tool)
		local Layers, TotalKE, TotalCE = GetArmorLayers(InitialTrace, Dir, GetClassFilter())

		if #Layers == 0 then
			Messages.PrintChat("Info", "No armor layers found along the trace.")
			return true
		end

		Messages.PrintChat("Normal", "--- Recursive Armor Trace ---")

		for Index, Layer in ipairs(Layers) do
			local Ent    = Layer.Entity
			local EntStr = string.format("%s [%d]", Ent:GetClass(), Ent:EntIndex())

			if Layer.Terminal then
				Messages.PrintChat("Normal", string.format("End: %s", EntStr))
			else
				Messages.PrintChat("Normal", string.format(
					"L%d: %s | %s | %.1f mm KE | %.1f mm CE",
					Index, EntStr, Layer.Material, Layer.EffKE, Layer.EffCE
				))
			end
		end

		Messages.PrintChat("Normal", string.format(
			"Total: %.1f mm effective (KE) | %.1f mm effective (CE)",
			TotalKE, TotalCE
		))

		return true
	end

	local ScanPanel

	local function OpenArmorScanPanel(Resolution, Cells, MaxKE, MaxCE)
		if IsValid(ScanPanel) then ScanPanel:Remove() end

		local ActualGrid = math.max(2, math.floor(512 / Resolution)) * Resolution

		ScanPanel = vgui.Create("DFrame")
		ScanPanel:SetTitle("Armor Scan (" .. Resolution .. "x" .. Resolution .. ")")
		ScanPanel:SetSize(ActualGrid, ActualGrid + 82)
		ScanPanel:Center()
		ScanPanel:MakePopup()
		ScanPanel:SetSizable(true)

		local ShowKE       = true
		local QueryPen     = ScanPen:GetInt()
		local OverlayAlpha = ScanTransparency:GetInt()
		local CursorX, CursorY, HoverCell

		local BtnW = 60

		-- Controls panel must be docked before Grid so FILL gets remaining space
		local ControlsPanel = ScanPanel:Add("DPanel")
		ControlsPanel:Dock(BOTTOM)
		ControlsPanel:SetTall(58)
		ControlsPanel:SetPaintBackground(false)
		ControlsPanel:DockPadding(0, 4, 0, 4)

		local InfoLabel = ControlsPanel:Add("DLabel")
		InfoLabel:Dock(TOP)
		InfoLabel:SetTall(20)
		InfoLabel:SetText("")

		local BtnRow = ControlsPanel:Add("DPanel")
		BtnRow:Dock(FILL)
		BtnRow:DockMargin(0, 4, 0, 0)
		BtnRow:SetPaintBackground(false)

		local KEBtn = BtnRow:Add("DButton")
		KEBtn:SetText("KE")
		KEBtn:Dock(LEFT)
		KEBtn:SetWide(BtnW)
		function KEBtn:DoClick() ShowKE = true end

		local CEBtn = BtnRow:Add("DButton")
		CEBtn:SetText("CE")
		CEBtn:Dock(LEFT)
		CEBtn:SetWide(BtnW)
		CEBtn:DockMargin(8, 0, 0, 0)
		function CEBtn:DoClick() ShowKE = false end

		local SlidersPanel = BtnRow:Add("DPanel")
		SlidersPanel:Dock(FILL)
		SlidersPanel:DockMargin(8, 0, 0, 0)
		SlidersPanel:SetPaintBackground(false)

		local PenSlider = SlidersPanel:Add("DNumSlider")
		PenSlider:SetText("Pen (mm)")
		PenSlider:SetMin(0)
		PenSlider:SetMax(1500)
		PenSlider:SetDecimals(0)
		PenSlider:SetValue(QueryPen)
		PenSlider.Label:SetDark(true)
		function PenSlider:OnValueChanged(Val)
			QueryPen = Val
			RunConsoleCommand("acfarmormesh_scan_pen", Val)
		end

		local AlphaSlider = SlidersPanel:Add("DNumSlider")
		AlphaSlider:SetText("Transparency (%)")
		AlphaSlider:SetMin(0)
		AlphaSlider:SetMax(100)
		AlphaSlider:SetDecimals(0)
		AlphaSlider:SetValue(OverlayAlpha)
		AlphaSlider.Label:SetDark(true)
		function AlphaSlider:OnValueChanged(Val)
			OverlayAlpha = Val
			RunConsoleCommand("acfarmormesh_scan_transparency", Val)
		end

		function SlidersPanel:PerformLayout(W, H)
			local SliderW = (W - 8) / 2
			PenSlider:SetPos(0, 0)
			PenSlider:SetSize(SliderW, H)
			AlphaSlider:SetPos(SliderW + 8, 0)
			AlphaSlider:SetSize(W - SliderW - 8, H)
		end

		local Grid = ScanPanel:Add("DPanel")
		Grid:Dock(FILL)
		Grid:SetMouseInputEnabled(true)

		function Grid:Paint(W, H)
			if not ScanRTMat then
				ScanRTMat = CreateMaterial("ACF_ArmorScan_BG_Mat", "UnlitGeneric")
				ScanRTMat:SetTexture("$basetexture", ScanRT)
			end
			surface.SetMaterial(ScanRTMat)
			surface.SetDrawColor(180, 180, 180, 255)
			surface.DrawTexturedRect(0, 0, W, H)

			local Max    = ShowKE and MaxKE or MaxCE
			local CellPx = W / Resolution
			for I = 1, #Cells do
				local Row = math.floor((I - 1) / Resolution)
				local Col = (I - 1) % Resolution
				local Val = ShowKE and Cells[I].KE or Cells[I].CE
				if Val > 0 then
					local Hue
					if QueryPen > 0 then
						Hue = Val < QueryPen and 120 or 0  -- green = penetrable, red = impenetrable
					else
						Hue = (1 - (Max > 0 and math.log(Val + 1) / math.log(Max + 1) or 0)) * 120
					end
					local Col2  = HSVToColor(Hue, 1, 1)
					local X0    = math.floor(Col * CellPx)
					local Y0    = math.floor(Row * CellPx)
					local X1    = math.floor((Col + 1) * CellPx)
					local Y1    = math.floor((Row + 1) * CellPx)
					surface.SetDrawColor(Col2.r, Col2.g, Col2.b, math.Round(OverlayAlpha / 100 * 255))
					surface.DrawRect(X0, Y0, X1 - X0, Y1 - Y0)
				end
			end

			if HoverCell then
				local Val   = ShowKE and HoverCell.KE or HoverCell.CE
				local Label = string.format("%.1f mm", Val)
				surface.SetFont("DermaDefault")
				local TW, TH = surface.GetTextSize(Label)
				local TipX = math.min(CursorX + 10, W - TW - 8)
				local TipY = math.min(CursorY + 10, H - TH - 4)
				surface.SetDrawColor(20, 20, 20, 220)
				surface.DrawRect(TipX - 4, TipY - 2, TW + 8, TH + 4)
				surface.SetTextColor(255, 255, 255, 255)
				surface.SetTextPos(TipX, TipY)
				surface.DrawText(Label)
			end
		end

		function Grid:OnCursorMoved(X, Y)
			CursorX, CursorY = X, Y
			local CellPx = self:GetWide() / Resolution
			local C = math.floor(X / CellPx)
			local R = math.floor(Y / CellPx)
			local I = R * Resolution + C + 1
			HoverCell = Cells[I]
			if HoverCell then
				InfoLabel:SetText(string.format(
					"Cell (%d, %d)  —  KE: %.1f mm  |  CE: %.1f mm",
					C + 1, R + 1, HoverCell.KE, HoverCell.CE
				))
			end
		end

		function Grid:OnCursorExited()
			HoverCell = nil
			InfoLabel:SetText("")
		end

		function ScanPanel:OnSizeChanged(W, H)
			local Overhead = 24 + ControlsPanel:GetTall()
			if H ~= W + Overhead then
				self:SetSize(W, W + Overhead)
			end
		end
	end

	local function DoArmorScan(Tool, InitialTrace)
		local Messages   = ACF.Utilities.Messages
		local Filter     = GetClassFilter()
		local Resolution = math.Clamp(math.floor(Tool:GetClientNumber("scan_resolution")), 4, 64)
		local ScanSize   = math.Clamp(Tool:GetClientNumber("scan_size"), 10, 10000)
		local CellSize   = ScanSize / Resolution
		local Dir        = GetTraceDir(Tool)

		local WorldUp = math.abs(Dir:Dot(Vector(0, 0, 1))) < 0.99 and Vector(0, 0, 1) or Vector(0, 1, 0)
		local Right   = Dir:Cross(WorldUp):GetNormalized()
		local Up      = Right:Cross(Dir):GetNormalized()

		local HitPos = InitialTrace.HitPos

		local BackTrace = util.TraceLine({
			start  = HitPos,
			endpos = HitPos - Dir * 2048,
			filter = LocalPlayer(),
			mask   = MASK_SOLID,
		})
		local CameraDistance = math.max(50, math.min(500, (BackTrace.HitPos - HitPos):Length() - 16))
		local CameraPos      = HitPos - Dir * CameraDistance

		Messages.PrintChat("Info", string.format(
			"Running armor scan (%dx%d, %.0f in wide)...", Resolution, Resolution, ScanSize
		))

		local Cells        = {}
		local MaxKE, MaxCE = 0, 0

		for Row = 0, Resolution - 1 do
			for Col = 0, Resolution - 1 do
				local OffRight = (Col - (Resolution - 1) * 0.5) * CellSize
				local OffUp    = ((Resolution - 1 - Row) - (Resolution - 1) * 0.5) * CellSize

				local Target = HitPos + Right * OffRight + Up * OffUp
				local RayDir = (Target - CameraPos):GetNormalized()

				local StartTrace = util.TraceLine({
					start  = CameraPos,
					endpos = CameraPos + RayDir * 65536,
					filter = LocalPlayer(),
					mask   = MASK_SOLID,
				})

				local _, TotalKE, TotalCE = GetArmorLayers(StartTrace, RayDir, Filter)

				if TotalKE > MaxKE then MaxKE = TotalKE end
				if TotalCE > MaxCE then MaxCE = TotalCE end

				Cells[#Cells + 1] = { KE = TotalKE, CE = TotalCE }
			end
		end

		ScanViewParams = { Origin = CameraPos, Angles = Dir:Angle(), ScanSize = ScanSize, CameraDistance = CameraDistance }
		ScanRTPending  = true
		OpenArmorScanPanel(Resolution, Cells, MaxKE, MaxCE)

		return false -- suppress toolgun effect so it doesn't appear in the RT capture
	end

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(Trace)
		local Owner       = self:GetOwner()
		local Ctrl, Shift = Owner:KeyDown(IN_DUCK), Owner:KeyDown(IN_SPEED)
		if Ctrl and Shift then return DoArmorScan(self, Trace) end
		if Ctrl then return DoRecursiveArmorTrace(self, Trace) end
		if Shift then return self:GetContraptionReadout(Trace, true) end
		return self:GetContraptionReadout(Trace, false)
	end

	-- In singleplayer, TOOL:Reload only fires serverside; the server nets Ctrl key state here so
	-- the client can run the clientside-only trace functions.
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

		local SphereCheck = Menu:AddCheckBox("#tool.acfarmormesh.sphere_search", "acfarmormesh_sphere_search")
		Menu:AddHelp("#tool.acfarmormesh.sphere_search_desc")

		local SphereRadiusSlider = Menu:AddSlider("#tool.acfarmormesh.sphere_search_radius", 0, 2000, 0)
		SphereRadiusSlider:SetConVar("acfarmormesh_sphere_radius")
		Menu:AddHelp("#tool.acfarmormesh.sphere_search_radius_desc")

		function SphereCheck:OnChange(Bool)
			SphereRadiusSlider:SetEnabled(Bool)
		end

		SphereRadiusSlider:SetEnabled(SphereCheck:GetChecked())

		local AlphaSlider = Menu:AddSlider("Convex Overlay Alpha", 0, 255, 0)
		AlphaSlider:SetConVar("acfarmormesh_alpha")

		Menu:AddCheckBox("Ignore camera elevation", "acfarmormesh_ignore_elevation")
		Menu:AddHelp("When enabled, the recursive armor trace fires horizontally toward the hit point, as if the camera had no pitch angle.")

		local ScanSection = Menu:AddCollapsible("Orthographic Armor Scan", false)

		local ScanResolutionSlider = ScanSection:AddSlider("Scan Resolution", 4, 64, 0)
		ScanResolutionSlider:SetConVar("acfarmormesh_scan_resolution")
		ScanSection:AddHelp("Number of cells per side in the orthographic scan grid.")

		local ScanSizeSlider = ScanSection:AddSlider("Scan Area Size (in)", 10, 10000, 0)
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
		if not SphereSearch:GetBool() then return end

		local Radius = SphereRadius:GetFloat()
		if Radius <= 0 then return end

		local Pos = Player:GetEyeTrace().HitPos

		render.SetColorMaterial()
		render.DrawSphere(Pos, Radius, 20, 20, GreenSphere)
		render.DrawWireframeSphere(Pos, Radius, 20, 20, GreenFrame, true)
	end)

	hook.Add("PostRender", "ACF_ArmorScan_BG", function()
		if not ScanRTPending or not ScanViewParams or not ScanRT then return end
		ScanRTPending = false

		local Half = ScanViewParams.ScanSize * 0.5
		local FOV  = math.deg(2 * math.atan(Half / ScanViewParams.CameraDistance))

		render.PushRenderTarget(ScanRT)
		render.RenderView({
			origin        = ScanViewParams.Origin,
			angles        = ScanViewParams.Angles,
			x = 0, y = 0, w = ScanRT_Size, h = ScanRT_Size,
			drawviewmodel = false,
			fov           = FOV,
		})
		render.PopRenderTarget()
	end)
elseif SERVER then
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
		if Entity.ACF_Volumetric_Materials then return end
		if Entity.ACF_Volumetric_Material_Override then return end

		duplicator.ClearEntityModifier(Entity, "ACF_Armor")

		if Entity.ACF_PreventArmoring then return end

		Entity.ACF_Volumetric_Material_Override = "RHA"

		Entity.ACF_Armor_Legacy_Thickness = Data.Thickness or 0
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
			-- DoRecursiveArmorTrace and DoArmorScan are clientside-only; in singleplayer TOOL:Reload
			-- is only called serverside, so we net the key state so the client can handle it.
			net.Start("ACF_ArmorMesh_Reload")
				net.WriteBool(Shift)
			net.Send(Owner)
			return false
		end
		if Shift then return self:GetContraptionReadout(Trace, true) end
		return self:GetContraptionReadout(Trace, false)
	end
end

--------------------------------------------------------------------------------------------------------------

do -- Contraption Readout
	local Contraption = ACF.Contraption
	local Messages    = ACF.Utilities.Messages

	-- Filters a raw entity list into a pseudo-contraption and delegates tally/mass work to CalcMassRatioFromContraption.
	-- Owner tracking stays here because it has no equivalent in the shared contraption path.
	local function ProcessList(Entities)
		local ValidEnts  = {}
		local ValidCount = 0
		local OtherNum   = 0
		local SeenOwners = {}
		local Owners     = {}
		local OwnerNum   = 0

		for _, Ent in ipairs(Entities) do
			if not ACF.Check(Ent) then
				if not Ent:IsWeapon() then OtherNum = OtherNum + 1 end
			elseif not (Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot()) then
				ValidCount            = ValidCount + 1
				ValidEnts[ValidCount] = Ent

				local Owner = Ent:CPPIGetOwner() or game.GetWorld()

				if (IsValid(Owner) or Owner:IsWorld()) and not SeenOwners[Owner] then
					local Name           = Owner:GetName()
					OwnerNum             = OwnerNum + 1
					Owners[OwnerNum]     = Name ~= "" and Name or "World"
					SeenOwners[Owner]    = true
				end
			end
		end

		local PseudoCon = ACF.EntitiesToPseudoContraption(ValidEnts)
		local Power, Fuel, PhysNum, ParNum, ConNum, ExtraOther, Total, PhysTotal = Contraption.CalcMassRatioFromContraption(PseudoCon, true)
		local Name = next(Owners) and table.concat(Owners, ", ") or "None"

		return Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum + ExtraOther, Total, PhysTotal
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
