# ACF Architecture Guide

## Core Principles

### Validate at Entry Points

Validate all input at system boundaries (console commands, hooks, network receives, public API functions). Once validated, internal code can trust the data without redundant checks.

```lua
-- Entry point: validate everything here
function ACF.CreateAmmo(data)
    if not data.Type or not AmmoTypes[data.Type] then return end
    if not data.Caliber or data.Caliber <= 0 then return end

    return CreateAmmoInternal(data)
end

-- Internal: data is already validated, no defensive checks needed
local function CreateAmmoInternal(data)
    local ammo = {
        Type    = data.Type,
        Caliber = data.Caliber,
    }

    return ammo
end
```

**Entry points include:**
- Console commands
- Network receives (`net.Receive`)
- Hooks (`hook.Add` callbacks)
- Public API functions (anything in the `ACF` table meant for external use)

**Not entry points:**
- Local/internal functions
- Methods called by other internal code

### File Structure Mirrors Code Structure

The physical location of code should match its logical structure. The file loader automatically creates tables for directories, so the folder hierarchy directly becomes the table hierarchy.

```
-- Folder structure
lua/acf/core/utilities/
lua/acf/damage/
lua/acf/entities/ammo_types/

-- Becomes table structure
ACF.Core.Utilities
ACF.Damage
```

**Keep the root table clean:**
```lua
-- Bad: polluting root ACF table
ACF.DamageScale     = 1
ACF.ArmorMod        = 1
ACF.CalculateDamage = function() end
ACF.ApplyDamage     = function() end

-- Good: nested under appropriate subtable
ACF.Damage.Scale    = 1
ACF.Damage.ArmorMod = 1
ACF.Damage.Calculate = function() end
ACF.Damage.Apply     = function() end
```

**Guidelines:**
- The table hierarchy should match the folder hierarchy
- Group related code together (server, client, shared for the same feature live near each other)
- Folder names should describe *what* the code does, not *how* it's categorized
- If you're looking for "damage calculations", there should be a `damage/` folder
- Avoid adding new keys to the root `ACF` table; use subtables instead

### Modular & Extensible Code

Design systems that can be extended without modifying core code.

**Base + Sub-type pattern:**

A base class handles shared logic. Sub-types inherit from the base and override only what makes them different.

```lua
-- lua/acf/entities/ammo_types/ap.lua
-- AP is the base ammo type, defines core behavior
local Ammo = AmmoTypes.Register("AP")

function Ammo:OnLoaded()
    self.Name        = "Armor Piercing"
    self.Description = "Solid shell, no explosive filler."
end

function Ammo:GetPenetration(Bullet, Speed)
    return ACF.Penetration(Speed, Bullet.ProjMass, Bullet.Diameter * 10)
end
```

```lua
-- lua/acf/entities/ammo_types/he.lua
-- HE inherits from APHE, only overrides what's different
local Ammo = AmmoTypes.Register("HE", "APHE")  -- Second arg is base class

function Ammo:OnLoaded()
    BASE.OnLoaded(self)  -- Call parent

    self.Name        = "High Explosive"
    self.Description = "Explodes on impact."
end

function Ammo:GetPenetration()
    return 0  -- HE doesn't penetrate
end
```

The base ammo code calls `Ammo:GetPenetration()` without knowing the specific type. Adding a new ammo type requires no changes to existing code.

**Registration over conditionals:**
```lua
-- Good: types register themselves, base code calls interface
local AmmoType = AmmoTypes.Get(bullet.Type)
local pen = AmmoType:GetPenetration(bullet, speed)

-- Bad: hardcoded switch statements that grow forever
if type == "AP" then
    pen = CalcAPPen(bullet)
elseif type == "HE" then
    pen = 0
elseif type == "HEAT" then
    pen = CalcHEATPen(bullet)
end
```

