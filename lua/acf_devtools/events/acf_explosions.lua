local ACF_DevTools = ACF_DevTools
local EventViewer = ACF_DevTools.EventViewer

do
    local CreateExplosion = EventViewer.DefineEvent("Damage.createExplosion")
    CreateExplosion.Icon = "icon16/bomb.png"
    function CreateExplosion.BuildNode(Node, Position, Power, Radius, Found)
        EventViewer.AddKeyValueNode(Node, "Position", Position, "icon16/map_magnify.png")
        EventViewer.AddKeyValueNode(Node, "Power", Power, "icon16/arrow_up.png")
        EventViewer.AddKeyValueNode(Node, "Radius", Radius, "icon16/cd.png")
        EventViewer.AddTableNode(Node, "Found Entities", Found, "icon16/table.png")
    end

    function CreateExplosion.Render3D(Position, _, Radius, Found)
        render.SetColorMaterial()
        local C = EventViewer.CurrentRenderingColor():Copy()
        C.a = 100
        render.DrawSphere(Position, Radius, 16, 8, C)
        if EventViewer.IsPrimaryFocusData() then
            for _, Entity in ipairs(Found) do
                if IsValid(Entity) then
                    render.DrawLine(Position, Entity:GetPos(), EventViewer.CurrentRenderingColor(), false)
                end
            end
        end
    end
end

do
    local CreateExplosion_Init = EventViewer.DefineEvent("Damage.createExplosion Init")
    CreateExplosion_Init.Icon = "icon16/bomb.png"
    function CreateExplosion_Init.BuildNode(Node, FillerMass, FragMass, _, MaxSphere, Fragments)
        EventViewer.AddKeyValueNode(Node, "Filler Mass", FillerMass, "icon16/bricks.png")
        EventViewer.AddKeyValueNode(Node, "Fragment Mass", FragMass, "icon16/bricks.png")
        EventViewer.AddKeyValueNode(Node, "Max. Sphere", MaxSphere, "icon16/cd.png")
        EventViewer.AddKeyValueNode(Node, "Fragments", Fragments, "icon16/bullet_black.png")
    end
end