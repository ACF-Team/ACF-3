local Sounds = ACF.Utilities.Sounds

local Panels = {}
local _MAXSOUNDS = 16 -- Maximum amount of sounds we're willing to send and have. TODO(TMF): Make this a global!
local AddBtn -- Dumb glocals cause i can't pattern!
local GraphPanel

local function AddComplexPanel(Menu)
	local ID = #Panels + 1
	local Wide = Menu:GetWide()
	local ButtonHeight = 20

	local Panel = Menu:AddPanel("DPanel")
		Panel:SetWide(Wide)
		Panel:SetTall(60)
		Panel:SetText("")
		Panel:Dock(TOP)
		Panel:DockMargin(0, -5, 0, 10)
		Panel.ID = ID

	local TopPanel = Menu:AddPanel("DPanel") -- This is equivalent to a HTML's Div, just here to parent other children to.
		TopPanel:SetParent(Panel)
		TopPanel:Dock(TOP)
		TopPanel:DockMargin(0, 4, 0, 0)
		TopPanel.Paint = function() end

	local BottomPanel = Menu:AddPanel("DPanel") -- Same as above
		BottomPanel:SetParent(Panel)
		BottomPanel:Dock(BOTTOM)
		BottomPanel:DockMargin(0, 0, 0, -6)
		BottomPanel:SetTall(34) -- Why is it setting the tall of its children as well :sob:
		BottomPanel.Paint = function() end

	local NumLabel = Menu:AddPanel("DLabel")
		NumLabel:SetParent(TopPanel)
		NumLabel:SetFont("ACF_Control")
		NumLabel:SetText(Panel.ID .. " = ")
		NumLabel:Dock(LEFT)
		NumLabel:DockMargin(4, 0, -36, 0)
		NumLabel:SetColor(color_black)
		NumLabel.ID = ID

	local Rpm = Menu:AddPanel("DNumberWang")
		Rpm:SetParent(TopPanel)
		Rpm:SetMinMax(0, 16383) -- Maximum number it can be networked to the client, also a minmax...
		Rpm:SetTall(ButtonHeight)
		Rpm:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding
		Rpm:SetValue(1000 * ID)
		Rpm:Dock(LEFT)
		Rpm:DockMargin(0, 0, 2, 0)
		Panel.RPM = Rpm

	local SoundPath = Menu:AddPanel("DTextEntry")
		SoundPath:SetParent(TopPanel)
		SoundPath:SetText("")
		SoundPath:SetWide(Wide - 20)
		SoundPath:SetTall(ButtonHeight)
		SoundPath:SetMultiline(false)
		SoundPath:Dock(FILL)
		SoundPath:DockMargin(0, 0, 2, 0)
		Panel.SoundPath = SoundPath
		SoundPath.OnChange = function()
			local isValid = Sounds.IsValidSound
			local value = SoundPath:GetValue()

			if isValid(value) then
				Panel.SoundPath:SetTooltip()
				Panel.ParseIcon:SetImage("icon16/accept.png")
			else
				Panel.SoundPath:SetTooltip("Invalid sound: File does not exist")
				Panel.ParseIcon:SetImage("icon16/cancel.png")
			end
		end

	local ParseIcon = Menu:AddPanel("DImage")
		Panel.ParseIcon = ParseIcon
		ParseIcon:SetParent(SoundPath)
		ParseIcon:Dock(RIGHT)
		ParseIcon:DockMargin(2, 2, 2, 2)
		ParseIcon:SetImage("icon16/accept.png")
		ParseIcon:SizeToContents()

	local RemoveBtn = Menu:AddPanel("DImageButton")
		RemoveBtn:SetParent(TopPanel)
		RemoveBtn:SetImage( "icon16/delete.png" )
		RemoveBtn:SizeToContents()
		RemoveBtn:Dock(RIGHT)
		RemoveBtn:DockMargin(2, 2, 2, 2)
		RemoveBtn:Center()
		RemoveBtn:SetTooltip("Remove this sound.")
		RemoveBtn.DoClick = function()
			-- TODO(TMF): Have it do a popup modal prompting for removal before executing this function!
			-- Don't remove the last item
			if #Panels == 1 then
				RemoveBtn.DoClick = function() end
				return
			end

			-- Move the label number of the other Panels up to compensate
			for k in ipairs(Panels) do
				Panel.ID = k
				NumLabel.ID = ID
				NumLabel:SetText(NumLabel.ID .. " = ")
			end

			local ID = Panel.ID
			Panels[ID]:Remove()
			table.remove(Panels, ID)

			AddBtn:SetEnabled(true) -- Reenable our button
		end

	local SearchBtn = Menu:AddPanel("DImageButton")
		SearchBtn:SetParent(TopPanel)
		SearchBtn:SetImage("icon16/application_view_list.png")
		SearchBtn:SizeToContents()
		SearchBtn:Dock(RIGHT)
		SearchBtn:DockMargin(2, 2, 2, 2)
		SearchBtn:Center()
		SearchBtn:SetTooltip("Open sound browser.")
		SearchBtn.DoClick = function()
			RunConsoleCommand("wire_sound_browser_open")
		end

	local PitchLabel = Menu:AddPanel("DLabel")
		PitchLabel:SetParent(BottomPanel)
		PitchLabel:SetFont("ACF_Control")
		PitchLabel:SetText("Pitch:")
		PitchLabel:Dock(LEFT)
		PitchLabel:DockMargin(4, 0, -28, 0)
		PitchLabel:SetColor(color_black)

	local Pitch = Menu:AddPanel("DNumberWang")
		Panel.Pitch = Pitch
		Pitch:SetParent(BottomPanel)
		Pitch:SetTall(ButtonHeight)
		Pitch:SetMinMax(0, 255)
		Pitch:SetValue(100)
		Pitch:Dock(LEFT)
		Pitch:SetTooltip("Set the pitch of your sound to play at this exact RPM")
		Pitch:SetWide(40) -- Equivalent to 000 + up/down buttons at font size = 16 + padding

	local VolumeLabel = Menu:AddPanel("DLabel")
		VolumeLabel:SetParent(BottomPanel)
		VolumeLabel:SetFont("ACF_Control")
		VolumeLabel:SetText("Volume:")
		VolumeLabel:Dock(LEFT)
		VolumeLabel:DockMargin(4, 0, -16, 0)
		VolumeLabel:SetColor(color_black)

	local Volume = Menu:AddPanel("DNumberWang")
		Panel.Volume = Volume
		Volume:SetParent(BottomPanel)
		Volume:SetTall(ButtonHeight)
		Volume:SetMinMax(0, 1)
		Volume:SetDecimals(2)
		Volume:SetInterval(0.01)
		Volume:SetFraction(0.01)
		Volume:SetValue(1)
		Volume:Dock(LEFT)
		Volume:SetTooltip("Set the volume of your sound to play at this exact RPM")
		Volume:SetWide(40) -- Equivalent to 000 w/ decimal point + up/down buttons at font size = 16 + padding

	local WidthLabel = Menu:AddPanel("DLabel")
		WidthLabel:SetParent(BottomPanel)
		WidthLabel:SetFont("ACF_Control")
		WidthLabel:SetText("Width:")
		WidthLabel:Dock(LEFT)
		WidthLabel:DockMargin(4, 0, -24, 0)
		WidthLabel:SetColor(color_black)

	local Width = Menu:AddPanel("DNumberWang")
		Panel.Width = Width
		Width:SetParent(BottomPanel)
		Width:SetTall(ButtonHeight)
		Width:SetMinMax(0, 16)
		Width:Dock(LEFT)
		Width:SetTooltip("Widens the curve of the sound, making it pitch up sooner/later in the curve") -- Better description for this!
		Width:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding

	table.insert(Panels, Panel)
	return Panel
