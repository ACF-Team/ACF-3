ACF.MenuImpl = ACF.MenuImpl or {}
local MenuImpl = ACF.MenuImpl

function MenuImpl.BuildCPanel(_)

end

function MenuImpl:DrawHUD()
    self:DrawInformation()
end

function MenuImpl:DrawToolScreen(_, _)

end

function MenuImpl:FreezeMovement()

end

-- Hotload.
if ACF.MenuImpl_Hotload then
    ACF.MenuImpl_Hotload()
end