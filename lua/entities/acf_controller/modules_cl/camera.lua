return function(State)
    State.CamAng = angle_zero
    State.FOV = 90
    State.Mode = 1
    State.CamOffset = vector_origin
    State.CamOrbit = 0

    -- Camera related
    local WorldCamMins = Vector(-4, -4, -4)
    local WorldCamMaxs = Vector(4, 4, 4)

    --- Unclips the camera from the world
    local worldUnclipTrace = {
        mask = MASK_SOLID_BRUSHONLY,
        mins = WorldCamMins,
        maxs = WorldCamMaxs
    }

    local function WorldUnclip(PreOrbit, PostOrbit)
        worldUnclipTrace.start = PreOrbit
        worldUnclipTrace.endpos = PostOrbit
        local Tr = util.TraceHull(worldUnclipTrace)
        if Tr.Hit then return Tr.HitPos end
        return PostOrbit
    end

    function UpdateCamera(ply)
        State.CamOffset = State.MyController["GetCam" .. State.Mode .. "Offset"]()
        State.CamOrbit = State.MyController["GetCam" .. State.Mode .. "Orbit"]()

        net.Start("ACF_Controller_CamInfo", true)
        net.WriteUInt(State.MyController:EntIndex(), MAX_EDICT_BITS)
        net.WriteUInt(State.Mode, 2)
        net.SendToServer(ply)
    end

    hook.Add("KeyPress", "ACFControllerCamMode", function(ply, key)
        if not IsValid(ply) or ply ~= LocalPlayer() then return end
        if not IsFirstTimePredicted() then return end
        if not IsValid(State.MyController) then return end

        if key == IN_DUCK then
            State.Mode = State.Mode + 1
            if State.Mode > State.MyController:GetCamCount() then State.Mode = 1 end
            UpdateCamera(ply)
        end
    end)

    hook.Add("InputMouseApply", "ACFControllerCamMove", function(_, x, y, _)
        if not IsValid(State.MyController) then return end

        local MinFOV = State.MyController:GetZoomMin()
        local MaxFOV = State.MyController:GetZoomMax()

        local MinSlew = State.MyController:GetSlewMin()
        local MaxSlew = State.MyController:GetSlewMax()

        local ZoomFrac = (State.FOV - MinFOV) / (MaxFOV - MinFOV)
        local Slew = MinSlew + ZoomFrac * (MaxSlew - MinSlew)

        local TrueSlew = Slew * 1 / 60 -- Previously used frametime, to keep average sensitivity the same, use 1/60 for 60 FPS
        State.CamAng = Angle(math.Clamp(State.CamAng.pitch + y * TrueSlew, -90, 90), State.CamAng.yaw - x * TrueSlew, 0)

        net.Start("ACF_Controller_CamData", true)
        net.WriteUInt(State.MyController:EntIndex(), MAX_EDICT_BITS)
        net.WriteAngle(State.CamAng)
        net.SendToServer()
    end)

    local LastFOV = FOV
    hook.Add("PlayerBindPress", "ACFControllerScroll", function(ply, bind, _)
        local delta = bind == "invnext" and 1 or bind == "invprev" and -1 or nil
        if not delta then return end

        if ply ~= LocalPlayer() then return end
        if not IsValid(State.MyController) then return end

        local MinFOV = State.MyController:GetZoomMin()
        local MaxFOV = State.MyController:GetZoomMax()
        local SpeedFOV = State.MyController:GetZoomSpeed()
        State.FOV = math.Clamp(State.FOV + delta * SpeedFOV, MinFOV, MaxFOV)

        if State.FOV ~= LastFOV then
            LastFOV = State.FOV
            net.Start("ACF_Controller_Zoom", true)
            net.WriteUInt(State.MyController:EntIndex(), MAX_EDICT_BITS)
            net.WriteFloat(State.FOV)
            net.SendToServer()
        end

        return true
    end)

    hook.Add("CalcView", "ACFControllerView", function(Player, _, _, _)
        if Player ~= LocalPlayer() then return end
        if not IsValid(State.MyController) then return end
        if State.MyController:GetDisableAIOCam() then return end

        local Pod = Player:GetVehicle()
        if not IsValid(Pod) then return end

        local PreOrbit = State.MyController:LocalToWorld(State.CamOffset)
        local PostOrbit = PreOrbit - State.CamAng:Forward() * State.CamOrbit

        local View = {
            origin = WorldUnclip(PreOrbit, PostOrbit),
            angles = State.CamAng,
            fov = State.FOV,
            drawviewer = true,
        }

        return View
    end)

    return UpdateCamera
end