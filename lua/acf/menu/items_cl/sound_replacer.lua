local ACF = ACF
local Sounds = ACF.Utilities.Sounds
local GetClientData, SetClientData = ACF.GetClientData, ACF.SetClientData
local GetClientNumber, GetClientString = ACF.GetClientNumber, ACF.GetClientString

local AddValue, ListPanel, ValuesGroup, SoundGraph
local Current = {Panels = {},
				 Count  = 0,
				 Graph  = {
					Idle      = 0,
					Redline   = 1,
					RPMSlider = 2}
				}
local _MAXSOUNDS = 16 -- Maximum amount of sounds we're willing to send and have. TODO(TMF): Make this a global!

-- The graphing function, this is a mirror of the function found in sounds_cl.lua
local function UpdateGraph(Panel)
	local Count = #Current.Panels
	if not Count then return end

	Panel:Clear()

	for I = 1, Count do
		local addCurveWidth = GetClientNumber("Width " .. I, 0) -- Current.Panels[I].Width 
		local pitch = GetClientNumber("Pitch " .. I, 0) -- Current.Panels[I].Pitch 
		--local volume = Current.Panels[I].Volume * 100 -- Idk if we want to plot volume as a function
		local min = I == 1 and 0 or GetClientNumber("RPM " .. math.Clamp(I - 1 - addCurveWidth, 0, 16383))
		local mid = GetClientNumber("RPM " .. I, 0)
		-- TODO(TMF): The max value below is hardcoded, this should be a global!
		local max = I == Count and 16383 or GetClientNumber("RPM " .. math.Clamp(I + 1 + addCurveWidth, 0, 16383))

		Panel:PlotFunction("Sound " .. I, nil, function(X)
			return (Sounds.Fade(X, min - addCurveWidth, mid, max + addCurveWidth)) * pitch
		end)
	end
end

