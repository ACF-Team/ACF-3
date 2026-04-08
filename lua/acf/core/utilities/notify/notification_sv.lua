util.AddNetworkString("ACF_Notify")

do -- Backwards compatibility with the old notification system.
    util.AddNetworkString("ACF_LegacyNotify")
    util.AddNetworkString("ACF_NameAndShame")

    function ACF.Shame(Entity, Message)
        if not ACF.NameAndShame then return end
        local Owner = Entity:CPPIGetOwner()

        if not IsValid(Owner) then return end

        local ShameMsg = Owner:GetName() .. " had " .. tostring(Entity) .. " disabled for " .. Message
        Messages.PrintLog("Error", ShameMsg)

        net.Start("ACF_NameAndShame")
            net.WriteString(ShameMsg)
        net.Broadcast()
    end

    function ACF.SendNotify(Player, Success, Message)
        net.Start("ACF_LegacyNotify")
            net.WriteBool(Success or false)
            net.WriteString(Message or "")
        net.Send(Player)
    end
end