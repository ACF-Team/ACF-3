local EntTable = {
    Entity2Table = {}
}

ACF.EntityIndexing = EntTable
local ent2tbl = EntTable.Entity2Table

function EntTable.Get(ent, key)
    local tbl = ent2tbl[ent]

    if not tbl then
        tbl = ent:GetTable()
        ent2tbl[ent] = tbl
    end

    return tbl[key]
end

function EntTable.Set(ent, key, value)
    local tbl = ent2tbl[ent]

    if not tbl then
        tbl = ent:GetTable()
        ent2tbl[ent] = tbl
    end

    tbl[key] = value
end

hook.Add("EntityRemoved", "ACF.EntityTable.EntityRemoved", function(ent)
    ent2tbl[ent] = nil
end)

--[[
    local ent = Entity(90)

    local st = SysTime
    local startTime, endTime
    print("")
    print("Profiling Results:")
    print("")
    
    local get, set = EntTable.Get, EntTable.Set
    
    startTime = st()
    for _ = 1, 100000 do
        ent.Test = 5
        -- set(ent, "Test", 5)
    end
    endTime = st()
    print("Variables.Set: " .. ((endTime - startTime) * 1000) .. " ms")
    
    startTime = st()
    for _ = 1, 100000 do
        local t = ent.Test
        -- get(ent, "Test")
    end
    endTime = st()
    print("Variables.Get: " .. ((endTime - startTime) * 1000) .. " ms")
]]