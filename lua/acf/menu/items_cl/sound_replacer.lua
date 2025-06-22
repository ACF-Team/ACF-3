--- Generates the menu used in the Sound Replacer tool.
--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateSoundMenu(Panel)
	local Menu = ACF.InitMenuBase(Panel, "SoundMenu", "acf_reload_sound_menu")
	local Wide = Menu:GetWide()
	local ButtonHeight = 20
	Menu:AddLabel("#tool.acfsound.help")

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
end