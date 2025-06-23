local Storyboard = Ponder.API.NewStoryboard("acf", "mobility", "engines-gearboxes")
Storyboard:WithName("acf.storyboards.mobility.engines_gearboxes")
Storyboard:WithModelIcon("models/engines/v8s.mdl")
Storyboard:WithDescription("#acf.storyboards.mobility.engines_gearboxes.desc")

local Chapter1 = Storyboard:Chapter("#acf.storyboards.mobility.engines_gearboxes.chapter1")

Chapter1:AddInstruction("Delay", {Length = 0.75})

local EnginePos = Vector(-20, 0, 10)

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainEngine",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter1.explain_engine"),
    Time = 0,
    Position = EnginePos
})

Chapter1:AddInstruction("Delay", {Length = 2.5})
Chapter1:AddInstruction("ShowToolgun", {Length = 0.75, Tool = language.GetPhrase("tool.acf_menu.menu_name")})
Chapter1:AddInstruction("MoveToolgunTo", {Time = 1.75, Position = EnginePos})
Chapter1:AddInstruction("ClickToolgun", {Time = 2.25})
Chapter1:AddInstruction("Delay", {Length = 2.5})
Chapter1:AddInstruction("PlaceModel", {
    Name = "Engine",
    IdentifyAs = "acf_engine",
    Model = "models/engines/v8s.mdl",
    Position = EnginePos
})
Chapter1:AddInstruction("Delay", {Length = 1.75})
Chapter1:AddInstruction("HideText", {Name = "ExplainEngine", Length = 0.4})
Chapter1:AddInstruction("Delay", {Length = 1.25})
Chapter1:AddInstruction("TransformModel", {Target = "Engine", Position = EnginePos + Vector(0, 0, 48), Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 1.5})

local FuelPos = Vector(-20, -20, 0)

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainFuel1",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter1.explain_fuel1"),
    Time = 0,
    Position = FuelPos
})

Chapter1:AddInstruction("Delay", {Length = 2.5})
Chapter1:AddInstruction("MoveToolgunTo", {Time = 0.75, Position = FuelPos})
Chapter1:AddInstruction("ClickToolgun", {Time = 1.25})
Chapter1:AddInstruction("Delay", {Length = 1})
Chapter1:AddInstruction("PlaceModel", {
    Name = "Fuel",
    IdentifyAs = "acf_fueltank",
    Model = "models/holograms/hq_rcube.mdl",
    Position = FuelPos + Vector(0, 0, 10),
    Scale = Vector(1.5, 1.5, 1.5)
})
Chapter1:AddInstruction("MaterialModel", {Target = "Fuel", Material = "models/props_canal/metalcrate001d"})
Chapter1:AddInstruction("Delay", {Length = 1})
Chapter1:AddInstruction("HideText", {Name = "ExplainFuel1", Length = 0.4})
Chapter1:AddInstruction("Delay", {Length = 0.4})

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainFuel2",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter1.explain_fuel2"),
    Time = 0,
    Position = FuelPos
})
Chapter1:AddInstruction("Delay", {Length = 3.75})
Chapter1:AddInstruction("HideText", {Name = "ExplainFuel2", Length = 0.4})
Chapter1:AddInstruction("Delay", {Length = 1})

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainFuel3",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter1.explain_fuel3"),
    Time = 0,
    Position = FuelPos
})
Chapter1:AddInstruction("Delay", {Length = 2})

local LinkingTime1 = Chapter1:AddInstruction("ACF Menu", {
    Children = {"Fuel"},
    Target = "Engine",
    Easing = math.ease.InOutQuad
})
Chapter1:AddInstruction("HideToolgun", {Time = LinkingTime1, Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 2})
Chapter1:AddInstruction("HideText", {Name = "ExplainFuel3", Time = 1})
Chapter1:AddInstruction("Delay", {Length = 2})

local Chapter2 = Storyboard:Chapter("#acf.storyboards.mobility.engines_gearboxes.chapter2")
local GearboxPos = Vector(30, 0, 10)