end

-- Build the panels according to our selection
local function BuildPanelsFromSelection(Num, Menu)
	local Case = {
		-- I explictly gave these their numeric keys so its easier to infer which panel we're working with
		-- First panel, Generic - One sound. Old menu with text entry for a single sound
		[1] = function ()
			local Wide = Menu:GetWide()
			local ButtonHeight = 20

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

			-- Adding these before the main panel shit happens
			local SoundPre = Menu:AddPanel("ACF_Panel")
				SoundPre:SetWide(Wide)
				SoundPre:SetTall(ButtonHeight)

			local SoundPrePlay = SoundPre:AddButton("#tool.acfsound.play")
				SoundPrePlay:SetIcon("icon16/sound.png")
				SoundPrePlay.DoClick = function()
					-- Do something here to play them sounds!
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

			-- The panel for the rest 
			local MainPanel = Menu:AddPanel("DPanel")
			-- TODO(TMF): Allow this panel to save and load the values that the user has placed!
			Panels = nil
			Panels = {} -- Reset the panels table
			MainPanel:SizeToContents()
			MainPanel:SetTall(200)

			-- I am unable to have the graph to accomodate itself to the bottom of this list dynamically, so instead i put it to be at the top
			local TopPanel = Menu:AddPanel("DPanel") -- This is equivalent to a HTML's Div, just here to parent other children to
				TopPanel:SetParent(MainPanel)
				TopPanel:SetText("")
				TopPanel:Dock(FILL)
				TopPanel:DockMargin(0, 0, 0, 0)
				TopPanel.Paint = function() end

			local _ = Menu:AddPanel("DPanel") -- Nameless panel just so i can properly fit these fucking panels
				_:SetParent(TopPanel)
				_:SetText("")
				_:SetTall(24)
				_:Dock(TOP)
				_:DockMargin(4, 4, 4, 4)
				_:SetWide(Wide)
				_.Paint = function() end

			local BottomPanel = Menu:AddPanel("DPanel") -- Same here...
				BottomPanel:SetParent(MainPanel)
				BottomPanel:SetText("")
				BottomPanel:Dock(BOTTOM)
				BottomPanel:DockMargin(0, 0, 0, 0)
				BottomPanel.Paint = function() end

			local IdleLabel = Menu:AddPanel("DLabel")
				IdleLabel:SetParent(_)
				IdleLabel:SetText("Idle:")
				IdleLabel:Dock(LEFT)
				IdleLabel:DockMargin(4, 0, 0, 0)
				IdleLabel:SetColor(color_black)

			local Idle = Menu:AddPanel("DNumberWang")
				Idle:SetParent(_)
				Idle:SetMinMax(0, 2000)
				Idle:SetValue(Idle:GetMin())
				Idle:Dock(LEFT)
				Idle:DockMargin(-40, 0, 0, 0)
				Idle:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding

			local RedlineLabel = Menu:AddPanel("DLabel")
				RedlineLabel:SetParent(_)
				RedlineLabel:SetText("Redline:")
				RedlineLabel:Dock(LEFT)
				RedlineLabel:DockMargin(4, 0, 0, 0)
				RedlineLabel:SetColor(color_black)

			local Redline = Menu:AddPanel("DNumberWang")
				Redline:SetParent(_)
				Redline:SetMinMax(Idle:GetValue(), 16383)
				Redline:SetValue(Idle:GetValue() + 1000)
				Redline:Dock(LEFT)
				Redline:DockMargin(-24, 0, 0, 0)
				Redline:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding

			-- Made it global for now, this is dumb
			GraphPanel = Menu:AddGraph()
				GraphPanel:SetParent(TopPanel)
				GraphPanel:SetPos(GraphPanel:GetX(), GraphPanel:GetY() + (32 * #Panels))
				GraphPanel:SetXLabel("RPM")
				GraphPanel:SetYLabel("Pitch/Volume")
				GraphPanel:SetXSpacing(1000)
				GraphPanel:SetYSpacing(100)
				GraphPanel:SetFidelity(10)
				GraphPanel:Dock(FILL)
				GraphPanel:DockMargin(4, 0, 4, 2)

			local RPMSlider = Menu:AddSlider("RPM", Idle:GetValue(), Redline:GetValue())
				RPMSlider:SetParent(TopPanel)
				RPMSlider:Dock(BOTTOM)
				RPMSlider:DockMargin(4, 0, 4, 0)

			local NumLabel = Menu:AddLabel("N°")
				NumLabel:SetParent(BottomPanel)
				NumLabel:Dock(LEFT)
				NumLabel:DockMargin(4, 0, 0, 0)
				NumLabel:SetColor(color_black)

			local RpmLabel = Menu:AddLabel("RPM")
				RpmLabel:SetParent(BottomPanel)
				RpmLabel:Dock(LEFT)
				RpmLabel:DockMargin(-36, 0, 0, 0)
				RpmLabel:SetColor(color_black)

			local PathLabel = Menu:AddLabel("Sound Path")
				PathLabel:SetParent(BottomPanel)
				PathLabel:Dock(LEFT)
				PathLabel:DockMargin(-12, 5, 0, 0) -- The top margin is fucking bullshit, why wont this align by itself??? :sob: :sob: :sob:
				PathLabel:SetColor(color_black)

			-- Made it global for now, this is dumb
			AddBtn = Menu:AddPanel("DImageButton")
				AddBtn:SetParent(BottomPanel)
				AddBtn:SetImage("icon16/add.png")
				AddBtn:SizeToContents()
				AddBtn:Dock(RIGHT)
				AddBtn:DockMargin(2, 2, 2, 2)
				AddBtn:SetTooltip("Add a new sound.")
				AddBtn.DoClick = function()
					if #Panels >= _MAXSOUNDS then AddBtn:SetEnabled(false) return end -- Disable the button if enough panels exist already
					AddComplexPanel(Menu)
				end

			-- Add the first panel if none exists
			if #Panels == 0 then AddComplexPanel(Menu) end
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

	local OptionSelectionBox = Menu:AddPanel("DComboBox")
	OptionSelectionBox:SetText("Select an Option...")
	OptionSelectionBox:Dock(TOP)
	OptionSelectionBox:SetTall(ButtonHeight)
	OptionSelectionBox:AddChoice("Generic - One sound. ")
	OptionSelectionBox:AddChoice("Weapons - Start/Loop/Stop. ")
	OptionSelectionBox:AddChoice("Engines - Simple interpolated. ")
	OptionSelectionBox:AddChoice("Engines - Custom interpolated. ")
	OptionSelectionBox.OnSelect = function(_, Index, _)
		Menu:StartTemporal(Panel)
		Menu:ClearTemporal(Panel)
		-- Build the panels according to our selection
		BuildPanelsFromSelection(Index, Menu)
		Menu:EndTemporal(Panel)
	end
end