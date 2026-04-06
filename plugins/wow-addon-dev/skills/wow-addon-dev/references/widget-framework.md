# WoW Widget Framework Reference (April 2026)

A self-contained reference for the WoW 12.0 (Midnight) widget system: frame types, event system, XML templates, Mixins, anchoring, and secure frames.

---

## Table of Contents

1. [Primary Frame Types via CreateFrame()](#1-primary-frame-types-via-createframe)
2. [Event System and Script Handlers](#2-event-system-and-script-handlers)
3. [XML Template Syntax](#3-xml-template-syntax)
4. [Mixin Pattern](#4-mixin-pattern)
5. [Frame Anchoring](#5-frame-anchoring)
6. [Secure vs Insecure Frames in 12.0](#6-secure-vs-insecure-frames-in-120)
7. [Complete Working Unit Frame Example](#7-complete-working-unit-frame-example)

---

## 1. Primary Frame Types via CreateFrame()

All frame types are created with `CreateFrame(frameType, name, parent, template, id)`. The `name`, `parent`, `template`, and `id` arguments are optional.

### Frame

The base widget type. All other widget types inherit from Frame. Used for containers, backdrops, hit regions, and as event listeners.

```lua
local f = CreateFrame("Frame", "MyFrame", UIParent)
f:SetSize(200, 100)
f:SetPoint("CENTER")
```

### Button

Extends Frame with clickable behavior: `OnClick`, `OnDoubleClick`, `OnMouseDown`, `OnMouseUp`. Supports normal/pushed/highlighted/disabled textures and label font strings.

```lua
local btn = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
btn:SetSize(80, 22)
btn:SetText("Click Me")
btn:SetScript("OnClick", function() print("clicked") end)
```

### StatusBar

A horizontal or vertical fill bar. Accepts secret values via `SetValue()` — this is the correct widget for displaying health, power, or any secret numeric value.

```lua
local bar = CreateFrame("StatusBar", nil, UIParent)
bar:SetMinMaxValues(0, 100)
bar:SetValue(75)
bar:SetStatusBarColor(0, 1, 0)   -- green
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
```

### Slider

A draggable knob for selecting a numeric value within a range. Triggers `OnValueChanged` when the value changes.

```lua
local slider = CreateFrame("Slider", nil, UIParent, "OptionsSliderTemplate")
slider:SetMinMaxValues(0, 100)
slider:SetValue(50)
slider:SetScript("OnValueChanged", function(self, val) print(val) end)
```

### EditBox

A single-line (or optionally multi-line) text input. Triggers `OnTextChanged`, `OnEnterPressed`, `OnEscapePressed`.

```lua
local eb = CreateFrame("EditBox", nil, UIParent, "InputBoxTemplate")
eb:SetSize(150, 20)
eb:SetAutoFocus(false)
eb:SetScript("OnEnterPressed", function(self)
    print("Input:", self:GetText())
    self:ClearFocus()
end)
```

### ScrollFrame

A viewport over a larger child frame. Manages scroll offset via `SetScrollChild()` and `SetVerticalScroll()`.

```lua
local sf = CreateFrame("ScrollFrame", nil, UIParent, "UIPanelScrollFrameTemplate")
sf:SetSize(200, 300)
local child = CreateFrame("Frame", nil, sf)
child:SetSize(200, 600)
sf:SetScrollChild(child)
```

### MessageFrame

A rolling log of text messages. Supports `AddMessage(text, r, g, b)` to append colored lines; old lines fade out automatically.

```lua
local mf = CreateFrame("MessageFrame", nil, UIParent)
mf:SetSize(300, 150)
mf:SetFading(true)
mf:SetFadeDuration(3)
mf:AddMessage("Hello", 1, 1, 0)
```

### Cooldown

Displays a radial sweep (pie-timer) overlay on top of a texture. Used for action bar spell cooldowns.

```lua
local cd = CreateFrame("Cooldown", nil, parentButton)
cd:SetAllPoints(parentButton)
cd:SetCooldown(GetTime(), 30)  -- start, duration in seconds
```

### Model

Renders a 3D model (creature, item, etc.) inside a frame region.

```lua
local model = CreateFrame("Model", nil, UIParent)
model:SetSize(128, 128)
model:SetDisplayInfo(46816)   -- display ID
```

### PlayerModel

Extends Model to display the player's character with full equipment. Used in character and dressing room frames.

```lua
local pm = CreateFrame("PlayerModel", nil, UIParent)
pm:SetSize(200, 300)
pm:SetUnit("player")
```

---

## 2. Event System and Script Handlers

Script handlers are set with `frame:SetScript(handlerName, function)`. Each handler receives the frame as the first argument (`self`), followed by handler-specific parameters.

### OnEvent

```lua
-- params: self, event (string), ... (event-specific args)
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- handle login
    end
end)
```

Fires whenever a registered event is received. Must call `RegisterEvent` for each event you want to receive.

### OnLoad

```lua
-- params: self
-- Only fires for frames defined in XML with a <Scripts><OnLoad> block.
-- Use ADDON_LOADED for Lua-created frames instead.
frame:SetScript("OnLoad", function(self)
    self:RegisterEvent("PLAYER_LOGIN")
end)
```

Fires once immediately after the frame is created (XML path). For Lua-created frames, initialization code goes directly after `CreateFrame`.

### OnUpdate

```lua
-- params: self, elapsed (seconds since last frame)
frame:SetScript("OnUpdate", function(self, elapsed)
    -- called every rendered frame; throttle with an accumulator
end)
```

Fires every rendered frame. Avoid heavy work here — use an elapsed accumulator to throttle (see Section 6 of common-patterns.md).

### OnShow

```lua
-- params: self
frame:SetScript("OnShow", function(self)
    -- frame became visible
end)
```

Fires when the frame transitions from hidden to visible.

### OnHide

```lua
-- params: self
frame:SetScript("OnHide", function(self)
    -- frame became hidden
end)
```

Fires when the frame transitions from visible to hidden.

### OnEnter

```lua
-- params: self, motion (boolean)
frame:SetScript("OnEnter", function(self, motion)
    -- mouse cursor entered the frame region
end)
```

Fires when the cursor moves over the frame. `motion` is true if triggered by mouse movement, false if by the frame moving under a stationary cursor.

### OnLeave

```lua
-- params: self, motion (boolean)
frame:SetScript("OnLeave", function(self, motion)
    -- mouse cursor left the frame region
end)
```

Fires when the cursor moves off the frame.

---

## 3. XML Template Syntax

XML templates let you define reusable frame layouts. WoW loads `.xml` files listed in your `.toc`.

### Basic Structure

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..\FrameXML\UI.xsd">

    <Frames>
        <Frame name="MyAddonFrameTemplate" virtual="true">
            <Size x="200" y="100"/>
            <Scripts>
                <OnLoad>
                    -- Lua code here runs when frame is created
                    self:RegisterEvent("PLAYER_LOGIN")
                </OnLoad>
                <OnEvent>
                    if event == "PLAYER_LOGIN" then
                        print("Player logged in")
                    end
                </OnEvent>
            </Scripts>
        </Frame>
    </Frames>

</Ui>
```

### Template Inheritance with `inherits`

```xml
<Frame name="MyAddonMainFrame" parent="UIParent"
       inherits="MyAddonFrameTemplate, BackdropTemplate">
    <Size x="300" y="200"/>
    <Anchors>
        <Anchor point="CENTER"/>
    </Anchors>
</Frame>
```

`inherits` accepts a comma-separated list of template names. Child frames inherit all scripts, regions, and attributes from parent templates. Blizzard's built-in templates (e.g., `BackdropTemplate`, `UIPanelButtonTemplate`) are always available.

### Key XML Elements

| Element | Purpose |
|---------|---------|
| `<Frames>` | Container for one or more `<Frame>` definitions |
| `<Frame>` | Defines a frame; `virtual="true"` makes it a template only (not instantiated) |
| `<Scripts>` | Container for script handler blocks |
| `<Size x="W" y="H"/>` | Sets frame dimensions |
| `<Anchors>` | Contains one or more `<Anchor>` placements |
| `<Layers>` | Contains `<Layer>` blocks for textures and font strings |

---

## 4. Mixin Pattern

Mixins copy methods from one or more tables onto a target object. WoW provides two helpers.

### Mixin(object, ...)

Copies all fields from each mixin table onto `object`. Returns `object`.

```lua
local MyMixin = {}

function MyMixin:Init(label)
    self.label = label
end

function MyMixin:GetLabel()
    return self.label
end

-- Apply to a new table
local obj = {}
Mixin(obj, MyMixin)
obj:Init("Hello")
print(obj:GetLabel())   -- "Hello"
```

### CreateAndInitFromMixin(mixin, ...)

Creates a new table, copies the mixin onto it, and calls `mixin:Init(...)` with any additional arguments. Equivalent to `Mixin({}, mixin)` followed by `obj:Init(...)`.

```lua
local CounterMixin = {}

function CounterMixin:Init(start)
    self.count = start or 0
end

function CounterMixin:Increment()
    self.count = self.count + 1
    return self.count
end

local counter = CreateAndInitFromMixin(CounterMixin, 10)
print(counter:Increment())   -- 11
print(counter:Increment())   -- 12
```

### Multiple Mixins

```lua
Mixin(obj, MixinA, MixinB, MixinC)
```

Fields are applied left-to-right; later mixins overwrite conflicting keys from earlier ones.

---

## 5. Frame Anchoring

### SetPoint

```lua
frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `point` | string | Anchor point on this frame (e.g., `"TOPLEFT"`, `"CENTER"`, `"BOTTOMRIGHT"`) |
| `relativeTo` | frame\|string\|nil | Frame to anchor to; `nil` means UIParent |
| `relativePoint` | string\|nil | Anchor point on `relativeTo`; defaults to `point` if nil |
| `xOffset` | number\|nil | Horizontal offset in pixels (positive = right) |
| `yOffset` | number\|nil | Vertical offset in pixels (positive = up) |

Examples:

```lua
-- Centered in parent
frame:SetPoint("CENTER")

-- Top-left of UIParent with 10px inset
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)

-- Below another frame
frame:SetPoint("TOP", otherFrame, "BOTTOM", 0, -5)
```

### ClearAllPoints

Always call `ClearAllPoints()` before repositioning a frame that already has anchors, to prevent anchor conflicts:

```lua
frame:ClearAllPoints()
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
```

### Valid Anchor Point Strings

`TOPLEFT`, `TOP`, `TOPRIGHT`, `LEFT`, `CENTER`, `RIGHT`, `BOTTOMLEFT`, `BOTTOM`, `BOTTOMRIGHT`

### Frame Strata

Strata controls the render layer order. Higher strata draw on top of lower strata regardless of frame level within the strata.

| Strata | Typical Use |
|--------|------------|
| `BACKGROUND` | World map underlays, floor decorations |
| `LOW` | Unit frames, action bars |
| `MEDIUM` | Standard addon UI panels |
| `HIGH` | Popup dialogs, dropdown menus |
| `DIALOG` | Blizzard dialog boxes |
| `FULLSCREEN` | Full-screen overlays (loading screens) |
| `FULLSCREEN_DIALOG` | Dialogs over fullscreen content |
| `TOOLTIP` | Tooltips — always on top |

```lua
frame:SetFrameStrata("HIGH")
frame:SetFrameLevel(5)   -- within the strata; higher = in front
```

---

## 6. Secure vs Insecure Frames in 12.0

### What Is Taint?

Taint is a flag the Lua environment attaches to values and frames when they are touched by addon (insecure) code. Once a value or frame is tainted, it cannot interact with Blizzard's protected (secure) APIs without triggering a Lua error.

Taint rules:
- Addon code that reads or writes global variables shared with Blizzard code can spread taint.
- Calling a protected function (e.g., `CastSpellByID`) from tainted context fails with "action blocked by an addon".
- Taint is cleared at specific game engine checkpoints (e.g., end of hardware event handler).

### SecureHandlerStateTemplate

`SecureHandlerStateTemplate` allows addons to drive secure actions (casting, targeting) in response to state changes, without taint. The state is set by addon code; the response is executed by secure code.

```lua
local secureHandler = CreateFrame("Frame", "MySecureHandler", UIParent,
    "SecureHandlerStateTemplate")

-- This attribute-driver runs in a restricted, secure environment
secureHandler:SetAttribute("_onstate-combat", [[
    if newstate == "combat" then
        -- perform secure actions here
    end
]])

RegisterStateDriver(secureHandler, "combat", "[combat] combat; nocombat")
```

### Restricted Environment Limitations

Inside a secure handler's attribute scripts, only a subset of Lua and WoW APIs are available. You cannot:
- Call arbitrary Lua functions defined by addon code.
- Access addon globals or `ns` tables.
- Print to chat.
- Run complex logic — only control flow, attribute reads/writes, and whitelisted API calls.

### Secure Action Buttons

For casting spells or targeting units from click handlers without taint, use `SecureActionButtonTemplate`:

```lua
local btn = CreateFrame("Button", "MySpellButton", UIParent,
    "SecureActionButtonTemplate")
btn:SetAttribute("type", "spell")
btn:SetAttribute("spell", "Fireball")
btn:RegisterForClicks("AnyUp")
```

This button casts Fireball on click without taint — the click goes through the secure action dispatcher, not addon code.

---

## 7. Complete Working Unit Frame Example

A minimal unit frame showing a health bar and player name, updated via events and an OnUpdate ticker.

```lua
-- UnitFrame.lua
-- Displays player health bar and name. Interface: 120001

local AddonName, ns = ...

-- Create the unit frame container
local unitFrame = CreateFrame("Frame", "MyUnitFrame", UIParent,
    "BackdropTemplate")
unitFrame:SetSize(200, 40)
unitFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
unitFrame:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 8,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
})

-- Health bar (fills inside the container)
local healthBar = CreateFrame("StatusBar", nil, unitFrame)
healthBar:SetPoint("TOPLEFT",    unitFrame, "TOPLEFT",  3, -3)
healthBar:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -3, 16)
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetStatusBarColor(0.1, 0.9, 0.1)   -- green default

-- Name text above the bar
local nameText = unitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
nameText:SetPoint("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", 4, 2)
nameText:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -4, 2)
nameText:SetJustifyH("LEFT")

-- Update function: reads health and updates bar + color
local function UpdateHealth()
    local unit = "player"
    if not UnitExists(unit) then return end

    local hp    = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)

    -- Set range first (hpMax may be secret; StatusBar accepts it)
    healthBar:SetMinMaxValues(0, hpMax)

    -- Set current value (hp may be secret; SetValue accepts it)
    healthBar:SetValue(hp)

    -- Update the name label (UnitName is not secret)
    local name = UnitName(unit) or "Unknown"
    if UnitIsDeadOrGhost(unit) then
        nameText:SetText(name .. " (Dead)")
        healthBar:SetStatusBarColor(0.5, 0.5, 0.5)
    else
        nameText:SetText(name)
        healthBar:SetStatusBarColor(0.1, 0.9, 0.1)
    end
end

-- Throttled OnUpdate for smooth health bar refresh
local elapsed_accum = 0
local UPDATE_INTERVAL = 0.1   -- seconds between updates

unitFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsed_accum = elapsed_accum + elapsed
    if elapsed_accum >= UPDATE_INTERVAL then
        elapsed_accum = 0
        UpdateHealth()
    end
end)

-- Event-driven updates for immediate response to health changes
unitFrame:RegisterEvent("UNIT_HEALTH")
unitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
unitFrame:RegisterEvent("PLAYER_DEAD")
unitFrame:RegisterEvent("PLAYER_ALIVE")

unitFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_HEALTH" then
        local unit = ...
        if unit == "player" then
            UpdateHealth()
        end
    elseif event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_DEAD"
        or event == "PLAYER_ALIVE" then
        UpdateHealth()
    end
end)
```

### How It Works

| Component | Pattern |
|-----------|---------|
| Health bar range | `SetMinMaxValues(0, hpMax)` — both args accept secret values |
| Health bar fill | `SetValue(hp)` — accepts secret value directly |
| Smooth updates | `OnUpdate` with a 0.1s throttle accumulator |
| Instant response | `UNIT_HEALTH` event triggers an immediate `UpdateHealth()` call |
| Dead state | Detected with `UnitIsDeadOrGhost()` (non-secret boolean) |
