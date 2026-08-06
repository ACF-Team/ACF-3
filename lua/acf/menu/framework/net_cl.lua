local ACF = ACF
ACF.Menu = ACF.Menu or {}

--- Commits a context: sends its class + serialized instance so the server spawns or updates in place.
function ACF.Menu.SendSpawn(ClassName, Data)
	if not ClassName then return end

	net.Start("ACF_MenuCommit")
		net.WriteString("spawn")
		net.WriteString(ClassName)
		net.WriteTable(Data or {})
	net.SendToServer()
end

--- Triggers a page's server-side action function (identified by page id + action index).
function ACF.Menu.SendFunc(PageID, ActionIndex)
	if not PageID or not ActionIndex then return end

	net.Start("ACF_MenuCommit")
		net.WriteString("func")
		net.WriteString(PageID)
		net.WriteUInt(ActionIndex, 8)
	net.SendToServer()
end

--- Fires a link interaction; the server reads the player's aim + modifiers to select/link/unlink.
function ACF.Menu.SendLink()
	net.Start("ACF_MenuCommit")
		net.WriteString("link")
	net.SendToServer()
end

-- How many entities the player currently has selected for linking (0 = not in linking mode). Kept in
-- sync by the server; drives which instruction set the tool HUD shows.
ACF.Menu.LinkSelected = ACF.Menu.LinkSelected or 0

net.Receive("ACF_MenuLinkState", function()
	ACF.Menu.LinkSelected = net.ReadUInt(16)
end)

--- Clears the player's link selection server-side (used when leaving the linking context: holstering
--- the tool or switching menu pages), mirroring the old linker's exit behavior. No-op if nothing is
--- selected. Optimistically clears the local count so the HUD reverts immediately.
function ACF.Menu.SendLinkClear()
	if (ACF.Menu.LinkSelected or 0) == 0 then return end

	ACF.Menu.LinkSelected = 0

	net.Start("ACF_MenuLinkClear")
	net.SendToServer()
end

-- Server -> client entity config push, used to hydrate a page's context from an existing entity
-- (the future "copy" feature). Scaffolded now; the request UX is a follow-up.
net.Receive("ACF_MenuCopy", function()
	local ClassName = net.ReadString()
	local Data      = net.ReadTable()

	hook.Run("ACF_OnMenuCopy", ClassName, Data)
end)
