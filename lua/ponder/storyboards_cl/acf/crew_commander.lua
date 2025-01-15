local Storyboard = Ponder.API.NewStoryboard("acf", "crew", "crew-commander")
Storyboard:WithMenuName("Commander Crew Guide")
Storyboard:WithPlaybackName("Crew - Commander Guide")
Storyboard:WithModelIcon("models/props_lab/citizenradio.mdl")
Storyboard:WithDescription("Learn how to use commanders")

-- Place crew 1
local Chapter1 = Storyboard:Chapter()
Chapter1:AddInstruction("PlaceModel", {
    Name = "Crew",
    IdentifyAs = "acf_crew (sitting)",
    Model = "models/chairs_playerstart/sitpose.mdl",
    Position = Vector(0, 0, 10),
    ComeFrom = Vector(0, 0, 32)
})
Chapter1:AddInstruction("MaterialModel", {Target = "Crew", Material = "sprops/trans/lights/light_plastic"})
Chapter1:AddInstruction("Delay", {Length = 0.5})

-- Place crew 2
Chapter1:AddInstruction("PlaceModel", {
    Name = "Crew2",
    IdentifyAs = "acf_crew (standing)",
    Model = "models/chairs_playerstart/standingpose.mdl",
    Position = Vector(0, 0, 10),
    ComeFrom = Vector(0, 0, 32),
    ParentTo = "TurretRing"
})
Chapter1:AddInstruction("MaterialModel", {Target = "Crew2", Material = "sprops/trans/lights/light_plastic"})
Chapter1:AddInstruction("Delay", {Length = 0.75})

Chapter1:AddInstruction("ShowText", {
    Name = "Explain",
    Text = language.GetPhrase("acf.storyboards.turrets.turret_parenting.chapter1.explain_hring"),
    Time = 0,
    Position = Vector(0, 0, 10)
})