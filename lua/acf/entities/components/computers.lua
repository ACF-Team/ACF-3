local ACF        = ACF
local Components = ACF.Classes.Components

Components.Register("GD-CPR", {
	Name   = "Guidance Computer",
	Entity = "acf_computer",
	LimitConVar = {
		Name   = "_acf_computer",
		Amount = 6,
		Text   = "Maximum amount of ACF Computers a player can create."
	}
})

-- Input actions
if SERVER then
	ACF.AddInputAction("acf_computer", "Pitch", function(Entity, Value)
		if not Entity.InputPitch then return end

		Value = math.Round(math.Clamp(Value, Entity.MinPitch, Entity.MaxPitch), 2)

		if Entity.InputPitch == Value then return end

		Entity.InputPitch = Value
	end)

	ACF.AddInputAction("acf_computer", "Yaw", function(Entity, Value)
		if not Entity.InputYaw then return end

		Value = math.Round(math.Clamp(Value, Entity.MinYaw, Entity.MaxYaw), 2)

		if Entity.InputYaw == Value then return end

		Entity.InputYaw = Value
	end)

	ACF.AddInputAction("acf_computer", "HitPos", function(Entity, Value)
		if not Entity.InputHitPos then return end

		if Entity.InputHitPos == Value then return end

		Entity.InputHitPos = Value
	end)

	ACF.AddInputAction("acf_computer", "Lase", function(Entity, Value)
		if Entity.Lasing == nil then return end
		if Entity.OnCooldown then return end

		Value = tobool(Value)

		if Entity.Lasing == Value then return end

		Entity.Lasing = Value

		Entity:SetNW2Bool("Lasing", Value)

		WireLib.TriggerOutput(Entity, "Lasing", Value and 1 or 0)
	end)

	ACF.AddInputAction("acf_computer", "Coordinates", function(Entity, Value)
		if not Entity.InputCoords then return end

		Value = istable(Value) and Vector(unpack(Value)) or Value

		if Entity.InputCoords == Value then return end

		Entity.InputCoords = Value

		WireLib.TriggerOutput(Entity, "Transmitting", Value ~= Vector() and 1 or 0)
		WireLib.TriggerOutput(Entity, "Current Coordinates", Value)
	end)
end

