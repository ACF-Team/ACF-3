local Storyboard = Ponder.API.NewStoryboard("acf", "weapons", "simple-gun")
Storyboard:WithName("acf.storyboards.weapons.simple_gun")
Storyboard:WithModelIcon("models/machinegun/machinegun_20mm.mdl")
Storyboard:WithDescription("#acf.storyboards.weapons.simple_gun.desc")

local Chapter1 = Storyboard:Chapter("#acf.storyboards.weapons.simple_gun.chapter1")

Chapter1:AddInstruction("Delay", {Length = 0.75})

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainGun",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter1.explain_gun"),
    Time = 0,
    Position = Vector(0, 0, 10)
})

Chapter1:AddInstruction("Delay", {Length = 2.5})
Chapter1:AddInstruction("ShowToolgun", {Length = .75, Tool = language.GetPhrase("tool.acf_menu.menu_name")})
Chapter1:AddInstruction("ClickToolgun", {Time = 1})
Chapter1:AddInstruction("Delay", {Length = 1})
Chapter1:AddInstruction("PlaceModel", {
    Name = "Gun",
    IdentifyAs = "acf_gun",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Position = Vector(0, 0, 10),
})
Chapter1:AddInstruction("Delay", {Length = 1.75})
Chapter1:AddInstruction("HideText", {Name = "ExplainGun", Length = 0.4})
Chapter1:AddInstruction("Delay", {Length = 1.25})
Chapter1:AddInstruction("TransformModel", {Target = "Gun", Position = Vector(0, 0, 48), Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 1.5})

local AmmoPos = Vector(20, -20, 0)

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainAmmo",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter1.explain_ammo"),
    Time = 0,
    Position = AmmoPos
})

Chapter1:AddInstruction("Delay", {Length = 2.5})
Chapter1:AddInstruction("MoveToolgunTo", {Time = 0.75, Position = AmmoPos})
Chapter1:AddInstruction("ClickToolgun", {Time = 1.25})
Chapter1:AddInstruction("Delay", {Length = 1})
Chapter1:AddInstruction("PlaceModel", {
    Name = "Ammo",
    IdentifyAs = "acf_ammo",
    Model = "models/holograms/hq_rcube_thin.mdl",
    Position = AmmoPos + Vector(0, 0, 10),
    Scale = Vector(1.5, 1.5, 1.5)
})
Chapter1:AddInstruction("MaterialModel", {Target = "Ammo", Material = "phoenix_storms/future_vents"})
Chapter1:AddInstruction("Delay", {Length = 1})
Chapter1:AddInstruction("HideText", {Name = "ExplainAmmo", Length = 0.4})
Chapter1:AddInstruction("Delay", {Length = 0.4})

local Chapter2 = Storyboard:Chapter(language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter2"))

Chapter2:AddInstruction("ShowText", {
    Name = "ExplainLinking",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter2.explain_linking"),
    Time = 0,
    Position = AmmoPos + Vector(0, 0, 10),
    ParentTo = "Ammo"
})
Chapter2:AddInstruction("Delay", {Length = 2})

local LinkingTime = Chapter2:AddInstruction("ACF Menu", {
    Children = {"Ammo"},
    Target = "Gun",
    Easing = math.ease.InOutQuad
})
Chapter2:AddInstruction("HideToolgun", {Time = LinkingTime, Length = .5})
Chapter2:AddInstruction("Delay", {Length = 1.75})
Chapter2:AddInstruction("HideText", {Name = "ExplainLinking", Time = 1})
Chapter2:AddInstruction("Delay", {Length = 2})

local Chapter3 = Storyboard:Chapter(language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter3"))

Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWiring1",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter3.explain_wiring1"),
    Time = 0,
    Position = Vector(0, 0, 0)
})
Chapter3:AddInstruction("HideText", {Name = "ExplainWiring1", Time = 4.5})
Chapter3:AddInstruction("Delay", {Length = 5})

local ButtonPos = Vector(-20, 20, 0)

Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWiring2",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter3.explain_wiring2"),
    Time = 0,
    Position = ButtonPos
})
Chapter3:AddInstruction("Delay", {Length = 1.5})
Chapter3:AddInstruction("ShowToolgun", {Length = .5, Tool = "Button Tool (Wire)"})
Chapter3:AddInstruction("Delay", {Length = 0.75})
Chapter3:AddInstruction("MoveToolgunTo", {Time = 0.5, Position = ButtonPos})
Chapter3:AddInstruction("Delay", {Length = 0.75})
Chapter3:AddInstruction("ClickToolgun", {Time = 1})
Chapter3:AddInstruction("Delay", {Length = 1})
Chapter3:AddInstruction("PlaceModel", {
    Name = "Button",
    IdentifyAs = "gmod_wire_button",
    Model = "models/cheeze/buttons/button_fire.mdl",
    Position = ButtonPos,
})
Chapter3:AddInstruction("Delay", {Length = 3})
Chapter3:AddInstruction("HideText", {Name = "ExplainWiring2", Time = 0})
Chapter3:AddInstruction("HideToolgun", {Time = 0.5})

Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWiring3",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter3.explain_wiring3"),
    Time = 0,
    Position = Vector(0, 0, 0)
})
Chapter3:AddInstruction("Delay", {Length = 1.5})
Chapter3:AddInstruction("ShowToolgun", {Length = 0, Tool = "Wiring Tool"})
Chapter3:AddInstruction("Delay", {Length = 3})
Chapter3:AddInstruction("HideText", {Name = "ExplainWiring3", Time = 0})
Chapter3:AddInstruction("Delay", {Length = 1})

Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWiring4",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter3.explain_wiring4"),
    Time = 0,
    Position = Vector(20, 0, 0),
    ParentTo = "Gun"
})
Chapter3:AddInstruction("MoveToolgunTo", {Time = 2.5, Position = Vector(0, 0, 48)})
Chapter3:AddInstruction("ClickToolgun", {Time = 3})
Chapter3:AddInstruction("MoveToolgunTo", {Time = 3.5, Position = ButtonPos})
Chapter3:AddInstruction("ClickToolgun", {Time = 4})
Chapter3:AddInstruction("HideText", {Name = "ExplainWiring4", Time = 4.5})

Chapter3:AddInstruction("ShowText", {
    Name = "ExplainWiring5",
    Text = language.GetPhrase("acf.storyboards.weapons.simple_gun.chapter3.explain_wiring5"),
    Time = 5,
    ParentTo = "Button"
})
Chapter3:AddInstruction("HideToolgun", {Time = 5.5})
Chapter3:AddInstruction("SetSequence", {Time = 6.5, Name = "Gun", Sequence = "shoot"})
Chapter3:AddInstruction("PlaySound", {Time = 6.5, Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter3:AddInstruction("HideText", {Name = "ExplainWiring5", Time = 9})