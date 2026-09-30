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

local Notify = ACF.Utilities.Notify
local _BIT_NUM_SOUNDBANKS = ACF.GetHighestPowerOfTwo(ACF.MaxSoundBanks)
local _BIT_NUM_SOUNDS = ACF.GetHighestPowerOfTwo(ACF.MaxSounds)

-- NOTE(TMF): I would have used concommands just to set clients data, however i didn't feel like using them here since i don't know how to use them lol
-- So instead i went the dumb, hard and convoluted way and network the data needed back and forth
if SERVER then
	util.AddNetworkString("ACF_SoundMenu_Send_ID")   -- Networks data from Server to Client
	util.AddNetworkString("ACF_SoundMenu_Get_Multi") -- Networks Entity data from Server to Client
	util.AddNetworkString("ACF_SoundMenu_Set_Multi") -- Networks Entity data from Client to Server
end

--===============================================================================================--
-- LOCAL FUNCS
--===============================================================================================--
	--- This function acts like a getter/setter where we network an entity soundbank data back and forth between the client and the server 
	--- This allows the client to populate a menu with the data received from the server's entity(engine) or...
	--- Sends any datavars that the client has back to the server to update an entity's soundbank table with the datavars that the client had, if any.
	--- @param Player player The player who clicked on the Entity
	--- @param Data table? The soundbank table to set soundbank Data to the Entity or not
	--- @param Loopback bool? False to just populate a client menu and its datavars or True to GET the datavars from client and send them back 
