-- Rebindable AIO controller actions, Default is a BUTTON_CODE combo held in full. Ammo keys are never rebindable.
ACF.ControllerBinds = {
	{ ID = "MoveForward",      Label = "Move Forward",    Default = { KEY_W } },
	{ ID = "MoveBack",         Label = "Move Back",       Default = { KEY_S } },
	{ ID = "TurnLeft",         Label = "Turn Left",       Default = { KEY_A } },
	{ ID = "TurnRight",        Label = "Turn Right",      Default = { KEY_D } },
	{ ID = "Brake",            Label = "Brake",           Default = { KEY_SPACE } },
	{ ID = "Fire1",            Label = "Fire Primary",    Default = { MOUSE_LEFT } },
	{ ID = "Fire2",            Label = "Fire Secondary",  Default = { MOUSE_RIGHT } },
	{ ID = "Fire3",            Label = "Fire Tertiary",   Default = { KEY_LALT } },
	{ ID = "FireSmoke",        Label = "Fire Smoke",      Default = { KEY_LSHIFT } },
	{ ID = "ToggleTurretLock", Label = "Toggle Turret Lock", Default = { KEY_R } },
	{ ID = "CameraCycle",      Label = "Cycle Camera",    Default = { KEY_LCONTROL }, Clientside = true },
	{ ID = "RadarLock",        Label = "Lock Radar Target", Default = { KEY_F }, Clientside = true },
	{ ID = "Lase",             Label = "Lase Ballistic Computer", Default = { MOUSE_MIDDLE } },
	-- A strict superset of Lase's combo, so it takes precedence over Lase while both are held
	{ ID = "LaseReset",        Label = "Reset Ballistic Computer Lase", Default = { MOUSE_MIDDLE, KEY_LCONTROL } },
}

