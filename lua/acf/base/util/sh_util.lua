do -- Ricochet/Penetration materials
	local Materials = {}
	local MatCache = {}
	local Lookup = {}
	local Count = 0

	local function GetMaterial(Path)
		if not Path then return end
		if MatCache[Path] then return MatCache[Path] end

		local Object = Material(Path)

		MatCache[Path] = Object

		return Object
	end

	local function DefaultScale(Caliber)
		return Caliber * 0.1312 -- Default AP decal makes a 76.2mm hole, dividing by 7.62cm
	end

	function ACF.RegisterAmmoDecal(Type, PenPath, RicoPath, ScaleFunc)
		if not Type then return end

		if not Lookup[Type] then
			Count = Count + 1

			Materials[Count] = {
				Penetration = GetMaterial(PenPath),
				Ricochet = GetMaterial(RicoPath),
				Scale = ScaleFunc or DefaultScale,
				Index = Count,
				Type = Type,
			}

			Lookup[Type] = Materials[Count]
		else
			local Data = Lookup[Type]
			Data.Penetration = GetMaterial(PenPath)
			Data.Ricochet = GetMaterial(RicoPath)
			Data.Scale = ScaleFunc or DefaultScale
		end
	end

	function ACF.IsValidAmmoDecal(Key)
		if not Key then return false end
		if Lookup[Key] then return true end
		if Materials[Key] then return true end

		return false
	end

	function ACF.GetAmmoDecalIndex(Type)
		if not Type then return end
		if not Lookup[Type] then return end

		return Lookup[Type].Index
	end

	function ACF.GetAmmoDecalType(Index)
		if not Index then return end
		if not Materials[Index] then return end

		return Materials[Index].Type
	end

	function ACF.GetPenetrationDecal(Key)
		if not Key then return end

		if Lookup[Key] then
			return Lookup[Key].Penetration
		end

		if Materials[Key] then
			return Materials[Key].Penetration
		end
	end

	function ACF.GetRicochetDecal(Key)
		if not Key then return end

		if Lookup[Key] then
			return Lookup[Key].Ricochet
		end

		if Materials[Key] then
			return Materials[Key].Ricochet
		end
	end

	function ACF.GetDecalScale(Key, Caliber)
		if not Key then return end

		if Lookup[Key] then
			return Lookup[Key].Scale(Caliber)
		end

		if Materials[Key] then
			return Materials[Key].Scale(Caliber)
		end
	end
end

do -- Unit conversion
	local Units = {
		{ Unit = "year", Reduction = 1970 },
		{ Unit = "month", Reduction = 1 },
		{ Unit = "day", Reduction = 1 },
		{ Unit = "hour", Reduction = 0 },
		{ Unit = "min", Reduction = 0 },
		{ Unit = "sec", Reduction = 0 },
	}

	local function LocalToUTC()
		return os.time(os.date("!*t", os.time()))
	end

	function ACF.GetTimeLapse(Date)
		if not Date then return end

		local Time = LocalToUTC() - Date
		local DateData = os.date("!*t", Time)

		-- Negative values to os.date will return nil
		-- LocalToUTC() is most likely flawed, will need testing with people from different timezones.
		if Time <= 0 then return "now" end

		for _, Data in ipairs(Units) do
			Time = DateData[Data.Unit] - Data.Reduction

			if Time > 0 then
				return Time .. " " .. Data.Unit .. (Time ~= 1 and "s" or "") .. " ago"
			end
		end
	end

	function ACF.GetProperMass(Kilograms)
		local Unit, Mult = "g", 1000

		if Kilograms >= 1000 then
			Unit, Mult = "t", 0.001
		elseif Kilograms >= 1 then
			Unit, Mult = "kg", 1
		end

		return math.Round(Kilograms * Mult, 2) .. " " .. Unit
	end
end

