local hook   = hook
local WireIO = ACF.Utilities.WireIO

--- Creates or updates Wire inputs on a given entity.
-- @param Entity The entity to create or update Wire inputs on.
-- @param List A numerically indexed list of inputs.
-- @param Data A key-value table with entity information, either ToolData or dupe data.
-- @param ... A list of entries that could further add inputs without having to use the hook, usually definition groups or items.
function WireIO.SetupInputs(Entity, List, Data, ...)
	local Objects = { ... }
	local Inputs  = {}

	for K, V in ipairs(List) do
		Inputs[K] = V
	end

	for _, V in ipairs(Objects) do
		if not V.SetupInputs then continue end

		V.SetupInputs(Entity, Inputs, Data, ...)
	end

	hook.Run("ACF_OnSetupInputs", Entity, Inputs, Data, ...)

	if Entity.Inputs then
		Entity.Inputs = WireLib.AdjustInputs(Entity, Inputs)
	else
		Entity.Inputs = WireLib.CreateInputs(Entity, Inputs)
	end
end

--- Creates or updates Wire outputs on a given entity.
-- @param Entity The entity to create or update Wire outputs on.
-- @param List A numerically indexed list of outputs.
-- @param Data A key-value table with entity information, either ToolData or dupe data.
-- @param ... A list of entries that could further add outputs without having to use the hook, usually definition groups or items.
function WireIO.SetupOutputs(Entity, List, Data, ...)
	local Objects = { ... }
	local Outputs = {}

	for K, V in ipairs(List) do
		Outputs[K] = V
	end

	for _, V in ipairs(Objects) do
		if not V.SetupOutputs then continue end

		V.SetupOutputs(Entity, Outputs, Data, ...)
	end

	hook.Run("ACF_OnSetupOutputs", Entity, Outputs, Data, ...)

	if Entity.Outputs then
		Entity.Outputs = WireLib.AdjustOutputs(Entity, Outputs)
	else
		Entity.Outputs = WireLib.CreateOutputs(Entity, Outputs)
	end
end
