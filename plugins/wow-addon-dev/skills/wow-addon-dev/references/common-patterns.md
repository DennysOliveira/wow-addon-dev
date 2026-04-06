# WoW Addon Common Patterns Reference (April 2026)

A self-contained reference for common WoW 12.0 (Midnight) addon patterns: Ace3, LibStub, LibDataBroker, LibSharedMedia, SavedVariables migration, addon communications, and performance patterns.

---

## Table of Contents

1. [Ace3 Library Framework](#1-ace3-library-framework)
2. [LibStub](#2-libstub)
3. [LibDataBroker and LibDBIcon](#3-libdatabroker-and-libdbicon)
4. [LibSharedMedia](#4-libsharedmedia)
5. [SavedVariables Migration](#5-savedvariables-migration)
6. [Addon Communications](#6-addon-communications)
7. [Performance Patterns](#7-performance-patterns)

---

## 1. Ace3 Library Framework

Ace3 is the standard WoW addon framework library suite. It provides lifecycle management, event registration, and database handling. Libraries are loaded via LibStub after embedding in your addon's `libs/` folder or via a CurseForge dependency.

### AceAddon-3.0 — Addon Object and Lifecycle

```lua
-- Core.lua
local MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon",
    "AceConsole-3.0",   -- adds :Print(), :RegisterChatCommand()
    "AceEvent-3.0"      -- adds :RegisterEvent(), :UnregisterEvent()
)

-- Called after ADDON_LOADED fires for your addon.
-- SavedVariables are available here.
function MyAddon:OnInitialize()
    -- Initialize database (see AceDB below)
    self.db = LibStub("AceDB-3.0"):New("MyAddonDB", self:GetDefaults(), true)
    self:RegisterChatCommand("myaddon", "OnSlashCommand")
end

-- Called after PLAYER_LOGIN fires.
-- All addons are loaded, UI is fully available.
function MyAddon:OnEnable()
    self:RegisterEvent("UNIT_HEALTH", "OnUnitHealth")
    self:Print("MyAddon enabled!")
end

-- Called when the addon is disabled (rare outside of AceAddon managed scenarios).
function MyAddon:OnDisable()
    -- unregister events, hide frames
end
```

### AceEvent-3.0 — Event Registration

```lua
-- Register an event with a method name (string) or function
function MyAddon:OnEnable()
    self:RegisterEvent("UNIT_HEALTH", "OnUnitHealth")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitial, isReload)
        MyAddon:OnEnteringWorld(isInitial, isReload)
    end)
end

function MyAddon:OnUnitHealth(event, unit)
    if unit == "player" then
        -- handle player health change
    end
end
```

### AceDB-3.0 — Profile-Based Saved Variables

```lua
-- Define defaults in a method or module
function MyAddon:GetDefaults()
    return {
        profile = {
            showFrame  = true,
            frameScale = 1.0,
            color      = { r = 0.1, g = 0.9, b = 0.1, a = 1.0 },
        },
        global = {
            lastVersion = 0,
        },
    }
end

-- In OnInitialize:
self.db = LibStub("AceDB-3.0"):New("MyAddonDB", self:GetDefaults(), true)
-- Third arg "true" = use "Default" profile by default

-- Access profile data:
local scale = self.db.profile.frameScale

-- Access global data (shared across all characters):
local lastVer = self.db.global.lastVersion
```

### Complete Minimal Ace3 Addon

```lua
-- MyAddon.lua (complete, copy-ready)
local MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon",
    "AceConsole-3.0",
    "AceEvent-3.0"
)

local defaults = {
    profile = {
        enabled  = true,
        message  = "Hello from MyAddon!",
    },
}

function MyAddon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MyAddonDB", defaults, true)
    self:RegisterChatCommand("myaddon", "SlashHandler")
end

function MyAddon:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")
    self:Print("Loaded. Type /myaddon hello")
end

function MyAddon:OnDisable()
    self:UnregisterAllEvents()
end

function MyAddon:OnEnterWorld(event, isInitialLogin)
    if isInitialLogin then
        self:Print(self.db.profile.message)
    end
end

function MyAddon:SlashHandler(input)
    local cmd = strtrim(input):lower()
    if cmd == "hello" then
        self:Print(self.db.profile.message)
    else
        self:Print("Usage: /myaddon hello")
    end
end
```

---

## 2. LibStub

LibStub is the minimal library versioning system used by virtually all WoW addon libraries. It prevents loading duplicate or older library versions.

### Embedding Pattern

Place LibStub's source file in your addon's `libs/` folder and list it first in your TOC:

```toc
## Interface: 120001
## Title: MyAddon
## Version: 1.0.0

libs\LibStub\LibStub.lua
libs\AceAddon-3.0\AceAddon-3.0.xml
Core.lua
```

### Calling a Library

```lua
-- Required: error if the library is not found
local AceAddon = LibStub("AceAddon-3.0")

-- Silent: returns nil instead of erroring if not found
local MyLib = LibStub("MyLibrary-1.0", true)
if not MyLib then
    print("MyLibrary not available")
end
```

### Registering a New Library

```lua
local MAJOR, MINOR = "MyLibrary-1.0", 1
local MyLib, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)

if not MyLib then
    return  -- already loaded with same or newer version
end

function MyLib:DoThing()
    print("thing done")
end
```

---

## 3. LibDataBroker and LibDBIcon

LibDataBroker (LDB) provides a standard data source protocol for minimap buttons, broker displays (e.g., Bazooka, ChocolateBar), and data feeds.

### Creating a Data Source

```lua
local LDB = LibStub("LibDataBroker-1.1")

local dataSource = LDB:NewDataObject("MyAddon", {
    type  = "data source",   -- or "launcher" for icon-only buttons
    text  = "MyAddon",
    icon  = "Interface\\Icons\\INV_Misc_QuestionMark",
    label = "My Addon",

    OnClick = function(self, button)
        if button == "LeftButton" then
            print("Left clicked")
        elseif button == "RightButton" then
            print("Right clicked")
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:AddLine("MyAddon", 1, 1, 1)
        tooltip:AddLine("Click to toggle the main frame.", 0.8, 0.8, 0.8)
    end,
})
```

### Adding a Minimap Button via LibDBIcon

```lua
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- In OnInitialize (after AceDB is ready):
if LDBIcon then
    -- self.db.profile.minimapButton is the saved position table
    if not self.db.profile.minimapButton then
        self.db.profile.minimapButton = { hide = false }
    end
    LDBIcon:Register("MyAddon", dataSource, self.db.profile.minimapButton)
end

-- Show/hide the icon:
if LDBIcon then
    LDBIcon:Show("MyAddon")
    LDBIcon:Hide("MyAddon")
end
```

---

## 4. LibSharedMedia

LibSharedMedia (LSM) provides a shared registry for textures, sounds, fonts, and statusbar textures, allowing users to replace media via addons like SharedMedia and Masque.

### Registering Media

```lua
local LSM = LibStub("LibSharedMedia-3.0")

-- Register a custom font
LSM:Register("font", "My Custom Font",
    "Interface\\AddOns\\MyAddon\\media\\MyFont.ttf")

-- Register a statusbar texture
LSM:Register("statusbar", "My Bar Texture",
    "Interface\\AddOns\\MyAddon\\media\\MyBar.tga")

-- Register a sound file
LSM:Register("sound", "My Alert Sound",
    "Interface\\AddOns\\MyAddon\\media\\alert.ogg")
```

### Retrieving Media

```lua
local LSM = LibStub("LibSharedMedia-3.0")

-- Fetch a font path (falls back to default if not found)
local fontPath = LSM:Fetch("font", "My Custom Font")
myFontString:SetFont(fontPath, 12, "OUTLINE")

-- Fetch a statusbar texture
local barTex = LSM:Fetch("statusbar", "My Bar Texture")
myStatusBar:SetStatusBarTexture(barTex)

-- Fetch a sound and play it
local soundPath = LSM:Fetch("sound", "My Alert Sound")
PlaySoundFile(soundPath, "Master")
```

### Media Type Keys

| Type key | Usage |
|----------|-------|
| `"font"` | Font files (.ttf, .otf) |
| `"statusbar"` | Statusbar fill textures |
| `"border"` | Border textures |
| `"background"` | Background tile textures |
| `"sound"` | Sound files (.ogg, .mp3) |

---

## 5. SavedVariables Migration

When you change your addon's SavedVariables schema between versions, you must safely migrate existing user data rather than wiping it.

### Pattern

```lua
local CURRENT_SCHEMA = 3

local function MigrateDB()
    -- First run: SavedVariable is nil
    if MyAddonDB == nil then
        MyAddonDB = {}
    end

    local schema = MyAddonDB.schema or 0

    -- Apply each migration in order
    if schema < 1 then
        -- Schema v1: initial structure
        MyAddonDB.showFrame  = (MyAddonDB.showFrame ~= false)   -- default true
        MyAddonDB.frameAlpha = MyAddonDB.frameAlpha or 1.0
    end

    if schema < 2 then
        -- Schema v2: renamed "frameAlpha" to "opacity", moved under "style"
        if not MyAddonDB.style then
            MyAddonDB.style = {}
        end
        MyAddonDB.style.opacity = MyAddonDB.frameAlpha or 1.0
        MyAddonDB.frameAlpha    = nil   -- remove old key
    end

    if schema < 3 then
        -- Schema v3: added color table
        if not MyAddonDB.style.color then
            MyAddonDB.style.color = { r = 1, g = 1, b = 1, a = 1 }
        end
    end

    -- Stamp with current schema version
    MyAddonDB.schema = CURRENT_SCHEMA
end

-- Call from ADDON_LOADED handler (or AceAddon:OnInitialize)
MigrateDB()
```

Key rules:
- Never wipe data unless the user explicitly resets.
- Check each schema version in order so a user upgrading across multiple versions gets all migrations applied.
- Stamp the schema version at the end, not at the beginning.

---

## 6. Addon Communications

Addon messages allow addons to communicate between clients in the same group or channel.

### Registering a Prefix

Prefixes must be registered before messages can be received. Do this in `ADDON_LOADED`.

```lua
local PREFIX = "MyAddon"

local function OnAddonLoaded()
    local registered = C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    if not registered then
        print("MyAddon: failed to register message prefix")
    end
end
```

### Sending a Message

```lua
-- channel values: "PARTY", "RAID", "GUILD", "WHISPER", "INSTANCE_CHAT"
C_ChatInfo.SendAddonMessage(PREFIX, "hello:world", "PARTY")

-- Whisper to a specific player:
C_ChatInfo.SendAddonMessage(PREFIX, "sync:data", "WHISPER", "PlayerName-Realm")
```

### Receiving a Message

```lua
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == PREFIX then
        -- parse message
        local cmd, data = message:match("^([^:]+):(.*)$")
        if cmd == "hello" then
            print("Got hello from", sender, "data:", data)
        end
    end
end)
```

### INSTANCE RESTRICTION NOTE

**`C_ChatInfo.SendAddonMessage` is blocked inside instances in WoW 12.0.** Attempting to send addon messages while inside a dungeon or raid instance will silently fail or return an error. Design your communication logic to handle this gracefully:

```lua
local function SendSafely(prefix, msg, channel)
    -- IsInInstance returns: inInstance (bool), instanceType (string)
    local inInstance = select(1, IsInInstance())
    if inInstance then
        -- Cannot send addon messages from inside an instance in 12.0
        return false
    end
    C_ChatInfo.SendAddonMessage(prefix, msg, channel)
    return true
end
```

---

## 7. Performance Patterns

### (a) OnUpdate Throttle with Elapsed Accumulator

`OnUpdate` fires every rendered frame (60+ times per second). Throttle heavy operations with an elapsed accumulator.

```lua
local UPDATE_INTERVAL = 0.2   -- run logic at most 5 times per second
local elapsed_total = 0

frame:SetScript("OnUpdate", function(self, elapsed)
    elapsed_total = elapsed_total + elapsed
    if elapsed_total < UPDATE_INTERVAL then
        return   -- not enough time has passed
    end
    elapsed_total = 0   -- reset accumulator

    -- Heavy work goes here — runs at ~5 FPS regardless of render FPS
    UpdateAllUnitFrames()
end)
```

For adaptive intervals, vary `UPDATE_INTERVAL` based on whether the player is in combat:

```lua
local function GetUpdateInterval()
    return InCombatLockdown() and 0.05 or 0.5
end

frame:SetScript("OnUpdate", function(self, elapsed)
    elapsed_total = elapsed_total + elapsed
    if elapsed_total < GetUpdateInterval() then return end
    elapsed_total = 0
    DoWork()
end)
```

### (b) Frame Pooling with CreateFramePool()

Creating and destroying frames is expensive. Use `CreateFramePool` to reuse frame objects.

```lua
-- Create a pool of "Button" frames with the given template
local pool = CreateFramePool("Button", UIParent, "MyButtonTemplate")

-- Acquire a frame from the pool (creates a new one if pool is empty)
local btn = pool:Acquire()
btn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
btn:Show()

-- Return a frame to the pool when done (hides and resets it)
pool:Release(btn)

-- Release all active frames at once (e.g., when clearing a list)
pool:ReleaseAll()
```

Custom reset function (called on release before the frame is recycled):

```lua
local pool = CreateFramePool("Button", UIParent, "MyButtonTemplate",
    function(framePool, frame)
        -- Custom cleanup: reset text, hide sub-elements, etc.
        frame.label:SetText("")
        frame.icon:SetTexture(nil)
    end
)
```

### (c) Lazy Loading via ADDON_LOADED

Defer module initialization until the addon's SavedVariables are ready. Avoid doing work at file-load time.

```lua
-- module.lua — expensive initialization deferred until ADDON_LOADED
local AddonName, ns = ...

ns.MyModule = {}

local function InitModule()
    -- Safe to access MyAddonDB and other modules here
    ns.MyModule.config = MyAddonDB.moduleConfig or {}
    ns.MyModule.frame  = CreateFrame("Frame", nil, UIParent)
    ns.MyModule.frame:SetSize(200, 100)
    ns.MyModule.frame:SetPoint("CENTER")
    -- Register module events
    ns.MyModule.frame:RegisterEvent("UNIT_HEALTH")
    ns.MyModule.frame:SetScript("OnEvent", ns.MyModule.OnEvent)
end

-- Listen for the addon's own ADDON_LOADED event
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == AddonName then
        self:UnregisterEvent("ADDON_LOADED")
        InitModule()
    end
end)
```

This ensures `MyAddonDB` exists and all files have executed before any module tries to use shared state.
