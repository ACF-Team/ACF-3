local panels = {}

local function addPanel(Menu, ParentPanel)
	local id = #panels + 1

	local Wide = Menu:GetWide()
	local ButtonHeight = 20
	local parent = ParentPanel
	parent = parent -- So the linter stops bitching, idk if i need this extra arg 

	local panel = Menu:AddPanel("DPanel")
	panel:SetWide(Wide)
	panel:SetTall(60)
	panel:SetText("")
	panel:Dock(TOP)
	panel:DockMargin(0, -5, 0, 10)
	panel.id = id

	local top_panel = Menu:AddPanel("DPanel")
	top_panel:SetParent(panel)
	top_panel.Paint = function() end
	top_panel:Dock(TOP)
	top_panel:DockMargin(0, 4, 0, 0)

	local bottom_panel = Menu:AddPanel("DPanel")
	bottom_panel:SetParent(panel)
	bottom_panel.Paint = function() end
	bottom_panel:Dock(BOTTOM)
	bottom_panel:DockMargin(0, 0, 0, -6)
	bottom_panel:SetTall(34) -- Why is it setting the tall of its children as well :sob:

	local num_panel = Menu:AddPanel("DLabel")
	num_panel:SetParent(top_panel)
	num_panel:SetText(panel.id .. " = ")
	num_panel:Dock(LEFT)
	num_panel:DockMargin(4, 0, -36, 0)
	num_panel:SetColor(color_black)
	num_panel.id = id

	local rpmInput = Menu:AddPanel("DNumberWang")
	rpmInput:SetParent(top_panel)
	rpmInput:SetMinMax(0, 16383) -- Maximum number it can be networked to the client, also a minmax...
	rpmInput:SetTall(ButtonHeight)
	rpmInput:SetWide(48) -- Equivalent to 00000 + up/down buttons at font size = 16 + padding
	rpmInput:Dock(LEFT)
	rpmInput:DockMargin(0, 0, 2, 0)

	local soundPath = Menu:AddPanel("DTextEntry")
	soundPath:SetParent(top_panel)
	soundPath:SetText("")
	soundPath:SetWide(Wide - 20)
	soundPath:SetTall(ButtonHeight)
	soundPath:SetMultiline(false)
	soundPath:Dock(FILL)
	soundPath:DockMargin(0, 0, 2, 0)

	local removeButton = Menu:AddPanel("DImageButton")
	removeButton:SetParent(top_panel)
	removeButton:SetImage( "icon16/delete.png" )
	removeButton:SizeToContents()
	removeButton:Dock(RIGHT)
	removeButton:DockMargin(2, 2, 2, 2)
	removeButton:Center()
	removeButton:SetTooltip("Remove this sound.")
	removeButton.DoClick = function()
		-- Don't remove the last item
		if #panels == 1 then
			removeButton.DoClick = function() end
			return
		end

		for k in ipairs(panels) do
			panel.id = k
			num_panel.id = id
			num_panel:SetText(num_panel.id .. " = ")
		end

		local id = panel.id
		panels[id]:Remove()
		table.remove(panels, id)
	end

	local searchButton = Menu:AddPanel("DImageButton")
	searchButton:SetParent(top_panel)
	searchButton:SetImage("icon16/application_view_list.png")
	searchButton:SizeToContents()
	searchButton:Dock(RIGHT)
	searchButton:DockMargin(2, 2, 2, 2)
	searchButton:Center()
	searchButton:SetTooltip("Open sound browser.")
	searchButton.DoClick = function()
		RunConsoleCommand("wire_sound_browser_open")
	end

	local pitchLabel = Menu:AddPanel("DLabel")
	pitchLabel:SetParent(bottom_panel)
	pitchLabel:SetTall(ButtonHeight)
	pitchLabel:SetText("Pitch:")
	pitchLabel:Dock(LEFT)
	pitchLabel:DockMargin(4, 0, -28, 0)
	pitchLabel:SetColor(color_black)

	local pitch = Menu:AddPanel("DNumberWang")
	pitch:SetParent(bottom_panel)
	pitch:SetTall(ButtonHeight)
	pitch:SetMinMax(0, 255)
	pitch:SetValue(100)
	pitch:Dock(LEFT)
	pitch:SetTooltip("Set the pitch of your sound to play at this exact RPM")
	pitch:SetWide(40) -- Equivalent to 000 + up/down buttons at font size = 16 + padding

	local volumeLabel = Menu:AddPanel("DLabel")
	volumeLabel:SetParent(bottom_panel)
	volumeLabel:SetTall(ButtonHeight)
	volumeLabel:SetText("Volume:")
	volumeLabel:Dock(LEFT)
	volumeLabel:DockMargin(4, 0, -20, 0)
	volumeLabel:SetColor(color_black)

	local volume = Menu:AddPanel("DNumberWang")
	volume:SetParent(bottom_panel)
	volume:SetTall(ButtonHeight)
	volume:SetMinMax(0, 1)
	volume:SetDecimals(2)
	volume:SetInterval(0.01)
	volume:SetFraction(0.01)
	volume:SetValue(1)
	volume:Dock(LEFT)
	volume:SetTooltip("Set the volume of your sound to play at this exact RPM")
	volume:SetWide(40) -- Equivalent to 000 + up/down buttons at font size = 16 + padding

	local widthLabel = Menu:AddPanel("DLabel")
	widthLabel:SetParent(bottom_panel)
	widthLabel:SetTall(ButtonHeight)
	widthLabel:SetText("Width:")
	widthLabel:Dock(LEFT)
	widthLabel:DockMargin(4, 0, -24, 0)
	widthLabel:SetColor(color_black)

	local width = Menu:AddPanel("DNumberWang")
	width:SetParent(bottom_panel)
	width:SetTall(ButtonHeight)
	width:SetMinMax(0, 16)
	width:Dock(LEFT)
	width:SetTooltip("Widens the curve of the sound, making it pitch up sooner/later in the curve")
	width:SetWide(32) -- Equivalent to 00 + up/down buttons at font size = 16 + padding

	table.insert(panels, panel)
	PrintTable(panels)
	return panel
