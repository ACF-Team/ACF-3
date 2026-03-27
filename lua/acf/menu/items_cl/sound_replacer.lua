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
	OptionSelectionBox:AddChoice("Generic - One sound. ", 1)
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
		-- Local Constants, Tables and Methods																	      --
		--============================================================================================================--
		local SoundGraph -- Glocal
		local _MAXSOUNDS = 16 -- Maximum amount of sounds we're willing to send and have. TODO(TMF): Make this a global!
		local Current = {
			Panels = {SoundBankPanels = {},  -- Contains the panel objects
					  ValuePanels = {0}},
			Count  = {OfSoundBankPanels = 0, -- Keeps count of them
					  OfSoundPanels = 0},
			Colors = (function() 			 -- IIFE that returns a table with optionally randomized colors and if the text should be dark or light colored
				local ColorTable = {}
				local IsRandomColor = GetClientData("RandomColors", false)

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
		local function UpdateGraph(Panel)
			local Count = Current.Count.OfSoundPanels
			if not Count then return end

			local Clamp = math.Clamp
			local Fade = Sounds.Fade

			Panel:Clear()

			for I = 1, Count do
				local AddCurveWidth = GetClientNumber("Width " .. I, 0)
				local Volume = GetClientNumber("Volume " .. I, 0) * 100
				local Min = I == 1 and -1000000 or GetClientNumber("RPM " .. Clamp(I - 1 - AddCurveWidth, 1, _MAXSOUNDS))
				local Mid = GetClientNumber("RPM " .. I, 0)
				local Max = I == Count and 1000000 or GetClientNumber("RPM " .. Clamp(I + 1 + AddCurveWidth, 1, _MAXSOUNDS))

				-- The 1000 extra is so it can see til the graph X limit and not cutoff
				Panel:PlotLimitFunction("Sound " .. I, 0, 16383 + 1000, Current.Colors.ValuePanels[I][1], function(X)
					return (Fade(X, Min, Mid, Max)) * Volume
				end)
			end
		end

		-- The function that adds the panels to the corresponding soundbanks
		local AddValuePanel = function(Menu, SBMenu)
			Current.Panels.ValuePanels = Current.Panels.ValuePanels or {}
			local VPPanel = Current.Panels.ValuePanels
			local ID = #VPPanel == 0 and 1 or #VPPanel + 1 -- Ensure it always begins from 1 and increments from there on
			local BGColor   = Current.Colors[ID][1] or color_white
			local TextColor = Current.Colors[ID][2]

			-- Defaults
			local DefaultRPM    = 1000 * ID
			local DefaultPath   = ""
			local DefaultPitch  = 100
			local DefaultVolume = 1
			local DefaultWidth  = 0

			-- VGUI panels
			local _, MPanel = Menu:AddCollapsible()
			local Base = Menu:AddPanel("DPanel")
			_ = Base -- Override ACF's basic Base with this
			local TopDiv = Menu:AddPanel("ACF_Panel") -- This is equivalent to a HTML Div, generic panel to parent other children to.
			local BotDiv = Menu:AddPanel("ACF_Panel") -- Same as above.
			-- TODO(TMF): The max value below is hardcoded, this should be a global!
			local RPMWang, RPMLabel = Menu:AddNumberWang("RPM:", 0, 16383, 0)
			local _, PathLabel, PathText = Menu:AddTextEntry("Path:")
			local ParseIcon = Menu:AddPanel("DImage")
			local SearchButton = Menu:AddPanel("DImageButton")
			local ClearButton = Menu:AddPanel("DImageButton")
			local PitchWang, PitchLabel = Menu:AddNumberWang("Pitch:", 0, 255, 0)
			local VolumeWang, VolumeLabel = Menu:AddNumberWang("Volume:", 0, 1, 2)
			local WidthWang, WidthLabel = Menu:AddNumberWang("Width:", 0, 15, 0)

			MPanel:DockMargin(0, 0, 0, 0)
			MPanel:SetLabel("Value " .. ID)

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
			RPMWang:SetValue(GetClientNumber("RPM " .. ID, DefaultRPM))
			RPMWang:SetClientData("RPM " .. ID, "OnValueChanged")
			RPMWang:DefineSetter(function(Panel, _, _, Value)
				-- TODO(TMF): The max value below is hardcoded, this should be a global!
				local Min = ID == 1 and 0 or GetClientNumber("RPM " .. ID - 1)
				local Max = ID == #VPPanel and 16383 or GetClientNumber("RPM " .. ID + 1)

				Panel:SetMinMax(Min, Max) -- YEA, I MINMAX MY NUMBERS, SO What!?
				Panel:SetValue(Value)

				return Value, Panel
			end)

			PathLabel:SetParent(TopDiv)
			PathLabel:Dock(LEFT)
			PathLabel:SetTextColor(TextColor)

			PathText:SetParent(TopDiv)
			PathText:Dock(FILL)
			PathText:DockMargin(-25, 0, 0, 0)
			PathText:SetTall(Menu.ButtonHeight)
			PathText:SetValue(GetClientString("Path " .. ID, DefaultPath))
			PathText:SetClientData("Path " .. ID, "OnValueChange")
			PathText:DefineSetter(function(Panel, _, _, Value)
				local IsValid = Sounds.IsValidSound -- Why wont this trigger

				if IsValid(Value) then
					ParseIcon:SetTooltip()
					ParseIcon:SetImage("icon16/accept.png")

					Panel:SetClientData("Path " .. ID, Value)
				else
					ParseIcon:SetTooltip("Invalid sound: File does not exist")
					ParseIcon:SetImage("icon16/cancel.png")

					Panel:SetClientData("Path " .. ID, "")
				end
				return Value, Panel
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
			ClearButton:SetTooltip("Reset all the values from this panel.")
			ClearButton:SetStretchToFit(false)
			ClearButton:SetSize(16, 16)
			ClearButton.DoClick = function()
				SetClientData("RPM " .. ID, DefaultRPM)
				SetClientData("Path " .. ID, DefaultPath)
				SetClientData("Pitch " .. ID, DefaultPitch)
				SetClientData("Volume " .. ID, DefaultVolume)
				SetClientData("Width " .. ID, DefaultWidth)
			end

			SearchButton:SetParent(TopDiv)
			SearchButton:Center()
			SearchButton:Dock(RIGHT)
			SearchButton:DockMargin(3, 3, 3, 3)
			SearchButton:SetImage("icon16/application_view_list.png")
			SearchButton:SetTooltip("Open sound browser.")
			SearchButton:SetStretchToFit(false)
			SearchButton:SetSize(16, 16)
			SearchButton.DoClick = function()
				RunConsoleCommand("wire_sound_browser_open")
			end

			PitchLabel:SetParent(BotDiv)
			PitchLabel:Dock(LEFT)
			PitchLabel:SetTextColor(TextColor)

			PitchWang:SetParent(BotDiv)
			PitchWang:SetWide(40) -- Equivalent to 000 + up/down buttons at font size = 16 + padding
			PitchWang:DockMargin(-30, 0, 4, 0)
			PitchWang:Dock(LEFT)
			PitchWang:SetValue(GetClientNumber("Pitch " .. ID, DefaultPitch))
			PitchWang:SetClientData("Pitch " .. ID, "OnValueChanged")
			PitchWang:DefineSetter(function(_, _, _, Value)
				SetClientData("Pitch " .. ID, Value)
			end)

			VolumeLabel:SetParent(BotDiv)
			VolumeLabel:Dock(LEFT)
			VolumeLabel:SetTextColor(TextColor)

			VolumeWang:SetParent(BotDiv)
			VolumeWang:SetWide(40) -- Equivalent to 0.00 + up/down buttons at font size = 16 + padding
			VolumeWang:DockMargin(-16, 0, 4, 0)
			VolumeWang:Dock(LEFT)
			VolumeWang:SetValue(GetClientNumber("Volume " .. ID, DefaultVolume))
			VolumeWang:SetClientData("Volume " .. ID, "OnValueChanged")
			VolumeWang:DefineSetter(function(_, _, _, Value)
				SetClientData("Volume " .. ID, Value)
			end)

			WidthLabel:SetParent(BotDiv)
			WidthLabel:Dock(LEFT)
			WidthLabel:SetTextColor(TextColor)

			WidthWang:SetParent(BotDiv)
			WidthWang:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding
			WidthWang:DockMargin(-24, 0, 4, 0)
			WidthWang:Dock(LEFT)
			WidthWang:SetValue(GetClientNumber("Width " .. ID, DefaultWidth))
			WidthWang:SetClientData("Width " .. ID, "OnValueChanged")
			WidthWang:DefineSetter(function(_, _, _, Value)
				SetClientData("Width " .. ID, Value)
			end)

			table.insert(VPPanel, {MPanel, SBMenu}) -- Insert this panel to keep count of them panels
			return MPanel
		end

		-- The function that adds the soundbank panels
		local AddSoundBankPanel = function(Menu)
			Current.Panels.SoundBankPanels = Current.Panels.SoundBankPanels or {}
			local SBPanel = Current.Panels.SoundBankPanels -- Make it less verbose
			local ID = #SBPanel == 0 and 1 or #SBPanel + 1 -- Ensure it always begins from 1 and increments sequentially from there on

			local _, MPanel = Menu:AddCollapsible()
			local PlayAtExhaust = Menu:AddCheckBox("Play At Exhaust")
			local OffThrottle, OFTBasePanel = Menu:AddNumberWang("OffThrottle", 0, 1, 2)
			local OnThrottle, ONTBasePanel = Menu:AddNumberWang("OnThrottle", 0, 1, 2)
			local ValueSlider = Menu:AddSlider("Sounds", 0, 16, 0)
			local BotPanel = Menu:AddPanel("DListLayout")

			MPanel:SetLabel("Sound Bank " .. ID)
			MPanel:Dock(TOP)
			MPanel:DockMargin(0, 0, 0, 8)

			PlayAtExhaust:SetParent(MPanel)
			PlayAtExhaust:Dock(TOP)
			PlayAtExhaust:DockMargin(0, 8, 8, 0)
			PlayAtExhaust:SetValue(false)
			PlayAtExhaust:SetClientData("PlayAtExhaust " .. ID, "OnChange")
			PlayAtExhaust:DefineSetter(function(Panel, _, _, Value)
				-- The first panel and therefore the soundbank must always be played from the engine
				if ID == 1 then
					Panel:SetValue(true)
					Panel:SetEnabled(false)
				end
				Panel:SetValue(Value)
			end)

			OFTBasePanel:SetParent(MPanel)
			OFTBasePanel:Dock(TOP)
			OFTBasePanel:DockMargin(0, 8, 8, 0)
			OffThrottle:SetParent(OFTBasePanel)
			OffThrottle:SetMinMax(0, 1)
			OffThrottle:SetValue(GetClientNumber("OffThrottle " .. ID), 0.25)
			OffThrottle:SetClientData("OffThrottle " .. ID, "OnValueChanged")
			OffThrottle:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			ONTBasePanel:SetParent(MPanel)
			ONTBasePanel:Dock(TOP)
			ONTBasePanel:DockMargin(0, 8, 8, 0)
			OnThrottle:SetParent(ONTBasePanel)
			OnThrottle:SetMinMax(0, 1)
			OnThrottle:SetValue(GetClientNumber("OnThrottle " .. ID), 1)
			OnThrottle:SetClientData("OnThrottle " .. ID, "OnValueChanged")
			OnThrottle:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
			end)

			local LastValueAmount = 0
			local Min = ID == 1 and 1 or 0
			ValueSlider:SetParent(MPanel)
			ValueSlider:SetValue(GetClientNumber("SoundsAtSoundBank " .. ID), Min)
			ValueSlider:SetClientData("SoundsAtSoundBank " .. ID, "OnValueChanged")
			ValueSlider:DefineSetter(function(Panel, _, _, Value)
				local ValueAmount = math.Clamp(math.floor(tonumber(Value)), Min, _MAXSOUNDS)
				if ValueAmount ~= LastValueAmount then
					if ValueAmount > LastValueAmount then
						for _ = LastValueAmount + 1, ValueAmount do
							BotPanel:Add(AddValuePanel(self, ID))
						end
					elseif ValueAmount < LastValueAmount then
						for I = ValueAmount + 1, LastValueAmount do
							if IsValid(Current.Panels.ValuePanels[I][1]) then
								Current.Panels.ValuePanels[I][1]:Remove()
								Current.Panels.ValuePanels[I] = nil
							end
						end
					end
				end
				LastValueAmount = ValueAmount
				Panel:SetClientData("ListSlider", ValueAmount)
				Panel:SetValue(ValueAmount)
			end)

			BotPanel:SetParent(MPanel)
			BotPanel:Dock(TOP)

			table.insert(SBPanel, MPanel) -- Insert this panel to keep count of the soundbank panels
			return MPanel
		end
		--============================================================================================================--
		-- ACTUAL SUBMENUS																							  --
		-- I explictly gave these their numeric keys so its easier to infer which submenu we're working with   		  --																		          --
		--============================================================================================================--
		local Case = {
			-- First panel, Generic - One sound. Old menu with text entry for a single sound
			[1] = function ()
				self:AddLabel("Play a single sound for all the supported ACF entities, excluding engines.")

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
				self:AddLabel("Play multiple interpolated sounds exclusively for ACF engines.")
				-- Contact panel
				local Contact = self:AddCollapsible("Contact", true, "icon16/bug_link.png")
				local Help = self:AddHelp("This panel is a Work In Progress. Expect bugs to arise and things to not work! \n \
										If you have any errors to report and/or suggestions to make, please contact us on our official discord server.")
				local ContactBtn = self:AddButton("Discord link")
				function ContactBtn:DoClick() gui.OpenURL("https://discord.gg/jf4cwarPUG") end

				Help:SetParent(Contact)
				ContactBtn:SetParent(Contact)

				-- Reset them panels
				Current.Panels = nil
				Current.Panels = {}
				Current.Count  = nil
				Current.Count  = {OfSoundBankPanels = 0,
								  OfSoundPanels = 0}

				-- The menu is divided in two groups
				-- The top group where the graph lies
				local GraphGroup = self:AddCollapsible("Graph", nil, "icon16/chart_curve_edit.png")
				local GraphPanel = self:AddPanel("DPanel")
				local LabelTop = self:AddLabel("This graph shows how your engine sound/s will be heard as a function of RPM.\
												Beware this panel can be resource intensive if you add too many sounds!")
				local RefreshBtn = self:AddPanel("DImageButton")
				SoundGraph = self:AddGraph() -- A Glocal so other functions can call this
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
				local DefaultIdle = GetClientData("Idle", 800)
				local DefaultRedline = GetClientData("Redline", 8000)
				SetClientData("Idle", DefaultIdle, true)
				SetClientData("Redline", DefaultRedline, true)
				SetClientData("RPMSlider", (DefaultIdle + DefaultRedline) / 2, true)

				-- The properties
				GraphGroup:DockMargin(0, 0, 0, 0)

				GraphPanel:SetParent(GraphGroup)
				GraphPanel:DockPadding(4, 4, 4, 8)
				GraphPanel:Dock(TOP)
				GraphPanel:SetTall(436) -- Why can't this grow dynamically 

				LabelTop:SetParent(GraphPanel)
				LabelTop:Dock(TOP)
				LabelTop:DockMargin(0, 2, 0, 2)

				RefreshBtn:SetParent(LabelTop)
				RefreshBtn:Dock(RIGHT)
				RefreshBtn:SetImage("icon16/arrow_refresh_small.png")
				RefreshBtn:SetTooltip("Refresh this graph.")
				RefreshBtn:SetStretchToFit(false)
				RefreshBtn:SetSize(16, 16)
				RefreshBtn.DoClick = function()
					UpdateGraph(SoundGraph)
				end

				SoundGraph:SetParent(GraphPanel)
				SoundGraph:Dock(TOP)
				SoundGraph:SetTall(192)
				SoundGraph:SetXLabel("RPM")
				SoundGraph:SetYLabel("Volume")
				SoundGraph:SetYRange(0, 200)
				SoundGraph:SetFidelity(1)
				SoundGraph:SetXSpacing(1000)
				SoundGraph:SetYSpacing(100)

				PanelBottom:SetParent(GraphPanel)
				PanelBottom:Dock(TOP)
				PanelBottom:DockPadding(0, 4, 4, -4)
				PanelBottom:SetTall(34)

				IdleLabel:SetParent(PanelBottom)
				IdleLabel:Dock(LEFT)

				IdleWang:SetParent(PanelBottom)
				IdleWang:Dock(LEFT)
				IdleWang:SetValue(DefaultIdle) -- I shouldn't need to do this but oh well, here we go...
				IdleWang:SetClientData("Idle", "OnValueChanged")
				IdleWang:DefineSetter(function(Panel, _, _, Value)
					Panel:SetMinMax(0, 2000) -- I shouldn't even need to do this!
					Panel:SetValue(Value)
					RedlineWang:SetMin(Value or 1)

					return Value
				end)

				RedlineLabel:SetParent(PanelBottom)
				RedlineLabel:Dock(LEFT)
				RedlineLabel:DockMargin(8, 4, 0, 0) -- Fucking retarded

				RedlineWang:SetParent(PanelBottom)
				RedlineWang:Dock(LEFT)
				RedlineWang:SetValue(DefaultRedline)
				RedlineWang:SetMinMax(GetClientNumber("Idle", 0), 16383)
				RedlineWang:SetClientData("Redline", "OnValueChanged")
				RedlineWang:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
					SoundGraph:SetXRange(0, Value + 1000)
					SoundGraph:SetXSpacing(Value < 1000 and 100 or 1000)

					return Value
				end)

				RPMSlider:SetParent(GraphPanel)
				RPMSlider:Dock(TOP)
				RPMSlider:SetWide(Menu.Wide)
				RPMSlider:SetMinMax(GetClientNumber("Idle"), GetClientNumber("Redline"))
				RPMSlider:SetValue(GetClientNumber("RPMSlider", 4400))
				RPMSlider:SetClientData("RPMSlider", "OnValueChanged")
				RPMSlider:DefineSetter(function(Panel, _, _, Value)
					-- TODO(TMF): The max value below is hardcoded, this should be a global!
					local Min = GetClientNumber("Idle", 0)
					local Max = GetClientNumber("Redline", 16383)

					Panel:SetMinMax(Min, Max)
					Panel:SetValue(Value)

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
				local SoundBanksGroup = self:AddCollapsible("Sound Banks", nil, "icon16/application_double.png")
				SoundBanksGroup:DockMargin(0, 4, 0, 4)

				-- The help label. TODO: The 3 down below is hardcoded, has to be a configurable global... 
				local SoundBankHelp = self:AddHelp("This panel allows you to set up to 3 different sound banks and up to " .. _MAXSOUNDS .. " sounds total. If you can't add a new sound, check that you're not hitting this limit!")
				SoundBankHelp:SetParent(SoundBanksGroup)

				local LastSoundBankValue = 0
				local SoundBankSlider = self:AddSlider("Sound Banks", 1, 3, 0)
				local SoundBankList = self:AddPanel("DListLayout")

				SoundBankSlider:SetParent(SoundBanksGroup)
				SoundBankSlider:Dock(TOP)
				SoundBankSlider:SetValue(GetClientData("SoundBankSlider"))
				SoundBankSlider:SetClientData("SoundBankSlider", "OnValueChanged")
				SoundBankSlider:DefineSetter(function(Panel, _, _, Value)
					local ValueAmount = math.Clamp(math.floor(tonumber(Value)), 1, 3)
					if ValueAmount ~= LastSoundBankValue then
						if ValueAmount > LastSoundBankValue then
							for _ = LastSoundBankValue + 1, ValueAmount do
								SoundBankList:Add(AddSoundBankPanel(self))
								Current.Count.OfSoundBankPanels = Current.Count.OfSoundBankPanels + 1
							end
						elseif ValueAmount < LastSoundBankValue then
							for I = ValueAmount + 1, LastSoundBankValue do
								if IsValid(Current.Panels.SoundBankPanels[I]) then
									Current.Panels.SoundBankPanels[I]:Remove()
									Current.Panels.SoundBankPanels[I] = nil
									Current.Count.OfSoundBankPanels = Current.Count.OfSoundBankPanels - 1
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

				self:EndTemporal(SoundBanksGroup)

				local OptionGroup = self:AddCollapsible("Options", nil, "icon16/application.png")
				OptionGroup:DockMargin(0, 8, 8, 0)

				local OptionColorCheckbox = self:AddCheckBox("Randomize colors of sound lines and panels")
				OptionColorCheckbox:SetParent(OptionGroup)
				OptionColorCheckbox:Dock(TOP)
				OptionColorCheckbox:SetValue(GetClientData("RandomColors", false))
				OptionColorCheckbox:SetClientData("RandomColors", "OnChange")
				OptionColorCheckbox:DefineSetter(function(Panel, _, _, Value)
					Panel:SetValue(Value)
				end)

				--OptionGroup:Toggle() -- FYM you don't exist as a method for CollapsibleCategory you useless piece of shit

				--[[ListSlider = self:AddSlider("Values", 1, _MAXSOUNDS, 0)
				ListPanel = self:AddPanel("DListLayout")
				AddValue = self:AddPanel("DImageButton")

				local LastValueAmount = 0
				ListSlider:SetParent(ValuesGroup)
				ListSlider:Dock(TOP)
				ListSlider:SetValue(GetClientData("ListSlider"))
				ListSlider:SetClientData("ListSlider", "OnValueChanged")
				ListSlider:DefineSetter(function(Panel, _, _, Value)
					local ValueAmount = math.Clamp(math.floor(tonumber(Value)), 1, _MAXSOUNDS)
					if ValueAmount ~= LastValueAmount then
						if ValueAmount > LastValueAmount then
							for _ = LastValueAmount + 1, ValueAmount do
								--ListPanel:Add(AddValuePanel(self))
							end
						elseif ValueAmount < LastValueAmount then
							for I = ValueAmount + 1, LastValueAmount do
								if IsValid(Current.Panels[I]) then
									Current.Panels[I]:Remove()
									Current.Panels[I] = nil
								end
							end
						end
					end
					LastValueAmount = ValueAmount
					Panel:SetClientData("ListSlider", ValueAmount)
				end)
			
				ListPanel:SetParent(ValuesGroup)
				ListPanel:Dock(TOP)
				ListPanel.OnChildAdded = function()
					Current.Count = #Current.Panels
					UpdateGraph(SoundGraph) -- Update our graph	

					-- Disable the button if enough panels exist already
					if #Current.Panels >= _MAXSOUNDS then AddValue:SetEnabled(false) return end
				end
				ListPanel.OnChildRemoved = function()
					AddValue:SetEnabled(true) -- Re-enable our add button

					Current.Count = #Current.Panels
					UpdateGraph(SoundGraph) -- Same here
				end

				

				AddValue:SetParent(ValuesGroup)
				AddValue:Dock(TOP)
				AddValue:SetImage("icon16/add.png")
				AddValue:SetTooltip("Add a new sound.")
				AddValue:SetStretchToFit(false)
				AddValue:SetSize(16, 16)
				AddValue.DoClick = function()
					local Value = GetClientData("ListSlider")
					ListSlider:SetValue(Value + 1)
				end]]--
			end
		}
		local Switch = Case[Num]
		Switch()
	end

	do -- SoundBank entity data reception and menu population
		local function PopulateMenu(Count)
			-- We set it to option 2 since that's where the values are located at 
			OptionSelectionBox:ChooseOption(OptionSelectionBox:GetOptionText(2), 2)

			-- Wipe the clients values list
			Menu:ClearTemporal(ListPanel)

			-- Reset them panels once again, but initialized count at 1
			Current.Panels = nil
			Current.Panels = {}
			Current.Count  = 1

			-- Set the slider to whatever count is
			ListSlider:SetValue(Count)
		end
		-- Receives data to populate the menu or to send back to server the client's datavars
		net.Receive("ACF_SoundMenu_Get_Multi", function()
			--print("Received " .. len .. " bits for call: \"ACF_SoundMenu_Get_Multi\"") -- Debug print

			local Origin = net.ReadEntity()
			if not Origin then return end

			local Feedback = net.ReadBool()
			if not Feedback then -- Get the data from the entity and populate menu
				local Count = net.ReadUInt(4)

				for I = 1, Count do
					local RPM 		 = net.ReadUInt(14)
					local StringPath = net.ReadString()
					local Pitch 	 = net.ReadUInt(8)
					local Volume 	 = net.ReadUInt(8)
					local Width 	 = net.ReadUInt(4)

					Volume = Volume * 0.01 -- Reduce the received value down to a float

					SetClientData("RPM " .. I, RPM)
					SetClientData("Path " .. I, StringPath)
					SetClientData("Pitch " .. I, Pitch)
					SetClientData("Volume " .. I, Volume)
					SetClientData("Width " .. I, Width)
				end
				PopulateMenu(Count)
			else -- Gets any datavars and networks them back to the server
				net.Start("ACF_SoundMenu_Set_Multi")
					net.WriteEntity(Origin)
					net.WriteUInt(Current.Count, 4)
				for I = 1, Current.Count do
					local RPM = GetClientNumber("RPM " .. I)
					local Path = GetClientString("Path " .. I)
					local Pitch = GetClientNumber("Pitch " .. I)
					local Volume = GetClientNumber("Volume " .. I)
					local Width = GetClientNumber("Width " .. I)

					Volume = Volume * 100 -- Increase the value up to an int
					net.WriteUInt(RPM, 14)
					net.WriteString(Path)
					net.WriteUInt(Pitch, 8)
					net.WriteUInt(Volume, 8)
					net.WriteUInt(Width, 4)
				end
				-- We're making the supposition here that the values being sent are already sorted
				net.SendToServer()
			end
		end)
	end
end