local Sounds = ACF.Utilities.Sounds

local panels = {}
local _MAXSOUNDS = 16 -- Maximum amount of sounds we're willing to send and have. TODO(TMF): Make this a global!
local addBtn -- Dumb glocals cause i can't pattern!
local graphPanel

local function addComplexPanel(Menu)
	local id = #panels + 1
	local Wide = Menu:GetWide()
	local ButtonHeight = 20

	local panel = Menu:AddPanel("DPanel")
		panel:SetWide(Wide)
		panel:SetTall(60)
		panel:SetText("")
		panel:Dock(TOP)
		panel:DockMargin(0, -5, 0, 10)
		panel.id = id

	local top_panel = Menu:AddPanel("DPanel") -- This is equivalent to a HTML's Div, just here to parent other children to.
		top_panel:SetParent(panel)
		top_panel:Dock(TOP)
		top_panel:DockMargin(0, 4, 0, 0)
		top_panel.Paint = function() end

	local bottom_panel = Menu:AddPanel("DPanel") -- Same as above
		bottom_panel:SetParent(panel)
		bottom_panel:Dock(BOTTOM)
		bottom_panel:DockMargin(0, 0, 0, -6)
		bottom_panel:SetTall(34) -- Why is it setting the tall of its children as well :sob:
		bottom_panel.Paint = function() end

	local numLabel = Menu:AddPanel("DLabel")
		numLabel:SetParent(top_panel)
		numLabel:SetFont("ACF_Control")
		numLabel:SetText(panel.id .. " = ")
		numLabel:Dock(LEFT)
		numLabel:DockMargin(4, 0, -36, 0)
		numLabel:SetColor(color_black)
		numLabel.id = id

	local rpm = Menu:AddPanel("DNumberWang")
		rpm:SetParent(top_panel)
		rpm:SetMinMax(0, 16383) -- Maximum number it can be networked to the client, also a minmax...
		rpm:SetTall(ButtonHeight)
		rpm:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding
		rpm:SetValue(1000 * id)
		rpm:Dock(LEFT)
		rpm:DockMargin(0, 0, 2, 0)
		panel.rpm = rpm

	local soundPath = Menu:AddPanel("DTextEntry")
		soundPath:SetParent(top_panel)
		soundPath:SetText("")
		soundPath:SetWide(Wide - 20)
		soundPath:SetTall(ButtonHeight)
		soundPath:SetMultiline(false)
		soundPath:Dock(FILL)
		soundPath:DockMargin(0, 0, 2, 0)
		panel.soundPath = soundPath
		soundPath.OnChange = function()
			local isValid = Sounds.IsValidSound
			local value = soundPath:GetValue()

			if isValid(value) then
				panel.soundPath:SetTooltip()
				panel.parseIcon:SetImage("icon16/accept.png")
			else
				panel.soundPath:SetTooltip("Invalid sound: File does not exist")
				panel.parseIcon:SetImage("icon16/cancel.png")
			end
		end

	local parseIcon = Menu:AddPanel("DImage")
		panel.parseIcon = parseIcon
		parseIcon:SetParent(soundPath)
		parseIcon:Dock(RIGHT)
		parseIcon:DockMargin(2, 2, 2, 2)
		parseIcon:SetImage("icon16/accept.png")
		parseIcon:SizeToContents()

	local removeBtn = Menu:AddPanel("DImageButton")
		removeBtn:SetParent(top_panel)
		removeBtn:SetImage( "icon16/delete.png" )
		removeBtn:SizeToContents()
		removeBtn:Dock(RIGHT)
		removeBtn:DockMargin(2, 2, 2, 2)
		removeBtn:Center()
		removeBtn:SetTooltip("Remove this sound.")
		removeBtn.DoClick = function()
			-- TODO(TMF): Have it do a popup modal prompting for removal before executing this function!
			-- Don't remove the last item
			if #panels == 1 then
				removeBtn.DoClick = function() end
				return
			end

			-- Move the label number of the other panels up to compensate
			for k in ipairs(panels) do
				panel.id = k
				numLabel.id = id
				numLabel:SetText(numLabel.id .. " = ")
			end

			local id = panel.id
			panels[id]:Remove()
			table.remove(panels, id)

			addBtn:SetEnabled(true) -- Reenable our button
		end

	local searchBtn = Menu:AddPanel("DImageButton")
		searchBtn:SetParent(top_panel)
		searchBtn:SetImage("icon16/application_view_list.png")
		searchBtn:SizeToContents()
		searchBtn:Dock(RIGHT)
		searchBtn:DockMargin(2, 2, 2, 2)
		searchBtn:Center()
		searchBtn:SetTooltip("Open sound browser.")
		searchBtn.DoClick = function()
			RunConsoleCommand("wire_sound_browser_open")
		end

	local pitchLabel = Menu:AddPanel("DLabel")
		pitchLabel:SetParent(bottom_panel)
		pitchLabel:SetFont("ACF_Control")
		pitchLabel:SetText("Pitch:")
		pitchLabel:Dock(LEFT)
		pitchLabel:DockMargin(4, 0, -28, 0)
		pitchLabel:SetColor(color_black)

	local pitch = Menu:AddPanel("DNumberWang")
		panel.pitch = pitch
		pitch:SetParent(bottom_panel)
		pitch:SetTall(ButtonHeight)
		pitch:SetMinMax(0, 255)
		pitch:SetValue(100)
		pitch:Dock(LEFT)
		pitch:SetTooltip("Set the pitch of your sound to play at this exact RPM")
		pitch:SetWide(40) -- Equivalent to 000 + up/down buttons at font size = 16 + padding

	local volumeLabel = Menu:AddPanel("DLabel")
		volumeLabel:SetParent(bottom_panel)
		volumeLabel:SetFont("ACF_Control")
		volumeLabel:SetText("Volume:")
		volumeLabel:Dock(LEFT)
		volumeLabel:DockMargin(4, 0, -16, 0)
		volumeLabel:SetColor(color_black)

	local volume = Menu:AddPanel("DNumberWang")
		panel.volume = volume
		volume:SetParent(bottom_panel)
		volume:SetTall(ButtonHeight)
		volume:SetMinMax(0, 1)
		volume:SetDecimals(2)
		volume:SetInterval(0.01)
		volume:SetFraction(0.01)
		volume:SetValue(1)
		volume:Dock(LEFT)
		volume:SetTooltip("Set the volume of your sound to play at this exact RPM")
		volume:SetWide(40) -- Equivalent to 000 w/ decimal point + up/down buttons at font size = 16 + padding

	local widthLabel = Menu:AddPanel("DLabel")
		widthLabel:SetParent(bottom_panel)
		widthLabel:SetFont("ACF_Control")
		widthLabel:SetText("Width:")
		widthLabel:Dock(LEFT)
		widthLabel:DockMargin(4, 0, -24, 0)
		widthLabel:SetColor(color_black)

	local width = Menu:AddPanel("DNumberWang")
		panel.width = width
		width:SetParent(bottom_panel)
		width:SetTall(ButtonHeight)
		width:SetMinMax(0, 16)
		width:Dock(LEFT)
		width:SetTooltip("Widens the curve of the sound, making it pitch up sooner/later in the curve") -- Better description for this!
		width:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding

	table.insert(panels, panel)
	return panel
