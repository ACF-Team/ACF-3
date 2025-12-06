return function(BaseClass)
    local HideInfo = ACF.HideInfoBubble
    local WireRender = Wire_Render

    function ENT:Initialize(...)
        BaseClass.Initialize(self, ...)

        self:Update()
    end
    function ENT:Update() end

    local ENTITY = FindMetaTable("Entity")
    -- Copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
    function ENT:Draw()
        local HaloTip = not HideInfo()

        local RenderContext = ACF.RenderContext
        local LookedAt = RenderContext.LookAt == self

        if HaloTip and LookedAt then
            if RenderContext.ShouldDrawOutline then
                self:DrawEntityOutline()
            end
            ENTITY.DrawModel(self)
        else
            ENTITY.DrawModel(self)
        end

        WireRender(self)
    end
end