local ACF = ACF
ACF.Menu = ACF.Menu or {}

local GUI_ICONS     = { lmb = "gui/lmb.png", rmb = "gui/rmb.png", key = "gui/key.png" }
local MOUSE_BUTTONS = { lmb = true, rmb = true }

-- Instruction piece types.
local IPTYPE_ICON  = 0
local IPTYPE_INPUT = 1
local IPTYPE_TEXT  = 2

ACF.Menu.IPTYPE_ICON  = IPTYPE_ICON
ACF.Menu.IPTYPE_INPUT = IPTYPE_INPUT
ACF.Menu.IPTYPE_TEXT  = IPTYPE_TEXT

-- Maps an action Bind token to the key/mouse combo shown in its instruction line.
local BIND_COMBO = {
	["left"]         = { "lmb" },
	["right"]        = { "rmb" },
	["reload"]       = { "R" },
	["shift+left"]   = { "SHIFT", "lmb" },
	["shift+right"]  = { "SHIFT", "rmb" },
	["r+right"]      = { "R", "rmb" },
	["shift+reload"] = { "SHIFT", "R" },
}

surface.CreateFont("ACF.ToolMenu.Key", { font = "Tahoma", size = 13, weight = 900 })

local IconCache = {}
local function CacheIcon(Path)
	if not IconCache[Path] then IconCache[Path] = Material(Path) end
	return IconCache[Path]
end

local function Phrase(Text)
	if Text:sub(1, 1) == "#" then Text = Text:sub(2) end
	return language.GetPhrase(Text)
end

--- Draws a list of instruction lines (each a list of pieces) as a HUD panel.
function ACF.Menu.DrawInstructions(Instructions)
	if not Instructions or #Instructions == 0 then return end

	local Gradient = surface.GetTextureID("gui/gradient")
	local Y = 160

	draw.TexturedQuad({ texture = Gradient, x = 0, y = Y, w = ScrW() / 3, h = #Instructions * 26, color = Color(0, 0, 0, 230) })

	for I, Instruction in ipairs(Instructions) do
		local YO = (Y + ((I - 1) * 26)) + 2
		local XO = 64

		for _, Piece in ipairs(Instruction) do
			if Piece.Type == IPTYPE_ICON then
				local Icon = GUI_ICONS[Piece.Icon] or ("icon16/" .. Piece.Icon .. ".png")

				surface.SetMaterial(CacheIcon(Icon))
				surface.SetDrawColor(255, 255, 255)
				surface.DrawTexturedRect(XO, YO, 16, 16)
				XO = XO + 24
			elseif Piece.Type == IPTYPE_INPUT then
				for I2, Key in ipairs(Piece.Combo) do
					if I2 ~= 1 then
						XO = XO + 8
						draw.TextShadow({ text = "+", font = "ACF.ToolMenu.Key", pos = { XO, YO }, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_TOP, color = color_white }, 1, 50)
						XO = XO + 8
					end

					if MOUSE_BUTTONS[Key] then
						surface.SetMaterial(CacheIcon(GUI_ICONS[Key]))
						surface.SetDrawColor(255, 255, 255)
						surface.DrawTexturedRect(XO, YO, 16, 16)
						XO = XO + 16
					else
						surface.SetFont("ACF.ToolMenu.Key")
						local TSX, TSY = surface.GetTextSize(Key)
						TSX = TSX + 12

						surface.SetMaterial(CacheIcon("gui/key.png"))
						surface.SetDrawColor(255, 255, 255)

						if TSX <= 16 then
							surface.DrawTexturedRect(XO, YO, 16, 16)
						else
							-- Stretch the keycap while keeping its edges intact (9-slice on X).
							surface.DrawTexturedRectUV(XO, YO, 8, 16, 0, 0, 0.5, 1)
							surface.DrawTexturedRectUV(XO + 8, YO, TSX - 16, 16, 0.5, 0, 0.5, 1)
							surface.DrawTexturedRectUV(XO + (TSX - 8), YO, 8, 16, 0.5, 0, 1, 1)

							draw.TextShadow({ text = Key, font = "ACF.ToolMenu.Key", pos = { XO + (TSX / 2), YO + (TSY / 2) }, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = Color(45, 45, 45) }, 1, 50)
						end

						XO = XO + TSX
					end
				end

				XO = XO + 8
			elseif Piece.Type == IPTYPE_TEXT then
				local TX = draw.TextShadow({ text = Phrase(Piece.Text), font = "GModToolHelp", pos = { XO, YO }, color = color_white }, 1)
				XO = XO + TX + 8
			end
		end
	end
end

--- Builds instruction lines for a page from its actions (or uses an explicit Instructions override).
function ACF.Menu.BuildInstructions(Page)
	if Page.Instructions then return Page.Instructions end

	local Lines = {}

	for _, Action in ipairs(Page.Actions or {}) do
		if not Action.Desc then continue end

		Lines[#Lines + 1] = {
			{ Type = IPTYPE_INPUT, Combo = BIND_COMBO[Action.Bind] or { Action.Bind } },
			{ Type = IPTYPE_TEXT, Text = Action.Desc },
		}
	end

	-- No actions (e.g. a non-entity page) -> no instruction HUD at all.
	return Lines
end

--- Instruction lines shown while the player has entities selected for linking (linking mode). These
--- replace the page's normal lines so the HUD reflects the select-then-link hand-off.
function ACF.Menu.BuildLinkInstructions(Count)
	local Noun = Count == 1 and "entity" or "entities"

	return {
		{ { Type = IPTYPE_INPUT, Combo = { "rmb" } },          { Type = IPTYPE_TEXT, Text = ("Link the %d selected %s to the entity you're aiming at"):format(Count, Noun) } },
		{ { Type = IPTYPE_INPUT, Combo = { "R", "rmb" } },     { Type = IPTYPE_TEXT, Text = "Unlink entities" } },
		{ { Type = IPTYPE_INPUT, Combo = { "SHIFT", "rmb" } }, { Type = IPTYPE_TEXT, Text = "Select or deselect another entity" } },
		{ { Type = IPTYPE_ICON, Icon = "cancel" },             { Type = IPTYPE_TEXT, Text = "Aim at the world to clear the selection" } },
	}
end

local function PageSupportsLink(Page)
	for _, Action in ipairs(Page and Page.Actions or {}) do
		if Action.Commit == "link" then return true end
	end

	return false
end

--- Returns the instruction lines the tool HUD should draw right now: the link-mode set while a
--- selection is active on a link-capable page, otherwise the active page's built-in lines.
function ACF.Menu.GetHUDInstructions()
	local Page = ACF.Menu.ActivePage
	if not Page then return nil end

	local Count = ACF.Menu.LinkSelected or 0
	if Count > 0 and PageSupportsLink(Page) then
		return ACF.Menu.BuildLinkInstructions(Count)
	end

	return ACF.Menu.ActiveInstructions
end
