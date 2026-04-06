# MyAddon — Secret-Aware Addon Template

A copy-ready WoW addon scaffold that correctly handles Midnight (Interface 120001 / 12.0+) Secret Values. Use this template when your addon reads any combat data — health, power, auras, or cooldowns.

## What Are Secret Values?

In Midnight (12.0+), Blizzard introduced the **Secret Values** system. Combat APIs such as `UnitHealth()` return opaque Lua values when the player's code is considered "tainted" (i.e., running in an addon context during combat). These values:

- **Cannot** be used in Lua arithmetic (`+`, `-`, `*`, `/`).
- **Cannot** be compared with `<`, `>`, `==`, or similar operators.
- **Cannot** be converted to strings with `tostring()`.
- **Can** be stored in variables.
- **Can** be passed directly to certain native widget APIs designed to accept them (e.g., `StatusBar:SetValue()`).

Attempting arithmetic or comparison on a secret value causes a Lua error at runtime.

## Why `issecretvalue()` Must Be Checked

Your code cannot know at write-time whether a health value will be secret. It depends on whether the unit is in combat when your event handler fires. The guard:

```lua
if issecretvalue(currentHealth) then
    -- secret path: pass raw value to native API only
    healthBar:SetValue(currentHealth)
else
    -- non-secret path: normal arithmetic is safe
    healthBar:SetValue(currentHealth)
    local pct = currentHealth / maxHealth  -- only safe here
end
```

Skipping the `issecretvalue()` check means your addon will error in combat the moment it tries arithmetic on the raw value.

## Why No Arithmetic on the Raw Health Value

Even storing `currentHealth / maxHealth` in a variable fails when `currentHealth` is secret — the division operator itself raises an error before the result is stored. You must never apply any Lua operator to the raw secret value.

## How `ColorCurve` Bridges the Gap

To color a health bar by health percentage (green when full, red when empty) you need to map health → color without dividing. `C_CurveUtil.CreateColorCurve()` solves this at the native level:

```lua
-- Created once at init time
local healthColorCurve = C_CurveUtil.CreateColorCurve({
    {0.0, 1.0, 0.0, 0.0, 1.0},  -- {x, r, g, b, a}  red at 0%
    {0.5, 1.0, 1.0, 0.0, 1.0},  -- {x, r, g, b, a}  yellow at 50%
    {1.0, 0.0, 1.0, 0.0, 1.0},  -- {x, r, g, b, a}  green at 100%
})
```

To evaluate the curve at a secret health percentage, first map the raw health value to a `[0.0, 1.0]` range using a `C_CurveUtil.CreateCurve()` — this keeps the division inside native code:

```lua
local rangeCurve = C_CurveUtil.CreateCurve({
    {0,         0.0},  -- {x, y}
    {maxHealth, 1.0},  -- {x, y}
})
local healthPct = rangeCurve:Evaluate(currentHealth)  -- secret in, secret out
local r, g, b = healthColorCurve:Evaluate(healthPct)  -- secret in, secret out
healthBar:SetStatusBarColor(r, g, b)                  -- native API accepts secrets
```

`r`, `g`, and `b` are themselves secret values, but `SetStatusBarColor()` accepts them. You never touch them with Lua operators.

## File Overview

| File | Purpose |
|------|---------|
| `MyAddon.toc` | Addon manifest; declares Interface 120001 and load order |
| `Core.lua` | Event framework, saved variable init, dispatches to SecretHandlers |
| `SecretHandlers.lua` | All secret-value logic: issecretvalue guard, ColorCurve, SetValue |
| `UI.xml` | Blizzard XML frame definition for the health StatusBar |

## Installation

Copy the `MyAddon/` folder into your retail WoW installation:

```
_retail_/Interface/Addons/MyAddon/
```

Enable **MyAddon** on the character select screen, then log in. A green health bar will appear centred near the top of the screen and update in real time.

## Customisation

- **Rename the addon:** Follow the same renaming steps as the basic-addon template (folder, TOC filename, SavedVariables global, Title field).
- **Change bar position:** Edit the `<Anchor>` block in `UI.xml`. The `point` and `relativePoint` attributes accept any standard frame anchor (`TOPLEFT`, `BOTTOMRIGHT`, etc.).
- **Change bar size:** Edit the `<AbsDimension>` inside the `<StatusBar>` `<Size>` block.
- **Track a different unit:** In `Core.lua`, change `unit == "player"` to `unit == "target"` (or any valid unit token). Update the `UNIT_HEALTH` event registration to match — `UNIT_HEALTH` fires for any unit, the first argument is the unit token.
- **Add more color stops:** Add extra `{x, r, g, b, a}` entries to the `CreateColorCurve()` call in `SecretHandlers.lua`. The `x` value is the position along the curve from `0.0` to `1.0`.
