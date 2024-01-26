local cat = ((ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction")
TOOL.Category = cat
TOOL.Name = "#Tool.acfsound.name"
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

if CLIENT then
	language.Add("Tool.acfsound.name", "ACF Sound Replacer")
	language.Add("Tool.acfsound.desc", "Change sounds of ACF entities")
	language.Add("Tool.acfsound.left", "Apply sound")
	language.Add("Tool.acfsound.right", "Copy sound")
	language.Add("Tool.acfsound.reload", "Set default sound")
	language.Add("Tool.acfsound.0", "Use an empty sound path to disable sound")
end

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
		ent:SetNWString("SoundPitch", soundData.Pitch)
		ent:SetNWString("SoundVolume", soundData.Volume)
	end,
	ResetSound = function(ent)
		ent.SoundPath   = ent.DefaultSound
		ent.SoundPitch  = 1
		ent.SoundVolume = 1

		ent:SetNWString("Sound", ent.DefaultSound)
		ent:SetNWString("SoundPitch", 1)
		ent:SetNWString("SoundVolume", 1)
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

local function ReplaceSound(_, Entity, Data)
	if not IsValid(Entity) then return end

	local Support = Sounds[Entity:GetClass()]
	local Sound, Pitch, Volume = unpack(Data)

	if not Support then return end

	Support.SetSound(Entity, {
		Sound  = Sound,
		Pitch  = Pitch or 1,
		Volume = Volume or 1,
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
			ACF.SendNotify(ply, false, class .. " is not supported by the sound tool!")
		else
			ACF.SendNotify(ply, false, "Only ACF entities are supported by the ACF sound tool!")
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
	local pitch = owner:GetInfo("acfsound_pitch")
	local volume = owner:GetInfo("acfsound_volume")

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

function TOOL.BuildCPanel(panel)
	local wide = panel:GetWide()
	local SoundNameText = vgui.Create("DTextEntry", ValuePanel)
	SoundNameText:SetText("")
	SoundNameText:SetWide(wide)
	SoundNameText:SetTall(20)
	SoundNameText:SetMultiline(false)
	SoundNameText:SetConVar("wire_soundemitter_sound")
	SoundNameText:SetVisible(true)
	panel:AddItem(SoundNameText)
	local SoundBrowserButton = vgui.Create("DButton")
	SoundBrowserButton:SetText("Open Sound Browser")
	SoundBrowserButton:SetWide(wide)
	SoundBrowserButton:SetTall(20)
	SoundBrowserButton:SetVisible(true)

	SoundBrowserButton.DoClick = function()
		RunConsoleCommand("wire_sound_browser_open", SoundNameText:GetValue())
	end

	panel:AddItem(SoundBrowserButton)
	local SoundPre = vgui.Create("DPanel")
	SoundPre:SetWide(wide)
	SoundPre:SetTall(20)
	SoundPre:SetVisible(true)
	local SoundPreWide = SoundPre:GetWide()
	local SoundPrePlay = vgui.Create("DButton", SoundPre)
	SoundPrePlay:SetText("Play")
	SoundPrePlay:SetWide(SoundPreWide / 2)
	SoundPrePlay:SetPos(0, 0)
	SoundPrePlay:SetTall(20)
	SoundPrePlay:SetVisible(true)

	SoundPrePlay.DoClick = function()
		RunConsoleCommand("play", SoundNameText:GetValue())
	end

	local SoundPreStop = vgui.Create("DButton", SoundPre)
	SoundPreStop:SetText("Stop")
	SoundPreStop:SetWide(SoundPreWide / 2)
	SoundPreStop:SetPos(SoundPreWide / 2, 0)
	SoundPreStop:SetTall(20)
	SoundPreStop:SetVisible(true)

	SoundPreStop.DoClick = function()
		RunConsoleCommand("play", "common/NULL.wav") -- Playing a silent sound will mute the preview but not the sound emitters.
	end

	panel:AddItem(SoundPre)
	SoundPre:InvalidateLayout(true)

	SoundPre.PerformLayout = function()
		local SPW = SoundPre:GetWide()
		SoundPrePlay:SetWide(SPW / 2)
		SoundPreStop:SetWide(SPW / 2)
		SoundPreStop:SetPos(SPW / 2, 0)
	end

	panel:AddControl("Slider", {
		Label = "Pitch:",
		Command = "acfsound_pitch",
		Type = "Float",
		Min = "0.1",
		Max = "2"
	}):SetTooltip("Works only for guns and engines.")

	panel:AddControl("Slider", {
		Label = "Volume:",
		Command = "acfsound_volume",
		Type = "Float",
		Min = "0.1",
		Max = "2"
	}):SetTooltip("Works only for guns and engines.")

	--[[
	local SoundPitch = vgui.Create("DNumSlider")
	SoundPitch:SetMin( 0.1 )
	SoundPitch:SetMax( 2 )
	SoundPitch:SetDecimals( 0.1 )
	SoundPitch:SetWide(wide)
	SoundPitch:SetText("Pitch:")
	SoundPitch:SetToolTip("Works only for engines")
	SoundPitch:SetConVar( "acfsound_pitch" )
	SoundPitch:SetValue( 1 )
	panel:AddItem(SoundPitch)
	]]
end
