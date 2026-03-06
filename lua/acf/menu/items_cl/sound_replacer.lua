local ACF = ACF
local Sounds = ACF.Utilities.Sounds
local GetClientData, SetClientData = ACF.GetClientData, ACF.SetClientData
local GetClientNumber, GetClientString = ACF.GetClientNumber, ACF.GetClientString

local _MAXSOUNDS = 16 -- Maximum amount of sounds we're willing to send and have. TODO(TMF): Make this a global!
local Current = {Panels = {},     		-- Contains the panel objects
				 Count  = 0,      		-- Keeps count of them
				 Graph  = {       		-- This only relates to the graph
					Idle      = 0,
					Redline   = 1,
					RPMSlider = 2},
				 Colors = (function() 	-- This IIFE returns a table with all the randomized colors 
					local ColorTable = {}
					for I = 1, _MAXSOUNDS do
						ColorTable[I] = ColorRand()
					end
					return ColorTable
				 end)()
				 }
--- Generates the menu used in the Sound Replacer tool.
--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateSoundMenu(Panel)
	local AddValue, ListSlider, ListPanel, SoundGraph -- Glocals
	-- The graphing function, this is a mirror of the function found in sounds_cl.lua and is redundant
	-- TODO(TMF): This should be a single function pulled from ACF.Sounds object
	local function UpdateGraph(Panel)
		local Count = Current.Count
		if not Count then return end

		local clamp = math.Clamp
		local fade = Sounds.Fade

		Panel:Clear()

		for I = 1, Count do
			local addCurveWidth = GetClientNumber("Width " .. I, 0)
			local pitch = GetClientNumber("Pitch " .. I, 0)
			--local volume = Current.Panels[I].Volume * 100 -- Idk if we want to plot volume as a function
			local min = I == 1 and 0 or GetClientNumber("RPM " .. clamp(I - 1 - addCurveWidth, 1, _MAXSOUNDS))
			local mid = GetClientNumber("RPM " .. I, 0)
			-- TODO(TMF): The max value below is hardcoded, this should be a global!
			local max = I == Count and 16383 or GetClientNumber("RPM " .. clamp(I + 1 + addCurveWidth, 1, _MAXSOUNDS))

			Panel:PlotFunction("Sound " .. I, Current.Colors[I], function(X)
				return (fade(X, min - addCurveWidth, mid, max + addCurveWidth)) * pitch
			end)
		end
	end
	-- The function that adds the panels to the menu
	local function AddValuePanel(Menu)
		local ID = #Current.Panels == 0 and 1 or #Current.Panels + 1 -- Ensure it always begins from 1 and increments from there on

		-- Defaults
		local DefaultPath   = ""
		local DefaultRPM    = 1000 * ID
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
		local RemoveButton = Menu:AddPanel("DImageButton")
		local PitchWang, PitchLabel = Menu:AddNumberWang("Pitch:", 0, 255, 0)
		local VolumeWang, VolumeLabel = Menu:AddNumberWang("Volume:", 0, 1, 2)
		local WidthWang, WidthLabel = Menu:AddNumberWang("Width:", 0, 15, 0)

		MPanel:DockMargin(0, 0, 0, 0)
		MPanel:SetLabel("Value " .. ID)

		Base:SetParent(MPanel)
		Base:SetTall(72)
		Base:DockPadding(4, 6, 4, 0)
		Base:DockMargin(0, 0, 0, 0)

		TopDiv:SetParent(Base)
		TopDiv:Dock(TOP)

		BotDiv:SetParent(Base)
		BotDiv:Dock(BOTTOM)

		RPMLabel:SetParent(TopDiv)
		RPMLabel:DockMargin(0, 0, 0, 0)
		RPMLabel:Dock(LEFT)

		RPMWang:SetParent(TopDiv)
		RPMWang:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding
		RPMWang:DockMargin(-30, 0, 0, 0)
		RPMWang:Dock(LEFT)
		RPMWang:SetValue(GetClientNumber("RPM " .. ID, DefaultRPM))
		RPMWang:SetClientData("RPM " .. ID, "OnValueChanged")
		RPMWang:DefineSetter(function(Panel, _, _, Value)
			-- TODO(TMF): The max value below is hardcoded, this should be a global!
			local min = ID == 1 and 0 or GetClientNumber("RPM " .. ID - 1)
			local max = ID == #Current.Panels and 16383 or GetClientNumber("RPM " .. ID + 1)

			Panel:SetMinMax(min, max) -- YEA, I MINMAX MY NUMBERS, SO What!?
			Panel:SetValue(Value)

			return Value, Panel
		end)

		PathLabel:SetParent(TopDiv)
		PathLabel:Dock(LEFT)

		PathText:SetParent(TopDiv)
		PathText:Dock(FILL)
		PathText:DockMargin(-25, 0, 0, 0)
		PathText:SetTall(Menu.ButtonHeight)
		PathText:SetValue(GetClientString("Path " .. ID, DefaultPath))
		PathText:SetClientData("Path " .. ID, "OnValueChange")
		PathText:DefineSetter(function(Panel, _, _, Value)
			local isValid = Sounds.IsValidSound

			if isValid(Value) then
				ParseIcon:SetTooltip()
				ParseIcon:SetImage("icon16/accept.png")

				SetClientData("Path " .. ID, Value)
			else
				ParseIcon:SetTooltip("Invalid sound: File does not exist")
				ParseIcon:SetImage("icon16/cancel.png")

				SetClientData("Path " .. ID, "")
			end
			return Value, Panel
		end)

		ParseIcon:SetParent(PathText)
		ParseIcon:Dock(RIGHT)
		ParseIcon:DockMargin(3, 3, 3, 3)
		ParseIcon:SetImage("icon16/accept.png")
		ParseIcon:SetSize(16, 16)

		RemoveButton:SetParent(TopDiv)
		RemoveButton:Dock(RIGHT)
		RemoveButton:DockMargin(3, 3, 3, 3)
		RemoveButton:SetImage("icon16/delete.png")
		RemoveButton:SetTooltip("Remove this sound.")
		RemoveButton:SetStretchToFit(false)
		RemoveButton:SetSize(16, 16)
		RemoveButton.DoClick = function()
			-- Don't remove the last panel 
			if Current.Count == 1 then
				RemoveButton.DoClick = function() end
				return
			end

			-- Remove the panel in question
			MPanel:Remove()
			table.remove(Current.Panels, ID)
			ListSlider:SetValue(math.max(ListSlider:GetValue() - 1, 1))

			-- Set the label of the remaining panels up
			for i = ID, Current.Count do
				if not Current.Panels[i] then continue end
				Current.Panels[i]:SetLabel("Value " .. i)
			end
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

		WidthWang:SetParent(BotDiv)
		WidthWang:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding
		WidthWang:DockMargin(-24, 0, 4, 0)
		WidthWang:Dock(LEFT)
		WidthWang:SetValue(GetClientNumber("Width " .. ID, DefaultWidth))
		WidthWang:SetClientData("Width " .. ID, "OnValueChanged")
		WidthWang:DefineSetter(function(_, _, _, Value)
			SetClientData("Width " .. ID, Value)
		end)

		table.insert(Current.Panels, MPanel) -- Insert this panel to keep count of them panels
		return MPanel
	end
	-- Actual menu stuff
	local Menu = ACF.InitMenuBase(Panel, "SoundMenu", "acf_reload_sound_menu")
	Menu.ButtonHeight = 20
	Menu.Wide = Menu:GetWide()
	Menu:AddLabel("#tool.acfsound.help")

	local OptionSelectionBox = Menu:AddComboBox()
	OptionSelectionBox:SetText("Select an Option...")
	OptionSelectionBox:Dock(TOP)
	OptionSelectionBox:SetTall(Menu.ButtonHeight)
	OptionSelectionBox:AddChoice("Generic - One sound. ", 1)
	OptionSelectionBox:AddChoice("Weapons - Start/Loop/Stop. ", 2)
	OptionSelectionBox:AddChoice("Engines - Simple interpolated. ", 3)
	OptionSelectionBox:AddChoice("Engines - Custom interpolated. ", 4)
	OptionSelectionBox.OnSelect = function(_, Index, _)
		Menu:StartTemporal(Panel)
		Menu:ClearTemporal(Panel)
		Menu:CreateSubMenu(Index) -- Build the sub menu
		Menu:EndTemporal(Panel)
	end

	--- Build the rest of the menu according to our selection
	--- @param Num int The sub menu selected at the index
	function Menu:CreateSubMenu(Num)
		local Case = {
			-- I explictly gave these their numeric keys so its easier to infer which panel we're working with
			-- First panel, Generic - One sound. Old menu with text entry for a single sound
			[1] = function ()
				self:AddLabel("This is the first panel, I don't know what to add here yet but you can imagine its gonna be something good, so stay tuned!")

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
			[2] = function()
				self:AddLabel("This is the second panel, I don't know what to add here yet but you can imagine its gonna be something nice, so stay tuned!")

			end,
			-- Third panel, Engines - Simple interpolated. New menu with a Slider that creates N amount of text entries to put the sound paths
			-- Layout is similar to the first option
			[3] = function()
				self:AddLabel("This is the third panel, I don't know what to add here yet but you can imagine its gonna be something fantastic, so stay tuned!")

			end,
			-- Fourth panel, Engines - Custom interpolated. New menu with a button to add up to 16 sound paths, with configurable pitch, volume and width for each sound
			-- Has a graph at the top of the list to better visualise how they play at a determined engine RPM
			[4] = function()
				self:AddLabel("This is the fourth panel, I don't know what to add here yet but you can imagine its gonna be something mindblowing, so stay tuned!")
				-- Reset them panels
				Current.Panels = nil
				Current.Panels = {}
				Current.Count  = 0
				-- The menu is divided in two groups
				-- The top group where the graph lies
				local GraphGroup = self:AddCollapsible("Graph", nil, "icon16/chart_curve_edit.png")
				local GraphPanel = self:AddPanel("DPanel")
				local LabelTop = self:AddLabel("This graph shows how your engine sound/s will be heard in function of RPM.\
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
				SoundGraph:SetYLabel("Pitch")
				SoundGraph:SetYRange(0, 255)
				SoundGraph:SetFidelity(10)
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
					Current.Graph["Idle"] = Value

					return Value
				end)

				RedlineLabel:SetParent(PanelBottom)
				RedlineLabel:Dock(LEFT)
				RedlineLabel:DockMargin(8, 4, 0, 0) -- Fucking retarded

				RedlineWang:SetParent(PanelBottom)
				RedlineWang:Dock(LEFT)
				RedlineWang:SetValue(DefaultRedline)
				RedlineWang:SetMinMax(Current.Graph["Idle"], 16383)
				RedlineWang:SetClientData("Redline", "OnValueChanged")
				RedlineWang:DefineSetter(function(Panel, _, _, Value)
					-- TODO(TMF): The max value below is hardcoded, this should be a global!
					Panel:SetValue(Value)
					Current.Graph["Redline"] = Value

					SoundGraph:SetXRange(0, Value + 1000)
					SoundGraph:SetXSpacing(Value < 1000 and 100 or 1000)
					return Value
				end)

				RPMSlider:SetParent(GraphPanel)
				RPMSlider:Dock(TOP)
				RPMSlider:SetWide(Menu.Wide)
				RPMSlider:SetValue(GetClientNumber("RPMSlider", 4400))
				RPMSlider:SetClientData("RPMSlider", "OnValueChanged")
				RPMSlider:DefineSetter(function(Panel, _, _, Value)
					-- TODO(TMF): The max value below is hardcoded, this should be a global!
					local Min = Current.Graph["Idle"] or 0
					local Max = Current.Graph["Redline"] or 16383

					Panel:SetMinMax(Min, Max)
					Panel:SetValue(Value)
					Current.Graph["RPM"] = Value

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
				SoundPrePlay.DoClick = function()
					-- Do something here to play them sounds!
				end
				SoundPreStop:SetIcon("icon16/sound_mute.png")
				-- Set the Play/Stop button positions here
				SoundPre:InvalidateLayout(true)
				SoundPre.PerformLayout = function()
					local HWide = SoundPre:GetWide() / 2
					SoundPrePlay:SetSize(HWide, Menu.ButtonHeight)
					SoundPrePlay:Dock(LEFT)
					SoundPreStop:Dock(FILL) -- FILL will cover the remaining space which the previous button didn't
				end

				-- The bottom group where the panels are added and removed dynamically
				local ValuesGroup = self:AddCollapsible("Values", nil, "icon16/application_double.png")
				ValuesGroup:DockMargin(0, 4, 0, 4)
				ListSlider = self:AddSlider("Values", 1, _MAXSOUNDS, 0)
				ListPanel = self:AddPanel("DListLayout")
				AddValue = self:AddPanel("DImageButton")

				local LastValueAmount = 0
				ListSlider:SetParent(ValuesGroup)
				ListSlider:Dock(TOP)
				ListSlider:SetValue(GetClientData("ListSlider"))
				ListSlider:SetClientData("ListSlider", "OnValueChanged")
				ListSlider:DefineSetter(function(Panel, _, _, Value)
					local ValueAmount = math.Clamp(math.Round(tonumber(Value)), 1, _MAXSOUNDS)
					if ValueAmount ~= LastValueAmount then
						if ValueAmount > LastValueAmount then
							for _ = LastValueAmount + 1, ValueAmount do
								ListPanel:Add(AddValuePanel(self))
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
				-- I don't know if this makes sense, but somehow it gives me less trouble to later remove any arbitrary panels
				self:StartTemporal(ValuesGroup)
				self:ClearTemporal(ValuesGroup)

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

				self:EndTemporal(ValuesGroup)

				AddValue:SetParent(ValuesGroup)
				AddValue:Dock(TOP)
				AddValue:SetImage("icon16/add.png")
				AddValue:SetTooltip("Add a new sound.")
				AddValue:SetStretchToFit(false)
				AddValue:SetSize(16, 16)
				AddValue.DoClick = function()
					local Value = GetClientData("ListSlider")
					ListSlider:SetValue(Value + 1)
				end
			end
		}
		local Switch = Case[Num]
		Switch()
	end

	do -- SoundBank entity data reception and menu population
		local function PopulateMenu(Count)
			-- We set it to option 4 since that's where the values are located at 
			OptionSelectionBox:ChooseOption(OptionSelectionBox:GetOptionText(4), 4)

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