local function AddValuePanel(Menu, Data)
	Current.Count = Current.Count + 1
	local ID = math.max(Current.Count, #Current.Panels)
	local ButtonHeight = 20

	local _, MPanel = Menu:AddCollapsible()
	local Base = Menu:AddPanel("DPanel")
	_ = Base -- Override ACF's basic Base with this
	local TopDiv = Menu:AddPanel("ACF_Panel") -- This is equivalent to a HTML's Div, just here to parent other children to.
	local BotDiv = Menu:AddPanel("ACF_Panel") -- Same as above.
	-- TODO(TMF): The max value below is hardcoded, this should be a global!
	local RPMWang, RPMLabel = Menu:AddNumberWang("RPM:", 0, 16383, 0)
	local _, PathLabel, PathText = Menu:AddTextEntry("Path:")
	local ParseIcon = Menu:AddPanel("DImage")
	local RemoveButton = Menu:AddPanel("DImageButton")
	local SearchButton = Menu:AddPanel("DImageButton")

	local PitchWang, PitchLabel = Menu:AddNumberWang("Pitch:", 0, 255, 0)
	local VolumeWang, VolumeLabel = Menu:AddNumberWang("Volume:", 0, 1, 2)
	local WidthWang, WidthLabel = Menu:AddNumberWang("Width:", 0, 15, 0)

	-- Defaults
	local DefaultPath   = ""
	local DefaultRPM    = 1000 * ID
	local DefaultPitch  = 100
	local DefaultVolume = 1
	local DefaultWidth  = 0

	Data = istable(Data) and Data or { RPM = GetClientNumber("RPM " .. ID, DefaultRPM),
								    Path = GetClientString("Path " .. ID, DefaultPath),
								    Pitch = GetClientNumber("Pitch " .. ID, DefaultPitch),
								    Volume = GetClientNumber("Volume " .. ID, DefaultVolume),
								    Width = GetClientNumber("Width " .. ID, DefaultWidth)}

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
	RPMWang:SetValue(Data.RPM)
	RPMWang:SetClientData("RPM " .. ID, "OnValueChanged")
	RPMWang:DefineSetter(function(Panel, _, _, Value)
		-- TODO(TMF): The max value below is hardcoded, this should be a global!
		local min = ID == 1 and 0 or GetClientNumber("RPM " .. ID - 1) -- Current.Panels[ID - 1].RPM
		local max = ID == #Current.Panels and 16383 or GetClientNumber("RPM " .. ID + 1) -- Current.Panels[ID + 1].RPM

		Panel:SetMinMax(min, max) -- YEA, I MINMAX MY NUMBERS, SO What!?
		Panel:SetValue(Value)

		Current.Panels[ID].RPM = Value

		return Value, Panel
	end)

	PathLabel:SetParent(TopDiv)
	PathLabel:Dock(LEFT)

	PathText:SetParent(TopDiv)
	PathText:Dock(FILL)
	PathText:DockMargin(-25, 0, 0, 0)
	PathText:SetTall(ButtonHeight)
	PathText:SetValue(Data.Path)
	PathText:SetClientData("Path " .. ID, "OnValueChange")
	PathText:DefineSetter(function(Panel, _, _, Value)
		local isValid = Sounds.IsValidSound

		print(Value)
		if isValid(Value) then
			ParseIcon:SetTooltip()
			ParseIcon:SetImage("icon16/accept.png")

			SetClientData("Path " .. ID, Value)
			Current.Panels[ID].Path = Value
		else
			ParseIcon:SetTooltip("Invalid sound: File does not exist")
			ParseIcon:SetImage("icon16/cancel.png")

			SetClientData("Path " .. ID, "")
			Current.Panels[ID].Path = ""
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

		-- Reset our client data
		SetClientData("RPM " .. ID, nil, true)
		SetClientData("Path " .. ID, nil, true)
		SetClientData("Pitch " .. ID, nil, true)
		SetClientData("Volume " .. ID, nil, true)
		SetClientData("Width " .. ID, nil, true)

		-- Remove the panel in question
		MPanel:Remove()
		table.remove(Current.Panels, ID)

		-- Set the label of the remaining panels up
		for k, v in pairs(Current.Panels) do
			if not IsValid(v) then continue end
			v:SetLabel("Value " .. k)
		end

		AddValue:SetEnabled(true) -- Re-enable our add button
		Current.Count = Current.Count - 1

		UpdateGraph(SoundGraph)
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
	PitchWang:SetValue(Data.Pitch)
	PitchWang:SetClientData("Pitch " .. ID, "OnValueChanged")
	PitchWang:DefineSetter(function(_, _, _, Value)
		SetClientData("Pitch " .. ID, Value)
		Current.Panels[ID].Pitch = Value
	end)

	VolumeLabel:SetParent(BotDiv)
	VolumeLabel:Dock(LEFT)

	VolumeWang:SetParent(BotDiv)
	VolumeWang:SetWide(40) -- Equivalent to 0.00 + up/down buttons at font size = 16 + padding
	VolumeWang:DockMargin(-16, 0, 4, 0)
	VolumeWang:Dock(LEFT)
	VolumeWang:SetValue(Data.Volume)
	VolumeWang:SetClientData("Volume " .. ID, "OnValueChanged")
	VolumeWang:DefineSetter(function(_, _, _, Value)
		SetClientData("Volume " .. ID, Value)
		Current.Panels[ID].Volume = Value
	end)

	WidthLabel:SetParent(BotDiv)
	WidthLabel:Dock(LEFT)

	WidthWang:SetParent(BotDiv)
	WidthWang:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding
	WidthWang:DockMargin(-24, 0, 4, 0)
	WidthWang:Dock(LEFT)
	WidthWang:SetValue(Data.Width)
	WidthWang:SetClientData("Width " .. ID, "OnValueChanged")
	WidthWang:DefineSetter(function(_, _, _, Value)
		SetClientData("Width " .. ID, Value)
		Current.Panels[ID].Width = Value
	end)

	table.insert(Current.Panels, MPanel)
	UpdateGraph(SoundGraph)
	return MPanel
end

-- Build the panels according to our selection
local function CreateSubMenu(Num, Menu)
	local Wide = Menu:GetWide()
	local ButtonHeight = 20
	local Case = {
		-- I explictly gave these their numeric keys so its easier to infer which panel we're working with
		-- First panel, Generic - One sound. Old menu with text entry for a single sound
		[1] = function ()
			Menu:AddLabel("This is the first panel, I don't know what to add here yet but you can imagine its gonna be something good, so stay tuned!")

			local SoundNameText = Menu:AddPanel("DTextEntry")
				SoundNameText:SetText("")
				SoundNameText:SetWide(Wide - 20)
				SoundNameText:SetTall(ButtonHeight)
				SoundNameText:SetMultiline(false)
				SoundNameText:SetConVar("wire_soundemitter_sound")

			local SoundBrowserButton = Menu:AddButton("#tool.acfsound.open_browser", "wire_sound_browser_open", SoundNameText:GetValue(), "1")
				SoundBrowserButton:SetWide(Wide)
				SoundBrowserButton:SetTall(ButtonHeight)
				SoundBrowserButton:SetIcon("icon16/application_view_list.png")

			local SoundPre = Menu:AddPanel("ACF_Panel")
				SoundPre:SetWide(Wide)
				SoundPre:SetTall(ButtonHeight)

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
					SoundPrePlay:SetSize(HWide, ButtonHeight)
					SoundPrePlay:Dock(LEFT)
					SoundPreStop:Dock(FILL) -- FILL will cover the remaining space which the previous button didn't
				end

			local CopyButton = Menu:AddButton("#tool.acfsound.copy")
				CopyButton:SetWide(Wide)
				CopyButton:SetTall(ButtonHeight)
				CopyButton:SetIcon("icon16/page_copy.png")
				CopyButton.DoClick = function()
					SetClipboardText(SoundNameText:GetValue())
				end

			local ClearButton = Menu:AddButton("#tool.acfsound.clear")
				ClearButton:SetWide(Wide)
				ClearButton:SetTall(ButtonHeight)
				ClearButton:SetIcon("icon16/cancel.png")
				ClearButton.DoClick = function()
					SoundNameText:SetValue("")
					RunConsoleCommand("wire_soundemitter_sound", "")
				end

			local VolumeSlider = Menu:AddSlider("#tool.acfsound.volume", 0.1, 1, 2)
				VolumeSlider:SetConVar("acfsound_volume")
			local PitchSlider = Menu:AddSlider("#tool.acfsound.pitch", 0.1, 2, 2)
				PitchSlider:SetConVar("acfsound_pitch")
		end,
		-- Second panel, Weapons - Start/Loop/Stop. New menu with three text entries labeled as "Start", "Loop", "End" respectively, to put the sound paths
		-- Layout is similar to the first option
		[2] = function()
			Menu:AddLabel("This is the second panel, I don't know what to add here yet but you can imagine its gonna be something nice, so stay tuned!")

		end,
		-- Third panel, Engines - Simple interpolated. New menu with a Slider that creates N amount of text entries to put the sound paths
		-- Layout is similar to the first option
		[3] = function()
			Menu:AddLabel("This is the third panel, I don't know what to add here yet but you can imagine its gonna be something fantastic, so stay tuned!")

		end,
		-- Fourth panel, Engines - Custom interpolated. New menu with a button to add up to 16 sound paths, with configurable pitch, volume and width for each sound
		-- Has a graph at the top of the list to better visualise how they play at a determined engine RPM
		[4] = function()
			Menu:AddLabel("This is the fourth panel, I don't know what to add here yet but you can imagine its gonna be something mindblowing, so stay tuned!")
			-- Reset them panels
			Current.Panels = nil
			Current.Panels = {}
			Current.Count  = 0
			-- The menu is divided in two groups
			-- The top group where the graph lies
			local GraphGroup = Menu:AddCollapsible("Graph", nil, "icon16/chart_curve_edit.png")
			local GraphPanel = Menu:AddPanel("DPanel")
			local LabelTop = Menu:AddLabel()
			SoundGraph = Menu:AddGraph() -- This one is glocal
			local PanelBottom = Menu:AddPanel("ACF_Panel")
			local IdleLabel = Menu:AddLabel("Idle:")
			local IdleWang = Menu:AddPanel("DNumberWang", 0, 2000)
			local RedlineLabel = Menu:AddLabel("Redline:")
			-- TODO(TMF): The max values below are hardcoded, this should be a global!
			local RedlineWang = Menu:AddPanel("DNumberWang", 0, 16383)
			local RPMSlider = Menu:AddSlider("RPM", 0, 16383)
			local SoundPre = Menu:AddPanel("ACF_Panel")
			local SoundPrePlay = SoundPre:AddButton("#tool.acfsound.play")
			local SoundPreStop = SoundPre:AddButton("#tool.acfsound.stop", "play", "common/null.wav") -- Playing a silent sound will mute the preview but not the sound emitters

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
			GraphPanel:SetTall(368) -- Why can't this grow dynamically 

			LabelTop:SetParent(GraphPanel)
			LabelTop:Dock(TOP)

			SoundGraph:SetParent(GraphPanel)
			SoundGraph:Dock(TOP)
			SoundGraph:SetTall(192)
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
				Current.Graph["Idle"] = Value

				return Value
			end)

			RedlineLabel:SetParent(PanelBottom)
			RedlineLabel:Dock(LEFT)
			RedlineLabel:DockMargin(8, 4, 0, 0) -- Fucking retarded

			RedlineWang:SetParent(PanelBottom)
			RedlineWang:Dock(LEFT)
			RedlineWang:SetValue(DefaultRedline)
			RedlineWang:SetClientData("Redline", "OnValueChanged")
			RedlineWang:DefineSetter(function(Panel, _, _, Value)
				-- TODO(TMF): The max value below is hardcoded, this should be a global!
				Panel:SetMin(Current.Graph["Idle"] or 1)
				Panel:SetMax(16383)
				Panel:SetValue(Value)
				Current.Graph["Redline"] = Value

				SoundGraph:SetXRange(0, Value + Current.Graph["Idle"])
				SoundGraph:SetXSpacing(Value < 1000 and 100 or 1000)
				return Value
			end)

			RPMSlider:SetParent(GraphPanel)
			RPMSlider:Dock(TOP)
			RPMSlider:SetWide(Wide)
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

			SoundPre:SetParent(GraphPanel)
			SoundPre:SetWide(Wide)
			SoundPre:SetTall(ButtonHeight)

			SoundPrePlay:SetIcon("icon16/sound.png")
			SoundPrePlay.DoClick = function()
				-- Do something here to play them sounds!
			end
			SoundPreStop:SetIcon("icon16/sound_mute.png")
			-- Set the Play/Stop button positions here
			SoundPre:InvalidateLayout(true)
			SoundPre.PerformLayout = function()
				local HWide = SoundPre:GetWide() / 2
				SoundPrePlay:SetSize(HWide, ButtonHeight)
				SoundPrePlay:Dock(LEFT)
				SoundPreStop:Dock(FILL) -- FILL will cover the remaining space which the previous button didn't
			end

			-- The bottom group where the panels are added and removed dynamically
			ValuesGroup = Menu:AddCollapsible("Values", nil, "icon16/application_double.png")
			ValuesGroup:DockMargin(0, 4, 0, 4)
			-- I don't know if this makes sense, but somehow it gives me less trouble to later remove any arbitrary panels
			Menu:StartTemporal(ValuesGroup)
			Menu:ClearTemporal(ValuesGroup)

			ListPanel = Menu:AddPanel("DListLayout")
			ListPanel:SetParent(ValuesGroup)
			ListPanel:Dock(TOP)

			Menu:EndTemporal(ValuesGroup)

			AddValue = Menu:AddPanel("DImageButton")
			AddValue:SetParent(ValuesGroup)
			AddValue:Dock(TOP)
			AddValue:SetImage("icon16/add.png")
			AddValue:SetTooltip("Add a new sound.")
			AddValue:SetStretchToFit(false)
			AddValue:SetSize(16, 16)
			AddValue.DoClick = function()
				ListPanel:Add(AddValuePanel(Menu, _))
				-- Disable the button if enough panels exist already
				if #Current.Panels >= _MAXSOUNDS then AddValue:SetEnabled(false) return end

			end
			-- Add the first panel if none exists
			if #Current.Panels == 0 then
				ListPanel:Add(AddValuePanel(Menu, _))
			end
		end
	}

	local Switch = Case[Num]
	Switch()
end

--- Generates the menu used in the Sound Replacer tool.
--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateSoundMenu(Panel)
	local Menu = ACF.InitMenuBase(Panel, "SoundMenu", "acf_reload_sound_menu")
	local ButtonHeight = 20
	Menu:AddLabel("#tool.acfsound.help")

	local OptionSelectionBox = Menu:AddComboBox()
	OptionSelectionBox:SetText("Select an Option...")
	OptionSelectionBox:Dock(TOP)
	OptionSelectionBox:SetTall(ButtonHeight)
	OptionSelectionBox:AddChoice("Generic - One sound. ", 1)
	OptionSelectionBox:AddChoice("Weapons - Start/Loop/Stop. ", 2)
	OptionSelectionBox:AddChoice("Engines - Simple interpolated. ", 3)
	OptionSelectionBox:AddChoice("Engines - Custom interpolated. ", 4)
	OptionSelectionBox.OnSelect = function(_, Index, _)
		Menu:StartTemporal(Panel)
		Menu:ClearTemporal(Panel)
		-- Build the panels according to our selection
		CreateSubMenu(Index, Menu)
		Menu:EndTemporal(Panel)
	end

	do -- SoundBank entity data reception and menu population
		local function PopulateMenu(Table, Count)
			-- We set it to option 4 since that's where the values are located at 
			OptionSelectionBox:ChooseOption(OptionSelectionBox:GetOptionText(4), 4)

			-- Reset them panels
			Current.Panels = nil
			Current.Panels = {}
			Current.Count  = 0

			-- Wipe the clients values list
			Menu:ClearTemporal(ListPanel)

			for I = 1, Count do
				local Data = Table[I]

				ListPanel:Add(AddValuePanel(Menu, Data))
			end
		end

		net.Receive("ACF_SoundMenu_Get_Multi", function(len)
			print("Received " .. len .. " bits for call: \"ACF_SoundMenu_Get_Multi\"")

			local Origin = net.ReadEntity()
			if not Origin then return end

			local Feedback = net.ReadBool()
			if not Feedback then
				local Count = net.ReadUInt(4)
				local SoundTable = {}

				for _ = 1, Count do
					local RPM 		 = net.ReadUInt(14)
					local StringPath = net.ReadString()
					local Pitch 	 = net.ReadUInt(8)
					local Volume 	 = net.ReadUInt(8)
					local Width 	 = net.ReadUInt(4)

					Volume = Volume * 0.01 -- Reduce the received value down to a float

					table.insert(SoundTable, {	RPM    = RPM,
												Path   = StringPath,
												Pitch  = Pitch or 100,
												Volume = Volume or 1,
												Width  = Width or 0 })
				end
				-- Sort the table before calling the function below
				table.sort(SoundTable, function(a, b) return a.RPM < b.RPM end)

				PopulateMenu(SoundTable, Count)
			else
				net.Start("ACF_SoundMenu_Set_Multi")
					net.WriteEntity(Origin)

					local Table = {}
					for I = 1, Current.Count do
						local RPM = GetClientNumber("RPM " .. I)
						local Path = GetClientString("Path " .. I)
						local Pitch = GetClientNumber("Pitch " .. I)
						local Volume = GetClientNumber("Volume " .. I)
						local Width = GetClientNumber("Width " .. I)

						table.insert(Table, {RPM = RPM,
											 Path = Path,
											 Pitch = Pitch,
											 Volume = Volume,
											 Width = Width})
					end
					net.WriteTable(Table)
				net.SendToServer()
			end
		end)
	end
end