local function DoSoundBankData(Ply, Data, Loopback)
	if CLIENT then return end

	net.Start("ACF_SoundMenu_Get_Multi")
		if not Loopback then
			net.WriteBool(false)
			-- The Getter: Send the data to populate the client's menu
			local SoundBanks = Data
			local SoundBankCount = #SoundBanks.SoundBanks

			net.WriteUInt(SoundBankCount, _BIT_NUM_SOUNDBANKS)

			for _, Bank in ipairs(SoundBanks.SoundBanks) do
				net.WriteBool(Bank.PlaysAtExhaust or false)
				net.WriteUInt((Bank.OffThrottle or 0.25) * 100, 8) -- Sending the approximate volume as an int to reduce message size
				net.WriteUInt((Bank.OnThrottle or 1) * 100, 8)  -- Same here
				net.WriteUInt(#Bank.Sounds, _BIT_NUM_SOUNDS)

				for _, Sound in ipairs(Bank.Sounds) do
					net.WriteUInt(Sound.RPM, ACF.NetSoundRPMBitLimit)
					net.WriteString(Sound.Path)
					net.WriteUInt(Sound.Pitch, 8)
					net.WriteUInt(Sound.Volume * 100, 8) -- Same here
					net.WriteUInt(Sound.Width or 0, 4)
				end
			end
		else -- The Setter: Otherwise we get from the client's data vars to create and replace the entity's soundbank
			 -- The reading of networked values sent by the client is not handled by this function but by SetSoundData
			net.WriteBool(true)
		end
	net.Send(Ply)
end

-- A function to network an integer to a client to populate their sound replacer menu
local function SetSoundMenu(Ply, ID)
	net.Start("ACF_SoundMenu_Send_ID")
		net.WriteUInt(ID, 4) -- I suppose 4 is enough
	net.Send(Ply)
end

-- A function to get the sound data according to the entity's class
local function GetSoundData(Ply, Trace, Support)
	if CLIENT then return end
	local Entity = Trace.Entity
	local Class = Entity:GetClass()

	if Class == "acf_engine" then
		local SoundTable = Support.GetSoundBanks(Entity)

		-- Send the found soundbank table from the entity to the client for sound menu population
		if SoundTable then
			SetSoundMenu(Ply, 2) -- The ID number must match what the sound replacer menu has for its menu choices
			DoSoundBankData(Ply, SoundTable, false)
		end
	else
		local SoundData = Support.GetSound(Entity)

		Ply:ConCommand("wire_soundemitter_sound " .. SoundData.Sound)

		if SoundData.Pitch then
			Ply:ConCommand("acfsound_pitch " .. SoundData.Pitch)
		end

		if SoundData.Volume then
			Ply:ConCommand("acfsound_volume " .. SoundData.Volume)
		end

		SetSoundMenu(Ply, 1) -- Same here.
	end
end

-- A function to set the sound data of an ACF entity that has support from this tool 
local function SetSoundData(Ply, Entity, Support)
	if not IsValid(Entity) then return end
	if CLIENT then return end

	local Class = Entity:GetClass()
	if not Class then return end

	local MenuMode = Ply:GetInfoNum("acf_soundmenu_mode", 1)

	if Class == "acf_engine" then
		-- This gets called everytime you spawn a entity, and also if you try to set with one sound, which will be wrong for engines, so lets ignore that
		if not Support.GetSoundBanks or not Support.SetSoundBanks or not Support.ResetSoundBanks then return end

		-- Prevent anyone from setting sounds with any other menu. 
		if MenuMode ~= 2 then
			Notify.EntityWarningToPlayer(Entity, Ply, "Wrong Sound Replacer Menu!", "Engines require the 'Engines - Multiple interpolated' menu option.") -- TODO: Localize me!
			return
		end

		-- Simple call just to get the client's sound menu data 
		DoSoundBankData(Ply, _, true)
		do -- Receives any datavars from the client, which matches what's seen regarding any values on the menu, and sets the soundbank
			local SoundTable = {}
			net.Receive("ACF_SoundMenu_Set_Multi", function ()
				local BankCount = net.ReadUInt(_BIT_NUM_SOUNDBANKS)
				local IsValidEntity = IsValid(Entity)

				for I = 1, BankCount do
					local PlayAtExhaust = net.ReadBool()
					local OffThrottle = net.ReadUInt(8) * 0.01 -- Reduce the size down to a float
					local OnThrottle = net.ReadUInt(8) * 0.01 -- Same here
					local SoundCount = net.ReadUInt(_BIT_NUM_SOUNDS)

					-- Prevent an expensive operation if the entity received wasn't valid. We still want to read the remaining data though
					if IsValidEntity then
						table.insert(SoundTable, {
							PlaysAtExhaust = PlayAtExhaust,
							OffThrottle = OffThrottle,
							OnThrottle = OnThrottle,
							Sounds = {}}
						)
					end

					for _ = 1, SoundCount do
						local RPM = net.ReadUInt(ACF.NetSoundRPMBitLimit)
						local Path = net.ReadString()
						local Pitch = net.ReadUInt(8)
						local Volume = net.ReadUInt(8) * 0.01 -- Again, same here
						local Width = net.ReadUInt(4)

						-- Same as above
						if IsValidEntity then
							table.insert(SoundTable[I].Sounds, {
								RPM    = RPM,
								Path   = Path,
								Pitch  = Pitch or 100,
								Volume = Volume or 1,
								Width  = Width or 0}
							)
						end
					end
				end
				if not IsValidEntity then return end
				Support.SetSoundBanks(Entity, SoundTable)
				-- Store AFTER the data actually arrives, and store the real SoundTable
				-- and not before this callback has had a chance to populate it.
				duplicator.StoreEntityModifier(Entity, "acf_replacesound", SoundTable)

				Notify.NoticeToPlayer(Ply, "Successfully replaced engine sounds!") -- TODO: Localize me!
			end)
		end
	else
		-- Prevent anyone from setting sounds with any other menu. 
		if MenuMode ~= 1 then
			Notify.EntityWarningToPlayer(Entity, Ply, "Wrong Sound Replacer Menu!", "This Entity requires the 'Generic - One Sound.' menu option.") -- TODO: Localize me!
			return
		end

		local Sound  = Ply:GetInfo("wire_soundemitter_sound")
		local Pitch  = Ply:GetInfoNum("acfsound_pitch", 1)
		local Volume = Ply:GetInfoNum("acfsound_volume", 1)

		Support.SetSound(Entity, {
			Sound  = Sound,
			Pitch  = ACF.CheckNumber(Pitch, 1),
			Volume = ACF.CheckNumber(Volume, 1),
		})

		duplicator.StoreEntityModifier(Entity, "acf_replacesound", { Sound, Pitch or 1, Volume or 1 })

		Notify.NoticeToPlayer(Ply, "Successfully replaced entity sound!") -- TODO: Localize me!
	end
end

-- A function to parse and apply the entity's stored sound data whenever its spawned by the duplicator
local function ApplySoundDuplicatorData(_, Entity, Data)
	if CLIENT then return end
	if not IsValid(Entity) then return end
	if not Data then return end

	local Class = Entity:GetClass()
	if not Class then return end

	local Support = ACF.SoundToolSupport[Class]
	if not Support then return end

	if Class == "acf_engine" then
		if not Support.SetSoundBanks then return end
		if not istable(Data) then return end

		-- Migrate old single sound data into our new soundbank table format
		if isstring(Data[1]) then
			-- These fields might not be populated just yet when the duplicator entity modifiers run, so a fallback is needed.
			-- These only work for single sound engines, so whatever RPM value will just work in the mean time. 
			local Idle    = Entity.IdleRPM or 800
			local Redline = Entity.LimitRPM or 6000
			local Path    = Data[1]

			Data = {{
				Sounds = {{
					RPM    = (Idle + Redline) / 2,
					Path   = Path,
					Pitch  = ACF.CheckNumber(Data[2], 1) * 100,
					Volume = ACF.CheckNumber(Data[3], 1),
				}}
			}}
		end

		-- Validate the stored data, early escape if there's corrupted/invalid sound table format
		for _, Bank in ipairs(Data) do
			if not istable(Bank) or not istable(Bank.Sounds) then return end
		end

		Support.SetSoundBanks(Entity, Data)
	else
		if not Support.SetSound then return end

		Support.SetSound(Entity, {
			Sound  = Data[1],
			Pitch  = ACF.CheckNumber(Data[2], 1),
			Volume = ACF.CheckNumber(Data[3], 1),
		})
	end
end

duplicator.RegisterEntityModifier("acf_replacesound", ApplySoundDuplicatorData)

-- An improved IsValid function, just to check if an entity is ACF class and if it has support from this tool
local function IsReallyValid(trace, ply)
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsPlayer() then return false end
	if SERVER and not trace.Entity:GetPhysicsObject():IsValid() then return false end
	local class = trace.Entity:GetClass()

	if not ACF.SoundToolSupport[class] then
		if SERVER and string.StartWith(class, "acf_") then
			Notify.EntityWarningToPlayer(trace.Entity, ply, "#tool.acfsound.unsupported_class")
		elseif SERVER then
			Notify.EntityWarningToPlayer(trace.Entity, ply, "#tool.acfsound.unsupported_ent")
		end

		return false
	end

	return true
end

-- A function to get the sound tool support of a valid acf entity
local function CheckSupport(Ply, Trace)
	if not IsReallyValid(Trace, Ply) then return false end

	local Class = Trace.Entity:GetClass()
	local Support = ACF.SoundToolSupport[Class]

	if CLIENT then return Support end -- I dunno if this is correct to do
	return Support
end

--===============================================================================================--
-- MAIN TOOL FUNCS
--===============================================================================================--
function TOOL:LeftClick(Trace)
	local Owner = self:GetOwner()

	local Support = CheckSupport(Owner, Trace)
	if not Support then return false end

	SetSoundData(Owner, Trace.Entity, Support)

	return true
end

function TOOL:RightClick(Trace)
	local Owner = self:GetOwner()

	local Support = CheckSupport(Owner, Trace)
	if not Support then return false end

	GetSoundData(Owner, Trace.Entity, Support)

	return true
end

function TOOL:Reload(Trace)
	local Owner = self:GetOwner()

	local Support = CheckSupport(Owner, Trace)
	if not Support then return false end

	local Class = Trace.Entity:GetClass()

	if Class == "acf_engine" then
		if not Trace.Entity.SoundBanks then return true end
		Support.ResetSoundBanks(Trace.Entity)

		Notify.NoticeToPlayer(Owner, "Successfully resetted engine sounds.") -- TODO: Localize me!
	else
		Support.ResetSound(Trace.Entity)

		Notify.NoticeToPlayer(Owner, "Successfully resetted entity sound.") -- TODO: Localize me!
	end

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