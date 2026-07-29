local ACF = ACF
local Sounds = ACF.Utilities.Sounds
local GetClientData, SetClientData = ACF.GetClientData, ACF.SetClientData
local GetClientNumber, GetClientString = ACF.GetClientNumber, ACF.GetClientString

-- Fixes the order of a panel that's parented and has many siblings, like a list(Think of them as if we were applying "Display: inline;" styling), so when  
-- you click into a focusable control (DNumberWang, DTextEntry), the call to RequestFocus() doesn't send them to the very end of the list, because internally
-- it calls MoveToFront(). Pinning an explicit ZPos helps keeping dock order in place, re-asserting it whenever RequestFocus fires undoes the MoveToFront bump 
-- immediately instead of letting it disturb the layout and messing up everything.
--- @param Panel table The panel to pin
--- @param ZPos integer The fixed dock order position to keep enforcing
--- @param Focusable? boolean Whether this panel can be clicked to edit (hooks RequestFocus if so)
local function LockDockOrder(Panel, ZPos, Focusable)
	Panel:SetZPos(ZPos)

	if not Focusable then return end

	local OldRequestFocus = Panel.RequestFocus
	function Panel:RequestFocus()
		if OldRequestFocus then OldRequestFocus(self) end

		self:SetZPos(ZPos)

		local Parent = self:GetParent()
		if IsValid(Parent) then Parent:InvalidateLayout(true) end
	end
end

if CLIENT then
	-- Keeps track of the client's currently selected submenu. 
	CreateClientConVar("acf_soundmenu_mode", 1, true, true)
