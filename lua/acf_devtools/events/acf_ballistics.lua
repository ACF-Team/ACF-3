local ACF_DevTools = ACF_DevTools
local EventViewer = ACF_DevTools.EventViewer

do
    local Ballistics_CreateBullet = EventViewer.DefineEvent("Ballistics.CreateBullet")
    Ballistics_CreateBullet.Icon = "icon16/add.png"

    function Ballistics_CreateBullet.BuildNode(Node, Bullet)
        EventViewer.AddTableNode(Node, nil, Bullet)
    end
    function Ballistics_CreateBullet.Render3D(Bullet)
        render.SetColorMaterial()
        render.DrawSphere(Bullet.Pos, 4, 16, 8, EventViewer.CurrentRenderingColor())
    end
end

local function GenericFlight_BuildNode(Node, Start, End, FlightTr)
    EventViewer.AddKeyValueNode(Node, "Start", Start, "icon16/control_start.png")
    EventViewer.AddKeyValueNode(Node, "End", End, "icon16/control_end.png")
    EventViewer.AddTraceNode(Node, "Flight Trace", FlightTr, "icon16/chart_line.png")
end

local function GenericFlight_Render3D(Start, End)
    render.DrawLine(Start, End, EventViewer.CurrentRenderingColor(), false)
        if EventViewer.IsPrimaryFocusData() then
            -- Exaggerate
            render.DrawWireframeSphere(Start, 8, 4, 2, EventViewer.CurrentRenderingColor(), false)
            render.DrawWireframeSphere(End, 4, 4, 2, EventViewer.CurrentRenderingColor(), false)
        end
end

do
    local Ballistics_DoBulletsFlight = EventViewer.DefineEvent("Ballistics.DoBulletsFlight")
    Ballistics_DoBulletsFlight.Icon = "icon16/chart_curve.png"
    Ballistics_DoBulletsFlight.BuildNode = GenericFlight_BuildNode
    Ballistics_DoBulletsFlight.Render3D = GenericFlight_Render3D
end

do
    local Size = 32
    local ImpactMax = Vector(0.7, Size, Size)
    local ImpactMin = -ImpactMax
    local function DrawImpact(Start, End, FlightTrace)
        GenericFlight_Render3D(Start, End)
        local Dist = EyePos():Distance(End) / 1500
        render.DrawBox(End, FlightTrace.HitNormal:Angle(), ImpactMin * Dist, ImpactMax * Dist, EventViewer.CurrentRenderingColor())
    end

    local Ballistics_OnImpact_Penetrated = EventViewer.DefineEvent("Ballistics.OnImpact.Penetrated")
    Ballistics_OnImpact_Penetrated.Icon = "icon16/collision_on.png"
    Ballistics_OnImpact_Penetrated.BuildNode = GenericFlight_BuildNode
    Ballistics_OnImpact_Penetrated.Render3D = DrawImpact

    local Ballistics_OnImpact_Ricochet = EventViewer.DefineEvent("Ballistics.OnImpact.Ricochet")
    Ballistics_OnImpact_Ricochet.Icon = "icon16/collision_on.png"
    Ballistics_OnImpact_Ricochet.BuildNode = GenericFlight_BuildNode
    Ballistics_OnImpact_Ricochet.Render3D = DrawImpact

    local Ballistics_OnImpact_Unknown = EventViewer.DefineEvent("Ballistics.OnImpact.Unknown")
    Ballistics_OnImpact_Unknown.Icon = "icon16/collision_on.png"
    Ballistics_OnImpact_Unknown.BuildNode = GenericFlight_BuildNode
    Ballistics_OnImpact_Unknown.Render3D = DrawImpact
end
