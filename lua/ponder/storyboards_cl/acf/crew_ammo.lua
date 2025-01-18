local Storyboard = Ponder.API.NewStoryboard("acf", "crew", "crew-ammo")
Storyboard:WithName("Crew Ammunition")
Storyboard:WithModelIcon("models/munitions/round_100mm_shot.mdl")
Storyboard:WithDescription("Learn about ammunition restocking and reload mechanics")
Storyboard:WithIndexOrder(1)

local Tank = ACF.PonderModelCaches.TankSkeleton

local Chapter1 = Storyboard:Chapter("Introduction")
Chapter1:AddInstruction("MoveCameraLookAt", {Length = 0, Angle = 60, Height = 1000, Distance = 2000})
Chapter1:AddInstruction("Delay", {Length = 2})
Chapter1:AddInstruction("HideText", {Name = "Explain"})
local T1 = Chapter1:AddInstruction("PlaceModels", {
    Length = 2,
    Models = Tank
})
Chapter1:AddDelay(T1 + 1)
Chapter1:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Ammo crates have a new menu option called \"priority\" (stage) which sets which crates the loader should try to load from first.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter1:AddInstruction("Delay", {Length = 6})
Chapter1:AddInstruction("HideText", {Name = "Explain"})
Chapter1:AddInstruction("Delay", {Length = 2})
Chapter1:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "A Loader's reload time is based on their distance to the gun and the crate.\nTry to make stage 1 the closest.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter1:AddInstruction("Delay", {Length = 6})
Chapter1:AddInstruction("HideText", {Name = "Explain"})
Chapter1:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "<font=DefaultSmall>Loader\n[Ready]</font>",
    Position = Vector(0, 0, 36),
    ParentTo = "Loader"
})
Chapter1:AddInstruction("Delay", {Length = 2})

local CrateStr = "<font=DefaultSmall>Type: %s\nStage: %d\nCount: %d\nTime: %ds\n[%s]\n</font>"
local CrateData = {
    AmmoCrate1 = {
        Type = "AP",
        TextID = "Explain3",
        Stage = 1,
        Count = 2,
        Time = 10
    },
    AmmoCrate2 = {
        Type = "AP",
        TextID = "Explain4",
        Stage = 2,
        Count = 2,
        Time = 12
    },
    AmmoCrate3 = {
        Type = "AP",
        TextID = "Explain5",
        Stage = 3,
        Count = 2,
        Time = 18
    },
    AmmoCrate4 = {
        Type = "AP",
        TextID = "Explain6",
        Stage = 4,
        Count = 2,
        Time = 20
    }
}

for k, v in pairs(CrateData) do
    Chapter1:AddInstruction("ShowText", {
        Name = v.TextID,
        Text = string.format(CrateStr, v.Type, v.Stage, v.Count, v.Time, ""),
        ParentTo = k
    })
end

local function Fire(chapter, current, time, loadtime)
    -- Fire gun
    chapter:AddInstruction("PlaySound", {Time = time, Sound = "acf_base/weapons/cannon_new.mp3"})
    chapter:AddInstruction("SetSequence", {Time = time, Name = "Gun", Sequence = "shoot"})

    -- Ammo goes down
    CrateData[current].Count = math.Max(CrateData[current].Count - 1, 0)
    chapter:AddInstruction("ChangeText", {
        Time = time + 0.5,
        Name = CrateData[current].TextID,
        Text = string.format(CrateStr, CrateData[current].Type, CrateData[current].Stage, CrateData[current].Count, CrateData[current].Time, "")
    })

    chapter:AddInstruction("ChangeText", {
        Time = time + 0.5,
        Name = "Explain2",
        Text = "<font=DefaultSmall>Loader\n[Loading...]</font>",
    })

    chapter:AddInstruction("ChangeText", {
        Time = time + loadtime,
        Name = "Explain2",
        Text = "<font=DefaultSmall>Loader\n[Ready]</font>",
    })

    return time + loadtime + 1
end

local function Restock(chapter, current, supplier, time)
    CrateData[supplier].Count = math.Min(CrateData[supplier].Count + 1, 2)
    CrateData[supplier].Count = math.Max(CrateData[supplier].Count - 1, 0)
    chapter:AddInstruction("ChangeText", {
        Name = CrateData[current].TextID,
        Text = string.format(CrateStr, CrateData[current].Type, CrateData[current].Stage, CrateData[current].Count, CrateData[current].Time, "")
    })
    chapter:AddInstruction("ChangeText", {
        Name = CrateData[supplier].TextID,
        Text = string.format(CrateStr, CrateData[supplier].Type, CrateData[supplier].Stage, CrateData[supplier].Count, CrateData[supplier].Time, "")
    })
end

local function Cycle(chapter, current, supplier)
    chapter:AddInstruction("Delay", {Length = 2})
    -- Fire
    chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
    chapter:AddInstruction("SetSequence", {Name = "Gun", Sequence = "shoot"})
    chapter:AddInstruction("Delay", {Length = 1})
    -- Ammo goes down
    CrateData[current].Count = CrateData[current].Count - 1
    chapter:AddInstruction("ChangeText", {
        Name = CrateData[current].TextID,
        Text = string.format(CrateStr, CrateData[current].Type, CrateData[current].Stage, CrateData[current].Count, CrateData[current].Time, "")
    })
    chapter:AddInstruction("Delay", {Length = 1})
    -- Loader starts loading
    chapter:AddInstruction("ChangeText", {
        Name = "Explain2",
        Text = "<font=DefaultSmall>Loader\n[Loading...]</font>",
    })
    chapter:AddInstruction("Delay", {Length = 1})
    -- Crate starts restocking
    chapter:AddInstruction("ChangeText", {
        Name = CrateData[current].TextID,
        Text = string.format(CrateStr, CrateData[current].Type, CrateData[current].Stage, CrateData[current].Count, CrateData[current].Time, "Restocking...")
    })
    chapter:AddInstruction("ChangeText", {
        Name = CrateData[supplier].TextID,
        Text = string.format(CrateStr, CrateData[supplier].Type, CrateData[supplier].Stage, CrateData[supplier].Count, CrateData[supplier].Time, "Supplying...")
    })
    chapter:AddInstruction("FlashModel", {Reps = 2, Models = {supplier}})
    chapter:AddInstruction("Delay", {Length = 1})
    -- Crates swap ammo counts
    CrateData[current].Count, CrateData[supplier].Count = CrateData[supplier].Count, CrateData[current].Count

    chapter:AddInstruction("Delay", {Length = 1})
    chapter:AddInstruction("ChangeText", {
        Name = "Explain2",
        Text = "<font=DefaultSmall>Loader\n[Ready]</font>",
    })
end

local Chapter2 = Storyboard:Chapter("Stage 1 - 2")
Cycle(Chapter2, "AmmoCrate1", "AmmoCrate2")
Cycle(Chapter2, "AmmoCrate1", "AmmoCrate2")

local Chapter3 = Storyboard:Chapter("Stage 1 - 3")
Cycle(Chapter3, "AmmoCrate1", "AmmoCrate3")
Cycle(Chapter3, "AmmoCrate1", "AmmoCrate3")

local Chapter4 = Storyboard:Chapter("Stage 1 - 4")
Cycle(Chapter4, "AmmoCrate1", "AmmoCrate4")
Cycle(Chapter4, "AmmoCrate1", "AmmoCrate4")