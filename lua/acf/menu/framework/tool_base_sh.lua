local ACF = ACF
ACF.Menu = ACF.Menu or {}

-- Resolves the modifier-qualified bind for a base mouse button from the local player's held keys.
local function ResolveBind(Button)
	local Player = LocalPlayer()
	if not IsValid(Player) then return Button end

	local Shift  = Player:KeyDown(IN_SPEED)
	local Reload = Player:KeyDown(IN_RELOAD)

	if Button == "left" then
		if Shift then return "shift+left" end
	elseif Button == "right" then
		if Reload then return "r+right" end
		if Shift then return "shift+right" end
	end

	return Button
end

local function FindAction(Page, Bind)
	for _, Action in ipairs(Page.Actions or {}) do
		if Action.Bind == Bind then return Action end
	end
end

-- Single player hack!!!
if game.SinglePlayer() then
	if SERVER then
		util.AddNetworkString("ACF_Menu_SPAction")
		function ACF.Menu.SendSPAction(Button)
			net.Start("ACF_Menu_SPAction")
			net.WriteString(Button)
			net.Broadcast()
		end
	else
		net.Receive("ACF_Menu_SPAction", function()
			ACF.Menu.DoClientAction(net.ReadString())
		end)
	end
else
	function ACF.Menu.SendSPAction() error("ACF.Menu.SendSPAction called in non-singleplayer game") end
end

--- Client side of an action press: resolves the action from button + modifiers and commits it.
function ACF.Menu.DoClientAction(Button)
	local Page = ACF.Menu.ActivePage
	if not Page then return end

	-- Prefer the exact modifier bind, else fall back to the plain button.
	local Action = FindAction(Page, ResolveBind(Button)) or FindAction(Page, Button)
	if not Action then return end

	if Action.Context then
		local Ctx = Page._Contexts and Page._Contexts[Action.Context]
		if Ctx then ACF.Menu.SendSpawn(Ctx.ClassName, Ctx:Serialize()) end
	elseif Action.Func then
		ACF.Menu.SendFunc(Page.ID, Action._Index)
	elseif Action.Commit == "link" then
		ACF.Menu.SendLink()
	end
end

--- True if the active page shows a toolgun ghost (has a spawn action flagged Preview).
function ACF.Menu.PageHasPreview(Page)
	for _, Action in ipairs(Page and Page.Actions or {}) do
		if Action.Preview and Action.Context then return true end
	end

	return false
end

--- Returns the primary/secondary spawn class names for the active page's ghost (secondary "N/A" if
--- none), letting the ghost renderer decide update-in-place highlighting without ClientData.
function ACF.Menu.GetGhostClasses()
	local Page = ACF.Menu.ActivePage
	if not Page or not Page._Contexts then return nil, "N/A" end

	local Primary, Secondary

	for _, Action in ipairs(Page.Actions or {}) do
		if Action.Preview and Action.Context then
			local Ctx = Page._Contexts[Action.Context]

			if Ctx then
				if Action.Bind and Action.Bind:find("shift") then
					Secondary = Ctx.ClassName
				else
					Primary = Ctx.ClassName
				end
			end
		end
	end

	return Primary, Secondary or "N/A"
end

function ACF.Menu.SetupTool(Tool)
	function Tool:LeftClick()
		if game.SinglePlayer() then
			-- not predicted, this is an annoying hack
			ACF.Menu.SendSPAction("left")
			return true
		end

		if CLIENT and IsFirstTimePredicted() then
			local Page = ACF.Menu.ActivePage
			if Page and Page.Actions then ACF.Menu.DoClientAction("left") end
		end

		return true
	end

	function Tool:RightClick()
		if game.SinglePlayer() then
			-- not predicted, this is an annoying hack
			ACF.Menu.SendSPAction("right")
			return true
		end

		if CLIENT and IsFirstTimePredicted() then
			local Page = ACF.Menu.ActivePage
			if Page and Page.Actions then ACF.Menu.DoClientAction("right") end
		end

		return true
	end

	if not CLIENT then return end

	local Category = GetConVar("acf_tool_category")
	Tool.Category  = (Category and Category:GetBool()) and "ACF" or "Construction"

	-- Releases the framework's ghost (shared Tool.GhostEntity). Called on page switch / holster / when
	-- the active page stops previewing, so we never leave a stray ghost.
	function Tool:ReleaseMenuGhost()
		if self._MenuGhostActive then
			ACF.ReleaseGhostEntity(self)
			self._MenuGhostActive = false
		end
	end

	function Tool:Think()
		local Page = ACF.Menu.ActivePage

		if Page and ACF.Menu.PageHasPreview(Page) then
			if not IsValid(self.GhostEntity) then ACF.CreateGhostEntity(self) end

			ACF.RenderGhostEntity(self)
			ACF.RunHoldOverlay(self)
			self._MenuGhostActive = true
		else
			self:ReleaseMenuGhost()
		end
	end

	function Tool:Holster()
		self:ReleaseMenuGhost()
		ACF.Menu.SendLinkClear() -- drop any link selection when putting the tool away (old UX)
	end
end
