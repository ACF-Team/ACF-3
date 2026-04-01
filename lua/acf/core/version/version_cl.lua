local ACF = ACF

net.Receive("ACF_VersionInfo", function()
    ACF.ServerExtensions = util.JSONToTable(net.ReadString())
end)