Chapter2:AddInstruction("Delay", {Length = 1})
Chapter2:AddInstruction("ShowText", {
    Name = "ExplainGearbox",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter2.explain_gearbox"),
    Time = 0,
    Position = GearboxPos
})

Chapter2:AddInstruction("Delay", {Length = 2.5})
Chapter2:AddInstruction("ShowToolgun", {Length = 0.75, Tool = language.GetPhrase("tool.acf_menu.menu_name")})
Chapter2:AddInstruction("MoveToolgunTo", {Time = 1.75, Position = GearboxPos})
Chapter2:AddInstruction("ClickToolgun", {Time = 2.25})
Chapter2:AddInstruction("Delay", {Length = 2.5})
Chapter2:AddInstruction("PlaceModel", {
    Name = "Gearbox",
    IdentifyAs = "acf_gearbox",
    Model = "models/engines/transaxial_s.mdl",
    Position = GearboxPos,
    Scale = Vector(1.5, 1.5, 1.5)
})
Chapter2:AddInstruction("Delay", {Length = 1.75})
Chapter2:AddInstruction("HideText", {Name = "ExplainGearbox", Length = 0.4})
Chapter2:AddInstruction("Delay", {Length = 1.25})
Chapter2:AddInstruction("TransformModel", {Target = "Gearbox", Position = GearboxPos + Vector(0, 0, 48), Length = 0.5})
Chapter2:AddInstruction("Delay", {Length = 1.5})

Chapter2:AddInstruction("ShowText", {
    Name = "ExplainDirection1",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter2.explain_direction1"),
    Time = 0,
    ParentTo = "Engine"
})
Chapter2:AddInstruction("Delay", {Length = 2.5})
Chapter2:AddInstruction("TransformModel", {Target = "Engine", Rotation = Angle(0, 180, 0), Length = 0.75})
Chapter2:AddInstruction("Delay", {Length = 1.75})
Chapter2:AddInstruction("HideText", {Name = "ExplainDirection1", Length = 0.4})
Chapter2:AddInstruction("Delay", {Length = 1.5})

Chapter2:AddInstruction("ShowText", {
    Name = "ExplainDirection2",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter2.explain_direction2"),
    Time = 0,
    ParentTo = "Gearbox"
})
Chapter2:AddInstruction("Delay", {Length = 2.5})
Chapter2:AddInstruction("TransformModel", {Target = "Gearbox", Rotation = Angle(0, -180, 0), Length = 0.75})
Chapter2:AddInstruction("Delay", {Length = 1.75})
Chapter2:AddInstruction("HideText", {Name = "ExplainDirection2", Length = 0.4})
Chapter2:AddInstruction("Delay", {Length = 1})

Chapter2:AddInstruction("ShowText", {
    Name = "ExplainDirection3",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter2.explain_direction3"),
    Time = 0,
    ParentTo = "Gearbox"
})
Chapter2:AddInstruction("Delay", {Length = 2.5})

local LinkingTime2 = Chapter2:AddInstruction("ACF Menu", {
    Children = {"Engine"},
    Target = "Gearbox",
    Easing = math.ease.InOutQuad
})
Chapter2:AddInstruction("HideToolgun", {Time = LinkingTime2, Length = 0.5})
Chapter2:AddInstruction("Delay", {Length = 2})
Chapter2:AddInstruction("HideText", {Name = "ExplainDirection3", Time = 1})
Chapter2:AddInstruction("Delay", {Length = 2})

local Chapter3 = Storyboard:Chapter("#acf.storyboards.mobility.engines_gearboxes.chapter3")
local WheelPos = Vector(0, 30, 20)

Chapter3:AddInstruction("Delay", {Length = 1})
Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWheels1",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter3.explain_wheels1"),
    Time = 0,
    Position = WheelPos
})
Chapter3:AddInstruction("Delay", {Length = 2.5})

