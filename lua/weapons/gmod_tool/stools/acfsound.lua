local cat = ((ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction")
TOOL.Category = cat
TOOL.Name = "#tool.acfsound.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ClientConVar["pitch"]  = "1"
TOOL.ClientConVar["volume"] = "1"
TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
	{ name = "info" }
}

ACF.SoundToolSupport = ACF.SoundToolSupport or {}

local Sounds   = ACF.SoundToolSupport

Sounds.acf_gun = {
	GetSound = function(ent)
		return {
			Sound  = ent.SoundPath,
			Pitch  = ent.SoundPitch,
			Volume = ent.SoundVolume
		}
	end,
	SetSound = function(ent, soundData)
		ent.SoundPath   = soundData.Sound
		ent.SoundPitch  = soundData.Pitch
		ent.SoundVolume = soundData.Volume

		ent:SetNWString("Sound", soundData.Sound)
		ent:SetNWFloat("SoundPitch", soundData.Pitch)
		ent:SetNWFloat("SoundVolume", soundData.Volume)
	end,
	ResetSound = function(ent)
		ent.SoundPath   = ent.DefaultSound
		ent.SoundPitch  = 1
		ent.SoundVolume = 1

		ent:SetNWString("Sound", ent.DefaultSound)
		ent:SetNWFloat("SoundPitch", 1)
		ent:SetNWFloat("SoundVolume", 1)
	end
}

Sounds.acf_engine = {
	GetSound = function(ent)
		return {
			Sound  = ent.SoundPath,
			Pitch  = ent.SoundPitch,
			Volume = ent.SoundVolume
		}
	end,
	SetSound = function(ent, soundData)
		local Sound = soundData.Sound:Trim():lower()

		ent.SoundPath   = Sound
		ent.SoundPitch  = soundData.Pitch
		ent.SoundVolume = soundData.Volume

		ent:UpdateSound()
	end,
	ResetSound = function(ent)
		ent.SoundPath   = ent.DefaultSound
		ent.SoundPitch  = 1
		ent.SoundVolume = 1

		ent:UpdateSound()
	end
}

Sounds.acf_gearbox = {
	GetSound = function(ent)
		return { Sound = ent.SoundPath }
	end,
	SetSound = function(ent, soundData)
		ent.SoundPath = soundData.Sound
	end,
	ResetSound = function(ent)
		ent.SoundPath = ent.DefaultSound
	end
}

Sounds.acf_piledriver = {
	GetSound = function(ent)
		return { Sound = ent.SoundPath or "" }
	end,
	SetSound = function(ent, soundData)
		ent.SoundPath = soundData.Sound
	end,
	ResetSound = function(ent)
		ent.SoundPath = nil
	end
}

Sounds.acf_turret_motor = {
	GetSound = function(ent)
		return { Sound = ent.SoundPath or ent.DefaultSound }
	end,
	SetSound = function(ent, soundData)
		ent.SoundPath = soundData.Sound

		if IsValid(ent.Turret) then ent.Turret:UpdateSound() end
	end,
	ResetSound = function(ent)
		ent.SoundPath = ent.DefaultSound

		if IsValid(ent.Turret) then ent.Turret:UpdateSound() end
	end
}

local function ReplaceSound(_, Entity, Data)
	if not IsValid(Entity) then return end

	local Support = Sounds[Entity:GetClass()]
	local Sound, Pitch, Volume = unpack(Data)

	if not Support then return end

	Support.SetSound(Entity, {
		Sound  = Sound,
		Pitch  = ACF.CheckNumber(Pitch, 1),
		Volume = ACF.CheckNumber(Volume, 1),
	})

	duplicator.StoreEntityModifier(Entity, "acf_replacesound", { Sound, Pitch or 1, Volume or 1 })
end

duplicator.RegisterEntityModifier("acf_replacesound", ReplaceSound)

local function IsReallyValid(trace, ply)
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsPlayer() then return false end
	if SERVER and not trace.Entity:GetPhysicsObject():IsValid() then return false end
	local class = trace.Entity:GetClass()

	if not ACF.SoundToolSupport[class] then
		if string.StartWith(class, "acf_") then
			ACF.SendNotify(ply, false, "#tool.acfsound.unsupported_class")
		else
			ACF.SendNotify(ply, false, "#tool.acfsound.unsupported_ent")
		end

		return false
	end

	return true
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end

	local owner = self:GetOwner()

	if not IsReallyValid(trace, owner) then return false end
	local sound = owner:GetInfo("wire_soundemitter_sound")
	local pitch = owner:GetInfoNum("acfsound_pitch", 1)
	local volume = owner:GetInfoNum("acfsound_volume", 1)

	ReplaceSound(owner, trace.Entity, { sound, pitch, volume })

	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end

	local owner = self:GetOwner()

	if not IsReallyValid(trace, owner) then return false end
	local class = trace.Entity:GetClass()
	local support = ACF.SoundToolSupport[class]
	if not support then return false end
	local soundData = support.GetSound(trace.Entity)
	owner:ConCommand("wire_soundemitter_sound " .. soundData.Sound)

	if soundData.Pitch then
		owner:ConCommand("acfsound_pitch " .. soundData.Pitch)
	end

	if soundData.Volume then
		owner:ConCommand("acfsound_volume " .. soundData.Volume)
	end

	return true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not IsReallyValid(trace, self:GetOwner()) then return false end
	local class = trace.Entity:GetClass()
	local support = ACF.SoundToolSupport[class]
	if not support then return false end
	support.ResetSound(trace.Entity)

	return true
end

if CLIENT then

	function TOOL.BuildCPanel(panel)
		local wide = panel:GetWide()

		local Desc = panel:Help("#tool.acfsound.help")
		Desc:SetFont("ACF_Control")

		local SoundNameText = vgui.Create("DTextEntry", ValuePanel)
		SoundNameText:SetText("")
		SoundNameText:SetWide(wide - 20)
		SoundNameText:SetTall(20)
		SoundNameText:SetMultiline(false)
		SoundNameText:SetConVar("wire_soundemitter_sound")
		SoundNameText:SetVisible(true)
		SoundNameText:Dock(LEFT)
		panel:AddItem(SoundNameText)

		local SoundBrowserButton = vgui.Create("DButton")
		SoundBrowserButton:SetText("#tool.acfsound.open_browser")
		SoundBrowserButton:SetFont("ACF_Control")
		SoundBrowserButton:SetWide(wide)
		SoundBrowserButton:SetTall(20)
		SoundBrowserButton:SetVisible(true)
		SoundBrowserButton:SetIcon("icon16/application_view_list.png")
		SoundBrowserButton.DoClick = function()
			RunConsoleCommand("wire_sound_browser_open", SoundNameText:GetValue(), "1")
		end
		panel:AddItem(SoundBrowserButton)

		local SoundPre = vgui.Create("DPanel")
		SoundPre:SetWide(wide)
		SoundPre:SetTall(20)
		SoundPre:SetVisible(true)

		local SoundPrePlay = vgui.Create("DButton", SoundPre)
		SoundPrePlay:SetText("#tool.acfsound.play")
		SoundPrePlay:SetFont("ACF_Control")
		SoundPrePlay:SetVisible(true)
		SoundPrePlay:SetIcon("icon16/sound.png")
		SoundPrePlay.DoClick = function()
			RunConsoleCommand("play", SoundNameText:GetValue())
		end

		local SoundPreStop = vgui.Create("DButton", SoundPre)
		SoundPreStop:SetText("#tool.acfsound.stop")
		SoundPreStop:SetFont("ACF_Control")
		SoundPreStop:SetVisible(true)
		SoundPreStop:SetIcon("icon16/sound_mute.png")
		SoundPreStop.DoClick = function()
			RunConsoleCommand("play", "common/null.wav") -- Playing a silent sound will mute the preview but not the sound emitters.
		end
		panel:AddItem(SoundPre)

		-- Set the Play/Stop button positions here
		SoundPre:InvalidateLayout(true)
		SoundPre.PerformLayout = function()
			local HWide = SoundPre:GetWide() / 2
			local Tall = SoundPre:GetTall()
			SoundPrePlay:SetSize(HWide, Tall)
			SoundPrePlay:Dock(LEFT)
			SoundPreStop:Dock(FILL) -- FILL will cover the remaining space which previous button didnt.
		end

		local CopyButton = vgui.Create("DButton")
		CopyButton:SetText("#tool.acfsound.copy")
		CopyButton:SetFont("ACF_Control")
		CopyButton:SetWide(wide)
		CopyButton:SetTall(20)
		CopyButton:SetIcon("icon16/page_copy.png")
		CopyButton:SetVisible(true)
		CopyButton.DoClick = function()
			SetClipboardText(SoundNameText:GetValue())
		end
		panel:AddItem(CopyButton)

		local ClearButton = vgui.Create("DButton")
		ClearButton:SetText("#tool.acfsound.clear")
		ClearButton:SetFont("ACF_Control")
		ClearButton:SetWide(wide)
		ClearButton:SetTall(20)
		ClearButton:SetIcon("icon16/cancel.png")
		ClearButton:SetVisible(true)
		ClearButton.DoClick = function()
			SoundNameText:SetValue("")
			RunConsoleCommand("wire_soundemitter_sound", "")
		end
		panel:AddItem(ClearButton)

		panel:NumSlider("#tool.acfsound.volume", "acfsound_volume", 0.1, 2, 2)
		panel:NumSlider("#tool.acfsound.pitch", "acfsound_pitch", 0.1, 2, 2)

		local SettingsHelp = panel:ControlHelp("#tool.acfsound.settings_help")
		SettingsHelp:SetFont("ACF_Control")
	end

	--[[
		This is another dirty hack that prevents the sound emitter tool from automatically equipping when a sound is selected in the sound browser.
		However, this hack only applies if the currently equipped tool is the sound replacer and you're trying to switch to the wire sound tool.
		Additionally, if you're using a weapon instead of a tool and you choose a sound while the sound replacer menu is displayed, you will be redirected to it.

		The sound emitter will be equipped normally when switching to any other tool at the time of the change.
	]]

	spawnmenu.ActivateToolLegacy = spawnmenu.ActivateToolLegacy or spawnmenu.ActivateTool

	function spawnmenu.ActivateTool(Tool, MenuBool, ...)
		local CurTool = LocalPlayer():GetTool()

		if CurTool and CurTool.Mode then
			local CurMode = isstring(CurTool.Mode) and CurTool.Mode or ""

			if Tool == "wire_soundemitter" and CurMode == "acfsound" then
				Tool = CurMode
			end
		end

		spawnmenu.ActivateToolLegacy(Tool, MenuBool, ...)
	end
end
