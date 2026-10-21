-- Serverside overlay output of the diagnostics an entity currently has
local ACF         = ACF
local Diagnostics = ACF.Diagnostics

--- Adds an entity's active diagnostics of one type to its overlay, in registration order.
--- @param State table The overlay state being built
--- @param Type string "Warning" or "Error"
--- @param Active table|nil Id to entry for the active diagnostics
--- @param Field string|nil Key holding the data inside an entry, the entry itself when nil
function Diagnostics.AddOverlayLines(State, Type, Active, Field)
	if not Active or not next(Active) then return end

	local Method = Diagnostics.GetOverlayMethod(Type)

	for _, Id in ipairs(Diagnostics.GetIds(Type)) do
		local Entry = Active[Id]

		if Entry then
			local Title, Detail = Diagnostics.Describe(Id, Field and Entry[Field] or Entry)

			State[Method](State, Detail ~= "" and Detail or Title, Id)
		end
	end
end