Chapter3:AddInstruction("PlaceModel", {
    Name = "Wheel",
    IdentifyAs = "prop_physics\nmodels/xeon133/racewheelskinny/race-wheel-30_s.mdl",
    Model = "models/xeon133/racewheelskinny/race-wheel-30_s.mdl",
    Position = WheelPos
})
Chapter3:AddInstruction("Delay", {Length = 1.5})
Chapter3:AddInstruction("HideText", {Name = "ExplainWheels1", Length = 0.4})
Chapter3:AddInstruction("Delay", {Length = 1})

Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWheels2",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter3.explain_wheels2"),
    Time = 0,
    ParentTo = "Gearbox"
})
Chapter3:AddInstruction("Delay", {Length = 2.5})

Chapter3:AddInstruction("TransformModel", {Target = "Wheel", Position = WheelPos + Vector(30, 10, 48)})
Chapter3:AddInstruction("Delay", {Length = 1.5})
Chapter3:AddInstruction("HideText", {Name = "ExplainWheels2", Length = 0.4})
Chapter3:AddInstruction("Delay", {Length = 1})

Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWheels3",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter3.explain_wheels3"),
    Time = 0,
    ParentTo = "Wheel"
})
Chapter3:AddInstruction("Delay", {Length = 1.5})
Chapter3:AddInstruction("ShowToolgun", {Length = 0.75, Tool = language.GetPhrase("tool.acf_menu.menu_name")})
Chapter3:AddInstruction("Delay", {Length = 1})

local LinkingTime3 = Chapter3:AddInstruction("ACF Menu", {
    Children = {"Gearbox"},
    Target = "Wheel",
    Easing = math.ease.InOutQuad
})
Chapter3:AddInstruction("HideToolgun", {Time = LinkingTime3, Length = 0.5})
Chapter3:AddInstruction("Delay", {Length = 2})
Chapter3:AddInstruction("HideText", {Name = "ExplainWheels3", Time = 1})
Chapter3:AddInstruction("Delay", {Length = 2})

local Chapter4 = Storyboard:Chapter("#acf.storyboards.mobility.engines_gearboxes.chapter4")

Chapter4:AddInstruction("Delay", {Length = 1})
Chapter4:AddInstruction("ShowText", {
    Name = "ExplainWiring1",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter4.explain_wiring1"),
    Time = 0,
    Position = Vector(0, 0, 0)
})
Chapter4:AddInstruction("Delay", {Length = 5.5})
Chapter4:AddInstruction("HideText", {Name = "ExplainWiring1", Length = 0.4})
Chapter4:AddInstruction("Delay", {Length = 1.5})

local ButtonPos = Vector(-20, 20, 0)

Chapter4:AddInstruction("ShowText", {
    Name = "ExplainWiring2",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter4.explain_wiring2"),
    Time = 0,
    Position = ButtonPos
})
Chapter4:AddInstruction("Delay", {Length = 1.5})
Chapter4:AddInstruction("ShowToolgun", {Length = .5, Tool = "Button Tool (Wire)"})
Chapter4:AddInstruction("Delay", {Length = 0.75})
Chapter4:AddInstruction("MoveToolgunTo", {Time = 0.5, Position = ButtonPos})
Chapter4:AddInstruction("Delay", {Length = 0.75})
Chapter4:AddInstruction("ClickToolgun", {Time = 1})
Chapter4:AddInstruction("Delay", {Length = 1})
Chapter4:AddInstruction("PlaceModel", {
    Name = "Button",
    IdentifyAs = "gmod_wire_button",
    Model = "models/cheeze/buttons/button_start.mdl",
    Position = ButtonPos,
})
Chapter4:AddInstruction("Delay", {Length = 3})
Chapter4:AddInstruction("HideText", {Name = "ExplainWiring2", Time = 0})
Chapter4:AddInstruction("HideToolgun", {Time = 0.5})

local ConstantPos = Vector(-20, 30, 0)