do -- Sound aliases
	local Stored = {}
	local Lookup = {}
	local Path = "sound/%s"

	local function CreateData(Name)
		if not Lookup[Name] then
			Lookup[Name] = {
				Name = Name,
				Children = {}
			}
		else
			Stored[Name] = nil
		end

		return Lookup[Name]
	end

	local function RegisterAlias(Old, New)
		if not isstring(Old) then return end
		if not isstring(New) then return end

		Old = Old:lower()
		New = New:lower()

		local OldData = CreateData(Old)
		local NewData = CreateData(New)

		NewData.Children[OldData] = true
		OldData.Parent = NewData
	end

	local function GetParentSound(Name, List, Total)
		for I = Total, 1, -1 do
			local Sound = List[I].Name

			if file.Exists(Path:format(Sound), "GAME") then
				Stored[Name] = Sound

				return Sound
			end
		end
	end

	-- Note: This isn't syncronized between server and client.
	-- If a sound happens to have multiple children, the result will differ between client and server.
	local function GetChildSound(Name)
		local Data = Lookup[Name]
		local Next = Data.Children
		local Checked = { [Data] = true }

		repeat
			local New = {}

			for Child in pairs(Next) do
				if Checked[Child] then continue end

				local Sound = Child.Name

				if file.Exists(Path:format(Sound), "GAME") then
					Stored[Name] = Sound

					return Sound
				end

				for K in pairs(Child.Children) do
					New[K] = true
				end

				Checked[Child] = true
			end

			Next = New

		until not next(Next)
	end

	local function GetAlias(Name)
		if not isstring(Name) then return end

		Name = Name:lower()

		if not Lookup[Name] then return Name end
		if Stored[Name] then return Stored[Name] end

		local Checked, List = {}, {}
		local Next = Lookup[Name]
		local Count = 0

		repeat
			if Checked[Next] then break end

			Count = Count + 1

			Checked[Next] = true
			List[Count] = Next

			Next = Next.Parent
		until not Next

		local Parent = GetParentSound(Name, List, Count)
		if Parent then return Parent end

		local Children = GetChildSound(Name)
		if Children then return Children end

		Stored[Name] = Name

		return Name
	end

	function ACF.RegisterSoundAliases(Table)
		if not istable(Table) then return end

		for K, V in pairs(Table) do
			RegisterAlias(K, V)
		end
	end

	ACF.GetSoundAlias = GetAlias

	-- sound.Play hijacking
	sound.DefaultPlay = sound.DefaultPlay or sound.Play

	function sound.Play(Name, ...)
		Name = GetAlias(Name)

		return sound.DefaultPlay(Name, ...)
	end

	-- ENT:EmitSound hijacking
	local ENT = FindMetaTable("Entity")

	ENT.DefaultEmitSound = ENT.DefaultEmitSound or ENT.EmitSound

	function ENT:EmitSound(Name, ...)
		Name = GetAlias(Name)

		return self:DefaultEmitSound(Name, ...)
	end

	-- CreateSound hijacking
	DefaultCreateSound = DefaultCreateSound or CreateSound

	function CreateSound(Entity, Name, ...)
		Name = GetAlias(Name)

		return DefaultCreateSound(Entity, Name, ...)
	end

	-- Valid sound check
	if CLIENT then
		local SoundCache = {}

		function ACF.IsValidSound(Name)
			Name = GetAlias(Name)

			if SoundCache[Name] == nil then
				SoundCache[Name] = file.Exists(Path:format(Name), "GAME")
			end

			return SoundCache[Name]
		end
	end
end

