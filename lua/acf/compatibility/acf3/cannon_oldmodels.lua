local OldModels = {
    ["models/tankgun/tankgun_100mm.mdl"] = true,
    ["models/tankgun/tankgun_120mm.mdl"] = true,
    ["models/tankgun/tankgun_140mm.mdl"] = true,
    ["models/tankgun/tankgun_170mm.mdl"] = true,
    ["models/tankgun/tankgun_37mm.mdl"] = true,
    ["models/tankgun/tankgun_50mm.mdl"] = true,
    ["models/tankgun/tankgun_75mm.mdl"] = true,
}

-- Bodygroup porting information
-- First table defines the bodygroup from the old model
-- Second table defines the index of of a specific body
-- Third can be either a table, defining the values that need to be applied into the new model
-- or "false", if there's no equivalent in the new model
local PortingData = {
    -- Muzzlebrakes
    [1] = {
        [1] = false,
        [2] = false,
        [3] = { [8] = 5 },
        [4] = { [8] = 1 },
        [5] = false,
        [6] = { [8] = 3 },
        [7] = false,
        [8] = false,
        [9] = { [7] = 4 },
        [10] = { [8] = 2 },
        [11] = { [8] = 4 },
    },
    -- Bore evacuators
    [2] = {
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = { [9] = 1 },
        [5] = { [9] = 2 },
        [6] = { [9] = 3 },
    },
}

-- patch ID from https://github.com/ACF-Team/ACF-3/commit/cadf24dc5a0fa78df21f81600692c1ee7887a390
ACF.Classes.Entities.RegisterCompatPatch("acf_gun", 2021111301, function(Data)
    local Model = Data.Model

    if not (Model and OldModels[Model]) then return end

    local Bodygroups = Data.BodyG
    local Result     = {}

    if Bodygroups then
        for Index, Value in pairs(Bodygroups) do
            local OldData = PortingData[Index]

            if not OldData then continue end

            local NewData = OldData[Value]

            if NewData then
                for NewIndex, NewValue in pairs(NewData) do
                    Result[NewIndex] = NewValue or nil
                end
            end

            Bodygroups[Index] = nil
        end
    end

    -- Applying cosmetic features to make it look like the old model
    Result[1] = 1
    Result[4] = 1
    Result[5] = 2

    Data.BodyG = Result
end)