Chapter4:AddInstruction("ShowText", {
    Name = "ExplainWiring3",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter4.explain_wiring3"),
    Time = 0,
    Position = ConstantPos
})
Chapter4:AddInstruction("Delay", {Length = 1.5})
Chapter4:AddInstruction("ShowToolgun", {Length = .5, Tool = "Value Tool (Wire)"})
Chapter4:AddInstruction("Delay", {Length = 0.75})
Chapter4:AddInstruction("MoveToolgunTo", {Time = 0.5, Position = ConstantPos})
Chapter4:AddInstruction("Delay", {Length = 0.75})
Chapter4:AddInstruction("ClickToolgun", {Time = 1})
Chapter4:AddInstruction("Delay", {Length = 1})
Chapter4:AddInstruction("PlaceModel", {
    Name = "ConstantValue",
    IdentifyAs = "gmod_wire_value",
    Model = "models/kobilica/value.mdl",
    Position = ConstantPos,
})
Chapter4:AddInstruction("Delay", {Length = 3})
Chapter4:AddInstruction("HideText", {Name = "ExplainWiring3", Time = 0})
Chapter4:AddInstruction("HideToolgun", {Time = 0.5})
Chapter4:AddInstruction("Delay", {Length = 2})

local Chapter5 = Storyboard:Chapter("#acf.storyboards.mobility.engines_gearboxes.chapter5")

Chapter5:AddInstruction("ShowText", {
    Name = "ExplainWiring4",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter5.explain_wiring4"),
    Time = 0,
    Position = Vector(0, 0, 0)
})
Chapter5:AddInstruction("Delay", {Length = 1.5})
Chapter5:AddInstruction("ShowToolgun", {Length = 0, Tool = "Wiring Tool"})
Chapter5:AddInstruction("Delay", {Length = 3})
Chapter5:AddInstruction("HideText", {Name = "ExplainWiring4", Time = 0})
Chapter5:AddInstruction("Delay", {Length = 1})

Chapter5:AddInstruction("ShowText", {
    Name = "ExplainWiring5",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter5.explain_wiring5"),
    Time = 0,
    ParentTo = "Button"
})
Chapter5:AddInstruction("MoveToolgunTo", {Time = 2.5, Position = EnginePos + Vector(0, 0, 58)})
Chapter5:AddInstruction("ClickToolgun", {Time = 3})
Chapter5:AddInstruction("MoveToolgunTo", {Time = 3.5, Position = ButtonPos})
Chapter5:AddInstruction("ClickToolgun", {Time = 4})
Chapter5:AddInstruction("HideText", {Name = "ExplainWiring5", Time = 4.5})
Chapter5:AddInstruction("Delay", {Length = 5.5})

Chapter5:AddInstruction("ShowText", {
    Name = "ExplainWiring6",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter5.explain_wiring6"),
    Time = 0,
    ParentTo = "ConstantValue"
})
Chapter5:AddInstruction("MoveToolgunTo", {Time = 2.5, Position = EnginePos + Vector(0, 0, 58)})
Chapter5:AddInstruction("ClickToolgun", {Time = 3})
Chapter5:AddInstruction("MoveToolgunTo", {Time = 3.5, Position = ConstantPos})
Chapter5:AddInstruction("ClickToolgun", {Time = 4})
Chapter5:AddInstruction("HideText", {Name = "ExplainWiring6", Time = 4.5})
Chapter5:AddInstruction("Delay", {Length = 5.5})

Chapter5:AddInstruction("ShowText", {
    Name = "ExplainWiring7",
    Text = language.GetPhrase("acf.storyboards.mobility.engines_gearboxes.chapter5.explain_wiring7"),
    Time = 0,
    ParentTo = "Button"
})
Chapter5:AddInstruction("HideToolgun", {Time = 2.5})
Chapter5:AddInstruction("PlaySound", {Time = 3.5, Sound = "acf_base/engines/v8_petrolsmall.wav", Length = 4, Volume = 0.75})
Chapter5:AddInstruction("TransformModel", {Time = 3.5, Target = "Wheel", Rotation = Angle(7000, 0, 0), Length = 4})
Chapter5:AddInstruction("HideText", {Name = "ExplainWiring7", Time = 7.5})