end

-- Build the panels according to our selection
local function doPanel(Num, Menu)
	local case = {
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
		-- Third panel, Engines - Simple interpolated. New menu with a slider that creates N amount of text entries to put the sound paths
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
			local mainPanel = Menu:AddPanel("DPanel")
			-- TODO(TMF): Allow this panel to save and load the values that the user has placed!
			panels = nil
			panels = {} -- Reset the panels table
			mainPanel:SizeToContents()
			mainPanel:SetTall(200)

			-- I am unable to have the graph to accomodate itself to the bottom of this list dynamically, so instead i put it to be at the top
			local top_panel = Menu:AddPanel("DPanel") -- This is equivalent to a HTML's Div, just here to parent other children to
				top_panel:SetParent(mainPanel)
				top_panel:SetText("")
				top_panel:Dock(FILL)
				top_panel:DockMargin(0, 0, 0, 0)
				top_panel.Paint = function() end

			local _ = Menu:AddPanel("DPanel")
				_:SetParent(top_panel)
				_:SetText("")
				_:SetTall(24)
				_:Dock(TOP)
				_:DockMargin(4, 4, 4, 4)
				_:SetWide(Wide)
				_.Paint = function() end

			local bottom_panel = Menu:AddPanel("DPanel") -- Same here...
				bottom_panel:SetParent(mainPanel)
				bottom_panel:SetText("")
				bottom_panel:Dock(BOTTOM)
				bottom_panel:DockMargin(0, 0, 0, 0)
				bottom_panel.Paint = function() end

			local idleLabel = Menu:AddPanel("DLabel")
				idleLabel:SetParent(_)
				idleLabel:SetText("Idle:")
				idleLabel:Dock(LEFT)
				idleLabel:DockMargin(4, 0, 0, 0)
				idleLabel:SetColor(color_black)

			local idle = Menu:AddPanel("DNumberWang")
				idle:SetParent(_)
				idle:SetMinMax(100, 2000)
				idle:SetValue(idle:GetMin())
				idle:Dock(LEFT)
				idle:DockMargin(-40, 0, 0, 0)
				idle:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding

			local redlineLabel = Menu:AddPanel("DLabel")
				redlineLabel:SetParent(_)
				redlineLabel:SetText("Redline:")
				redlineLabel:Dock(LEFT)
				redlineLabel:DockMargin(4, 0, 0, 0)
				redlineLabel:SetColor(color_black)

			local redline = Menu:AddPanel("DNumberWang")
				redline:SetParent(_)
				redline:SetMinMax(idle:GetValue(), 16383)
				redline:SetValue(idle:GetValue() + 1000)
				redline:Dock(LEFT)
				redline:DockMargin(-24, 0, 0, 0)
				redline:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding

			-- Made it global for now, this is dumb
			graphPanel = Menu:AddGraph()
				graphPanel:SetParent(top_panel)
				graphPanel:SetPos(graphPanel:GetX(), graphPanel:GetY() + (32 * #panels))
				graphPanel:SetXLabel("RPM")
				graphPanel:SetYLabel("Pitch/Volume")
				graphPanel:SetXSpacing(1000)
				graphPanel:SetYSpacing(100)
				graphPanel:SetFidelity(10)
				graphPanel:Dock(FILL)
				graphPanel:DockMargin(4, 0, 4, 2)

			local slider = Menu:AddSlider("RPM", idle:GetValue(), redline:GetValue())
				slider:SetParent(top_panel)
				slider:Dock(BOTTOM)
				slider:DockMargin(4, 0, 4, 0)

			local numLabel = Menu:AddLabel("N°")
				numLabel:SetParent(bottom_panel)
				numLabel:Dock(LEFT)
				numLabel:DockMargin(4, 0, 0, 0)
				numLabel:SetColor(color_black)

			local rpmLabel = Menu:AddLabel("RPM")
				rpmLabel:SetParent(bottom_panel)
				rpmLabel:Dock(LEFT)
				rpmLabel:DockMargin(-36, 0, 0, 0)
				rpmLabel:SetColor(color_black)

			local pathLabel = Menu:AddLabel("Sound Path")
				pathLabel:SetParent(bottom_panel)
				pathLabel:Dock(LEFT)
				pathLabel:DockMargin(-12, 5, 0, 0) -- The top margin is fucking bullshit, why wont this align by itself??? :sob: :sob: :sob:
				pathLabel:SetColor(color_black)

			-- Made it global for now, this is dumb
			addBtn = Menu:AddPanel("DImageButton")
				addBtn:SetParent(bottom_panel)
				addBtn:SetImage("icon16/add.png")
				addBtn:SizeToContents()
				addBtn:Dock(RIGHT)
				addBtn:DockMargin(2, 2, 2, 2)
				addBtn:SetTooltip("Add a new sound.")
				addBtn.DoClick = function()
					if #panels >= _MAXSOUNDS then addBtn:SetEnabled(false) return end -- Disable the button if enough panels exist already
					addComplexPanel(Menu)
				end

			-- Add the first panel if none exists
			if #panels == 0 then addComplexPanel(Menu) end
		end
	}

	local switch = case[Num]
	switch()
end

--- Generates the menu used in the Sound Replacer tool.
--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateSoundMenu(Panel)
	local Menu = ACF.InitMenuBase(Panel, "SoundMenu", "acf_reload_sound_menu")
	local ButtonHeight = 20
	Menu:AddLabel("#tool.acfsound.help")

	local optionSelectionBox = Menu:AddPanel("DComboBox")
	optionSelectionBox:SetText("Select an Option...")
	optionSelectionBox:Dock(TOP)
	optionSelectionBox:SetTall(ButtonHeight)
	optionSelectionBox:AddChoice("Generic - One sound. ")
	optionSelectionBox:AddChoice("Weapons - Start/Loop/Stop. ")
	optionSelectionBox:AddChoice("Engines - Simple interpolated. ")
	optionSelectionBox:AddChoice("Engines - Custom interpolated. ")
	optionSelectionBox.OnSelect = function(_, index, _)
		Menu:StartTemporal(Panel)
		Menu:ClearTemporal(Panel)
		-- Build the panels according to our selection
		doPanel(index, Menu)
		Menu:EndTemporal(Panel)
	end
end