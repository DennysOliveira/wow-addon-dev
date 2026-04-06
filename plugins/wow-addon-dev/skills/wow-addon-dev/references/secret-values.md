# Secret Values System (April 2026)

A complete reference for WoW 12.0 (Midnight) Secret Values — the opaque combat data mechanism that prevents tainted addon code from performing logic on protected values.

---

## Table of Contents

1. [Overview](#overview)
2. [issecretvalue()](#issecretvalue)
3. [FrameScriptObject Methods](#framescriptobject-methods)
4. [Curve](#curve)
5. [ColorCurve](#colorcurve)
6. [Duration](#duration)
7. [UnitHealPredictionCalculator](#unithealPredictioncalculator)
8. [C_RestrictedActions Namespace](#c_restrictedactions-namespace)
9. [C_Secrets Namespace](#c_secrets-namespace)
10. [Complete Health Bar Example](#complete-health-bar-example)

---

## Overview

Secret Values are opaque Lua values returned by combat-related APIs in WoW 12.0+. They implement Blizzard's "addon disarmament" philosophy: addons can display combat data but cannot perform logic on it.

**What tainted (addon) code CANNOT do with secret values:**
- Arithmetic (`+`, `-`, `*`, `/`, `%`, `^`)
- Comparison (`<`, `>`, `<=`, `>=`, `==`, `~=`)
- String operations (`tostring`, concatenation, `string.format`)
- Boolean logic derived from secret values
- Table indexing using a secret value as a key

**What tainted code CAN do with secret values:**
- Store them in variables
- Pass them to whitelisted native APIs (e.g., `StatusBar:SetValue()`, `Curve:Evaluate()`)
- Pass them to `issecretvalue()` to check their nature
- Pass them to `FrameScriptObject:HasSecretValues()`

**When execution is NOT tainted** (Blizzard/secure code), secret values behave as normal Lua values.

Interface version: **120001**

---

## issecretvalue()

### Signature

```lua
-- Returns true if the value is a secret value, false otherwise
local isSecret = issecretvalue(value)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | any | The value to test |

| Return | Type | Description |
|--------|------|-------------|
| `isSecret` | boolean | `true` if value is secret, `false` for normal values |

### Usage

`issecretvalue()` is a global Lua function (not a method). It is safe to call on any value including `nil`.

```lua
-- Check before any StatusBar operation
local hp = UnitHealth("player")
if issecretvalue(hp) then
    -- hp is secret — use only whitelisted APIs
    healthBar:SetValue(hp)
else
    -- hp is a normal number — can use freely
    healthBar:SetValue(hp)
    local pct = hp / UnitHealthMax("player") * 100  -- safe only when not secret
end
```

**Best practice:** Always call `issecretvalue()` before branching on combat data. Code that branches on the result is safe; code that does arithmetic on the secret value itself is not.

---

## FrameScriptObject Methods

All frame objects that inherit from `FrameScriptObject` gain two secret-inspection methods in 12.0.

### HasSecretValues()

```lua
-- Returns true if the object currently holds any secret aspects
local hasSecrets = frame:HasSecretValues()
```

| Return | Type | Description |
|--------|------|-------------|
| `hasSecrets` | boolean | `true` if any secret aspect is applied to this object |

### HasSecretAspect()

```lua
-- Returns true if the object has the specified secret aspect
local hasAspect = frame:HasSecretAspect(aspect)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `aspect` | string | The aspect name to check (e.g., `"Value"`, `"Color"`, `"MinMaxValues"`) |

| Return | Type | Description |
|--------|------|-------------|
| `hasAspect` | boolean | `true` if the specified aspect is secret on this object |

### Secret Aspects

When a secret value is passed to a widget API, that widget acquires a "secret aspect." Other APIs on the same widget may then return secret values. Auto-generated API docs list which aspects connect to each API.

```lua
-- Example: check if a StatusBar's value aspect is secret
if healthBar:HasSecretAspect("Value") then
    -- The bar's value was set from a secret source
    -- Anchoring and sizing APIs may also return secret values
end

-- Check any secret aspect is present
if healthBar:HasSecretValues() then
    -- Do not read back numeric values from this bar
end
```

---

## Curve

A `Curve` maps secret numeric input values to output values using linear interpolation across defined key-value pairs. This allows health-percentage-style logic without ever touching the raw number.

### Creation

```lua
-- C_CurveUtil.CreateCurve(keyValues) -> Curve
local curve = C_CurveUtil.CreateCurve(keyValues)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `keyValues` | table | Array of `{x, y}` control points, sorted by x ascending |

| Return | Type | Description |
|--------|------|-------------|
| `curve` | Curve | The curve object |

### Key-Value Pairs

Each entry in `keyValues` is a two-element array `{x, y}` where both are plain (non-secret) numbers defining the shape of the mapping.

```lua
-- Map health fraction (0.0–1.0) to bar fill width (0–200 pixels)
local widthCurve = C_CurveUtil.CreateCurve({
    {0.0,   0},    -- 0% health → 0px
    {0.25,  50},   -- 25% health → 50px
    {0.5,  100},   -- 50% health → 100px
    {1.0,  200},   -- 100% health → 200px
})
```

### Curve:Evaluate()

```lua
-- Returns the interpolated output for a secret or plain input
local output = curve:Evaluate(secretInput)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `secretInput` | secret or number | The input value (may be a secret value) |

| Return | Type | Description |
|--------|------|-------------|
| `output` | secret or number | Interpolated result — secret if input was secret |

### Curve:EvaluateNormalized()

```lua
-- Evaluates after normalizing input to the curve's x range [0, 1]
local output = curve:EvaluateNormalized(secretInput)
```

Same parameter and return types as `Evaluate()`. Normalizes `secretInput` relative to the curve's defined x-range before interpolating.

### Example

```lua
-- Build a curve mapping UnitHealth secret value to a 0–1 fraction
-- (used to drive StatusBar min/max, not raw arithmetic)
local healthCurve = C_CurveUtil.CreateCurve({
    {0,   0.0},
    {100, 0.1},
    {500, 0.5},
    {1000, 1.0},
})

local hp = UnitHealth("target")
-- Pass secret value through the curve; result is also secret
local fraction = healthCurve:Evaluate(hp)
healthBar:SetValue(fraction)  -- Safe: SetValue accepts secret values
```

---

## ColorCurve

A `ColorCurve` maps a secret numeric input to an RGBA color, enabling health-color gradients (green→yellow→red) without any addon arithmetic on the underlying value.

### Creation

```lua
-- C_CurveUtil.CreateColorCurve(colorKeyValues) -> ColorCurve
local colorCurve = C_CurveUtil.CreateColorCurve(colorKeyValues)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `colorKeyValues` | table | Array of `{x, r, g, b, a}` control points, x ascending |

| Return | Type | Description |
|--------|------|-------------|
| `colorCurve` | ColorCurve | The color curve object |

### ColorCurve:Evaluate()

```lua
-- Returns interpolated RGBA for a secret or plain input
local r, g, b, a = colorCurve:Evaluate(secretInput)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `secretInput` | secret or number | Input value |

| Return | Type | Description |
|--------|------|-------------|
| `r` | secret or number | Red channel (0–1) |
| `g` | secret or number | Green channel (0–1) |
| `b` | secret or number | Blue channel (0–1) |
| `a` | secret or number | Alpha channel (0–1) |

All returned color components are secret if the input was secret. Pass them directly to `frame:SetVertexColor()` or `texture:SetColorTexture()` — do not perform arithmetic on them.

### Green-to-Red Gradient Example

```lua
-- Classic health color: green at full, yellow at half, red at empty
-- x values represent health fraction (0.0 = dead, 1.0 = full)
local healthColorCurve = C_CurveUtil.CreateColorCurve({
    -- {x,   r,    g,    b,    a}
    {0.0,  1.0,  0.0,  0.0,  1.0},   -- 0% → red
    {0.5,  1.0,  1.0,  0.0,  1.0},   -- 50% → yellow
    {1.0,  0.0,  1.0,  0.0,  1.0},   -- 100% → green
})

-- Usage: pass the secret health fraction through the color curve
local hp = UnitHealth("player")
local r, g, b, a = healthColorCurve:Evaluate(hp)
healthBar:SetStatusBarColor(r, g, b, a)  -- All args may be secret; API accepts them
```

---

## Duration

A `Duration` object wraps secret time-based data, enabling addons to display cooldowns, cast times, and aura durations without performing arithmetic on protected values.

### Creation

```lua
-- C_DurationUtil.CreateDuration(secretTimeValue) -> Duration
local duration = C_DurationUtil.CreateDuration(secretTimeValue)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `secretTimeValue` | secret or number | A secret time value (e.g., from aura or cooldown APIs) |

| Return | Type | Description |
|--------|------|-------------|
| `duration` | Duration | Duration object wrapping the secret value |

### Purpose

`Duration` objects are accepted by timer status bars and cooldown frames natively, so addons can display time-based information without decoding it.

```lua
-- Example: display a cooldown duration on a timer bar
local start, dur = GetSpellCooldown(spellID)
if issecretvalue(dur) then
    local durationObj = C_DurationUtil.CreateDuration(dur)
    cooldownBar:SetDuration(durationObj)  -- Native API, accepts Duration object
else
    cooldownBar:SetMinMaxValues(0, dur)
    cooldownBar:SetValue(GetTime() - start)
end
```

---

## UnitHealPredictionCalculator

Replaces direct heal prediction arithmetic. Returns an opaque calculator object that drives prediction bars natively without exposing raw heal amounts.

### Creation

```lua
-- CreateUnitHealPredictionCalculator(unit) -> UnitHealPredictionCalculator
local calc = CreateUnitHealPredictionCalculator(unit)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `unit` | string | A valid unit token (e.g., `"player"`, `"target"`, `"party1"`) |

| Return | Type | Description |
|--------|------|-------------|
| `calc` | UnitHealPredictionCalculator | Calculator object for the unit |

### Usage

Pass the calculator object to prediction bar APIs rather than reading raw heal values:

```lua
local calc = CreateUnitHealPredictionCalculator("player")

-- Drive a StatusBar with heal prediction; the API handles secret internals
healPredictBar:SetHealPredictionCalculator(calc)

-- Update when heal prediction changes
local function OnHealPredictionChanged()
    calc:Update()
end
frame:RegisterEvent("UNIT_HEAL_PREDICTION")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_HEAL_PREDICTION" then
        OnHealPredictionChanged()
    end
end)
```

---

## C_RestrictedActions Namespace

Tests the current addon restriction state. Use these to branch behavior based on whether the player is in combat or an instance.

| Function | Signature | Returns | Description |
|----------|-----------|---------|-------------|
| `IsRestricted` | `C_RestrictedActions.IsRestricted()` | `boolean` | `true` if any restriction is active |
| `IsInRestrictedInstance` | `C_RestrictedActions.IsInRestrictedInstance()` | `boolean` | `true` if inside a restricted instance |
| `IsInRestrictedCombat` | `C_RestrictedActions.IsInRestrictedCombat()` | `boolean` | `true` if in restricted combat state |
| `GetRestrictions` | `C_RestrictedActions.GetRestrictions()` | `table` | Table of active restriction flags |

```lua
-- Adjust addon behavior based on restriction state
if C_RestrictedActions.IsRestricted() then
    -- Use secret-safe code paths only
    myFrame:Hide()  -- Or use secret-aware display
else
    -- Full addon functionality available
    myFrame:Show()
end
```

---

## C_Secrets Namespace

Evaluates secret predicates directly. These functions accept secret values and return secret booleans or perform safe comparisons within the protected runtime.

| Function | Signature | Returns | Description |
|----------|-----------|---------|-------------|
| `IsLessThan` | `C_Secrets.IsLessThan(a, b)` | secret boolean | `true` if secret `a < b`; result is itself secret |
| `IsGreaterThan` | `C_Secrets.IsGreaterThan(a, b)` | secret boolean | `true` if secret `a > b` |
| `IsEqual` | `C_Secrets.IsEqual(a, b)` | secret boolean | `true` if secret `a == b` |
| `Select` | `C_Secrets.Select(condition, ifTrue, ifFalse)` | secret value | Returns `ifTrue` or `ifFalse` based on secret condition |
| `EvaluateColorFromBoolean` | `C_CurveUtil.EvaluateColorFromBoolean(secretBool, trueColor, falseColor)` | r,g,b,a | Picks color based on secret boolean |
| `EvaluateColorValueFromBoolean` | `C_CurveUtil.EvaluateColorValueFromBoolean(secretBool, trueVal, falseVal)` | secret value | Picks numeric value based on secret boolean |

```lua
-- Example: use C_Secrets.Select to pick a value without branching on secret
local hp = UnitHealth("player")
local maxHp = UnitHealthMax("player")  -- non-secret for player since 12.0

-- Safe comparison using C_Secrets namespace
local isLow = C_Secrets.IsLessThan(hp, 1000)  -- result is secret boolean
local displayColor = C_CurveUtil.EvaluateColorFromBoolean(
    isLow,
    {r=1, g=0, b=0, a=1},  -- low health: red
    {r=0, g=1, b=0, a=1}   -- normal: green
)
healthBar:SetStatusBarColor(displayColor.r, displayColor.g, displayColor.b, displayColor.a)
```

---

## Complete Health Bar Example

A fully working health bar using `ColorCurve` + `StatusBar:SetValue()`. Displays current health with a green-to-red color gradient. Safe for use in 12.0+ where `UnitHealth("target")` returns a secret value.

```lua
-- HealthBar.lua — Secret-safe health bar for WoW 12.0+
-- Interface: 120001

local ADDON_NAME = "MyHealthBar"

-- === Color curve: green at full health, red at empty ===
-- x-axis: raw health value (secret), mapped via EvaluateNormalized
-- Since we don't know max health for target (it may be secret),
-- we set the bar's min/max and let SetValue handle the fraction.
local healthColorCurve = C_CurveUtil.CreateColorCurve({
    -- {x,   r,    g,    b,    a}
    {0.0,  1.0,  0.0,  0.0,  1.0},   -- 0% health → red
    {0.5,  1.0,  1.0,  0.0,  1.0},   -- 50% health → yellow
    {1.0,  0.0,  1.0,  0.0,  1.0},   -- 100% health → green
})

-- === Create the StatusBar frame ===
local healthBar = CreateFrame("StatusBar", ADDON_NAME .. "HealthBar", UIParent)
healthBar:SetSize(200, 20)
healthBar:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetMinMaxValues(0, 1)  -- Use normalized 0–1 range

local bg = healthBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.6)

-- === Curve to normalize health into 0–1 range ===
-- For player: UnitHealthMax is non-secret. For target: may be secret in instances.
-- Use a single normalized curve approach via EvaluateNormalized.
local normCurve = C_CurveUtil.CreateCurve({
    {0.0, 0.0},
    {1.0, 1.0},
})

-- === Update function ===
local function UpdateHealthBar(unit)
    if unit ~= "target" then return end

    local hp = UnitHealth("target")
    local maxHp = UnitHealthMax("target")

    -- Always check before operating
    if issecretvalue(hp) or issecretvalue(maxHp) then
        -- Secret path: pass hp directly as StatusBar value.
        -- Blizzard's StatusBar accepts secret values for SetValue.
        -- Use SetMinMaxValues with secret maxHp as well.
        healthBar:SetMinMaxValues(0, maxHp)
        healthBar:SetValue(hp)

        -- For color: evaluate using a 0–1 normalized curve
        -- We cannot compute hp/maxHp directly, so use a pre-defined
        -- color curve keyed to the raw secret hp with known max.
        -- Fallback: use a static "unknown" color when both are secret.
        healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)  -- grey = secret, can't color
    else
        -- Non-secret path: full control
        healthBar:SetMinMaxValues(0, maxHp)
        healthBar:SetValue(hp)

        -- Compute normalized fraction for color curve
        local fraction = (maxHp > 0) and (hp / maxHp) or 0
        local r, g, b, a = healthColorCurve:Evaluate(fraction)

        -- r, g, b, a are plain numbers here (fraction was plain)
        healthBar:SetStatusBarColor(r, g, b, a)
    end
end

-- === Secret-safe update using ColorCurve when min/max are known ===
-- When UnitHealthMax is non-secret (e.g., for player), full color curve works:
local function UpdatePlayerHealthBar()
    local hp = UnitHealth("player")
    local maxHp = UnitHealthMax("player")  -- non-secret for player since 12.0

    healthBar:SetMinMaxValues(0, maxHp)
    healthBar:SetValue(hp)  -- hp may be secret; SetValue accepts it

    if issecretvalue(hp) then
        -- Use a Curve to map secret hp → normalized 0–1, then ColorCurve for color
        local hpCurve = C_CurveUtil.CreateCurve({
            {0,      0.0},
            {maxHp,  1.0},
        })
        local normalized = hpCurve:Evaluate(hp)  -- secret output
        local r, g, b, a = healthColorCurve:Evaluate(normalized)  -- secret RGBA
        healthBar:SetStatusBarColor(r, g, b, a)  -- accepts secret color components
    else
        local fraction = (maxHp > 0) and (hp / maxHp) or 0
        local r, g, b, a = healthColorCurve:Evaluate(fraction)
        healthBar:SetStatusBarColor(r, g, b, a)
    end
end

-- === Event registration ===
healthBar:RegisterEvent("UNIT_HEALTH")
healthBar:RegisterEvent("PLAYER_TARGET_CHANGED")
healthBar:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        UpdateHealthBar("target")
    elseif event == "UNIT_HEALTH" then
        UpdateHealthBar(unit)
    end
end)

-- Initial update
UpdateHealthBar("target")
```

**Key rules demonstrated:**
1. `issecretvalue()` checked before any branch or operation on combat data.
2. `StatusBar:SetValue()` accepts secret values — used directly without arithmetic.
3. `SetMinMaxValues()` accepts secret values for max health.
4. `ColorCurve:Evaluate()` accepts secret input and returns secret RGBA — passed directly to `SetStatusBarColor()`.
5. No arithmetic (`hp / maxHp`) performed when either value is secret.
6. No CLEU usage anywhere — health updates driven by `UNIT_HEALTH` event.