do -- Joystick
	local MenuText = "Joystick bounds : +-%s degrees\nJoystick speed : %s degrees/s\nMass : %s kg"

	Components.RegisterItem("CPR-Joystick", "GD-CPR", {
		Name        = "Joystick",
		Description = "A small joystick, used to manually guide anti-tank missiles and munitions.",
		Model       = "models/weapons/w_slam.mdl",
		Mass        = 7,
		MaxAngle    = 25,
		Speed       = 50, -- Degrees per second
		Offset      = Vector(0, -1.5, -0.25),
		Inputs      = { "Pitch (Degrees on the vertical axis)", "Yaw (Degrees in the horizontal axis)" },
		Outputs     = { "Current Pitch (Current degrees on the vertical axis)", "Current Yaw (Current degrees on the horizontal axis)" },
		Stick = {
			Model  = "models/props_c17/trappropeller_lever.mdl",
			Scale  = 0.5,
			Offset = 1.5,
		},
		CreateMenu = function(Data, Menu)
			local Angle = Data.MaxAngle
			local Speed = Data.Speed
			local Mass  = Data.Mass

			Menu:AddLabel(MenuText:format(Angle, Speed, Mass))

			ACF.SetClientData("PrimaryClass", "acf_computer")
		end,
		-- Serverside actions
		OnUpdate = function(Entity, _, _, Computer)
			Entity.IsJoystick = true
			Entity.MoveSpeed  = Computer.Speed
			Entity.MinPitch   = -Computer.MaxAngle
			Entity.MaxPitch   = Computer.MaxAngle
			Entity.MinYaw     = -Computer.MaxAngle
			Entity.MaxYaw     = Computer.MaxAngle
			Entity.Pitch      = 0
			Entity.Yaw        = 0
			Entity.InputPitch = 0
			Entity.InputYaw   = 0
			Entity.Spread     = 0

			Entity:SetNW2Float("Pitch", 0)
			Entity:SetNW2Float("Yaw", 0)

			WireLib.TriggerOutput(Entity, "Current Pitch", 0)
			WireLib.TriggerOutput(Entity, "Current Yaw", 0)
		end,
		OnLast = function(Entity)
			Entity.IsJoystick = nil
			Entity.MoveSpeed  = nil
			Entity.MinPitch   = nil
			Entity.MaxPitch   = nil
			Entity.MinYaw     = nil
			Entity.MaxYaw     = nil
			Entity.Pitch      = nil
			Entity.Yaw        = nil
			Entity.InputPitch = nil
			Entity.InputYaw   = nil
			Entity.Spread     = nil
		end,
		OnOverlayTitle = function(Entity)
			if not Entity.IsJoystick then return end
			if Entity.InputPitch ~= 0 or Entity.InputYaw ~= 0 then
				return "In use"
			end
		end,
		OnOverlayBody = function(Entity, State)
			if not Entity.IsJoystick then return end

			local Pitch, Yaw = Entity.Pitch, Entity.Yaw

			State:AddNumber("Pitch", Entity.Pitch, Pitch >= 1 and Pitch < 2 and " degree" or " degrees")
			State:AddNumber("Yaw", Entity.Yaw, Yaw >= 1 and Yaw < 2 and " degree" or " degrees")
		end,
		OnDamaged = function(Entity)
			Entity.Spread = 1 - math.Round(Entity.ACF.Health / Entity.ACF.MaxHealth, 2)
		end,
		OnEnabled = function(Entity)
			local Inputs = Entity.Inputs
			local Pitch  = Inputs.InputPitch
			local Yaw    = Inputs.InputYaw

			if Pitch and Pitch.Path then
				Entity:TriggerInput("Pitch", Pitch.Value)
			end

			if Yaw and Yaw.Path then
				Entity:TriggerInput("Yaw", Yaw.Value)
			end
		end,
		OnDisabled = function(Entity)
			Entity:TriggerInput("Pitch", 0)
			Entity:TriggerInput("Yaw", 0)
		end,
		OnThink = function(Entity)
			local Speed = Entity.MoveSpeed * engine.TickInterval()

			if Entity.Pitch ~= Entity.InputPitch then
				local Delta = math.Clamp(Entity.InputPitch - Entity.Pitch, -Speed, Speed)

				Entity.Pitch = Entity.Pitch + Delta

				WireLib.TriggerOutput(Entity, "Current Pitch", Entity.Pitch)

				Entity:SetNW2Float("Pitch", Entity.Pitch)

				Entity:UpdateOverlay()
			end

			if Entity.Yaw ~= Entity.InputYaw then
				local Delta = math.Clamp(Entity.InputYaw - Entity.Yaw, -Speed, Speed)

				Entity.Yaw = Entity.Yaw + Delta

				WireLib.TriggerOutput(Entity, "Current Yaw", Entity.Yaw)

				Entity:SetNW2Float("Yaw", Entity.Yaw)

				Entity:UpdateOverlay()
			end
		end,
		-- Clientside actions
		OnUpdateCL = function(Entity, _, Computer)
			Entity.IsJoystick  = true
			Entity.MoveSpeed   = Computer.Speed
			Entity.Pitch       = 0
			Entity.Yaw         = 0
			Entity.InputPitch  = 0
			Entity.InputYaw    = 0
			Entity.BaseOffset  = Computer.Offset
			Entity.StickModel  = Computer.Stick.Model
			Entity.StickScale  = Computer.Stick.Scale
			Entity.StickOffset = Computer.Stick.Offset
		end,
		OnLastCL = function(Entity)
			Entity.IsJoystick  = nil
			Entity.MoveSpeed   = nil
			Entity.Pitch       = nil
			Entity.Yaw         = nil
			Entity.InputPitch  = nil
			Entity.InputYaw    = nil
			Entity.BaseOffset  = nil
			Entity.StickModel  = nil
			Entity.StickScale  = nil
			Entity.StickOffset = nil

			if IsValid(Entity.Stick) then
				Entity.Stick:Remove()
				Entity.Stick = nil
			end
		end,
		OnThinkCL = function(Entity)
			local Speed = Entity.MoveSpeed * engine.TickInterval()

			Entity.InputPitch = Entity:GetNW2Float("Pitch")
			Entity.InputYaw   = Entity:GetNW2Float("Yaw")

			if Entity.Pitch ~= Entity.InputPitch then
				local Delta = math.Clamp(Entity.InputPitch - Entity.Pitch, -Speed, Speed)

				Entity.Pitch = Entity.Pitch + Delta
			end

			if Entity.Yaw ~= Entity.InputYaw then
				local Delta = math.Clamp(Entity.InputYaw - Entity.Yaw, -Speed, Speed)

				Entity.Yaw = Entity.Yaw + Delta
			end
		end,
		OnDrawCL = function(Entity)
			if not IsValid(Entity.Stick) then
				Entity.Stick = ClientsideModel(Entity.StickModel, Entity.RenderGroup)
				Entity.Stick:SetModelScale(Entity.StickScale)
				Entity.Stick:SetParent(Entity)
			end

			local Offset = Angle(-Entity.Pitch, 0, Entity.Yaw):Up() * Entity.StickOffset
			local Ang    = Entity:LocalToWorldAngles(Angle(-Entity.Yaw, 90, 90 - Entity.Pitch))
			local Pos    = Entity:LocalToWorld(Entity.BaseOffset + Offset)

			render.Model({
				model = Entity.StickModel,
				pos   = Pos,
				angle = Ang,
			}, Entity.Stick)
		end,
	})
