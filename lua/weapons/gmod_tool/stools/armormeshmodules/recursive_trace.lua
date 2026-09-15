-- Takes the shared trace helpers (armor_trace.lua) and the tool's class filter accessor as explicit
-- dependencies, since locals from the main stool file aren't visible across include() boundaries.
return function(ArmorTrace, GetClassFilter)
	local function DoRecursiveArmorTrace(Tool, InitialTrace)
		local Messages                 = ACF.Utilities.Messages
		local Dir                      = ArmorTrace.GetTraceDir(Tool)
		local Layers, TotalKE, TotalCE = ArmorTrace.GetArmorLayers(InitialTrace, Dir, GetClassFilter())

		if #Layers == 0 then
			Messages.PrintChat("Info", "No armor layers found along the trace.")
			return true
		end

		Messages.PrintChat("Normal", "--- Recursive Armor Trace ---")

		for Index, Layer in ipairs(Layers) do
			local Ent    = Layer.Entity
			local EntStr = string.format("%s [%d]", Ent:GetClass(), Ent:EntIndex())

			if Layer.Terminal then
				Messages.PrintChat("Normal", string.format("End: %s", EntStr))
			else
				Messages.PrintChat("Normal", string.format(
					"L%d: %s | %s | %.1f mm KE | %.1f mm CE",
					Index, EntStr, Layer.Material, Layer.EffKE, Layer.EffCE
				))
			end
		end

		Messages.PrintChat("Normal", string.format(
			"Total: %.1f mm effective (KE) | %.1f mm effective (CE)",
			TotalKE, TotalCE
		))

		return true
	end

	return DoRecursiveArmorTrace
end
