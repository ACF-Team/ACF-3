-- A namespaced aliasing system.

ACF.Aliases = ACF.Aliases or {
    Store = {}
}
local Aliases = ACF.Aliases

-- Gets an aliased value from a series of namespaces and a final key
-- Example: local Value = Get("Namespace1", "Namespace2", "Key")
function Aliases.Get(...)
    local Args   = select('#', ...)
    if Args <= 0 then return ErrorNoHaltWithStack("Aliases.Get expected one or more values (key...)") end

    local Table  = Aliases.Store

    for I = 1, Args - 1 do
        Table = Table[select(I, ...)]
        if not Table then return end
    end

    return Table[select(Args, ...)]
end

-- Sets an aliased value from a series of namespaces and a final key to a value.
-- Example: Register("Namespace1", "Namespace2", "Key", Value)
function Aliases.Register(...)
    local Args   = select('#', ...)
    if Args <= 1 then return ErrorNoHaltWithStack("Aliases.Set expected two or more values (key..., value)") end

    local Table  = Aliases.Store

    for I = 1, Args - 2 do
        local Key = select(I, ...)
        if not Table[Key] then
            Table[Key] = {}
        end

        Table = Table[Key]
    end

    Table[select(Args - 1, ...)] = select(Args, ...)
end