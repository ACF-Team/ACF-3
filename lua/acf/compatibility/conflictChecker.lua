
-- Older versions of ACF will conflict due to the new file loading system we implemented.
-- If the server has an older version installed simultaneously, we'll let the players know.

if ACF.Version then
    if SERVER then
        util.AddNetworkString("ACF_VersionConflict")

        hook.Add("PlayerSpawn", "ACF Version Conflict", function(Player)
            net.Start("ACF_VersionConflict")
            net.Send(Player)
        end)
    elseif CLIENT then
        net.Receive("ACF_VersionConflict", function()
            hook.Add("CreateMove", "ACF Version Conflict", function(Move)
                if Move:GetButtons() ~= 0 then
                    ACF.PrintToChat("Warning", "An unsupported or multiple versions of ACF detected. Check server's ACF installation.")

                    hook.Remove("CreateMove", "ACF Version Conflict")
                end
            end)
        end)
    end
end
