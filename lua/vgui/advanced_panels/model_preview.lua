return function(PANEL)
    -- TODO: Add more options etc.
    -- TODO: Use DAdjustableModelPanel instead and require user to click to focus, then keys are disabled.
    function PANEL:AddModelPreview(Model)
        local ModelPanel    = self:AddPanel("DModelPanel")

        function ModelPanel:UpdateModel(Model)
            self:SetModel(Model)
            local Entity = self:GetEntity()
            if not IsValid(Entity) then return end

            -- local Min, Max = Entity:GetRenderBounds()
            -- local Size = Max - Min
            -- local Distance = Size:Length() * 1.5
            -- self:SetCamPos(Vector(Distance, Distance, Distance))
            -- self:SetLookAt((Min + Max) * 0.5)
        end

        ModelPanel:SetModel(Model)
        ModelPanel:SetSize(200, 200)
        ModelPanel:SetCamPos(Vector(-100, 0, 0))
        ModelPanel:SetLookAt(Vector(0, 0, 0))

        function ModelPanel:PaintOver( w, h )
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 5)
        end

        return ModelPanel
    end
end