-- Bits used to network an action as its index into ACF.ControllerBinds instead of its ID string
ACF.CONTROLLER_BIND_INDEX_BITS = 5
assert(#ACF.ControllerBinds <= 2 ^ ACF.CONTROLLER_BIND_INDEX_BITS - 1, "ACF.ControllerBinds has outgrown its networked index bit width")

for Index, Bind in ipairs(ACF.ControllerBinds) do
	Bind.Index = Index
end

if SERVER then
	local RecacheActionState = ENT.RecacheActionState
	local Handlers = {} -- ActionID -> Handler(Entity, SelfTbl), registered by the module owning the action

	--- Registers a handler run on an action's down edge, held actions use ENT.GetBindState instead.
	function ENT.AddBindHandler(ActionID, Handler)
		Handlers[ActionID] = Handler
	end

	-- Rebound keyboard actions from the driver's client, sent only when a combo's state actually changes
	net.Receive("ACF_Controller_Action", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local Index = net.ReadUInt(ACF.CONTROLLER_BIND_INDEX_BITS)
		local Down = net.ReadBool()

		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end

		local Bind = ACF.ControllerBinds[Index]
		if not Bind then return end

		local SelfTbl = Entity:GetTable()
		if not RecacheActionState(SelfTbl, Bind.ID, Down) then return end
		if not Down then return end

		local Handler = Handlers[Bind.ID]
		if Handler then Handler(Entity, SelfTbl) end
	end)
end

if CLIENT then
	-- Overrides sit with the defaults since the controller reads them at runtime, the menu only edits them.
	local Folder   = "acf/controller"
	local BindFile = "keybinds.json"
	local Saved -- lazy-loaded: { [ActionID] = {codes} }

	local function Load()
		if not Saved then Saved = ACF.LoadFromFile(Folder, BindFile) or {} end
		return Saved
	end

	--- Returns the saved ActionID -> {codes} overrides, an action missing from it uses its Default.
	function ACF.GetSavedControllerBinds()
		return Load()
	end

	--- Saves (or, with a nil Codes, clears) one action's combo. Written immediately, rebinding is rare.
	function ACF.SaveControllerBind(ActionID, Codes)
		local Store = Load()
		Store[ActionID] = Codes
		ACF.SaveToJSON(Folder, BindFile, Store, true)
	end

	-- True if every code in Small is also present in Big
	local function IsSubset(Small, Big)
		for _, Code in ipairs(Small) do
			local Found = false
			for _, OtherCode in ipairs(Big) do
				if Code == OtherCode then Found = true break end
			end
			if not Found then return false end
		end
		return true
	end

	-- Tracks the driver's rebound keys from button events, resolving largest combo first so a superset suppresses its subsets.
	return function(State)
		local Entries = {}  -- One per bind with its combo and state, largest combo first
		local Affected = {} -- BUTTON_CODE -> the only entries a change of it can affect, in Entries order
		local Held = {}     -- BUTTON_CODE -> true while down, tracked from button events

		local function ReloadBinds()
			local Overrides = ACF.GetSavedControllerBinds() -- Via the global, this file is included more than once

			Entries, Affected = {}, {}
			for _, Bind in ipairs(ACF.ControllerBinds) do
				Entries[#Entries + 1] = {Bind = Bind, Codes = Overrides[Bind.ID] or Bind.Default, Supersets = {}, Down = false}
			end
			table.sort(Entries, function(A, B) return #A.Codes > #B.Codes end)

			-- Every combo containing this entry's own suppresses it and makes its codes affect it
			for _, Entry in ipairs(Entries) do
				for _, Other in ipairs(Entries) do
					if IsSubset(Entry.Codes, Other.Codes) then
						-- Strictly bigger only, two binds on the same combo must not suppress each other
						if #Other.Codes > #Entry.Codes then Entry.Supersets[#Entry.Supersets + 1] = Other end

						for _, Code in ipairs(Other.Codes) do
							local List = Affected[Code] or {}
							Affected[Code] = List

							if List[#List] ~= Entry then List[#List + 1] = Entry end
						end
					end
				end
			end
		end
		ReloadBinds()
		ACF.ReloadControllerBinds = ReloadBinds

		local function IsComboDown(Codes)
			for _, Code in ipairs(Codes) do
				if not Held[Code] then return false end
			end
			return true
		end

		local function Resolve(List)
			for _, Entry in ipairs(List) do
				local Down = IsComboDown(Entry.Codes)

				for _, Superset in ipairs(Entry.Supersets) do -- A bigger combo that is down wins
					if Superset.Down then Down = false break end
				end

				if Entry.Down ~= Down then
					Entry.Down = Down

					local Bind = Entry.Bind

					if Bind.Clientside then
						hook.Run("ACF_ControllerBindChanged", Bind.ID, Down)
					else
						net.Start("ACF_Controller_Action", true)
						net.WriteUInt(State.MyController:EntIndex(), MAX_EDICT_BITS)
						net.WriteUInt(Bind.Index, ACF.CONTROLLER_BIND_INDEX_BITS)
						net.WriteBool(Down)
						net.SendToServer()
					end
				end
			end
		end

		-- Single entry point for the driver's buttons, local or forwarded, relayed on "ACF_ControllerButton" for other consumers
		local function OnButtonChanged(Code, Down)
			if not IsValid(State.MyController) then return end
			if (Held[Code] or false) == Down then return end -- Only act on real transitions, never a repeat

			Held[Code] = Down or nil

			hook.Run("ACF_ControllerButton", Code, Down)

			local List = Affected[Code]
			if List then Resolve(List) end
		end

		hook.Add("PlayerButtonDown", "ACFControllerBindDown", function(Ply, Code)
			if Ply ~= LocalPlayer() then return end
			OnButtonChanged(Code, true)
		end)

		hook.Add("PlayerButtonUp", "ACFControllerBindUp", function(Ply, Code)
			if Ply ~= LocalPlayer() then return end
			OnButtonChanged(Code, false)
		end)

		-- Singleplayer fallback, PlayerButtonDown/Up don't fire client side there
		net.Receive("ACF_Controller_Button", function()
			OnButtonChanged(net.ReadUInt(8), net.ReadBool())
		end)

		-- Reseed on sitting down, for keys already held and because the server clears its action states then
		return function()
			Held = {}

			for _, Entry in ipairs(Entries) do
				Entry.Down = false

				for _, Code in ipairs(Entry.Codes) do
					if input.IsButtonDown(Code) then Held[Code] = true end
				end
			end

			Resolve(Entries)
		end
	end
end