end

do -- Optical guidance computer
	local MenuText  = "Pitch bounds : +-%s degrees\nYaw bounds : +-%s degrees\nAim speed : %s degrees/s\nFocus speed : %s m/s\nMass : %s kg"
	local TraceData = { start = true, endpos = true, filter = true }
	local Computers = {}

	local function GetTraceEndPos(Entity, Distance)
		return Entity:LocalToWorld(Entity.Offset + Entity.Direction * Distance)
	end

	-- Floors the value to intervals of 10 meters
	local function FloorMeters(Value)
		return math.floor(Value * (ACF.InchToMeter / 10)) * (ACF.MeterToInch * 10)
	end

	hook.Add("ACF_OnLaunchMissile", "ACF Optical Computer Filter", function(Missile)
		for Computer in pairs(Computers) do
			local Filter = Computer.Filter

			Filter[#Filter + 1] = Missile
		end
	end)

	Components.RegisterItem("CPR-OPT", "GD-CPR", {
		Name        = "Optical Guidance Computer",
		Description = "Fully analog guidance computer. Unlike the laser guidance computer, it takes a few seconds for it to aim and focus properly.",
		Model       = "models/props_lab/monitor01b.mdl",
		Mass        = 43,
		Offset      = Vector(6, -1, 0),
		Speed       = 10, -- Degrees per second
		FocusSpeed  = 300, -- Meters per second
		Inputs      = { "Pitch (Degrees on the vertical axis)", "Yaw (Degrees on the horizontal axis)", "HitPos (Target location to aim laser at) [VECTOR]" },
		Outputs     = {
			"Ranging (Whether or not the computer is currently adjusting to focus)",
			"Distance (The currently measured distance from the computer, in meters)",
			"HitPos (The vector of where the computer is currently focused on) [VECTOR]",
			"Current Pitch (Current degrees on the vertical axis)",
			"Current Yaw (Current degrees on the horizontal axis)" },
		Bounds = {
			Pitch = 15,
			Yaw   = 20,
		},
		Preview = {
			FOV = 110,
		},
		CreateMenu = function(Data, Menu)
			local Pitch = Data.Bounds.Pitch
			local Yaw   = Data.Bounds.Yaw
			local Speed = Data.Speed
			local Focus = Data.FocusSpeed
			local Mass  = Data.Mass

			Menu:AddLabel(MenuText:format(Pitch, Yaw, Speed, Focus, Mass))

			ACF.SetClientData("PrimaryClass", "acf_computer")
		end,
		-- Serverside actions
		OnUpdate = function(Entity, _, _, Computer)
			Entity.IsComputer = true
			Entity.IsOptical  = true
			Entity.Offset     = Computer.Offset
			Entity.Filter     = { Entity }
			Entity.HitPos     = Vector()
			Entity.TraceDir   = Vector()
			Entity.TracePos   = Vector()
			Entity.Distance   = 0
			Entity.TraceDist  = 0
			Entity.Spread     = 0
			Entity.FocusSpeed = Computer.FocusSpeed * ACF.MeterToInch -- Converting to in/s
			Entity.MoveSpeed  = Computer.Speed
			Entity.MinPitch   = -Computer.Bounds.Pitch
			Entity.MaxPitch   = Computer.Bounds.Pitch
			Entity.MinYaw     = -Computer.Bounds.Yaw
			Entity.MaxYaw     = Computer.Bounds.Yaw
			Entity.Direction  = Vector(1)
			Entity.Pitch      = 0
			Entity.Yaw        = 0
			Entity.InputPitch = 0
			Entity.InputYaw   = 0
			Entity.InputHitPos = Vector()

			Computers[Entity] = true

			WireLib.TriggerOutput(Entity, "Ranging", 0)
			WireLib.TriggerOutput(Entity, "Distance", 0)
			WireLib.TriggerOutput(Entity, "HitPos", Vector())
			WireLib.TriggerOutput(Entity, "Current Pitch", 0)
			WireLib.TriggerOutput(Entity, "Current Yaw", 0)
		end,
		OnLast = function(Entity)
			Entity.IsComputer = nil
			Entity.IsOptical  = nil
			Entity.Offset     = nil
			Entity.Filter     = nil
			Entity.HitPos     = nil
			Entity.TraceDir   = nil
			Entity.TracePos   = nil
			Entity.Distance   = nil
			Entity.TraceDist  = nil
			Entity.Spread     = nil
			Entity.FocusSpeed = nil
			Entity.MoveSpeed  = nil
			Entity.MinPitch   = nil
			Entity.MaxPitch   = nil
			Entity.MinYaw     = nil
			Entity.MaxYaw     = nil
			Entity.Direction  = nil
			Entity.Pitch      = nil
			Entity.Yaw        = nil
			Entity.InputPitch = nil
			Entity.InputYaw   = nil
			Entity.InputHitPos = nil

			Computers[Entity] = nil
		end,
		OnOverlayTitle = function(Entity)
			if not Entity.IsComputer then return end
			if Entity.Distance ~= Entity.TraceDist then return "Ranging" end
			if Entity.InputPitch ~= 0 or Entity.InputYaw ~= 0 then
				return "In use"
			end
		end,
		OnOverlayBody = function(Entity, State)
			if not Entity.IsComputer then return end

			local Pitch, Yaw = Entity.Pitch, Entity.Yaw

			State:AddNumber("Distance", FloorMeters(Entity.Distance) * ACF.InchToMeter, " m", 2)
			State:AddNumber("Pitch", Entity.Pitch, Pitch >= 1 and Pitch < 2 and " degree" or " degrees")
			State:AddNumber("Yaw", Entity.Yaw, Yaw >= 1 and Yaw < 2 and " degree" or " degrees")
			State:AddCoordinates("HitPos", Entity.HitPos:Unpack())
		end,
		OnDamaged = function(Entity)
			Entity.Spread = 1 - math.Round(Entity.ACF.Health / Entity.ACF.MaxHealth, 2)
		end,
		OnEnabled = function(Entity)
			local Inputs = Entity.Inputs
			local Pitch  = Inputs.InputPitch
			local Yaw    = Inputs.InputYaw

			if Pitch and Pitch.Path then
				Entity:TriggerInput("Pitch", Pitch.Value)
			end

			if Yaw and Yaw.Path then
				Entity:TriggerInput("Yaw", Yaw.Value)
			end
		end,
		OnDisabled = function(Entity)
			Entity:TriggerInput("Pitch", 0)
			Entity:TriggerInput("Yaw", 0)
		end,
		OnThink = function(Entity)
			local Tick  = engine.TickInterval()
			local Speed = Entity.MoveSpeed * Tick * math.Rand(Entity.Spread, 1)
			local Focus = Entity.FocusSpeed * Tick * math.Rand(Entity.Spread, 1)
			local Changed

			if Entity.InputHitPos ~= Vector() then
				local RayOrigin = Entity:LocalToWorld(Entity.Offset)
				local Angle = (Entity.InputHitPos - RayOrigin):Angle()
				local LocalAngle = Entity:WorldToLocalAngles(Angle)
				Entity.InputPitch = math.Round(math.Clamp(-LocalAngle[1], Entity.MinPitch, Entity.MaxPitch), 2)
				Entity.InputYaw = math.Round(math.Clamp(-LocalAngle[2], Entity.MinYaw, Entity.MaxYaw), 2)
			end

			if Entity.Pitch ~= Entity.InputPitch then
				local Delta = math.Clamp(Entity.InputPitch - Entity.Pitch, -Speed, Speed)

				Entity.Pitch = Entity.Pitch + Delta

				WireLib.TriggerOutput(Entity, "Current Pitch", Entity.Pitch)

				Entity:UpdateOverlay()

				Changed = true
			end

			if Entity.Yaw ~= Entity.InputYaw then
				local Delta = math.Clamp(Entity.InputYaw - Entity.Yaw, -Speed, Speed)

				Entity.Yaw = Entity.Yaw + Delta

				WireLib.TriggerOutput(Entity, "Current Yaw", Entity.Yaw)

				Entity:UpdateOverlay()

				Changed = true
			end

			if Changed then
				Entity.Direction = Angle(-Entity.Pitch, -Entity.Yaw, 0):Forward()
			end

			TraceData.start  = Entity:LocalToWorld(Entity.Offset)
			TraceData.endpos = GetTraceEndPos(Entity, 50000)
			TraceData.filter = Entity.Filter

			local Result = ACF.trace(TraceData)

			Entity.TraceDir  = Result.Normal
			Entity.TracePos  = Result.HitPos
			Entity.TraceDist = Result.Fraction * 50000

			if Entity.Distance ~= Entity.TraceDist or Entity.HitPos ~= Entity.TracePos then
				local Delta = math.Clamp(Entity.TraceDist - Entity.Distance, -Focus, Focus)

				Entity.Distance = Entity.Distance + Delta

				local MeterDistance = FloorMeters(Entity.Distance)

				Entity.HitPos = GetTraceEndPos(Entity, MeterDistance)

				WireLib.TriggerOutput(Entity, "HitPos", Entity.HitPos)
				WireLib.TriggerOutput(Entity, "Distance", MeterDistance)

				Entity:UpdateOverlay()
			end
		end,
	})
end

do -- Laser guidance computer
	local MenuText  = "Pitch bounds : +-%s degrees\nYaw bounds : +-%s degrees\nAim speed : %s degrees/s\nMass : %s kg"
	local LaserText = "Lasing time : %s seconds\nCooldown : %s seconds"
	local Clock     = ACF.Utilities.Clock

	Components.RegisterItem("CPR-LSR", "GD-CPR", {
		Name        = "Laser Guidance Computer",
		Description = "Modern equivalent to the analog guidance computer, provides faster and more accurate measurements. Can be also used as a laser target designator.",
		Model       = "models/props_lab/monitor01b.mdl",
		Mass        = 30,
		LaseTime    = 20,
		Cooldown    = 10,
		Offset      = Vector(6, -1, 0),
		Speed       = 45, -- Degrees per second
		Inputs      = { "Lase (Turns on the laser)", "Pitch (Degrees on the vertical axis)", "Yaw (Degrees on the horizontal axis)", "HitPos (Target location to aim laser at) [VECTOR]" },
		Outputs     = {
			"Lasing (Whether or not the laser is on)",
			"Lase Time (How long the laser can stay on before requiring a cool down)",
			"Cooling Down (Whether or not the laser is cooling off)",
			"Distance (The currently measured distance from the computer, in meters)",
			"HitPos (The vector of where the computer detects a hit from the laser) [VECTOR]",
			"Current Pitch (Current degrees on the vertical axis)",
			"Current Yaw (Current degrees on the horizontal axis)" },
		Bounds = {
			Pitch = 10,
			Yaw   = 15,
		},
		Preview = {
			FOV = 110,
		},
		CreateMenu = function(Data, Menu)
			local Pitch    = Data.Bounds.Pitch
			local Yaw      = Data.Bounds.Yaw
			local Speed    = Data.Speed
			local Mass     = Data.Mass
			local LaseTime = Data.LaseTime
			local Cooldown = Data.Cooldown

			Menu:AddLabel(MenuText:format(Pitch, Yaw, Speed, Mass))
			Menu:AddLabel(LaserText:format(LaseTime, Cooldown))

			ACF.SetClientData("PrimaryClass", "acf_computer")
		end,
		-- Serverside actions
		OnUpdate = function(Entity, _, _, Computer)
			Entity.IsComputer = true
			Entity.Lasing     = false
			Entity.Offset     = Computer.Offset
			Entity.OnCooldown = false
			Entity.HitPos     = Vector()
			Entity.Distance   = 0
			Entity.TraceDir   = Vector()
			Entity.TracePos   = Entity.HitPos
			Entity.TraceDist  = Entity.Distance
			Entity.NextSpread = 0
			Entity.Spread     = 0
			Entity.LaseTime   = 0
			Entity.LastLase   = 0
			Entity.MaxTime    = Computer.LaseTime
			Entity.Cooldown   = Computer.Cooldown
			Entity.MoveSpeed  = Computer.Speed
			Entity.MinPitch   = -Computer.Bounds.Pitch
			Entity.MaxPitch   = Computer.Bounds.Pitch
			Entity.MinYaw     = -Computer.Bounds.Yaw
			Entity.MaxYaw     = Computer.Bounds.Yaw
			Entity.Direction  = Vector(1)
			Entity.Pitch      = 0
			Entity.Yaw        = 0
			Entity.InputPitch = 0
			Entity.InputYaw   = 0
			Entity.InputHitPos = Vector()

			Entity:SetNW2Vector("Direction", Vector(1))

			ACF.SetupLaserSource(Entity, {
				NetVar    = "Lasing",
				Offset    = Computer.Offset,
				Direction = "Direction",
			})

			WireLib.TriggerOutput(Entity, "Lasing", 0)
			WireLib.TriggerOutput(Entity, "Lase Time", Entity.MaxTime)
			WireLib.TriggerOutput(Entity, "Cooling Down", 0)
			WireLib.TriggerOutput(Entity, "Distance", 0)
			WireLib.TriggerOutput(Entity, "HitPos", Vector())
			WireLib.TriggerOutput(Entity, "Current Pitch", 0)
			WireLib.TriggerOutput(Entity, "Current Yaw", 0)
		end,
		OnLast = function(Entity)
			Entity.IsComputer = nil
			Entity.Lasing     = nil
			Entity.OnCooldown = nil
			Entity.HitPos     = nil
			Entity.Distance   = nil
			Entity.TraceDir   = nil
			Entity.TracePos   = nil
			Entity.TraceDist  = nil
			Entity.NextSpread = nil
			Entity.Spread     = nil
			Entity.LaseTime   = nil
			Entity.LastLase   = nil
			Entity.MaxTime    = nil
			Entity.Cooldown   = nil
			Entity.MoveSpeed  = nil
			Entity.MinPitch   = nil
			Entity.MaxPitch   = nil
			Entity.MinYaw     = nil
			Entity.MaxYaw     = nil
			Entity.Direction  = nil
			Entity.Pitch      = nil
			Entity.Yaw        = nil
			Entity.InputPitch = nil
			Entity.InputYaw   = nil
			Entity.InputHitPos = nil

			ACF.ClearLaserSource(Entity)
		end,
		OnOverlayTitle = function(Entity)
			if not Entity.IsComputer then return end
			if Entity.OnCooldown then return "Cooling down" end
			if Entity.Lasing then return "Lasing" end
			if Entity.InputPitch ~= 0 or Entity.InputYaw ~= 0 then
				return "In use"
			end
		end,
		OnOverlayBody = function(Entity, State)
			if not Entity.IsComputer then return end

			local Distance = math.Round(Entity.Distance * ACF.InchToMeter)
			local Pitch, Yaw = Entity.Pitch, Entity.Yaw

			State:AddNumber("Distance", Distance, " m", 0)
			State:AddNumber("Pitch", Entity.Pitch, Pitch >= 1 and Pitch < 2 and " degree" or " degrees")
			State:AddNumber("Yaw", Entity.Yaw, Yaw >= 1 and Yaw < 2 and " degree" or " degrees")
			State:AddCoordinates("HitPos", Entity.HitPos:Unpack())
		end,
		OnDamaged = function(Entity)
			Entity.Spread = 1 - math.Round(Entity.ACF.Health / Entity.ACF.MaxHealth, 2)
		end,
		OnEnabled = function(Entity)
			local Inputs = Entity.Inputs
			local Lase   = Inputs.Lase
			local Pitch  = Inputs.InputPitch
			local Yaw    = Inputs.InputYaw

			if Lase and Lase.Path then
				Entity:TriggerInput("Lase", Lase.Value)
			end

			if Pitch and Pitch.Path then
				Entity:TriggerInput("Pitch", Pitch.Value)
			end

			if Yaw and Yaw.Path then
				Entity:TriggerInput("Yaw", Yaw.Value)
			end
		end,
		OnDisabled = function(Entity)
			Entity:TriggerInput("Lase", 0)
			Entity:TriggerInput("Pitch", 0)
			Entity:TriggerInput("Yaw", 0)
		end,
		OnThink = function(Entity)
			local Tick  = engine.TickInterval()
			local Speed = Entity.MoveSpeed * Tick
			local Changed

			if Entity.InputHitPos ~= Vector() then
				local RayOrigin = Entity:LocalToWorld(Entity.Offset)
				local Angle = (Entity.InputHitPos - RayOrigin):Angle()
				local LocalAngle = Entity:WorldToLocalAngles(Angle)
				Entity.InputPitch = math.Round(math.Clamp(-LocalAngle.p, Entity.MinPitch, Entity.MaxPitch), 2)
				Entity.InputYaw = math.Round(math.Clamp(-LocalAngle.y, Entity.MinYaw, Entity.MaxYaw), 2)
			end

			if Entity.Pitch ~= Entity.InputPitch then
				local Delta = math.Clamp(Entity.InputPitch - Entity.Pitch, -Speed, Speed)

				Entity.Pitch = Entity.Pitch + Delta

				WireLib.TriggerOutput(Entity, "Current Pitch", Entity.Pitch)

				Entity:UpdateOverlay()

				Changed = true
			end

			if Entity.Yaw ~= Entity.InputYaw then
				local Delta = math.Clamp(Entity.InputYaw - Entity.Yaw, -Speed, Speed)

				Entity.Yaw = Entity.Yaw + Delta

				WireLib.TriggerOutput(Entity, "Current Yaw", Entity.Yaw)

				Entity:UpdateOverlay()

				Changed = true
			end

			if Changed or Entity.Spread ~= 0 then
				local Pitch     = math.Rand(-Entity.Spread, Entity.Spread)
				local Yaw       = math.Rand(-Entity.Spread, Entity.Spread)
				local Direction = Angle(-Entity.Pitch + Pitch, -Entity.Yaw + Yaw, 0):Forward()

				Entity.Direction = Direction

				if Entity.NextSpread <= Clock.CurTime then
					Entity:SetNW2Vector("Direction", Direction)

					Entity.NextSpread = Clock.CurTime + 0.1
				end
			end

			if Entity.Lasing or Entity.LaseTime > 0 then
				local Delta = math.min(Clock.CurTime - Entity.LastLase, Tick) * (Entity.Lasing and 1 or -1)

				Entity.LaseTime = math.Clamp(Entity.LaseTime + Delta, 0, Entity.MaxTime)

				if Entity.LaseTime == Entity.MaxTime then
					Entity:TriggerInput("Lase", 0)

					Entity.OnCooldown = true
					Entity.HitPos     = Vector()
					Entity.Distance   = 0
					Entity.LaseTime   = 0
					Entity.TraceDir   = Vector()
					Entity.TracePos   = Entity.HitPos
					Entity.TraceDist  = Entity.Distance

					WireLib.TriggerOutput(Entity, "Cooling Down", 1)
					WireLib.TriggerOutput(Entity, "HitPos", Vector())
					WireLib.TriggerOutput(Entity, "Distance", 0)

					timer.Simple(Entity.Cooldown, function()
						if not IsValid(Entity) then return end

						Entity.OnCooldown = false

						if Entity.Inputs.Lase.Path then
							Entity:TriggerInput("Lase", Entity.Inputs.Lase.Value)
						end

						WireLib.TriggerOutput(Entity, "Cooling Down", 0)

						Entity:UpdateOverlay()
					end)
				else
					local Laser = ACF.GetLaserData(Entity)

					Entity.Distance  = Laser and Laser.Distance or 0
					Entity.HitPos    = Laser and Laser.HitPos or Vector()
					Entity.TraceDir  = Laser and Laser.Trace.Normal
					Entity.TracePos  = Entity.HitPos
					Entity.TraceDist = Entity.Distance

					WireLib.TriggerOutput(Entity, "Distance", Entity.Distance)
					WireLib.TriggerOutput(Entity, "HitPos", Entity.HitPos)
				end

				WireLib.TriggerOutput(Entity, "Lase Time", Entity.MaxTime - Entity.LaseTime)

				Entity.LastLase = Clock.CurTime

				Entity:UpdateOverlay()
			end
		end,
	})
end

do -- GPS transmitter
	local ZERO = Vector()

	Components.RegisterItem("CPR-GPS", "GD-CPR", {
		Name        = "GPS Transmitter",
		Description = "A transmitter for GPS-based guided munitions.",
		Model       = "models/props_lab/reciever01a.mdl",
		Mass        = 15,
		Inputs      = { "Coordinates (The vector to pass along to the linked rack) [VECTOR]" },
		Outputs     = {
			"Transmitting (Whether or not the transmitter is functioning)",
			"Jammed (Whether or not the transmitter is being countered)",
			"Current Coordinates (The vector currently being transmitted) [VECTOR]" },
		Preview = {
			FOV = 80,
		},
		CreateMenu = function(Data, Menu)
			Menu:AddLabel("Mass : " .. Data.Mass .. " kg")
			--Menu:AddLabel("This entity can be jammed.") -- Not yet

			ACF.SetClientData("PrimaryClass", "acf_computer")
		end,
		-- Serverside actions
		OnUpdate = function(Entity)
			Entity.IsGPS       = true
			Entity.IsJammed    = false
			Entity.InputCoords = Vector()
			Entity.Coordinates = Vector()
			Entity.Spread      = 0

			WireLib.TriggerOutput(Entity, "Current Coordinates", Vector())
			WireLib.TriggerOutput(Entity, "Transmitting", 0)
			WireLib.TriggerOutput(Entity, "Jammed", 0)
		end,
		OnLast = function(Entity)
			Entity.IsGPS       = nil
			Entity.IsJammed    = nil
			Entity.InputCoords = nil
			Entity.Coordinates = nil
			Entity.Spread      = nil
		end,
		OnOverlayTitle = function(Entity)
			if not Entity.IsGPS then return end
			if Entity.IsJammed then return "Jammed" end
			if Entity.InputCoords ~= Vector() then
				return "Transmitting"
			end
		end,
		OnOverlayBody = function(Entity, State)
			if not Entity.IsGPS then return end

			State:AddCoordinates("Coordinates", Entity.Coordinates:Unpack())
		end,
		OnDamaged = function(Entity)
			Entity.Spread = ACF.MaxDamageInaccuracy * (1 - math.Round(Entity.ACF.Health / Entity.ACF.MaxHealth, 2))
		end,
		OnEnabled = function(Entity)
			local Coordinates = Entity.Inputs.Coordinates

			if Coordinates and Coordinates.Path then
				Entity:TriggerInput("Coordinates", Coordinates.Value)
			end
		end,
		OnDisabled = function(Entity)
			Entity:TriggerInput("Coordinates", Vector())
		end,
		OnThink = function(Entity)
			if Entity.InputCoords == ZERO then return end

			local Spread = VectorRand(-Entity.Spread, Entity.Spread)

			Entity.Coordinates = Entity.InputCoords + Spread

			WireLib.TriggerOutput(Entity, "Current Coordinates", Entity.Coordinates)

			Entity:UpdateOverlay()
		end,
	})
end

local GroundLoaderText = "Mass : %s kg\n"

function ACF.CreateGroundLoaderMenu(Data, Menu)
	Menu:AddLabel(GroundLoaderText:format(Data.Mass))

	ACF.SetClientData("PrimaryClass", "acf_groundloader")

	if Menu.ComponentPreview then
		local Settings = {
			GhostAngOffset = Angle(0, -90, 0)
		}

		Menu.ComponentPreview:UpdateSettings(Settings)
		Menu.ComponentPreview:SetModelScale(1, true)
	end
end

-- Wow I love this file so much
-- This is just to get it in the menu.
Components.Register("GND-LDR", {
	Name   = "Ground Loader",
	Entity = "acf_groundloader",
	CreateMenu = ACF.CreateGroundLoaderMenu,
})

Components.RegisterItem("GND-LDR-ITM", "GND-LDR", {
	Name        = "Ground Loader",
	Description = "An entity capable of linking to ammo crates and loading racks within line of sight and range. Must be stationary to function.",
	Model       = "models/props_vehicles/generatortrailer01.mdl",
	Mass        = 200,
})