end

	--- Generates the menu used in the Sound Replacer tool.
	--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateSoundMenu(Panel) -- MARK: CreateSoundMenu
	-- Main menu, aka the selection box from where everything else gets built upon
	local Menu = ACF.InitMenuBase(Panel, "SoundMenu", "acf_reload_sound_menu")
	Menu.ButtonHeight = 20
	Menu.Wide = Menu:GetWide()
	Menu:AddLabel("#tool.acfsound.help")

	local OptionSelectionBox = Menu:AddComboBox()
	OptionSelectionBox:SetText("Select an Option...")
	OptionSelectionBox:Dock(TOP)
	OptionSelectionBox:SetTall(Menu.ButtonHeight)
	OptionSelectionBox:AddChoice("Generic - One sound. ", 1) -- TODO: Localize me!
	OptionSelectionBox:AddChoice("Engines - Multiple interpolated. ", 2) -- TODO: Localize me!
	OptionSelectionBox:AddChoice("Weapons - Start/Loop/Stop. ", 3) -- TODO: Localize me!
	OptionSelectionBox.OnSelect = function(_, Index, _)
		RunConsoleCommand("acf_soundmenu_mode", tostring(Index))
		Menu:StartTemporal(Panel)
		Menu:ClearTemporal(Panel)
		Menu:CreateSubMenu(Index) -- Build the sub menu
		Menu:EndTemporal(Panel)
	end

	--- Build the rest of the menu according to our selection
	--- @param Num int The sub menu selected at the index.
	function Menu:CreateSubMenu(Num) -- MARK: CreateSubMenu
		--============================================================================================================--
		-- Local Constants, Variables, Tables and Methods															  --
		--============================================================================================================--
		local SoundGraph  					  -- Glocal
		local _MAX_NET_SOUND_RPM = (2 ^ ACF.NetSoundRPMBitLimit) - 1 -- Maximum limit RPM related stuff is allowed to have for networking reasons
		local Current = {					  -- Local table used to store objects and other miscellaneous stuff
			Panels  = {SoundBankPanels = {}}, -- Contains the panel objects
			Count   = {OfSoundBankPanels = 0, -- Keeps total count of them
					  OfSoundPanels = 0},
			Graph   = {Idle      = 0,         -- Graph that contains the values to be set for the SoundGraph panel
					  Redline   = 1,		  -- Datavars wouldn't initialize correctly so here is this...
					  RPMSlider = 2},
			Preview = {Channels = {}},        -- Holds the currently playing soundbank channels in the preview
			Colors  = (function() 			  -- IIFE that returns a table with optionally randomized colors and if the text should be dark or light colored
				local ColorTable = {}
				local IsRandomColor = GetClientData("GetRandomColors")

				for I = 1, ACF.MaxSounds do
					local Col
					if not IsRandomColor then
						-- In short, it creates a rainbow :3
						local Freq = 360 / ACF.MaxSounds
						Col = HSVToColor(I * Freq % 360, 1, 1)
					else
						-- Create a randomized reduced range color to allow it to contrast with the background
						Col = Color(math.random(25, 200), math.random(25, 200), math.random(25, 200))
					end
					-- Calculate luminance to determine text color (0.2126*R + 0.7152*G + 0.0722*B)
					local Luminance = (0.2126 * Col.r + 0.7152 * Col.g + 0.0722 * Col.b) / 255
					local TextColor = Luminance > 0.5 and color_black or color_white
					ColorTable[I] = {Col, TextColor}
				end

				return ColorTable
			end)()
		}
		--============================================================================================================--
		-- MARK: Helper funcs														 								  --
		--============================================================================================================--
		-- Recomputes the true total sound-panel count across every bank (not just one), and writes it into our Current table.
		-- This is called any time a soundBank Values table changes size, instead of overwriting the counter directly.
		local function RecalcTotalSoundPanels(SoundBankPanel)
			local Total = 0

			for I = 1, #SoundBankPanel do
				if SoundBankPanel[I] then
					Total = Total + #SoundBankPanel[I].Values
				end
			end
			Current.Count.OfSoundPanels = Total

			return Total
		end

		-- Pushes an updated max onto every slider so that no bank can be raised past the amount still available in the shared sound budget.
		local function RecalcSoundMaxes(SoundBankPanel)
			for I = 1, #SoundBankPanel do
				local Bank = SoundBankPanel[I]

				if Bank then
					local OwnCount    = #Bank.Values
					local OthersTotal = Current.Count.OfSoundPanels - OwnCount
					local MaxAllowed  = math.Clamp(ACF.MaxSounds - OthersTotal, 0, ACF.MaxSounds)

					Bank[2]:SetMax(MaxAllowed)
				end
			end
		end

		-- The graphing function, this is a mirror of the function found in sounds_cl.lua
		local function UpdateGraph()
			local Bank = GetClientData("SoundBankPlotIndex")
			if not Bank or not isnumber(Bank) then return end -- Kinda pointless isnumber check, but just in case...

			local Panel = Current.Panels.SoundBankPanels[Bank]
			if not Panel then return end

			local Count = #Panel.Values
			if not Count then return end

			local Clamp = math.Clamp
			local Fade = Sounds.Fade

			SoundGraph:Clear()

			for I = 1, Count do
				local AddCurveWidth = GetClientNumber("Width@SB" .. Bank .. "-" .. I, 0)
				local Volume = GetClientNumber("Volume@SB" .. Bank .. "-" .. I, 0) * 100
				local Min = I == 1 and -1000000 or GetClientNumber("RPM@SB" .. Bank .. "-" .. Clamp(I - 1 - AddCurveWidth, 1, ACF.MaxSounds))
				local Mid = GetClientNumber("RPM@SB" .. Bank .. "-" .. I, 0)
				local Max = I == Count and 1000000 or GetClientNumber("RPM@SB" .. Bank .. "-" .. Clamp(I + 1 + AddCurveWidth, 1, ACF.MaxSounds))

				-- The 1000 extra is so it can see til the graph X limit and not cutoff
				SoundGraph:PlotLimitFunction("Sound " .. I, 0, _MAX_NET_SOUND_RPM + 1000, Current.Colors[I][1], function(X) -- TODO: Localize me!
					return (Fade(X, Min, Mid, Max)) * Volume
				end)
			end
		end

		-- SoundBank's preview functions: Plays every sound in the currently-plotted bank simultaneously.
		-- Does cross-fading on them sound Pitch/Volume based on the RPM slider. This behavior mirrors exactly what
		-- DoPitchVolumeAtRPM does in sounds_cl.lua, just driven by this menu RPM slider instead of the entity's live RPM.
		local function UpdateSoundBankPreview(SoundBank, OffVolume, OnVolume, VolumeSliderPanel)
			local Fade = Sounds.Fade
			local Count = math.Clamp(#SoundBank, 1, ACF.MaxSounds)
			local RPM = Current.Graph.RPMSlider or 0
			-- DoPitchVolumeAtRPM expects a 0-100 range for throttle, but our volume slider works in the 0.1-1 range.
			-- So instead we simply multiply that by 100 to get the actual value that our function expects.
			local Throttle = VolumeSliderPanel:GetValue() * 100

			for I, SoundData in ipairs(SoundBank) do
				local Channel = Current.Preview.Channels[I]
				if not IsValid(Channel) then continue end

				local AddCurveWidth = SoundData.Width
				local Min = I == 1 and -1000000 or SoundBank[math.Clamp(I - 1 - AddCurveWidth, 1, Count)].RPM
				local Mid = SoundData.RPM
				local Max = I == Count and 1000000 or SoundBank[math.Clamp(I + 1 + AddCurveWidth, 1, Count)].RPM

				local Curve = Fade(RPM, Min, Mid, Max)
				local Volume = Curve * math.Remap(Throttle, 0, 100, OffVolume, OnVolume) * SoundData.Volume
				local Pitch = (RPM / SoundData.RPM) * SoundData.Pitch

				Channel:SetVolume(Volume * ACF.Volume)
				Channel:SetPlaybackRate(Pitch / 100)
			end
		end

		local function StopSoundBankPreview()
			for I, Channel in pairs(Current.Preview.Channels) do
				if IsValid(Channel) then Channel:Stop() end
				Current.Preview.Channels[I] = nil
			end

			Current.Preview.SoundList  = nil
			Current.Preview.OffVolume  = nil
			Current.Preview.OnVolume   = nil
		end
		--============================================================================================================--
		-- SUBMENUS of the SUBMENUS  																				  --
		--============================================================================================================--
		-- The function that adds the panels to the corresponding SoundBank panels 
		-- NOTE: For every DataVar defined here, they get formatted as follows:
		-- [VALUE]@SB[SoundBankPanelID]-[SoundPanelID]; e.g:
		-- RPM@SB1-1: DataVar with the RPM value of the first Soundpanel that's within the first SoundBank panel; 
		-- Volume@SB2-3: DataVar with the Volume value of the third Soundpanel that's within the second SoundBank panel.
		local AddValuePanel = function(SBPanelID) -- MARK: AddValuePanel
			Current.Panels.SoundBankPanels[SBPanelID].Values = Current.Panels.SoundBankPanels[SBPanelID].Values or {}
			local VPPanel   = Current.Panels.SoundBankPanels[SBPanelID].Values -- Just here for verbosity sake
			local PanelID   = #VPPanel == 0 and 1 or #VPPanel + 1 -- Ensure it always begins from 1 and increments from there on for every soundbank panel
			local BGColor   = Current.Colors[PanelID][1] or color_white
			local TextColor = Current.Colors[PanelID][2]

			-- Defaults
			local DefaultRPM    = 1000 * PanelID
			local DefaultPath   = ""
			local DefaultPitch  = 100
			local DefaultVolume = 1
			local DefaultWidth  = 0

			-- VGUI panels
			local BaseMainPanel, MainPanel = self:AddCollapsible()
			local BasePanel = BaseMainPanel:Add(self:AddPanel("DPanel"))
			local TopDiv = BasePanel:Add(self:AddPanel("ACF_Panel")) -- This is equivalent to a HTML Div, generic panel to parent other children to.
			local BotDiv = BasePanel:Add(self:AddPanel("ACF_Panel")) -- Same as above.
			local RPMWang, RPMLabel = self:AddNumberWang("RPM:", 0, _MAX_NET_SOUND_RPM, 0) -- TODO: Localize me!
			local _, PathLabel, PathText = self:AddTextEntry("Path:") -- TODO: Localize me!
			local ParseIcon = PathText:Add(self:AddPanel("DImage"))
			local SearchButton = TopDiv:Add(self:AddPanel("DImageButton"))
			local ClearButton = TopDiv:Add(self:AddPanel("DImageButton"))
			local PitchWang, PitchLabel = self:AddNumberWang("Pitch:", 0, 255, 0) -- TODO: Localize me!
			local VolumeWang, VolumeLabel = self:AddNumberWang("Volume:", 0, 1, 2) -- TODO: Localize me!
			local WidthWang, WidthLabel = self:AddNumberWang("Width:", 0, 15, 0) -- TODO: Localize me!

			local RPMWangBase = RPMWang:GetParent()
			local PitchWangBase = PitchWang:GetParent()
			local VolumeWangBase = VolumeWang:GetParent()
			local WidthWangBase = WidthWang:GetParent()

			BaseMainPanel:DockMargin(0, 0, 0, 0)
			BaseMainPanel:DockPadding(0, 0, 0, 0)

			MainPanel:DockMargin(0, 2, 0, 2)
			MainPanel:SetLabel("Value " .. PanelID) -- TODO: Localize me!

			BasePanel:SetTall(72)
			BasePanel:DockPadding(4, 8, 4, 0)
			BasePanel:SetBackgroundColor(BGColor)

			TopDiv:Dock(TOP)
			BotDiv:Dock(BOTTOM)

			RPMLabel:SetParent(TopDiv)
			-- RPMLabel:DockMargin(0, 0, 0, 0)
			RPMLabel:Dock(LEFT)
			RPMLabel:SetTextColor(TextColor)
			RPMLabel:SizeToContentsX(4)
			LockDockOrder(RPMLabel, 1)

			RPMWang:SetParent(TopDiv)
			RPMWang:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding
			RPMWang:DockMargin(0, 0, 0, 0)
			RPMWang:Dock(LEFT)
			RPMWang:SetValue(GetClientNumber("RPM@SB" .. SBPanelID .. "-" .. PanelID, DefaultRPM))
			RPMWang:SetClientData("RPM@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			LockDockOrder(RPMWang, 2, true)
			RPMWang:DefineSetter(function(Panel, _, _, Value)
				local Min = PanelID == 1 and 0 or GetClientNumber("RPM@SB" .. SBPanelID .. "-" .. (PanelID - 1))
				local Max = PanelID == #VPPanel and _MAX_NET_SOUND_RPM or GetClientNumber("RPM@SB" .. SBPanelID .. "-" .. (PanelID + 1))

				Panel:SetMinMax(Min, Max) -- YEA, I MINMAX MY NUMBERS, SO What!?
				Panel:SetValue(Value)
			end)

			if IsValid(RPMWangBase) then RPMWangBase:Remove() end

			PathLabel:SetParent(TopDiv)
			PathLabel:Dock(LEFT)
			PathLabel:SetTextColor(TextColor)
			LockDockOrder(PathLabel, 3)

			PathText:SetParent(TopDiv)
			PathText:Dock(FILL)
			PathText:DockMargin(-25, 0, 0, 0)
			PathText:SetTall(Menu.ButtonHeight)
			PathText:SetValue(GetClientString("Path@SB" .. SBPanelID .. "-" .. PanelID, DefaultPath))
			PathText:SetClientData("Path@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChange")
			LockDockOrder(PathText, 4, true)
			PathText:DefineSetter(function(Panel, _, _, Value)
				local IsValid = Sounds.IsValidSound

				if IsValid(Value) then
					ParseIcon:SetTooltip()
					ParseIcon:SetImage("icon16/accept.png")
				else
					ParseIcon:SetTooltip("Invalid sound: File does not exist") -- TODO: Localize me!
					ParseIcon:SetImage("icon16/cancel.png")
				end

				Panel:SetValue(Value)
			end)

			ParseIcon:Dock(RIGHT)
			ParseIcon:DockMargin(3, 3, 3, 3)
			ParseIcon:SetImage("icon16/accept.png")
			ParseIcon:SetSize(16, 16)
			LockDockOrder(ParseIcon, 5)

			ClearButton:Dock(RIGHT)
			ClearButton:DockMargin(3, 3, 3, 3)
			ClearButton:SetImage("icon16/arrow_undo.png")
			ClearButton:SetTooltip("Reset all the values from this panel.") -- TODO: Localize me!
			ClearButton:SetStretchToFit(false)
			ClearButton:SetSize(16, 16)
			LockDockOrder(ClearButton, 6)
			ClearButton.DoClick = function()
				SetClientData("RPM@SB" .. SBPanelID .. "-" .. PanelID, DefaultRPM)
				SetClientData("Path@SB" .. SBPanelID .. "-" .. PanelID, DefaultPath)
				SetClientData("Pitch@SB" .. SBPanelID .. "-" .. PanelID, DefaultPitch)
				SetClientData("Volume@SB" .. SBPanelID .. "-" .. PanelID, DefaultVolume)
				SetClientData("Width@SB" .. SBPanelID .. "-" .. PanelID, DefaultWidth)
			end

			SearchButton:Dock(RIGHT)
			SearchButton:DockMargin(3, 3, 3, 3)
			SearchButton:SetImage("icon16/application_view_list.png")
			SearchButton:SetTooltip("Open sound browser.") -- TODO: Localize me!
			SearchButton:SetStretchToFit(false)
			SearchButton:SetSize(16, 16)
			LockDockOrder(SearchButton, 7)
			SearchButton.DoClick = function()
				RunConsoleCommand("wire_sound_browser_open")
			end

			PitchLabel:SetParent(BotDiv)
			PitchLabel:Dock(LEFT)
			PitchLabel:SetTextColor(TextColor)
			PitchLabel:SizeToContentsX(4)
			LockDockOrder(PitchLabel, 1)

			-- TODO(TMF): Add tooltip to the panels below!
			PitchWang:SetParent(BotDiv)
			PitchWang:SetWide(40) -- Equivalent to 000 + up/down buttons at font size = 16 + padding
			PitchWang:DockMargin(0, 0, 4, 0)
			PitchWang:Dock(LEFT)
			PitchWang:SetValue(GetClientNumber("Pitch@SB" .. SBPanelID .. "-" .. PanelID, DefaultPitch))
			PitchWang:SetClientData("Pitch@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			LockDockOrder(PitchWang, 2, true)
			PitchWang:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			if IsValid(PitchWangBase) then PitchWangBase:Remove() end

			VolumeLabel:SetParent(BotDiv)
			VolumeLabel:Dock(LEFT)
			VolumeLabel:SetTextColor(TextColor)
			VolumeLabel:SizeToContentsX(4)
			LockDockOrder(VolumeLabel, 3)

			VolumeWang:SetParent(BotDiv)
			VolumeWang:SetWide(40) -- Equivalent to 0.00 + up/down buttons at font size = 16 + padding
			VolumeWang:DockMargin(0, 0, 4, 0)
			VolumeWang:Dock(LEFT)
			VolumeWang:SetValue(GetClientNumber("Volume@SB" .. SBPanelID .. "-" .. PanelID, DefaultVolume))
			VolumeWang:SetClientData("Volume@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			LockDockOrder(VolumeWang, 4, true)
			VolumeWang:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			if IsValid(VolumeWangBase) then VolumeWangBase:Remove() end

			WidthLabel:SetParent(BotDiv)
			WidthLabel:Dock(LEFT)
			WidthLabel:SetTextColor(TextColor)
			WidthLabel:SizeToContentsX(4)
			LockDockOrder(WidthLabel, 5)

			WidthWang:SetParent(BotDiv)
			WidthWang:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding
			WidthWang:DockMargin(0, 0, 4, 0)
			WidthWang:Dock(LEFT)
			WidthWang:SetValue(GetClientNumber("Width@SB" .. SBPanelID .. "-" .. PanelID, DefaultWidth))
			WidthWang:SetClientData("Width@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			LockDockOrder(WidthWang, 6, true)
			WidthWang:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			if IsValid(WidthWangBase) then WidthWangBase:Remove() end

			table.insert(VPPanel, MainPanel) -- Insert this panel to keep count of them panels
			return MainPanel
		end

		-- The function that adds the soundbank panels
		local AddSoundBankPanel = function() -- MARK: AddSoundBankPanel
			Current.Panels.SoundBankPanels = Current.Panels.SoundBankPanels or {}
			local SBPanel = Current.Panels.SoundBankPanels -- Make it less verbose
			local ID = #SBPanel == 0 and 1 or #SBPanel + 1 -- Ensure it always begins from 1 and increments sequentially from there on

			local _, MPanel = self:AddCollapsible()
			local PlayAtExhaust = _:Add(self:AddCheckBox("Play At Exhaust")) -- TODO: Localize me!
			local OffThrottle = _:Add(self:AddSlider("OffThrottle", 0, 1, 2)) -- TODO: Localize me!
			local OnThrottle = _:Add(self:AddSlider("OnThrottle", 0, 1, 2)) -- TODO: Localize me!
			local ValueSlider = _:Add(self:AddSlider("Sounds", 0, ACF.MaxSounds, 0)) -- TODO: Localize me!
			local BotPanel = _:Add(self:AddPanel("DListLayout"))

			MPanel:SetLabel("Sound Bank " .. ID) -- TODO: Localize me!
			MPanel:Dock(TOP)
			MPanel:DockMargin(0, 0, 0, 8)

			PlayAtExhaust:Dock(TOP)
			PlayAtExhaust:DockMargin(0, 8, 8, 0)
			PlayAtExhaust:SetValue(ID == 1 and false or GetClientData("PlayAtExhaust " .. ID))
			PlayAtExhaust:SetEnabled(ID == 1 and false or true)
			PlayAtExhaust:SetClientData("PlayAtExhaust " .. ID, "OnChange")
			PlayAtExhaust:DefineSetter(function(Panel, _, _, Value)
				-- The first panel and therefore the soundbank must always be played from the engine
				if ID == 1 then
					Panel:SetValue(false)
					Panel:SetEnabled(false)
				else
					Panel:SetValue(Value)
				end
			end)

			OffThrottle:Dock(TOP)
			OffThrottle:DockMargin(0, 8, 8, 0)
			OffThrottle:SetMinMax(0, 1)
			OffThrottle:SetValue(GetClientNumber("OffThrottle " .. ID, 0.25))
			OffThrottle:SetClientData("OffThrottle " .. ID, "OnValueChanged")
			OffThrottle:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			OnThrottle:Dock(TOP)
			OnThrottle:DockMargin(0, 8, 8, 0)
			OnThrottle:SetMinMax(0, 1)
			OnThrottle:SetValue(GetClientNumber("OnThrottle " .. ID, 1))
			OnThrottle:SetClientData("OnThrottle " .. ID, "OnValueChanged")
			OnThrottle:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			local LastValueAmount  = 0
			local Min = ID == 1 and 1 or 0 -- Dumb hack
			ValueSlider:DockMargin(0, 8, 8, 0)
			ValueSlider:SetValue(GetClientNumber("SoundsAtSoundBank " .. ID), Min)
			ValueSlider:SetClientData("SoundsAtSoundBank " .. ID, "OnValueChanged")
			ValueSlider:DefineSetter(function(Panel, _, _, Value)
				local OthersTotal = Current.Count.OfSoundPanels - LastValueAmount
				local MaxAllowed  = math.Clamp(ACF.MaxSounds - OthersTotal, Min, ACF.MaxSounds)
				local ValueAmount = math.Clamp(math.floor(tonumber(Value)), Min, MaxAllowed)

				if ValueAmount ~= LastValueAmount then
					if ValueAmount > LastValueAmount then
						for _ = LastValueAmount + 1, ValueAmount do
							BotPanel:Add(AddValuePanel(ID))
						end
					elseif ValueAmount < LastValueAmount then
						for I = ValueAmount + 1, LastValueAmount do
							if IsValid(SBPanel[ID].Values[I]) then
								SBPanel[ID].Values[I]:Remove()
								SBPanel[ID].Values[I] = nil
							end
						end
					end
					RecalcTotalSoundPanels(SBPanel)
				end
				LastValueAmount = ValueAmount

				Panel:SetClientData("SoundsAtSoundBank " .. ID, ValueAmount)
				Panel:SetValue(ValueAmount)

				RecalcSoundMaxes(SBPanel) -- Let's keep every soundBank's slider max in sync with the new total
			end)

			BotPanel:Dock(TOP)

			-- Update the count on events
			BotPanel.OnChildAdded = function()
				RecalcTotalSoundPanels(SBPanel)
				UpdateGraph()
			end
			BotPanel.OnChildRemoved = function()
				RecalcTotalSoundPanels(SBPanel)
				UpdateGraph()
			end

			table.insert(SBPanel, {MPanel, ValueSlider, Values = {}}) -- Insert this panel to keep count of the soundbank panels
			return MPanel
		end
		--============================================================================================================--
		-- MAIN SUBMENUS																							  --
		-- I explictly gave these their numeric keys so its easier to infer which submenu we're working with   		  --																		          --
		--============================================================================================================--
		local Case = { -- MARK: SwitchCase Menus
			-- First panel, Generic - One sound. Old menu with text entry for a single sound
			[1] = function ()
				self:AddLabel("Play a single sound for all the supported ACF entities, excluding engines.") -- TODO: Localize me!

				local SoundNameText = self:AddPanel("DTextEntry")
					SoundNameText:SetText("")
					SoundNameText:SetWide(Menu.Wide - 20)
					SoundNameText:SetTall(Menu.ButtonHeight)
					SoundNameText:SetMultiline(false)
					SoundNameText:SetConVar("wire_soundemitter_sound")

				local SoundBrowserButton = self:AddButton("#tool.acfsound.open_browser", "wire_sound_browser_open", SoundNameText:GetValue(), "1")
					SoundBrowserButton:SetWide(Menu.Wide)
					SoundBrowserButton:SetTall(Menu.ButtonHeight)
					SoundBrowserButton:SetIcon("icon16/application_view_list.png")

				local SoundPre = self:AddPanel("ACF_Panel")
					SoundPre:SetWide(Menu.Wide)
					SoundPre:SetTall(Menu.ButtonHeight)

				local SoundPrePlay = SoundPre:AddButton("#tool.acfsound.play")
					SoundPrePlay:SetIcon("icon16/sound.png")
					SoundPrePlay.DoClick = function()
						RunConsoleCommand("play", SoundNameText:GetValue())
					end

				-- Playing a silent sound will mute the preview but not the sound emitters.
				local SoundPreStop = SoundPre:AddButton("#tool.acfsound.stop", "play", "common/null.wav")
					SoundPreStop:SetIcon("icon16/sound_mute.png")

					-- Set the Play/Stop button positions here
					SoundPre:InvalidateLayout(true)
					SoundPre.PerformLayout = function()
						local HWide = SoundPre:GetWide() / 2
						SoundPrePlay:SetSize(HWide, Menu.ButtonHeight)
						SoundPrePlay:Dock(LEFT)
						SoundPreStop:Dock(FILL) -- FILL will cover the remaining space which the previous button didn't
					end

				local CopyButton = self:AddButton("#tool.acfsound.copy")
					CopyButton:SetWide(Menu.Wide)
					CopyButton:SetTall(Menu.ButtonHeight)
					CopyButton:SetIcon("icon16/page_copy.png")
					CopyButton.DoClick = function()
						SetClipboardText(SoundNameText:GetValue())
					end

				local ClearButton = self:AddButton("#tool.acfsound.clear")
					ClearButton:SetWide(Menu.Wide)
					ClearButton:SetTall(Menu.ButtonHeight)
					ClearButton:SetIcon("icon16/cancel.png")
					ClearButton.DoClick = function()
						SoundNameText:SetValue("")
						RunConsoleCommand("wire_soundemitter_sound", "")
					end

				local VolumeSlider = self:AddSlider("#tool.acfsound.volume", 0.1, 1, 2)
					VolumeSlider:SetConVar("acfsound_volume")
				local PitchSlider = self:AddSlider("#tool.acfsound.pitch", 0.1, 2, 2)
					PitchSlider:SetConVar("acfsound_pitch")
			end,
			-- Second panel, Engines - Multiple interpolated. New menu with a button to add up to 16 sound paths, with configurable pitch, volume and width for each sound
			-- Has a graph at the top of the list to better visualise how they play at a determined engine RPM
			[2] = function() -- MARK: Multiple sounds
				self:AddLabel("Play multiple interpolated sounds exclusively for ACF engines.") -- TODO: Localize me!
				-- Contact panel
				local Contact = self:AddCollapsible("Contact", true, "icon16/bug_link.png") -- TODO: Localize me!
				local Help = self:AddHelp("This panel is a Work In Progress. Expect bugs to arise and things to not work! \n \
										If you have any errors to report and/or suggestions to make, please contact us on our official discord server.") -- TODO: Localize me!
				local ContactBtn = self:AddButton("Discord link")
				function ContactBtn:DoClick() gui.OpenURL("https://discord.gg/jf4cwarPUG") end

				Help:SetParent(Contact)
				ContactBtn:SetParent(Contact)

				-- Reset them panels
				Current.Panels = nil
				Current.Count  = nil
				Current.Panels = {SoundBankPanels = {}}
				Current.Count  = {OfSoundBankPanels = 0,
								  OfSoundPanels = 0}

				-- The menu is divided in two groups
				-- The top group where the graph lies
				local GraphGroup = self:AddCollapsible("Graph", nil, "icon16/chart_curve_edit.png") -- TODO: Localize me!
				local GraphPanel = GraphGroup:Add(self:AddPanel("DPanel"))
				local LabelTop = GraphPanel:Add(self:AddLabel("This graph shows how your engine sound/s will be heard as a function of RPM.\
												Beware this panel can be resource intensive if you add too many sounds!")) -- TODO: Localize me!
				local RefreshBtn = LabelTop:Add(self:AddPanel("DImageButton"))
				SoundGraph = GraphPanel:Add(self:AddGraph()) -- A Glocal so other functions can call this
				local BankSlider = GraphPanel:Add(self:AddComboBox())
				local PanelBottom = GraphPanel:Add(self:AddPanel("ACF_Panel"))
				local IdleWang, IdleLabel = self:AddNumberWang("Idle:", 0, 2000, 0)
				local IdleWangBase = IdleWang:GetParent()
				local RedlineWang, RedlineLabel = self:AddNumberWang("Redline:", 0, _MAX_NET_SOUND_RPM, 0)
				local RedlineWangBase = RedlineWang:GetParent()
				local RPMSlider = GraphPanel:Add(self:AddSlider("RPM", 0, _MAX_NET_SOUND_RPM))
				local VolumeSlider = GraphPanel:Add(self:AddSlider("#tool.acfsound.volume", 0.1, 1, 2))
				local SoundPre = GraphPanel:Add(self:AddPanel("ACF_Panel"))
				local SoundPrePlay = SoundPre:AddButton("#tool.acfsound.play")
				local SoundPreStop = SoundPre:AddButton("#tool.acfsound.stop", "play", "common/null.wav") -- Playing a silent sound will mute the preview but not the sound emitters

				-- Set defaults
				local DefaultIdle = GetClientData("Idle") or 800
				local DefaultRedline = GetClientData("Redline") or 8000
				SetClientData("Idle", DefaultIdle, true)
				SetClientData("Redline", DefaultRedline, true)
				SetClientData("RPMSlider", (DefaultIdle + DefaultRedline) / 2, true)
				Current.Graph.Idle = GetClientData("Idle") or DefaultIdle
				Current.Graph.Redline = GetClientData("Redline") or DefaultRedline
				Current.Graph.RPMSlider = GetClientData("RPMSlider")

				-- The properties
				GraphGroup:DockMargin(0, 0, 0, 0)
				GraphGroup.OnRemove = function() StopSoundBankPreview() end -- Stop our soundbank sounds whenever we change menus

				GraphPanel:DockPadding(4, 4, 4, 0)
				GraphPanel:Dock(TOP)
				GraphPanel:SetTall(466) -- Why can't this grow dynamically 

				LabelTop:Dock(TOP)
				LabelTop:DockMargin(0, 2, 0, 2)

				RefreshBtn:Dock(RIGHT)
				RefreshBtn:SetImage("icon16/arrow_refresh_small.png")
				RefreshBtn:SetTooltip("Refresh this graph.") -- TODO: Localize me!
				RefreshBtn:SetStretchToFit(false)
				RefreshBtn:SetSize(16, 16)
				RefreshBtn.DoClick = function()
					UpdateGraph()
				end

				SoundGraph:Dock(TOP)
				SoundGraph:SetTall(192)
				SoundGraph:SetXLabel("RPM") -- TODO: Localize me!
				SoundGraph:SetYLabel("Volume") -- TODO: Localize me!
				SoundGraph:SetXRange(0, DefaultRedline + 1000)
				SoundGraph:SetYRange(0, 200)
				SoundGraph:SetFidelity(1)
				SoundGraph:SetXSpacing(1000)
				SoundGraph:SetYSpacing(100)

				BankSlider:SetTall(Menu.ButtonHeight)
				BankSlider:SetValue("Select a Sound Bank to plot") -- TODO: Localize me!
				BankSlider:SetClientData("SoundBankPlotIndex", "OnSelect")
				BankSlider:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
					Panel:SetText(Panel:GetOptionText(Value) or "Select a Sound Bank to plot") -- TODO: Localize me!

					-- Switching the plotted bank invalidates whatever's currently playing
					StopSoundBankPreview()
					SoundPrePlay:SetEnabled(Current.Panels.SoundBankPanels[Value] ~= nil)
					SoundPreStop:SetEnabled(false)

					UpdateGraph()
				end)

				PanelBottom:Dock(TOP)

				IdleLabel:SetParent(PanelBottom)
				IdleLabel:Dock(LEFT)
				LockDockOrder(IdleLabel, 1)

				IdleWang:SetParent(PanelBottom)
				IdleWang:Dock(LEFT)
				IdleWang:SetClientData("Idle", "OnValueChanged")
				IdleWang:SetValue(DefaultIdle) -- I shouldn't need to do this but oh well, here we go...
				LockDockOrder(IdleWang, 2, true)
				IdleWang:DefineSetter(function(Panel, _, _, Value)
					Panel:SetMinMax(0, 2000) -- I shouldn't even need to do this!
					Panel:SetValue(Value)
					RedlineWang:SetMin(Value or 1)
					Current.Graph.Idle = Value

					return Value
				end)

				if IsValid(IdleWangBase) then IdleWangBase:Remove() end

				RedlineLabel:SetParent(PanelBottom)
				RedlineLabel:Dock(LEFT)
				RedlineLabel:DockMargin(8, 4, 0, 0)
				LockDockOrder(RedlineLabel, 3)

				RedlineWang:SetParent(PanelBottom)
				RedlineWang:Dock(LEFT)
				RedlineWang:SetWide(48)
				RedlineWang:SetMinMax(GetClientNumber("Idle"), _MAX_NET_SOUND_RPM)
				RedlineWang:SetClientData("Redline", "OnValueChanged")
				RedlineWang:SetValue(DefaultRedline)
				LockDockOrder(RedlineWang, 4, true)
				RedlineWang:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
					IdleWang:SetMax(math.min(2000, Value))
					SoundGraph:SetXRange(0, math.Clamp(Value + 1000, 0, _MAX_NET_SOUND_RPM + 1000))
					SoundGraph:SetXSpacing(Value < 1000 and 100 or 1000)
					Current.Graph.Redline = Value

					return Value
				end)

				if IsValid(RedlineWangBase) then RedlineWangBase:Remove() end

				RPMSlider:Dock(TOP)
				RPMSlider:SetWide(Menu.Wide)
				RPMSlider:SetMinMax(GetClientNumber("Idle"), GetClientNumber("Redline"))
				RPMSlider:SetClientData("RPMSlider", "OnValueChanged")
				RPMSlider:SetValue(GetClientNumber("RPMSlider", 4400))
				RPMSlider:DefineSetter(function(Panel, _, _, Value)
					local Min = GetClientNumber("Idle", 0)
					local Max = GetClientNumber("Redline", _MAX_NET_SOUND_RPM)

					Panel:SetMinMax(Min, Max)
					Panel:SetValue(Value)

					Current.Graph.RPMSlider = Value
					SoundGraph:PlotLimitLine("RPM", false, Value, color_black)

					-- Update our currently active soundbank preview 
					if Current.Preview.SoundList then
						UpdateSoundBankPreview(Current.Preview.SoundList, Current.Preview.OffVolume, Current.Preview.OnVolume, VolumeSlider)
					end

					return Value
				end)

				VolumeSlider:Dock(TOP)
				VolumeSlider.OnValueChanged = function()
					-- Same as above here but only for volume
					if Current.Preview.SoundList then
						UpdateSoundBankPreview(Current.Preview.SoundList, Current.Preview.OffVolume, Current.Preview.OnVolume, VolumeSlider)
					end
				end

				SoundPre:SetWide(Menu.Wide)
				SoundPre:SetTall(Menu.ButtonHeight)

				SoundPrePlay:SetIcon("icon16/sound.png")
				SoundPrePlay:SetTooltip("Plays the currently selected Sound Bank, cross-faded at the selected RPM.") -- TODO: Localize me!
				SoundPrePlay:SetEnabled(false)
				SoundPrePlay.DoClick = function()
					local Bank = GetClientData("SoundBankPlotIndex")
					if not Bank or not isnumber(Bank) then return end

					local BankPanel = Current.Panels.SoundBankPanels[Bank]
					if not BankPanel then return end

					local Count = #BankPanel.Values
					if Count == 0 then return end

					StopSoundBankPreview() -- Stop any previous sound bank before starting a new one

					-- Get the values straight out of the datavars the same way UpdateGraph does. 
					local SoundList = {}

					for I = 1, Count do
						SoundList[I] = {
							RPM    = GetClientNumber("RPM@SB" .. Bank .. "-" .. I, 0),
							Path   = GetClientString("Path@SB" .. Bank .. "-" .. I, ""),
							Pitch  = GetClientNumber("Pitch@SB" .. Bank .. "-" .. I, 100),
							Volume = GetClientNumber("Volume@SB" .. Bank .. "-" .. I, 1),
							Width  = GetClientNumber("Width@SB" .. Bank .. "-" .. I, 0),
						}
					end

					local OffVolume = GetClientNumber("OffThrottle " .. Bank, 0.25)
					local OnVolume  = GetClientNumber("OnThrottle " .. Bank, 1)

					-- Stash our preview values
					Current.Preview.SoundList = SoundList
					Current.Preview.OffVolume = OffVolume
					Current.Preview.OnVolume  = OnVolume

					for I, SoundData in ipairs(SoundList) do
						if not Sounds.IsValidSound(SoundData.Path) then continue end

						-- "noplay" lets us set volume/pitch before it actually starts.
						sound.PlayFile("sound/" .. SoundData.Path, "noplay", function(Channel)
							if not IsValid(Channel) then return end

							Current.Preview.Channels[I] = Channel
							Channel:EnableLooping(true)
							Channel:SetVolume(0) -- Silent until the Think hook sets the real value next tick
							Channel:Play()

							UpdateSoundBankPreview(SoundList, OffVolume, OnVolume, VolumeSlider)
						end)
					end

					SoundPreStop:SetEnabled(true)
				end

				SoundPreStop:SetIcon("icon16/sound_mute.png")
				SoundPreStop:SetTooltip("Stop the Sound Bank preview.") -- TODO: Localize me!
				SoundPreStop:SetEnabled(false)
				SoundPreStop.DoClick = function()
					StopSoundBankPreview()
					SoundPreStop:SetEnabled(false)
				end

				-- Set the Play/Stop button positions here
				SoundPre:InvalidateLayout(true)
				SoundPre.PerformLayout = function()
					local HWide = SoundPre:GetWide() / 2
					SoundPrePlay:SetSize(HWide, Menu.ButtonHeight)
					SoundPrePlay:Dock(LEFT)
					SoundPreStop:Dock(FILL) -- FILL will cover the remaining space which the previous button didn't
				end

				-- The bottom group where the panels are added and removed dynamically
				local SoundBanksGroup = self:AddCollapsible("Sound Banks", nil, "icon16/application_double.png") -- TODO: Localize me!
				-- TODO: Localize me!
				local SoundBankHelp = SoundBanksGroup:Add(self:AddHelp("This panel allows you to set up to " .. ACF.MaxSoundBanks .. " different sound banks and up to " .. ACF.MaxSounds .. " sounds total. If you can't add a new sound, check that you're not hitting this limit!"))
				local SoundBankSlider = SoundBanksGroup:Add(self:AddSlider("Sound Banks", 1, ACF.MaxSoundBanks, 0))
				local SoundBankList = SoundBanksGroup:Add(self:AddPanel("DListLayout"))

				SoundBanksGroup:DockMargin(0, 0, 0, 0)

				SoundBankHelp:DockMargin(0, 4, 0, 0)

				local LastSoundBankValue = 0
				SoundBankSlider:Dock(TOP)
				SoundBankSlider:SetValue(GetClientData("SoundBankSlider"))
				SoundBankSlider:SetClientData("SoundBankSlider", "OnValueChanged")
				SoundBankSlider:DefineSetter(function(Panel, _, _, Value)
					local ValueAmount = math.Clamp(math.floor(tonumber(Value)), 1, ACF.MaxSoundBanks)
					if ValueAmount ~= LastSoundBankValue then
						if ValueAmount > LastSoundBankValue then
							for I = LastSoundBankValue + 1, ValueAmount do
								BankSlider:AddChoice("Plot Sound Bank " .. I, I) -- TODO: Localize me!
								Current.Count.OfSoundBankPanels = Current.Count.OfSoundBankPanels + 1
								SoundBankList:Add(AddSoundBankPanel())
							end
						elseif ValueAmount < LastSoundBankValue then
							-- We're removing the highest index first, in descending order so each RemoveChoice
							-- doesn't shift the position of entries still waiting to be removed and accidentally cause chaos.
							for I = LastSoundBankValue, ValueAmount + 1, -1 do
								if IsValid(Current.Panels.SoundBankPanels[I][1]) then
									Current.Count.OfSoundPanels = Current.Count.OfSoundPanels - #Current.Panels.SoundBankPanels[I].Values
									Current.Count.OfSoundBankPanels = Current.Count.OfSoundBankPanels - 1
									Current.Panels.SoundBankPanels[I][1]:Remove()
									Current.Panels.SoundBankPanels[I] = nil

									BankSlider:RemoveChoice(I)

									-- The bank currently plotted/previewed just got deleted so now we reset our combobox selection, 
									-- stop any active sound preview, and clear the now stale plotted graph curve.
									if GetClientData("SoundBankPlotIndex") == I then
										StopSoundBankPreview()
										SetClientData("SoundBankPlotIndex", 0)

										BankSlider:SetValue("Select a Sound Bank to plot") -- TODO: Localize me!
										SoundPrePlay:SetEnabled(false)
										SoundPreStop:SetEnabled(false)
										SoundGraph:Clear()
									end
								end
							end
						end
					end
					LastSoundBankValue = ValueAmount
					Panel:SetValue(Value)
				end)

				-- I don't know if this makes sense, but somehow it gives me less trouble to later remove any arbitrary panels
				self:StartTemporal(SoundBanksGroup)
				self:ClearTemporal(SoundBanksGroup)

				SoundBankList:Dock(TOP)
				SoundBankList.OnChildAdded = function()
					Current.Count.OfSoundBankPanels = #Current.Panels.SoundBankPanels
				end
				SoundBankList.OnChildRemoved = function()
					Current.Count.OfSoundBankPanels = #Current.Panels.SoundBankPanels
				end

				self:EndTemporal(SoundBanksGroup)

				local OptionGroup = self:AddCollapsible("Options", false, "icon16/application.png") -- TODO: Localize me!
				OptionGroup:DockMargin(0, 8, 8, 0)

				local OptionColorCheckbox = self:AddCheckBox("Randomize colors of sound lines and panels") -- TODO: Localize me!
				OptionColorCheckbox:SetParent(OptionGroup)
				OptionColorCheckbox:Dock(TOP)
				OptionColorCheckbox:SetValue(GetClientData("GetRandomColors")) -- WHAT: This value is initially set to false, yet somehow later on it toggles itself back to true??!
				OptionColorCheckbox:SetClientData("GetRandomColors", "OnChange")
				OptionColorCheckbox:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
				end)

			end,
			-- Third panel, Weapons - Start/Loop/Stop. New menu with three text entries labeled as "Start", "Loop", "End" respectively, to put the sound paths
			-- Layout is similar to the first option
			[3] = function() -- MARK: Weapon Sounds
				self:AddLabel("This is the third panel, Nothing here was added just yet but you can imagine its gonna be something nice, so stay tuned!")
			end
		}
		local Switch = Case[Num]
		Switch()
	end

	do -- MARK: Networking
		-- SoundBank networking entity data reception and menu population
		-- Receives data just to set the option of the selection box
		net.Receive("ACF_SoundMenu_Send_ID", function()
			local MenuID = net.ReadUInt(4)

			OptionSelectionBox:ChooseOption(OptionSelectionBox:GetOptionText(MenuID), MenuID)
		end)

		-- Receives data to populate the menu or to send back to server the client's datavars
		net.Receive("ACF_SoundMenu_Get_Multi", function()
			local Feedback = net.ReadBool()

			if not Feedback then -- Get the data from the entity and populate menu
				local SoundBankCount = net.ReadUInt(3)

				SetClientData("SoundBankSlider", SoundBankCount)

				for SB = 1, SoundBankCount do
					local PlayAtExhaust = net.ReadBool()
					local OffThrottle = net.ReadUInt(8)
					local OnThrottle = net.ReadUInt(8)
					local SoundCount = net.ReadUInt(4)

					SetClientData("PlayAtExhaust " .. SB, PlayAtExhaust)
					SetClientData("OffThrottle " .. SB, OffThrottle * 0.01) -- Reduce the received value down to a float
					SetClientData("OnThrottle " .. SB, OnThrottle * 0.01)   -- Same here
					SetClientData("SoundsAtSoundBank " .. SB, SoundCount)

					for S = 1, SoundCount do
						local RPM 	 = net.ReadUInt(ACF.NetSoundRPMBitLimit)
						local Path   = net.ReadString()
						local Pitch  = net.ReadUInt(8)
						local Volume = net.ReadUInt(8)
						local Width  = net.ReadUInt(4)

						SetClientData("RPM@SB" .. SB .. "-" .. S, RPM)
						SetClientData("Path@SB" .. SB .. "-" .. S, Path)
						SetClientData("Pitch@SB" .. SB .. "-" .. S, Pitch)
						SetClientData("Volume@SB" .. SB .. "-" .. S, Volume * 0.01) -- Again, same here
						SetClientData("Width@SB" .. SB .. "-" .. S, Width)
					end
				end
			else -- Gets any datavars and networks them back to the server
				net.Start("ACF_SoundMenu_Set_Multi")
					local BankCount = GetClientData("SoundBankSlider", 1)
					net.WriteUInt(BankCount, 3)

					for SB = 1, BankCount do
						local PlaysAtExhaust = GetClientData("PlayAtExhaust " .. SB, false)
						local OffThrottle = GetClientData("OffThrottle " .. SB, 0.25) * 100
						local OnThrottle = GetClientData("OnThrottle " .. SB, 1) * 100

						net.WriteBool(PlaysAtExhaust)
						net.WriteUInt(OffThrottle, 8) -- Sending the approximate volume as an int to reduce message size
						net.WriteUInt(OnThrottle, 8)  -- Same here

						local SoundCount = GetClientData("SoundsAtSoundBank " .. SB)
						net.WriteUInt(SoundCount, 4)

						for S = 1, SoundCount do
							net.WriteUInt(GetClientNumber("RPM@SB" .. SB .. "-" .. S), ACF.NetSoundRPMBitLimit)
							net.WriteString(GetClientString("Path@SB" .. SB .. "-" .. S))
							net.WriteUInt(GetClientNumber("Pitch@SB" .. SB .. "-" .. S), 8)
							net.WriteUInt(GetClientNumber("Volume@SB" .. SB .. "-" .. S) * 100, 8) -- Again, same here
							net.WriteUInt(GetClientNumber("Width@SB" .. SB .. "-" .. S), 4)
						end
					end
				-- We're making the supposition here that the values being sent are already sorted
				net.SendToServer()
			end
		end)
	end
end