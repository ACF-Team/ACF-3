local Classes = ACF.Classes
Classes.DefineClass("ACF.Racks.BaseRack", function()
    CLASS.EntType = "Rack"
    function CLASS.__inherited(NewClass)
        if not NewClass.LimitConVar then
            NewClass.LimitConVar = {
                Name   = "_acf_rack",
                Amount = 12,
                Text   = "Maximum amount of ACF Racks a player can create."
            }
        end

        if not NewClass.BreechConfigs then
            NewClass.BreechConfigs = {
                Locations = {
                    {Name = "Rear", LPos = Vector(-1, 0, 0), LAng = Angle(0, 0, 0), Direction = 1},
                    {Name = "Front", LPos = Vector(1, 0, 0), LAng = Angle(180, 0, 0), Direction = -1},
                }
            }
        end

        if NewClass.MountPoints then
            NewClass.MagSize = table.Count(NewClass.MountPoints)
        end

        Classes.AddSboxLimit(NewClass.LimitConVar)
    end

    return Class
end)