**Clear interfaces:**
- Sub-types implement a known set of methods (`OnLoaded`, `GetPenetration`, `UpdateRoundData`, etc.)
- Base code calls these without knowing the specific type
- Return consistent types (don't return `nil` sometimes and `false` other times)

### Minimal Redundancy (DRY)

Avoid duplicating logic. Extract shared code into utility functions.

```lua
-- Good: shared logic in one place
local function CalculateDamage(caliber, modifier)
    return caliber * modifier * ACF.DamageScale
end

-- Bad: same calculation copy-pasted everywhere
local damage1 = caliber * 2 * ACF.DamageScale
local damage2 = caliber * 1.5 * ACF.DamageScale
```

**Table-driven design** for repetitive patterns:
```lua
local AmmoModifiers = {
    AP   = 2.0,
    HE   = 1.5,
    HEAT = 1.8,
}

local function GetDamage(type, caliber)
    local mod = AmmoModifiers[type] or 1

    return caliber * mod
end
```

---

## Supporting Principles

### Fail Fast

When validation fails, fail immediately and clearly. Don't silently continue with bad data.

```lua
-- Good: immediate, clear failure
if not IsValid(ent) then return false, "Invalid entity" end

-- Bad: silent failure that causes issues later
local health = IsValid(ent) and ent:Health() or 0
```

### Explicit Over Implicit

Make data flow and behavior clear. Avoid magic.

```lua
-- Good: explicit parameter
function Weapon:Fire(target)
    self:AimAt(target)
    self:Shoot()
end

-- Bad: implicit state dependency
function Weapon:Fire()
    self:AimAt(self.lastTarget)  -- Where did this come from?
    self:Shoot()
end
```

---

## Performance

### Localize Library Functions

Global lookups are slower than local lookups. Localize frequently-used library functions at the top of the file.

```lua
-- At file top: localize what you need
local math = math
local cos  = math.cos
local sin  = math.sin
local rad  = math.rad
local abs  = math.abs
local min  = math.min
local max  = math.max
local Clamp = math.Clamp

-- Now use the locals in hot paths
local function ConeContainsPos(conePos, coneDir, degrees, position)
    local minDot    = cos(rad(degrees))
    local direction = (position - conePos):GetNormalized()

    return coneDir:Dot(direction) >= minDot
end
```

**When to localize:**
- Functions called in Think hooks, render hooks, or tight loops
- Math functions used repeatedly (`cos`, `sin`, `rad`, `abs`, `min`, `max`, `Clamp`)

**When it doesn't matter:**
- One-time setup code
- Rarely called or low impact functions

### Avoid Table Creation in Hot Paths

Creating tables generates garbage that the GC must collect. In frequently-called functions, prefer multiple return values or reuse tables.

```lua
-- Bad: creates a new table every call
function ACF.Kinetic(speed, mass)
    return {
        Kinetic  = mass * 0.5 * speed ^ 2,
        Momentum = speed * mass,
    }
end

-- Good: multiple return values
function ACF.Kinetic(speed, mass)
    local kinetic  = mass * 0.5 * speed ^ 2
    local momentum = speed * mass

    return kinetic, momentum
end

-- Usage
local kinetic, momentum = ACF.Kinetic(speed, mass)
```

**Guidelines:**
- Use multiple returns when returning 2-4 simple values
- If you need named fields or more than 4 values, consider object pooling
- Avoid creating tables inside loops

### Reuse Tables

Instead of creating new tables in hot paths, create a table once at file scope and reuse it by modifying its fields.

```lua
-- Create once at file scope
local TraceData = {}

local function DoTrace(start, endpos, filter)
    TraceData.start  = start
    TraceData.endpos = endpos
    TraceData.filter = filter

    return util.TraceLine(TraceData)
end
```

**Real example from ballistics:**
```lua
local TraceData = { start = true, endpos = true, filter = true, mask = true }

local function DoBulletTrace(bullet)
    TraceData.start  = bullet.Pos
    TraceData.endpos = bullet.Pos + bullet.Flight
    TraceData.filter = bullet.Filter

    return ACF.trace(TraceData)
end
```

**Guidelines:**
- Create the table at file scope, outside any function
- Don't store references to the reused table (it will be overwritten)
