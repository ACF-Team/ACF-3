-- Takes the shared trace helpers (armor_trace.lua) and the tool's class filter accessor as explicit
-- dependencies, since locals from the main stool file aren't visible across include() boundaries.
return function(ArmorTrace, GetClassFilter)
	local ScanPen          = CreateClientConVar("acfarmormesh_scan_pen", 100, false, true, "", 0, 1500)
	local ScanTransparency = CreateClientConVar("acfarmormesh_scan_transparency", 50, false, true, "", 0, 100)
	CreateClientConVar("acfarmormesh_scan_resolution", 32, false, true, "", 4, 64)
	CreateClientConVar("acfarmormesh_scan_size", 160, false, true, "", 10, 10000)

	local ScanViewParams
	local ScanRTPending = false
	local ScanRT_Size   = 512
	local ScanRT = GetRenderTarget("ACF_ArmorScan_BG", ScanRT_Size, ScanRT_Size)
	local ScanRTMat

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
		local Dir        = ArmorTrace.GetTraceDir(Tool)

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

				local _, TotalKE, TotalCE = ArmorTrace.GetArmorLayers(StartTrace, RayDir, Filter)

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

	return DoArmorScan
end
