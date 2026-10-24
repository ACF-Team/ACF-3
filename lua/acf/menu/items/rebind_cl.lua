local ACF = ACF

-- Included directly since menu items can be built before the acf_controller entity class has loaded
include("entities/acf_controller/modules_sh/binds_sh.lua")

local function ComboText(Codes)
	local Parts = {}
	for _, Code in ipairs(Codes) do
		Parts[#Parts + 1] = input.GetKeyName(Code) or ("#" .. Code)
	end
	return table.concat(Parts, " + ")
end

-- Text for a bind's active combo, its saved override if it has one, otherwise its registered default
local function BindText(Bind)
	return ComboText(ACF.GetSavedControllerBinds()[Bind.ID] or Bind.Default)
end

local function ReloadBinds()
	if ACF.ReloadControllerBinds then ACF.ReloadControllerBinds() end
end

-- Captures the next combo of keys pressed on Btn, handling multiple simultaneous keys, Escape cancels.
local function StartCapture(Btn, Bind)
	local Held = {}
	local Captured = {}

	Btn:SetText("Press keys...")
	Btn:SetKeyboardInputEnabled(true)
	Btn:RequestFocus()

	local function StopCapture()
		Btn:SetKeyboardInputEnabled(false)
		Btn.OnKeyCodePressed = nil
		Btn.OnKeyCodeReleased = nil
	end

	function Btn:OnKeyCodePressed(Code)
		if Code == KEY_ESCAPE then
			Btn:SetText(BindText(Bind))
			StopCapture()
			return
		end

		Held[Code] = true
		Captured[Code] = true
	end

	function Btn:OnKeyCodeReleased(Code)
		Held[Code] = nil
		if next(Held) then return end -- Wait for every held key to be released before finalizing

		local Codes = {}
		for CapturedCode in pairs(Captured) do Codes[#Codes + 1] = CapturedCode end
		table.sort(Codes)

		if #Codes > 0 then
			ACF.SaveControllerBind(Bind.ID, Codes)
			ReloadBinds()
		end

		Btn:SetText(BindText(Bind))
		StopCapture()
	end
end

-- Window must be a plain docking panel, an ACF_Panel sizes itself to its children and fights FILL docking
local function BuildBindsPanel(Window)
	local Help = Window:Add("DLabel")
	Help:SetText("Click a bind to set it. Hold multiple keys together for a combo, Escape cancels.")
	Help:SetFont("ACF_Label")
	Help:SetDark(true)
	Help:SetWrap(true)
	Help:SetAutoStretchVertical(true)
	Help:Dock(TOP)
	Help:DockMargin(5, 5, 5, 5)

	local Search = Window:Add("DTextEntry")
	Search:SetPlaceholderText("Search binds...")
	Search:Dock(TOP)
	Search:DockMargin(5, 0, 5, 5)

	local Rows = {}

	-- Docked before Scroll so BOTTOM reserves its space first; FILL (added after) then fills the rest.
	local Reset = Window:Add("DButton")
	Reset:SetText("Reset All to Defaults")
	Reset:Dock(BOTTOM)
	Reset:DockMargin(5, 5, 5, 5)
	Reset.DoClick = function()
		for _, Entry in ipairs(Rows) do
			ACF.SaveControllerBind(Entry.Bind.ID, nil)
			Entry.Button:SetText(ComboText(Entry.Bind.Default))
		end
		ReloadBinds()
	end

	local Scroll = Window:Add("DScrollPanel")
	Scroll:Dock(FILL)
	Scroll:DockMargin(5, 0, 5, 5)

	for _, Bind in ipairs(ACF.ControllerBinds) do
		local Row = Scroll:Add("DPanel")
		Row:Dock(TOP)
		Row:DockMargin(0, 0, 0, 5)
		Row:SetTall(24)
		Row:SetPaintBackground(false)

		local Label = Row:Add("DLabel")
		Label:SetText(Bind.Label)
		Label:SetFont("ACF_Label")
		Label:SetDark(true)
		Label:SetWide(180)
		Label:Dock(LEFT)

		local Btn = Row:Add("DButton")
		Btn:SetText(BindText(Bind))
		Btn:Dock(FILL)
		Btn.DoClick = function() StartCapture(Btn, Bind) end

		Rows[#Rows + 1] = { Panel = Row, Bind = Bind, Button = Btn }
	end

	function Search:OnValueChange(Text)
		Text = string.lower(Text or "")

		for _, Entry in ipairs(Rows) do
			Entry.Panel:SetVisible(Text == "" or string.find(string.lower(Entry.Bind.Label), Text, 1, true) ~= nil)
		end

		Scroll:InvalidateLayout()
	end
end

--- Opens the controller binds menu as a standalone popup window.
function ACF.OpenControllerBindsMenu()
	local Window = vgui.Create("DFrame")
	Window:SetSize(420, 480)
	Window:SetTitle("AIO Controller Binds")
	Window:Center()
	Window:SetSizable(true)
	Window:MakePopup()

	BuildBindsPanel(Window)
end
