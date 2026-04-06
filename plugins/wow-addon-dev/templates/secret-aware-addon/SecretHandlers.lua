-- SecretHandlers.lua
-- Secret-value-aware health bar logic for MyAddon (Midnight 12.0+)
--
-- In Midnight (12.0+) combat APIs return "Secret Values" — opaque Lua values
-- that tainted (addon) code cannot perform arithmetic or comparisons on.
-- UnitHealth() returns a secret value when the unit is in combat.
--
-- The pattern:
--   1. Check issecretvalue() before branching on health data.
--   2. Pass the raw secret value directly to StatusBar:SetValue() — no arithmetic.
--   3. Use C_CurveUtil.CreateColorCurve() to map health percentage to a color
--      without ever touching the raw value with Lua operators.

local AddonName, ns = ...

ns.SecretHandlers = {}
local SH = ns.SecretHandlers

-- Color curve: green (full health) → yellow (half) → red (empty)
-- Created once during Init and reused for every update.
local healthColorCurve

function SH.Init()
    -- CreateColorCurve takes an array of positional control points:
    -- { x, r, g, b, a } where x is position (0.0-1.0), rgba are color channels (0.0-1.0)
    -- x=0.0 maps to the minimum value (empty bar / 0% health)
    -- x=1.0 maps to the maximum value (full bar / 100% health)
    healthColorCurve = C_CurveUtil.CreateColorCurve({
        {0.0,  1.0,  0.0,  0.0,  1.0},  -- red    at 0% health
        {0.5,  1.0,  1.0,  0.0,  1.0},  -- yellow at 50% health
        {1.0,  0.0,  1.0,  0.0,  1.0},  -- green  at 100% health
    })
end

function SH.UpdateHealthBar(unit)
    local healthBar = MyAddonHealthBar
    if not healthBar then return end

    -- UnitHealthMax is no longer secret for player units in 12.0+.
    -- We use it to set the bar range; this is safe arithmetic.
    local maxHealth = UnitHealthMax(unit)
    if not maxHealth or maxHealth == 0 then return end
    healthBar:SetMinMaxValues(0, maxHealth)

    -- UnitHealth returns a secret value while the unit is in combat.
    local currentHealth = UnitHealth(unit)

    -- Always guard with issecretvalue() before any Lua operation on health data.
    if issecretvalue(currentHealth) then
        -- Secret path: pass the raw value straight to the native API.
        -- No arithmetic, no comparison, no string conversion on currentHealth.
        healthBar:SetValue(currentHealth)

        -- Derive a health percentage secret value via a Curve (no division in Lua).
        -- C_CurveUtil.CreateCurve takes positional {x, y} control points.
        -- Maps the [0, maxHealth] domain to [0.0, 1.0].
        local rangeCurve = C_CurveUtil.CreateCurve({
            {0,         0.0},
            {maxHealth, 1.0},
        })
        local healthPct = rangeCurve:Evaluate(currentHealth)

        -- Evaluate the color curve at the (secret) health percentage.
        -- r, g, b, a are also secret values, but SetStatusBarColor accepts them.
        local r, g, b, a = healthColorCurve:Evaluate(healthPct)
        healthBar:SetStatusBarColor(r, g, b, a)
    else
        -- Non-secret path: normal Lua arithmetic is safe here.
        healthBar:SetValue(currentHealth)

        local healthPct = currentHealth / maxHealth
        local r, g, b, a = healthColorCurve:Evaluate(healthPct)
        healthBar:SetStatusBarColor(r, g, b, a)
    end
end