do -- Parentable Wire model list
	local WireModels = {
		["models/blacknecro/ledboard60.mdl"] = true,
		["models/blacknecro/tv_plasma_4_3.mdl"] = true,
		["models/bull/buttons/key_switch.mdl"] = true,
		["models/bull/buttons/rocker_switch.mdl"] = true,
		["models/bull/buttons/toggle_switch.mdl"] = true,
		["models/bull/gates/capacitor.mdl"] = true,
		["models/bull/gates/capacitor_mini.mdl"] = true,
		["models/bull/gates/capacitor_nano.mdl"] = true,
		["models/bull/gates/logic.mdl"] = true,
		["models/bull/gates/logic_mini.mdl"] = true,
		["models/bull/gates/logic_nano.mdl"] = true,
		["models/bull/gates/microcontroller1.mdl"] = true,
		["models/bull/gates/microcontroller1_mini.mdl"] = true,
		["models/bull/gates/microcontroller1_nano.mdl"] = true,
		["models/bull/gates/microcontroller2.mdl"] = true,
		["models/bull/gates/microcontroller2_mini.mdl"] = true,
		["models/bull/gates/microcontroller2_nano.mdl"] = true,
		["models/bull/gates/processor.mdl"] = true,
		["models/bull/gates/processor_mini.mdl"] = true,
		["models/bull/gates/processor_nano.mdl"] = true,
		["models/bull/gates/resistor.mdl"] = true,
		["models/bull/gates/resistor_mini.mdl"] = true,
		["models/bull/gates/resistor_nano.mdl"] = true,
		["models/bull/gates/transistor1.mdl"] = true,
		["models/bull/gates/transistor1_mini.mdl"] = true,
		["models/bull/gates/transistor1_nano.mdl"] = true,
		["models/bull/gates/transistor2.mdl"] = true,
		["models/bull/gates/transistor2_mini.mdl"] = true,
		["models/bull/gates/transistor2_nano.mdl"] = true,
		["models/bull/various/gyroscope.mdl"] = true,
		["models/bull/various/speaker.mdl"] = true,
		["models/bull/various/subwoofer.mdl"] = true,
		["models/bull/various/usb_socket.mdl"] = true,
		["models/bull/various/usb_stick.mdl"] = true,
		["models/cheeze/buttons/button_0.mdl"] = true,
		["models/cheeze/buttons/button_1.mdl"] = true,
		["models/cheeze/buttons/button_2.mdl"] = true,
		["models/cheeze/buttons/button_3.mdl"] = true,
		["models/cheeze/buttons/button_4.mdl"] = true,
		["models/cheeze/buttons/button_5.mdl"] = true,
		["models/cheeze/buttons/button_6.mdl"] = true,
		["models/cheeze/buttons/button_7.mdl"] = true,
		["models/cheeze/buttons/button_8.mdl"] = true,
		["models/cheeze/buttons/button_9.mdl"] = true,
		["models/cheeze/buttons/button_arm.mdl"] = true,
		["models/cheeze/buttons/button_clear.mdl"] = true,
		["models/cheeze/buttons/button_enter.mdl"] = true,
		["models/cheeze/buttons/button_fire.mdl"] = true,
		["models/cheeze/buttons/button_minus.mdl"] = true,
		["models/cheeze/buttons/button_muffin.mdl"] = true,
		["models/cheeze/buttons/button_plus.mdl"] = true,
		["models/cheeze/buttons/button_reset.mdl"] = true,
		["models/cheeze/buttons/button_set.mdl"] = true,
		["models/cheeze/buttons/button_start.mdl"] = true,
		["models/cheeze/buttons/button_stop.mdl"] = true,
		["models/cheeze/pcb/pcb0.mdl"] = true,
		["models/cheeze/pcb/pcb1.mdl"] = true,
		["models/cheeze/pcb/pcb2.mdl"] = true,
		["models/cheeze/pcb/pcb3.mdl"] = true,
		["models/cheeze/pcb/pcb4.mdl"] = true,
		["models/cheeze/pcb/pcb5.mdl"] = true,
		["models/cheeze/pcb/pcb6.mdl"] = true,
		["models/cheeze/pcb/pcb7.mdl"] = true,
		["models/cheeze/pcb/pcb8.mdl"] = true,
		["models/cheeze/wires/amd_test.mdl"] = true,
		["models/cheeze/wires/cpu.mdl"] = true,
		["models/cheeze/wires/cpu2.mdl"] = true,
		["models/cheeze/wires/gyroscope.mdl"] = true,
		["models/cheeze/wires/mini_chip.mdl"] = true,
		["models/cheeze/wires/mini_cpu.mdl"] = true,
		["models/cheeze/wires/mini_cpu2.mdl"] = true,
		["models/cheeze/wires/nano_chip.mdl"] = true,
		["models/cheeze/wires/nano_compare.mdl"] = true,
		["models/cheeze/wires/nano_cpu.mdl"] = true,
		["models/cheeze/wires/nano_logic.mdl"] = true,
		["models/cheeze/wires/nano_math.mdl"] = true,
		["models/cheeze/wires/nano_memory.mdl"] = true,
		["models/cheeze/wires/nano_select.mdl"] = true,
		["models/cheeze/wires/nano_timer.mdl"] = true,
		["models/cheeze/wires/nano_trig.mdl"] = true,
		["models/cheeze/wires/nano_value.mdl"] = true,
		["models/cheeze/wires/ram.mdl"] = true,
		["models/cheeze/wires/router.mdl"] = true,
		["models/cheeze/wires/speaker.mdl"] = true,
		["models/cheeze/wires/wireless_card.mdl"] = true,
		["models/cyborgmatt/capacitor_large.mdl"] = true,
		["models/cyborgmatt/capacitor_medium.mdl"] = true,
		["models/cyborgmatt/capacitor_small.mdl"] = true,
		["models/expression 2/cpu_controller.mdl"] = true,
		["models/expression 2/cpu_controller_mini.mdl"] = true,
		["models/expression 2/cpu_controller_nano.mdl"] = true,
		["models/expression 2/cpu_expression.mdl"] = true,
		["models/expression 2/cpu_expression_mini.mdl"] = true,
		["models/expression 2/cpu_expression_nano.mdl"] = true,
		["models/expression 2/cpu_interface.mdl"] = true,
		["models/expression 2/cpu_interface_mini.mdl"] = true,
		["models/expression 2/cpu_interface_nano.mdl"] = true,
		["models/expression 2/cpu_microchip.mdl"] = true,
		["models/expression 2/cpu_microchip_mini.mdl"] = true,
		["models/expression 2/cpu_microchip_nano.mdl"] = true,
		["models/expression 2/cpu_processor.mdl"] = true,
		["models/expression 2/cpu_processor_mini.mdl"] = true,
		["models/expression 2/cpu_processor_nano.mdl"] = true,
		["models/hammy/pci_card.mdl"] = true,
		["models/hammy/pci_slot.mdl"] = true,
		["models/holograms/cone.mdl"] = true,
		["models/holograms/cube.mdl"] = true,
		["models/holograms/cylinder.mdl"] = true,
		["models/holograms/hexagon.mdl"] = true,
		["models/holograms/hq_cone.mdl"] = true,
		["models/holograms/hq_cubinder.mdl"] = true,
		["models/holograms/hq_cylinder.mdl"] = true,
		["models/holograms/hq_dome.mdl"] = true,
		["models/holograms/hq_hdome.mdl"] = true,
		["models/holograms/hq_hdome_thick.mdl"] = true,
		["models/holograms/hq_hdome_thin.mdl"] = true,
		["models/holograms/hq_icosphere.mdl"] = true,
		["models/holograms/hq_rcube.mdl"] = true,
		["models/holograms/hq_rcube_thick.mdl"] = true,
		["models/holograms/hq_rcube_thin.mdl"] = true,
		["models/holograms/hq_rcylinder.mdl"] = true,
		["models/holograms/hq_rcylinder_thick.mdl"] = true,
		["models/holograms/hq_rcylinder_thin.mdl"] = true,
		["models/holograms/hq_sphere.mdl"] = true,
		["models/holograms/hq_stube.mdl"] = true,
		["models/holograms/hq_stube_thick.mdl"] = true,
		["models/holograms/hq_stube_thin.mdl"] = true,
		["models/holograms/hq_torus.mdl"] = true,
		["models/holograms/hq_torus_oldsize.mdl"] = true,
		["models/holograms/hq_torus_thick.mdl"] = true,
		["models/holograms/hq_torus_thin.mdl"] = true,
		["models/holograms/hq_tube.mdl"] = true,
		["models/holograms/hq_tube_thick.mdl"] = true,
		["models/holograms/hq_tube_thin.mdl"] = true,
		["models/holograms/icosphere.mdl"] = true,
		["models/holograms/icosphere2.mdl"] = true,
		["models/holograms/icosphere3.mdl"] = true,
		["models/holograms/octagon.mdl"] = true,
		["models/holograms/plane.mdl"] = true,
		["models/holograms/prism.mdl"] = true,
		["models/holograms/pyramid.mdl"] = true,
		["models/holograms/sphere.mdl"] = true,
		["models/holograms/sphere2.mdl"] = true,
		["models/holograms/sphere3.mdl"] = true,
		["models/holograms/tetra.mdl"] = true,
		["models/holograms/torus.mdl"] = true,
		["models/holograms/torus2.mdl"] = true,
		["models/holograms/torus3.mdl"] = true,
		["models/jaanus/thruster_flat.mdl"] = true,
		["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = true,
		["models/jaanus/wiretool/wiretool_controlchip.mdl"] = true,
		["models/jaanus/wiretool/wiretool_detonator.mdl"] = true,
		["models/jaanus/wiretool/wiretool_gate.mdl"] = true,
		["models/jaanus/wiretool/wiretool_grabber_forcer.mdl"] = true,
		["models/jaanus/wiretool/wiretool_input.mdl"] = true,
		["models/jaanus/wiretool/wiretool_output.mdl"] = true,
		["models/jaanus/wiretool/wiretool_pixel_lrg.mdl"] = true,
		["models/jaanus/wiretool/wiretool_pixel_med.mdl"] = true,
		["models/jaanus/wiretool/wiretool_pixel_sml.mdl"] = true,
		["models/jaanus/wiretool/wiretool_range.mdl"] = true,
		["models/jaanus/wiretool/wiretool_siren.mdl"] = true,
		["models/jaanus/wiretool/wiretool_speed.mdl"] = true,
		["models/jaanus/wiretool/wiretool_waypoint.mdl"] = true,
		["models/killa-x/speakers/speaker_medium.mdl"] = true,
		["models/killa-x/speakers/speaker_small.mdl"] = true,
		["models/kobilica/capacatitor.mdl"] = true,
		["models/kobilica/lowpolygate.mdl"] = true,
		["models/kobilica/relay.mdl"] = true,
		["models/kobilica/transistor.mdl"] = true,
		["models/kobilica/transistorsmall.mdl"] = true,
		["models/kobilica/value.mdl"] = true,
		["models/kobilica/wiremonitorbig.mdl"] = true,
		["models/kobilica/wiremonitorrt.mdl"] = true,
		["models/kobilica/wiremonitorrtbig.mdl"] = true,
		["models/kobilica/wiremonitorsmall.mdl"] = true,
		["models/led.mdl"] = true,
		["models/led2.mdl"] = true,
		["models/segment.mdl"] = true,
		["models/segment2.mdl"] = true,
		["models/segment3.mdl"] = true,
		["models/wingf0x/altisasocket.mdl"] = true,
		["models/wingf0x/ethernetplug.mdl"] = true,
		["models/wingf0x/ethernetsocket.mdl"] = true,
		["models/wingf0x/hdmiplug.mdl"] = true,
		["models/wingf0x/hdmisocket.mdl"] = true,
		["models/wingf0x/isaplug.mdl"] = true,
		["models/wingf0x/isasocket.mdl"] = true,
	}

	function ACF.IsWireModel(Entity)
		return WireModels[Entity:GetModel()]
	end
end
