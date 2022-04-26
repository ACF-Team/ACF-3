-- Older versions of ACF will conflict due to the new file loading system we implemented.
-- If the server has an older version installed simultaneously, we'll let the players know.
if ACF.Version then
	net.Receive("ACF_VersionConflict", function()
		hook.Add("CreateMove", "ACF Version Conflict", function(Move)
			if Move:GetButtons() ~= 0 then
				ACF.PrintToChat("Warning", "An older version of ACF was detected. Please contact the server owner as it will conflict with ACF-3")

				hook.Remove("CreateMove", "ACF Version Conflict")
			end
		end)
	end)
end
