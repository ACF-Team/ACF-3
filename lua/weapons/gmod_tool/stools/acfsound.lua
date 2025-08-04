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

local Sounds = ACF.SoundToolSupport

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
		if SERVER and string.StartWith(class, "acf_") then
			ACF.SendNotify(ply, false, "#tool.acfsound.unsupported_class")
		elseif SERVER then
			ACF.SendNotify(ply, false, "#tool.acfsound.unsupported_ent")
		end

		return false
	end

	return true
end

function TOOL:LeftClick(trace)
	local owner = self:GetOwner()

	if not IsReallyValid(trace, owner) then return false end
	if CLIENT then return true end

	local sound = owner:GetInfo("wire_soundemitter_sound")
	local pitch = owner:GetInfoNum("acfsound_pitch", 1)
	local volume = owner:GetInfoNum("acfsound_volume", 1)

	ReplaceSound(owner, trace.Entity, { sound, pitch, volume })

	return true
end

function TOOL:RightClick(trace)
	local owner = self:GetOwner()

	if not IsReallyValid(trace, owner) then return false end
	if CLIENT then return true end

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
	if not IsReallyValid(trace, self:GetOwner()) then return false end
	if CLIENT then return true end

	local class = trace.Entity:GetClass()
	local support = ACF.SoundToolSupport[class]
	if not support then return false end
	support.ResetSound(trace.Entity)

	return true
end

if CLIENT then
	TOOL.BuildCPanel = ACF.CreateSoundMenu

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