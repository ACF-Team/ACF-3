local Interception = {}
ACF.Interception = Interception

Interception.Interceptors   = {}
Interception.Interceptables = {}

local INTERCEPTION_BBOX_TOLERANCE = 0

function Interception.BoundingBox(Radius, Length)
    Radius = Radius
    Length = Length / 2

    local bbox = {
        Ready    = false,
        Origin   = Vector(0, 0, 0),
        Angles   = Angle(0, 0, 0),
        Min      = Vector(-Radius, -Radius, -Radius),
        Max      = Vector(Radius, Radius, Radius),
        Distance = 0,
        Length   = Length,
        Birth    = CurTime()
    }

    function bbox:Update(Data)
        if not Data.LastPos then return end
        if not Data.Pos then return end

        self.Origin = (Data.LastPos + Data.Pos) / 2
        self.Angles = Data.Angles

        local Dist = Data.LastPos:Distance(Data.Pos) / 2
        self.Min[1]   = -Dist + (-self.Length / 2)
        self.Max[1]   = Dist + (self.Length / 2)
        self.Distance = Dist

        self.Ready = true

    end

    function bbox:IntersectTest(other)
        if not self.Ready then return false end
        if not other or not other.Ready then return false end

        local DeltaTime = CurTime() - self.Birth
        local CubeColor = HSVToColor(DeltaTime * 1500, 0.9, 1)
        CubeColor = Color(CubeColor.r, CubeColor.g, CubeColor.b, 120)

        debugoverlay.BoxAngles(self.Origin, self.Min, self.Max, self.Angles, 5,     CubeColor)
        debugoverlay.BoxAngles(other.Origin, other.Min, other.Max, other.Angles, 5, CubeColor)

        return util.IsOBBIntersectingOBB(
            self.Origin,  self.Angles,  self.Min,  self.Max,
            other.Origin, other.Angles, other.Min, other.Max,
            INTERCEPTION_BBOX_TOLERANCE
        )
    end

    return bbox
end

function Interception.RegisterInterceptable(Object, Radius, Length, GetPos, GetAngles, OnIntercepted)
    Interception.Interceptables[Object] = {
        Object               = Object,
        BoundingBox          = Interception.BoundingBox(Radius, Length),
        GetPos               = GetPos,
        GetAngles            = GetAngles,
        InterceptionCallback = OnIntercepted,
        Update               = function(self)
            local res = Interception.StoreNewData(self)
            if res == nil then self:Remove() end

            if res then
                self.BoundingBox:Update(self)
            end
        end,
        Remove               = function(self)
            Interception.Interceptables[self.Object] = nil
        end
    }
end

function Interception.RegisterInterceptor(Object, Radius, Length, GetPos, GetAngles, OnIntercepted)
    Interception.Interceptors[Object] = {
        Object               = Object,
        BoundingBox          = Interception.BoundingBox(Radius, Length),
        GetPos               = GetPos,
        GetAngles            = GetAngles,
        InterceptionCallback = OnIntercepted,
        Update               = function(self)
            local res = Interception.StoreNewData(self)
            if res == nil then self:Remove() end

            if res then
                self.BoundingBox:Update(self)
            end
        end,
        Remove               = function(self)
            Interception.Interceptors[self.Object] = nil
        end
    }
end

function Interception.StoreNewData(Data)
    if not IsValid(Data.Object) then return end
    local now = engine.TickCount()
    if Data.LastTick != now then
        Data.LastTick = now
        Data.LastPos  = Data.Pos
        Data.Pos      = Data.GetPos(Data.Object)
        Data.Angles   = Data.GetAngles(Data.Object)

        return true
    end

    return false
end

hook.Add("Tick", "ACF_Interception_Think", function()
    for InterceptorObject, Interceptor in pairs(Interception.Interceptors) do
        Interceptor:Update()
        for InterceptableObject, Interceptable in pairs(Interception.Interceptables) do
            if InterceptableObject == InterceptorObject then continue end

            Interceptable:Update()
            if Interceptor.BoundingBox:IntersectTest(Interceptable.BoundingBox) then
                local InterceptorCallback = Interceptor.InterceptionCallback
                local InterceptableCallback = Interceptable.InterceptionCallback

                if InterceptorCallback then InterceptorCallback(Interceptor, Interceptable) end
                if InterceptableCallback then InterceptableCallback(Interceptable, Interceptor) end

                Interception.Interceptors[InterceptorObject] = nil
                Interception.Interceptables[InterceptableObject] = nil

                break
            end
        end
    end
end)

local function MISSILE_HIT_INTERCEPTABLE(self, _)
    self.Object:Detonate()
    print("detonated")
end

hook.Add("ACF_OnLaunchMissile", "ACF_Interception_Missiles", function(Missile)
    local Min, Max = Missile:OBBMins(), Missile:OBBMaxs()
    local Radius, Length = math.abs(Max[2] - Min[2]), math.abs(Max[1] - Min[1])

    Interception.RegisterInterceptor(Missile, Radius, Length, Missile.GetPos, Missile.GetAngles, MISSILE_HIT_INTERCEPTABLE)
    Interception.RegisterInterceptable(Missile, Radius, Length, Missile.GetPos, Missile.GetAngles, MISSILE_HIT_INTERCEPTABLE)
end)