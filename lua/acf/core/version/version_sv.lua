local ACF = ACF

do -- Retrieve most recent commit and current server commit and network to all clients
    util.AddNetworkString("ACF_VersionInfo")
    hook.Add("ACF_OnLoadPlayer", "ACF_SendVersionInfo", function(ply)
        net.Start("ACF_VersionInfo")
        net.WriteString(util.TableToJSON(ACF.Extensions or {}))
        net.Send(ply)
    end)
end