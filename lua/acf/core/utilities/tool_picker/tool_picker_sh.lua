-- Lets a tool work on one part of an entity, picked from a list with the scroll wheel while looking at it.
-- The first row is the entity itself, clicks on it work as the tool normally does.
local ACF        = ACF
local ToolPicker = ACF.ToolPicker or {}
local Pickers    = ToolPicker.Pickers or {} -- [Tool mode][Entity class] = Picker
local Buttons    = { "LeftClick", "RightClick", "Reload" }

ACF.ToolPicker     = ToolPicker
ToolPicker.Pickers = Pickers
ToolPicker.ConVar  = "acf_toolpicker_row" -- Row picked on the client, 1 is the entity

if CLIENT then
	ToolPicker.RowVar = CreateClientConVar(ToolPicker.ConVar, "1", false, true, "Row of the ACF tool picker the tool works on, 1 is the entity.", 1)
end

--- Adds a picker for a tool on an entity class. Picker fields, all optional:
---   Title: shown above the list, "Apply To" when left out
---   GetRows(Entity): client, every row top first, the entity first. A row is
---     { Text, Icon = material path, Stripe = color, Swatch = color, Note = dim text, Help = text under the list }
---   LeftClick, RightClick, Reload(Tool, Entity, Index, Trace): server, a click on row Index + 1. true shows the tool effect
function ToolPicker.Register(Mode, Class, Picker)
	Pickers[Mode] = Pickers[Mode] or {}
	Pickers[Mode][Class] = Picker
end

function ToolPicker.Get(Mode, Entity)
	if not IsValid(Entity) then return end

	local ForMode = Pickers[Mode]

	return ForMode and ForMode[Entity:GetClass()]
end

--- Whether a click of the tool went to the picker, and what the tool returns then
function ToolPicker.Handle(Tool, Button, Trace)
	local Entity = Trace.Entity
	local Picker = ToolPicker.Get(Tool:GetMode(), Entity)

	if not Picker then return false end

	local Row = math.floor(Tool:GetOwner():GetInfoNum(ToolPicker.ConVar, 1))

	if Row <= 1 then return false end
	if CLIENT then return true, true end -- Handlers are server only

	local Handler = Picker[Button]

	if not Handler then return true, false end

	return true, Handler(Tool, Entity, Row - 1, Trace) == true
end

-- Every toolgun has its own copy of each tool
local function WrapTool(Tool)
	if Tool.ACF_PickerWrapped then return end

	Tool.ACF_PickerWrapped = true

	for _, Button in ipairs(Buttons) do
		local Original = Tool[Button]

		Tool[Button] = function(self, Trace)
			local Handled, Result = ToolPicker.Handle(self, Button, Trace)

			if Handled then return Result end
			if Original then return Original(self, Trace) end

			return false
		end
	end
end

-- Runs before the toolgun's attack, so the tool is wrapped by the time it gets the click
hook.Add("KeyPress", "ACF_ToolPicker", function(Player)
	local Weapon = Player:GetActiveWeapon()

	if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return end

	local Tool = Player:GetTool()

	if Tool and Pickers[Tool:GetMode()] then WrapTool(Tool) end
end)
