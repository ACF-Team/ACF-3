--ACF missile list.
--Obviously none of this is balanced yet.

AddCSLuaFile("acf/shared/acfmissilelist.lua")

local RackTable = {}

local RackSingle = {}
    RackSingle.id = "rack_single"
    RackSingle.ent = "acf_rack"
    RackSingle.type = "Missiles"
    RackSingle.name = "Missile Rack - Single"
    RackSingle.desc = "Missile racks fire guided or unguided missiles with HEAT or HE warheads."
    RackSingle.model = "models/missiles/rack_single.mdl"
    RackSingle.shots = 1
    RackSingle.weight = 500
    RackSingle.maxweight = 500
	RackSingle.armored = false
    if ( CLIENT ) then
        RackSingle.guicreate = (function( Panel, Table ) ACFRackGUICreate ( Table ) end or nil)
        RackSingle.guiupdate = function() return end
    end
RackTable["rack_single"] = RackSingle

local RackDouble = {}
    RackDouble.id = "rack_double"
    RackDouble.ent = "acf_rack"
    RackDouble.type = "Missiles"
    RackDouble.name = "Missile Rack - Double"
    RackDouble.desc = "Missile racks fire guided or unguided missiles with HEAT or HE warheads."
    RackDouble.model = "models/missiles/rack_double.mdl"
    RackDouble.shots = 2
    RackDouble.weight = 500
    RackDouble.maxweight = 300
	RackDouble.armored = false
    if ( CLIENT ) then
        RackDouble.guicreate = (function( Panel, Table ) ACFRackGUICreate ( Table ) end or nil)
        RackDouble.guiupdate = function() return end
    end
RackTable["rack_double"] = RackDouble

local RackQuad = {}
    RackQuad.id = "rack_quad"
    RackQuad.ent = "acf_rack"
    RackQuad.type = "Missiles"
    RackQuad.name = "Missile Rack - Quad"
    RackQuad.desc = "Missile racks fire guided or unguided missiles with HEAT or HE warheads."
    RackQuad.model = "models/missiles/rack_quad.mdl"
    RackQuad.shots = 4
    RackQuad.weight = 500
    RackQuad.maxweight = 150
	RackQuad.armored = false
    if ( CLIENT ) then
        RackQuad.guicreate = (function( Panel, Table ) ACFRackGUICreate ( Table ) end or nil)
        RackQuad.guiupdate = function() return end
    end
RackTable["rack_quad"] = RackQuad

local Minipod = {}
    Minipod.id = "minipod"
    Minipod.ent = "acf_rack"
    Minipod.type = "Missiles"
    Minipod.name = "16 Shot Rocket Pod"
    Minipod.desc = "Rocket pods fire smaller missiles."
    Minipod.model = "models/missiles/minipod.mdl"
    Minipod.shots = 16
    Minipod.weight = 500
    Minipod.maxweight = 30
	Minipod.armored = true
    if ( CLIENT ) then
        Minipod.guicreate = (function( Panel, Table ) ACFRackGUICreate ( Table ) end or nil)
        Minipod.guiupdate = function() return end
    end
RackTable["minipod"] = Minipod

list.Set( "ACFEnts", "Missiles", RackTable )

-- missile list

local Missiles = {}

local FFAR = {}
    FFAR.id = "ffar"
    FFAR.model = "models/missiles/70mmFFAR.mdl"
    FFAR.name = "70mm FFAR"
    FFAR.mechanics = {}
        FFAR.mechanics.maxweight = 30
        FFAR.mechanics.maxengine = 10       -- maximum engine kg
        FFAR.mechanics.maxwarhead = 30      -- maximum warhead kg
        FFAR.mechanics.eiwtmod = 1          -- engine impulse weight mod (kg/(N/s))
        FFAR.mechanics.ecwtmod = 1          -- engine cutoff weight mod (kg/s)
        FFAR.mechanics.tcwtmod = 1          -- tracking cone weight mod (kg/deg)
        FFAR.mechanics.trwtmod = 1          -- turning radius weight mod (kg/(deg/s))
        FFAR.mechanics.drag = 1             -- drag
        FFAR.mechanics.gldrag = 1           -- gliding drag.
        FFAR.mechanics.tidrag = 1           -- turn induced drag
        FFAR.mechanics.guidanceweight = 1   -- weight of an included guidance system (GPS/IR/Radar)
Missiles["ffar"] = FFAR

