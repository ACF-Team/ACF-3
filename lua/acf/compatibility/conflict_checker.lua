local Messages = ACF.Utilities.Messages

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
                    Messages.PrintChat("Warning", "An unsupported or multiple versions of ACF detected. Check server's ACF installation.")

                    hook.Remove("CreateMove", "ACF Version Conflict")
                end
            end)
        end)
    end
end

-- Make sure that players also know they need to install CFW if they haven't already

timer.Simple(1, function()
    if not CFW then
        hook.Add("CreateMove", "ACF CFW Requirement", function(Move)
            if Move:GetButtons() ~= 0 then
                local PrintFunc = CLIENT and Messages.PrintChat or Messages.PrintLog
                PrintFunc("Warning", "Contraption Framework is not installed! ACF will not work correctly! Install it at https://steamcommunity.com/sharedfiles/filedetails/?id=3154971187")

                hook.Remove("CreateMove", "ACF CFW Requirement")
            end
        end)
    end
end)