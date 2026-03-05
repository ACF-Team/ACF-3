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

-- NOTE: I would have used concommands just to set clients data, however i didn't feel like using them here since i don't know how to use them lol
-- So instead i went the dumb, hard and convoluted way and network the data needed back and forth
if SERVER then
	util.AddNetworkString("ACF_SoundMenu_Get_Multi") -- Server to Client
	util.AddNetworkString("ACF_SoundMenu_Set_Multi") -- Client to Server
end

local Sounds = ACF.SoundToolSupport

local function DoSoundBankData(Player, Entity, Data, Loopback)
	net.Start("ACF_SoundMenu_Get_Multi")
		net.WriteEntity(Entity)
	if not Loopback then -- Send the sound table to populate the client's sound replacer menu
		local soundTable = Data
		local count = #soundTable

		net.WriteBool(false) -- Just in case
		net.WriteUInt(count, 4)

		for _, v in ipairs(soundTable) do
			local rpm = v.RPM
			local stringPath = v.Path
			local pitch = v.Pitch
			local volume = v.Volume
			local width = v.Width

			net.WriteUInt(rpm, 14)
			net.WriteString(stringPath)
			net.WriteUInt(pitch, 8)

			volume = volume * 100 -- Sending the approximate volume as an int to reduce message size
			net.WriteUInt(volume, 8)
			net.WriteUInt(width, 4)
		end
	else -- Otherwise we get from the client's data vars to create and replace the entity's soundbank
		net.WriteBool(true)
	end
	net.Send(Player)
end

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

-- Just like the above function, except for soundbanks
local function ReplaceSounds(_, Entity, Data)
	if not IsValid(Entity) then return end

	local Support = Sounds[Entity:GetClass()]
	if not Support then return end

	Support.SetSoundBank(Entity, Data)

	duplicator.StoreEntityModifier(Entity, "acf_replacesoundbank", Data)
end

duplicator.RegisterEntityModifier("acf_replacesoundbank", ReplaceSounds)

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

	-- Simple call just to get the client's sound menu data 
	DoSoundBankData(owner, trace.Entity, _, true)
	do -- Sound Table from client reception, this is the same as the one displayed on the client's menu
		net.Receive("ACF_SoundMenu_Set_Multi", function (_, ply)
			--print("Received " .. len .. " bits for call: \"ACF_SoundMenu_Set_Multi\" from player " .. ply:Nick()) -- Debug print

			local SoundTable = {}
			local Origin = net.ReadEntity()
			local Count = net.ReadUInt(4)

			if not Origin then return end
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
											Width  = Width or 0})
			end
			ReplaceSounds(ply, Origin, SoundTable)
		end)
	end

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

	-- Soundbank stuff, if it gets found, we switch to that instead
	if not trace.Entity.SoundBank then return true end
	local soundTable = support.GetSoundBank(trace.Entity).SoundBank

	-- Send the found soundbank table from the entity to the client for sound menu population
	if soundTable then
		DoSoundBankData(owner, trace.Entity, soundTable, false)
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

	-- If it has a soundbank set, we also reset that
	if not trace.Entity.SoundBank then return true end
	support.ResetSoundBank(trace.Entity)

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