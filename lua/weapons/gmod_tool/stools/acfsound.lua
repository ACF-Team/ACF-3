local cat = ((ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction")
TOOL.Category = cat
TOOL.Name = "#Tool.acfsound.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ClientConVar["pitch"] = "1"

if CLIENT then
	language.Add("Tool.acfsound.name", "ACF Sound Replacer")
	language.Add("Tool.acfsound.desc", "Change sound of guns/engines.")
	language.Add("Tool.acfsound.0", "Left click to apply sound. Right click to copy sound. Reload to set default sound. Use an empty sound path to disable sound.")
end

ACF.SoundToolSupport = ACF.SoundToolSupport or {}

local Sounds = ACF.SoundToolSupport

Sounds.acf_gun = {
	GetSound = function(ent)
		return {
			Sound = ent.SoundPath
		}
	end,
	SetSound = function(ent, soundData)
		ent.SoundPath = soundData.Sound
		ent:SetNWString("Sound", soundData.Sound)
	end,
	ResetSound = function(ent)
		ent.SoundPath = ent.DefaultSound
		ent:SetNWString("Sound", ent.DefaultSound)
	end
}

Sounds.acf_engine = {
	GetSound = function(ent)
		return {
			Sound = ent.SoundPath,
			Pitch = ent.SoundPitch
		}
	end,
	SetSound = function(ent, soundData)
		ent.SoundPath = soundData.Sound
		ent.SoundPitch = soundData.Pitch
	end,
	ResetSound = function(ent)
		local setSound = Sounds.acf_engine.SetSound

		setSound(ent, { Sound = ent.DefaultSound })
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
	local Sound, Pitch = unpack(Data)

	if not Support then return end

	timer.Simple(1, function()
		Support.SetSound(Entity, {
			Sound = Sound,
			Pitch = Pitch or 1,
		})

		duplicator.StoreEntityModifier(Entity, "acf_replacesound", { Sound, Pitch or 1 })
	end)
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
	if not IsReallyValid(trace, self:GetOwner()) then return false end
	local sound = self:GetOwner():GetInfo("wire_soundemitter_sound")
	local pitch = self:GetOwner():GetInfo("acfsound_pitch")
	ReplaceSound(self:GetOwner(), trace.Entity, {sound, pitch})

	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not IsReallyValid(trace, self:GetOwner()) then return false end
	local class = trace.Entity:GetClass()
	local support = ACF.SoundToolSupport[class]
	if not support then return false end
	local soundData = support.GetSound(trace.Entity)
	self:GetOwner():ConCommand("wire_soundemitter_sound " .. soundData.Sound)

	if soundData.Pitch then
		self:GetOwner():ConCommand("acfsound_pitch " .. soundData.Pitch)
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
		RunConsoleCommand("play", "common/NULL.wav") --Playing a silent sound will mute the preview but not the sound emitters.
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
	}):SetTooltip("Works only for engines.")
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