end

local function do4thPanel(Menu)
	local mainPanel = Menu:AddPanel("DPanel")
	-- Clear the panels table 
	panels = nil
	panels = {}
	mainPanel:SizeToContents()

	local top_panel = Menu:AddPanel("DPanel")
	top_panel:SetParent(mainPanel)
	top_panel:SetText("")
	top_panel:Dock(TOP)
	top_panel.Paint = function() end

	local numLabel = Menu:AddPanel("DLabel")
	numLabel:SetParent(top_panel)
	numLabel:SetText("N°")
	numLabel:Dock(LEFT)
	numLabel:DockMargin(4, 0, 0, 0)
	numLabel:SetColor(color_black)

	local rpmLabel = Menu:AddPanel("DLabel")
	rpmLabel:SetParent(top_panel)
	rpmLabel:SetText("RPM")
	rpmLabel:Dock(LEFT)
	rpmLabel:DockMargin(-36, 0, 0, 0)
	rpmLabel:SetColor(color_black)

	local addbtn = Menu:AddPanel("DImageButton")
	addbtn:SetParent(top_panel)
	addbtn:SetImage("icon16/add.png")
	addbtn:SizeToContents()
	addbtn:Dock(RIGHT)
	addbtn:DockMargin(2, 2, 2, 2)
	addbtn:SetTooltip("Add a new sound.")
	addbtn.DoClick = function()
		addPanel(Menu, mainPanel)
	end

	local pathLabel = Menu:AddPanel("DLabel")
	pathLabel:SetParent(top_panel)
	pathLabel:SetText("Sound Path")
	pathLabel:Dock(FILL)
	pathLabel:DockMargin(-12, 0, 0, 0)
	pathLabel:Center()
	pathLabel:SetColor(color_black)

	addPanel(Menu, mainPanel) -- add the first
end

--- Generates the menu used in the Sound Replacer tool.
--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateSoundMenu(Panel)
	local Menu = ACF.InitMenuBase(Panel, "SoundMenu", "acf_reload_sound_menu")
	--local Wide = Menu:GetWide()
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
	optionSelectionBox.OnSelect = function(_, index, value)
		Menu:StartTemporal(Panel)
		Menu:ClearTemporal(Panel)
		-- Ideas for how i want this to look like, thinking about how to implement these...
		-- Wether it makes sense to have it like this or not, we'll see...
		print("This option should show... \n")
		if index == 1 then
			print(value .. "Old menu with text entry for a single sound")

		elseif index == 2 then
			print(value .. "New menu with three text entries stylized as [Label] = [Sound Path]")
		-- This one in particular is probably not really necessary, if i manage to consolidate this idea with the custom one...
		elseif index == 3 then
			print(value .. "New menu with a slider(min = 2, max = 5) that dynamically adds a label \
				 (can be numeric like 00, 33, 66, 99 OR verylow, low, mid, high, veryhigh; we'd see) and the text entries for them sound paths; For simple sound interpolation")

		elseif index == 4 then
			-- Creates an invisible generic panel(like a HTML div)
			do4thPanel(Menu)
		end

		Menu:EndTemporal(Panel)
	end

	--[[local SoundNameText = Menu:AddPanel("DTextEntry")
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
		SoundPreStop:Dock(FILL) -- FILL will cover the remaining space which the previous button didn't.
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

	--]]
end