local Sidewinder = {}
    Sidewinder.id = "sidewinder"
    Sidewinder.model = "models/missiles/aim9.mdl"
    Sidewinder.name = "AIM-9 Sidewinder"
    Sidewinder.mechanics = {}
        Sidewinder.mechanics.maxweight = 120
        Sidewinder.mechanics.maxengine = 10  
        Sidewinder.mechanics.maxwarhead = 30 
        Sidewinder.mechanics.eiwtmod = 1 
        Sidewinder.mechanics.ecwtmod = 1 
        Sidewinder.mechanics.tcwtmod = 1 
        Sidewinder.mechanics.trwtmod = 1 
        Sidewinder.mechanics.drag = 1 
        Sidewinder.mechanics.gldrag = 1
        Sidewinder.mechanics.tidrag = 1
        Sidewinder.mechanics.guidanceweight = 1
Missiles["sidewinder"] = Sidewinder

local ATGM = {}
    ATGM.id = "atgm"
    ATGM.model = "models/missiles/micro.mdl"
    ATGM.name = "ATGM"
    ATGM.mechanics = {}
        ATGM.mechanics.maxweight = 150
        ATGM.mechanics.maxengine = 10
        ATGM.mechanics.maxwarhead = 80
        ATGM.mechanics.eiwtmod = 1
        ATGM.mechanics.ecwtmod = 1
        ATGM.mechanics.tcwtmod = 1
        ATGM.mechanics.trwtmod = 1
        ATGM.mechanics.drag = 1
        ATGM.mechanics.gldrag = 1
        ATGM.mechanics.tidrag = 1
        ATGM.mechanics.guidanceweight = 1
Missiles["atgm"] = ATGM

local AMRAAM = {}
    AMRAAM.id = "amraam"
    AMRAAM.model = "models/missiles/aim120.mdl"
    AMRAAM.name = "AIM-120 AMRAAM"
    AMRAAM.mechanics = {}
        AMRAAM.mechanics.maxweight = 250
        AMRAAM.mechanics.maxengine = 10      
        AMRAAM.mechanics.maxwarhead = 30     
        AMRAAM.mechanics.eiwtmod = 1         
        AMRAAM.mechanics.ecwtmod = 1         
        AMRAAM.mechanics.tcwtmod = 1         
        AMRAAM.mechanics.trwtmod = 1         
        AMRAAM.mechanics.drag = 1            
        AMRAAM.mechanics.gldrag = 1          
        AMRAAM.mechanics.tidrag = 1          
        AMRAAM.mechanics.guidanceweight = 1  
Missiles["amraam"] = AMRAAM

local Phoenix = {}
    Phoenix.id = "phoenix"
    Phoenix.model = "models/missiles/aim54.mdl"
    Phoenix.name = "AIM-54 Phoenix"
    Phoenix.mechanics = {}
        Phoenix.mechanics.maxweight = 350
        Phoenix.mechanics.maxengine = 10
        Phoenix.mechanics.maxwarhead = 30
        Phoenix.mechanics.eiwtmod = 1
        Phoenix.mechanics.ecwtmod = 1
        Phoenix.mechanics.tcwtmod = 1
        Phoenix.mechanics.drag = 1
        Phoenix.mechanics.gldrag = 1
        Phoenix.mechanics.tidrag = 1
        Phoenix.mechanics.guidanceweight = 1
Missiles["phoenix"] = Phoenix

local FAB = {}
    FAB.id = "fab"
    FAB.model = "models/missiles/fab250.mdl"
    FAB.name = "FAB-250 General Purpose Bomb"
    FAB.mechanics = {}
        FAB.mechanics.maxweight = 200
        FAB.mechanics.maxengine = 0
        FAB.mechanics.maxwarhead = 200
        FAB.mechanics.eiwtmod = 1
        FAB.mechanics.ecwtmod = 1
        FAB.mechanics.drag = 1
        FAB.mechanics.gldrag = 1
        FAB.mechanics.tidrag = 1
        FAB.mechanics.guidanceweight = 1
Missiles["fab"] = FAB

local Paveway = {}
    Paveway.id = "paveway"
    Paveway.model = "models/missiles/GBU12.mdl"
    Paveway.name = "GBU-12 Paveway II"
    Paveway.mechanics = {}
        Paveway.mechanics.maxweight = 500
        Paveway.mechanics.maxengine = 0
        Paveway.mechanics.maxwarhead = 500
        Paveway.mechanics.eiwtmod = 1
        Paveway.mechanics.ecwtmod = 1
        Paveway.mechanics.drag = 1
        Paveway.mechanics.gldrag = 1
        Paveway.mechanics.tidrag = 1
        Paveway.mechanics.guidanceweight = 1
Missiles["paveway"] = Paveway

list.Set( "ACFClasses", "MissileTypes", Missiles )
