local ACF = ACF
local Sounds = ACF.Utilities.Sounds
local GetClientData, SetClientData = ACF.GetClientData, ACF.SetClientData
local GetClientNumber, GetClientString = ACF.GetClientNumber, ACF.GetClientString

	--- Generates the menu used in the Sound Replacer tool.
	--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateSoundMenu(Panel)
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
	--OptionSelectionBox:AddChoice("Weapons - Start/Loop/Stop. ", 2)
	--OptionSelectionBox:AddChoice("Engines - Simple interpolated. ", 3)
	OptionSelectionBox:AddChoice("Engines - Multiple interpolated. ", 4)
	OptionSelectionBox.OnSelect = function(_, Index, _)
		Menu:StartTemporal(Panel)
		Menu:ClearTemporal(Panel)
		Menu:CreateSubMenu(Index) -- Build the sub menu
		Menu:EndTemporal(Panel)
	end

	--- Build the rest of the menu according to our selection
	--- @param Num int The sub menu selected at the index.
	function Menu:CreateSubMenu(Num)
		--============================================================================================================--
		-- Local Constants, Variables, Tables and Methods															  --
		--============================================================================================================--
		local SoundGraph 			   -- Glocal
		local _MAXSOUNDS 	      = 16 -- Maximum amount of sounds we're willing to send and have. TODO(TMF): Make this a global!
		local _MAXSOUNDBANKPANELS = 4  -- Maximum amount of soundbanks we're willing to have. Again this should be a global!
		local Current = {					 -- Local table used to store objects and other miscellaneous stuff
			Panels = {SoundBankPanels = {}}, -- Contains the panel objects
			Count  = {OfSoundBankPanels = 0, -- Keeps total count of them
					  OfSoundPanels = 0},
			Graph  = {Idle      = 0,         -- Datavars wouldn't persist correctly so here is this...
					  Redline   = 1,
					  RPMSlider = 2},
			Colors = (function() 			 -- IIFE that returns a table with optionally randomized colors and if the text should be dark or light colored
				local ColorTable = {}
				local IsRandomColor = GetClientData("GetRandomColors", false)

				for I = 1, _MAXSOUNDS do
					local Col
					if not IsRandomColor then
						-- In short, it creates a rainbow :3
						local Freq = 360 / _MAXSOUNDS
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
		-- SUBMENUS of the SUBMENUS  																				  --
		--============================================================================================================--
		-- The graphing function, this is a mirror of the function found in sounds_cl.lua and is redundant
		-- TODO(TMF): This should be a single function pulled from ACF.Sounds object
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
				local Min = I == 1 and -1000000 or GetClientNumber("RPM@SB" .. Bank .. "-" .. Clamp(I - 1 - AddCurveWidth, 1, _MAXSOUNDS))
				local Mid = GetClientNumber("RPM@SB" .. Bank .. "-" .. I, 0)
				local Max = I == Count and 1000000 or GetClientNumber("RPM@SB" .. Bank .. "-" .. Clamp(I + 1 + AddCurveWidth, 1, _MAXSOUNDS))

				-- The 1000 extra is so it can see til the graph X limit and not cutoff
				SoundGraph:PlotLimitFunction("Sound " .. I, 0, 16383 + 1000, Current.Colors[I][1], function(X) -- TODO: Localize me!
					return (Fade(X, Min, Mid, Max)) * Volume
				end)
			end
		end
		-- The function that adds the panels to the corresponding soundbank panels
		local AddValuePanel = function(SBPanelID)
			Current.Panels.SoundBankPanels[SBPanelID].Values = Current.Panels.SoundBankPanels[SBPanelID].Values or {}
			local VPPanel   = Current.Panels.SoundBankPanels[SBPanelID].Values -- Just here for verbosity sake
			local PanelID   = #VPPanel == 0 and 1 or #VPPanel + 1 -- Ensure it always begins from 1 and increments from there on for every soundbank panel
			--local SoundID   = Current.Count.OfSoundPanels -- Keep count of how many sound panels there are
			local BGColor   = Current.Colors[PanelID][1] or color_white
			local TextColor = Current.Colors[PanelID][2]

			-- Defaults
			local DefaultRPM    = 1000 * PanelID
			local DefaultPath   = ""
			local DefaultPitch  = 100
			local DefaultVolume = 1
			local DefaultWidth  = 0

			-- VGUI panels
			local _, MPanel = self:AddCollapsible()
			local Base = self:AddPanel("DPanel")
			_ = Base -- Override ACF's basic Base with this
			local TopDiv = self:AddPanel("ACF_Panel") -- This is equivalent to a HTML Div, generic panel to parent other children to.
			local BotDiv = self:AddPanel("ACF_Panel") -- Same as above.
			-- TODO(TMF): The max value below is hardcoded, this should be a global!
			local RPMWang, RPMLabel = self:AddNumberWang("RPM:", 0, 16383, 0) -- TODO: Localize me!
			local _, PathLabel, PathText = self:AddTextEntry("Path:") -- TODO: Localize me!
			local ParseIcon = self:AddPanel("DImage")
			local SearchButton = self:AddPanel("DImageButton")
			local ClearButton = self:AddPanel("DImageButton")
			local PitchWang, PitchLabel = self:AddNumberWang("Pitch:", 0, 255, 0) -- TODO: Localize me!
			local VolumeWang, VolumeLabel = self:AddNumberWang("Volume:", 0, 1, 2) -- TODO: Localize me!
			local WidthWang, WidthLabel = self:AddNumberWang("Width:", 0, 15, 0) -- TODO: Localize me!

			MPanel:DockMargin(0, 0, 0, 0)
			MPanel:SetLabel("Value " .. PanelID) -- TODO: Localize me!

			Base:SetParent(MPanel)
			Base:SetTall(72)
			Base:DockPadding(4, 6, 4, 0)
			Base:DockMargin(0, 0, 0, 0)
			Base:SetBackgroundColor(BGColor)

			TopDiv:SetParent(Base)
			TopDiv:Dock(TOP)

			BotDiv:SetParent(Base)
			BotDiv:Dock(BOTTOM)

			RPMLabel:SetParent(TopDiv)
			RPMLabel:DockMargin(0, 0, 0, 0)
			RPMLabel:Dock(LEFT)
			RPMLabel:SetTextColor(TextColor)

			RPMWang:SetParent(TopDiv)
			RPMWang:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding
			RPMWang:DockMargin(-30, 0, 0, 0)
			RPMWang:Dock(LEFT)
			RPMWang:SetValue(GetClientNumber("RPM@SB" .. SBPanelID .. "-" .. PanelID, DefaultRPM))
			RPMWang:SetClientData("RPM@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			RPMWang:DefineSetter(function(Panel, _, _, Value)
				-- TODO(TMF): The max value below is hardcoded, this should be a global!
				local Min = PanelID == 1 and 0 or GetClientNumber("RPM@SB" .. SBPanelID .. "-" .. (PanelID - 1))
				local Max = PanelID == #VPPanel and 16383 or GetClientNumber("RPM@SB" .. SBPanelID .. "-" .. (PanelID + 1))

				Panel:SetMinMax(Min, Max) -- YEA, I MINMAX MY NUMBERS, SO What!?
				Panel:SetValue(Value)
			end)

			PathLabel:SetParent(TopDiv)
			PathLabel:Dock(LEFT)
			PathLabel:SetTextColor(TextColor)

			PathText:SetParent(TopDiv)
			PathText:Dock(FILL)
			PathText:DockMargin(-25, 0, 0, 0)
			PathText:SetTall(Menu.ButtonHeight)
			PathText:SetValue(GetClientString("Path@SB" .. SBPanelID .. "-" .. PanelID, DefaultPath))
			PathText:SetClientData("Path@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChange")
			PathText:DefineSetter(function(Panel, _, _, Value)
				local IsValid = Sounds.IsValidSound

				if IsValid(Value) then
					ParseIcon:SetTooltip()
					ParseIcon:SetImage("icon16/accept.png")
				else
					ParseIcon:SetTooltip("Invalid sound: File does not exist") -- TODO: Localize me!
					ParseIcon:SetImage("icon16/cancel.png")
				end

				Panel:SetClientData(Value)
			end)

			ParseIcon:SetParent(PathText)
			ParseIcon:Dock(RIGHT)
			ParseIcon:DockMargin(3, 3, 3, 3)
			ParseIcon:SetImage("icon16/accept.png")
			ParseIcon:SetSize(16, 16)

			ClearButton:SetParent(TopDiv)
			ClearButton:Dock(RIGHT)
			ClearButton:DockMargin(3, 3, 3, 3)
			ClearButton:SetImage("icon16/arrow_undo.png")
			ClearButton:SetTooltip("Reset all the values from this panel.") -- TODO: Localize me!
			ClearButton:SetStretchToFit(false)
			ClearButton:SetSize(16, 16)
			ClearButton.DoClick = function()
				SetClientData("RPM@SB" .. SBPanelID .. "-" .. PanelID, DefaultRPM)
				SetClientData("Path@SB" .. SBPanelID .. "-" .. PanelID, DefaultPath)
				SetClientData("Pitch@SB" .. SBPanelID .. "-" .. PanelID, DefaultPitch)
				SetClientData("Volume@SB" .. SBPanelID .. "-" .. PanelID, DefaultVolume)
				SetClientData("Width@SB" .. SBPanelID .. "-" .. PanelID, DefaultWidth)
			end

			SearchButton:SetParent(TopDiv)
			SearchButton:Center()
			SearchButton:Dock(RIGHT)
			SearchButton:DockMargin(3, 3, 3, 3)
			SearchButton:SetImage("icon16/application_view_list.png")
			SearchButton:SetTooltip("Open sound browser.") -- TODO: Localize me!
			SearchButton:SetStretchToFit(false)
			SearchButton:SetSize(16, 16)
			SearchButton.DoClick = function()
				RunConsoleCommand("wire_sound_browser_open")
			end

			PitchLabel:SetParent(BotDiv)
			PitchLabel:Dock(LEFT)
			PitchLabel:SetTextColor(TextColor)

			-- TODO(TMF): Add tooltip to the panels below!
			PitchWang:SetParent(BotDiv)
			PitchWang:SetWide(40) -- Equivalent to 000 + up/down buttons at font size = 16 + padding
			PitchWang:DockMargin(-30, 0, 4, 0)
			PitchWang:Dock(LEFT)
			PitchWang:SetValue(GetClientNumber("Pitch@SB" .. SBPanelID .. "-" .. PanelID, DefaultPitch))
			PitchWang:SetClientData("Pitch@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			PitchWang:DefineSetter(function(Panel, _, _, Value)
				Panel:SetClientData(Value)
			end)

			VolumeLabel:SetParent(BotDiv)
			VolumeLabel:Dock(LEFT)
			VolumeLabel:SetTextColor(TextColor)

			VolumeWang:SetParent(BotDiv)
			VolumeWang:SetWide(40) -- Equivalent to 0.00 + up/down buttons at font size = 16 + padding
			VolumeWang:DockMargin(-16, 0, 4, 0)
			VolumeWang:Dock(LEFT)
			VolumeWang:SetValue(GetClientNumber("Volume@SB" .. SBPanelID .. "-" .. PanelID, DefaultVolume))
			VolumeWang:SetClientData("Volume@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			VolumeWang:DefineSetter(function(Panel, _, _, Value)
				Panel:SetClientData(Value)
			end)

			WidthLabel:SetParent(BotDiv)
			WidthLabel:Dock(LEFT)
			WidthLabel:SetTextColor(TextColor)

			WidthWang:SetParent(BotDiv)
			WidthWang:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding
			WidthWang:DockMargin(-24, 0, 4, 0)
			WidthWang:Dock(LEFT)
			WidthWang:SetValue(GetClientNumber("Width@SB" .. SBPanelID .. "-" .. PanelID, DefaultWidth))
			WidthWang:SetClientData("Width@SB" .. SBPanelID .. "-" .. PanelID, "OnValueChanged")
			WidthWang:DefineSetter(function(Panel, _, _, Value)
				Panel:SetClientData(Value)
			end)

			table.insert(VPPanel, MPanel) -- Insert this panel to keep count of them panels
			return MPanel
		end

		-- The function that adds the soundbank panels
		local AddSoundBankPanel = function()
			Current.Panels.SoundBankPanels = Current.Panels.SoundBankPanels or {}
			local SBPanel = Current.Panels.SoundBankPanels -- Make it less verbose
			local ID = #SBPanel == 0 and 1 or #SBPanel + 1 -- Ensure it always begins from 1 and increments sequentially from there on

			local _, MPanel = self:AddCollapsible()
			local PlayAtExhaust = self:AddCheckBox("Play At Exhaust") -- TODO: Localize me!
			local OffThrottle = self:AddSlider("OffThrottle", 0, 1, 2) -- TODO: Localize me!
			local OnThrottle = self:AddSlider("OnThrottle", 0, 1, 2) -- TODO: Localize me!
			local ValueSlider = self:AddSlider("Sounds", 0, 16, 0) -- TODO: Localize me!
			local BotPanel = self:AddPanel("DListLayout")

			MPanel:SetLabel("Sound Bank " .. ID) -- TODO: Localize me!
			MPanel:Dock(TOP)
			MPanel:DockMargin(0, 0, 0, 8)

			PlayAtExhaust:SetParent(MPanel)
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

			OffThrottle:SetParent(MPanel)
			OffThrottle:Dock(TOP)
			OffThrottle:DockMargin(0, 8, 8, 0)
			OffThrottle:SetMinMax(0, 1)
			OffThrottle:SetValue(GetClientNumber("OffThrottle " .. ID, 0.25))
			OffThrottle:SetClientData("OffThrottle " .. ID, "OnValueChanged")
			OffThrottle:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			OnThrottle:SetParent(MPanel)
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
			ValueSlider:SetParent(MPanel)
			ValueSlider:SetValue(GetClientNumber("SoundsAtSoundBank " .. ID), Min)
			ValueSlider:SetClientData("SoundsAtSoundBank " .. ID, "OnValueChanged")
			ValueSlider:DefineSetter(function(Panel, _, _, Value)
				local ValueAmount = math.Clamp(math.floor(tonumber(Value)), Min, _MAXSOUNDS)
				if ValueAmount ~= LastValueAmount then
					if ValueAmount <= _MAXSOUNDS and ValueAmount > LastValueAmount then
						for _ = LastValueAmount + 1, ValueAmount do
							Current.Count.OfSoundPanels = Current.Count.OfSoundPanels + 1
							BotPanel:Add(AddValuePanel(ID))
						end
					elseif ValueAmount < LastValueAmount then
						for I = ValueAmount + 1, LastValueAmount do
							if IsValid(SBPanel[ID].Values[I]) then
								SBPanel[ID].Values[I]:Remove()
								SBPanel[ID].Values[I] = nil
								Current.Count.OfSoundPanels = Current.Count.OfSoundPanels - 1
							end
						end
					end
				end
				LastValueAmount = ValueAmount

				Panel:SetClientData("SoundsAtSoundBank " .. ID, ValueAmount)
				Panel:SetValue(ValueAmount)
				-- This does not work unfortunately, i need a less ass solution to this!
				--[[for I = 1, #SBPanel do
					if I ~= ID then
						SBPanel[I][2]:SetMax(_MAXSOUNDS - Current.Count.OfSoundPanels)
					end
				end]]--
			end)

			BotPanel:SetParent(MPanel)
			BotPanel:Dock(TOP)
			-- Update the count on events
			BotPanel.OnChildAdded = function()
				Current.Count.OfSoundPanels = #SBPanel[ID].Values
				UpdateGraph()
			end
			BotPanel.OnChildRemoved = function()
				Current.Count.OfSoundPanels = #SBPanel[ID].Values
				UpdateGraph()
			end

			table.insert(SBPanel, {MPanel, ValueSlider, Values = {}}) -- Insert this panel to keep count of the soundbank panels
			return MPanel
		end
		--============================================================================================================--
		-- ACTUAL SUBMENUS																							  --
		-- I explictly gave these their numeric keys so its easier to infer which submenu we're working with   		  --																		          --
		--============================================================================================================--
		local Case = {
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
			-- Second panel, Weapons - Start/Loop/Stop. New menu with three text entries labeled as "Start", "Loop", "End" respectively, to put the sound paths
			-- Layout is similar to the first option
			--[[[2] = function()
				self:AddLabel("This is the second panel, I don't know what to add here yet but you can imagine its gonna be something nice, so stay tuned!")

			end,
			-- Third panel, Engines - Simple interpolated. New menu with a Slider that creates N amount of text entries to put the sound paths
			-- Layout is similar to the first option
			[3] = function()
				self:AddLabel("This is the third panel, I don't know what to add here yet but you can imagine its gonna be something fantastic, so stay tuned!")

			end,]]--
			-- Fourth panel, Engines - Custom interpolated. New menu with a button to add up to 16 sound paths, with configurable pitch, volume and width for each sound
			-- Has a graph at the top of the list to better visualise how they play at a determined engine RPM
			[2] = function()
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
				local GraphPanel = self:AddPanel("DPanel")
				local LabelTop = self:AddLabel("This graph shows how your engine sound/s will be heard as a function of RPM.\
												Beware this panel can be resource intensive if you add too many sounds!") -- TODO: Localize me!
				local RefreshBtn = self:AddPanel("DImageButton")
				SoundGraph = self:AddGraph() -- A Glocal so other functions can call this
				local BankSlider = self:AddComboBox()
				local PanelBottom = self:AddPanel("ACF_Panel")
				local IdleLabel = self:AddLabel("Idle:")
				local IdleWang = self:AddPanel("DNumberWang", 0, 2000)
				local RedlineLabel = self:AddLabel("Redline:")
				-- TODO(TMF): The max values below are hardcoded, this should be a global!
				local RedlineWang = self:AddPanel("DNumberWang", 0, 16383)
				local RPMSlider = self:AddSlider("RPM", 0, 16383)
				local SoundPre = self:AddPanel("ACF_Panel")
				local SoundPrePlay = SoundPre:AddButton("#tool.acfsound.play")
				local SoundPreStop = SoundPre:AddButton("#tool.acfsound.stop", "play", "common/null.wav") -- Playing a silent sound will mute the preview but not the sound emitters
				local VolumeSlider = self:AddSlider("#tool.acfsound.volume", 0.1, 1, 2)

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

				GraphPanel:SetParent(GraphGroup)
				GraphPanel:DockPadding(4, 4, 4, 8)
				GraphPanel:Dock(TOP)
				GraphPanel:SetTall(466) -- Why can't this grow dynamically 

				LabelTop:SetParent(GraphPanel)
				LabelTop:Dock(TOP)
				LabelTop:DockMargin(0, 2, 0, 2)

				RefreshBtn:SetParent(LabelTop)
				RefreshBtn:Dock(RIGHT)
				RefreshBtn:SetImage("icon16/arrow_refresh_small.png")
				RefreshBtn:SetTooltip("Refresh this graph.") -- TODO: Localize me!
				RefreshBtn:SetStretchToFit(false)
				RefreshBtn:SetSize(16, 16)
				RefreshBtn.DoClick = function()
					UpdateGraph()
				end

				SoundGraph:SetParent(GraphPanel)
				SoundGraph:Dock(TOP)
				SoundGraph:SetTall(192)
				SoundGraph:SetXLabel("RPM") -- TODO: Localize me!
				SoundGraph:SetYLabel("Volume") -- TODO: Localize me!
				SoundGraph:SetXRange(0, DefaultRedline + 1000)
				SoundGraph:SetYRange(0, 200)
				SoundGraph:SetFidelity(1)
				SoundGraph:SetXSpacing(1000)
				SoundGraph:SetYSpacing(100)

				BankSlider:SetParent(GraphPanel)
				BankSlider:SetTall(Menu.ButtonHeight)
				BankSlider:SetValue("Select a Sound Bank to plot")
				-- TODO(TMF): This should be shown dynamically, but this should suffice for now...
				BankSlider:AddChoice("Plot Sound Bank 1", 1)
				BankSlider:AddChoice("Plot Sound Bank 2", 2)
				BankSlider:AddChoice("Plot Sound Bank 3", 3)
				BankSlider:AddChoice("Plot Sound Bank 4", 4)
				BankSlider:SetClientData("SoundBankPlotIndex", "OnSelect")
				BankSlider:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
					Panel:SetText(Panel:GetOptionText(Value))
					UpdateGraph()
				end)

				PanelBottom:SetParent(GraphPanel)
				PanelBottom:Dock(TOP)
				PanelBottom:DockPadding(0, 4, 4, -4)
				PanelBottom:SetTall(34)

				IdleLabel:SetParent(PanelBottom)
				IdleLabel:Dock(LEFT)

				IdleWang:SetParent(PanelBottom)
				IdleWang:Dock(LEFT)
				IdleWang:SetClientData("Idle", "OnValueChanged")
				IdleWang:SetValue(DefaultIdle) -- I shouldn't need to do this but oh well, here we go...
				IdleWang:DefineSetter(function(Panel, _, _, Value)
					Panel:SetMinMax(0, 2000) -- I shouldn't even need to do this!
					Panel:SetValue(Value)
					RedlineWang:SetMin(Value or 1)
					Current.Graph.Idle = Value

					return Value
				end)

				RedlineLabel:SetParent(PanelBottom)
				RedlineLabel:Dock(LEFT)
				RedlineLabel:DockMargin(8, 4, 0, 0) -- Fucking retarded

				RedlineWang:SetParent(PanelBottom)
				RedlineWang:Dock(LEFT)
				RedlineWang:SetMinMax(GetClientNumber("Idle"), 16383)
				RedlineWang:SetClientData("Redline", "OnValueChanged")
				RedlineWang:SetValue(DefaultRedline)
				RedlineWang:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
					IdleWang:SetMax(math.min(2000, Value))
					SoundGraph:SetXRange(0, Value + 1000)
					SoundGraph:SetXSpacing(Value < 1000 and 100 or 1000)
					Current.Graph.Redline = Value

					return Value
				end)

				RPMSlider:SetParent(GraphPanel)
				RPMSlider:Dock(TOP)
				RPMSlider:SetWide(Menu.Wide)
				RPMSlider:SetMinMax(GetClientNumber("Idle"), GetClientNumber("Redline"))
				RPMSlider:SetClientData("RPMSlider", "OnValueChanged")
				RPMSlider:SetValue(GetClientNumber("RPMSlider", 4400))
				RPMSlider:DefineSetter(function(Panel, _, _, Value)
					-- TODO(TMF): The max value below is hardcoded, this should be a global!
					local Min = GetClientNumber("Idle", 0)
					local Max = GetClientNumber("Redline", 16383)

					Panel:SetMinMax(Min, Max)
					Panel:SetValue(Value)

					Current.Graph.RPMSlider = Value
					SoundGraph:PlotLimitLine("RPM", false, Value, color_black)
					return Value
				end)

				VolumeSlider:SetConVar("acfsound_volume")
				VolumeSlider:SetParent(GraphPanel)
				VolumeSlider:Dock(TOP)

				SoundPre:SetParent(GraphPanel)
				SoundPre:SetWide(Menu.Wide)
				SoundPre:SetTall(Menu.ButtonHeight)

				SoundPrePlay:SetIcon("icon16/sound.png")
				SoundPrePlay:SetTooltip("Unimplemented!")
				SoundPrePlay:SetEnabled(false)
				SoundPrePlay.DoClick = function()
					-- Do something here to play them sounds!
				end

				SoundPreStop:SetIcon("icon16/sound_mute.png")
				SoundPreStop:SetTooltip("Unimplemented!")
				SoundPreStop:SetEnabled(false)

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
				SoundBanksGroup:DockMargin(0, 4, 0, 4)

				-- TODO: Localize me!
				local SoundBankHelp = self:AddHelp("This panel allows you to set up to " .. _MAXSOUNDBANKPANELS .. " different sound banks and up to " .. _MAXSOUNDS .. " sounds total. If you can't add a new sound, check that you're not hitting this limit!")
				SoundBankHelp:SetParent(SoundBanksGroup)

				local SoundBankSlider = self:AddSlider("Sound Banks", 1, _MAXSOUNDBANKPANELS, 0)
				local SoundBankList = self:AddPanel("DListLayout")

				local LastSoundBankValue = 0
				SoundBankSlider:SetParent(SoundBanksGroup)
				SoundBankSlider:Dock(TOP)
				SoundBankSlider:SetValue(GetClientData("SoundBankSlider"))
				SoundBankSlider:SetClientData("SoundBankSlider", "OnValueChanged")
				SoundBankSlider:DefineSetter(function(Panel, _, _, Value)
					local ValueAmount = math.Clamp(math.floor(tonumber(Value)), 1, _MAXSOUNDBANKPANELS)
					if ValueAmount ~= LastSoundBankValue then
						if ValueAmount > LastSoundBankValue then
							for _ = LastSoundBankValue + 1, ValueAmount do
								Current.Count.OfSoundBankPanels = Current.Count.OfSoundBankPanels + 1
								SoundBankList:Add(AddSoundBankPanel())
							end
						elseif ValueAmount < LastSoundBankValue then
							for I = ValueAmount + 1, LastSoundBankValue do
								if IsValid(Current.Panels.SoundBankPanels[I][1]) then
									Current.Count.OfSoundPanels = Current.Count.OfSoundPanels - #Current.Panels.SoundBankPanels[I].Values
									Current.Count.OfSoundBankPanels = Current.Count.OfSoundBankPanels - 1
									Current.Panels.SoundBankPanels[I][1]:Remove()
									Current.Panels.SoundBankPanels[I] = nil
								end
							end
						end
					end
					LastSoundBankValue = ValueAmount
					Panel:SetClientData("SoundBankSlider", ValueAmount)
					Panel:SetValue(Value)
				end)

				-- I don't know if this makes sense, but somehow it gives me less trouble to later remove any arbitrary panels
				self:StartTemporal(SoundBanksGroup)
				self:ClearTemporal(SoundBanksGroup)

				SoundBankList:SetParent(SoundBanksGroup)
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
				OptionColorCheckbox:SetValue(GetClientData("GetRandomColors", false))
				OptionColorCheckbox:SetClientData("GetRandomColors", "OnChange")
				OptionColorCheckbox:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
				end)

			end
		}
		local Switch = Case[Num]
		Switch()
	end

	do -- SoundBank entity data reception and menu population
		-- Recieve data just to set the option of the selection box
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
						local RPM 	 = net.ReadUInt(14)
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
							net.WriteUInt(GetClientNumber("RPM@SB" .. SB .. "-" .. S), 14)
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