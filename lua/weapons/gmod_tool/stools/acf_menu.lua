--[[
    PURPOSE: Lua loading order will load autorun/ before weapons/gmod_tool/stools.
    Updating a stool is really, really slow, since I think it triggers a full refresh of every stool for some reason.
    So the idea is that the stool is defined in the lua/acf/tool folder. The function call allows us to load ourselves
    at the appropriate time, and allows the tool definition files to hotload themselves.
]]

ACF.MenuImpl_Hotload(TOOL)