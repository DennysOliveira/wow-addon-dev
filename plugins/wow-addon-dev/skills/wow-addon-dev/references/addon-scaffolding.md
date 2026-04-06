# WoW Addon Scaffolding Reference (April 2026)

A self-contained guide to creating a valid WoW 12.0 (Midnight) addon from scratch.

---

## Table of Contents

1. [Minimal File Structure](#1-minimal-file-structure)
2. [Namespace Pattern](#2-namespace-pattern)
3. [SavedVariables](#3-savedvariables)
4. [Slash Commands](#4-slash-commands)
5. [Event Handling](#5-event-handling)
6. [Complete Hello World](#6-complete-hello-world)

---

## 1. Minimal File Structure

A valid WoW addon requires at minimum two files: a `.toc` manifest and at least one `.lua` file. Both must live in a folder whose name matches the `.toc` filename.

```
Interface/Addons/MyAddon/
├── MyAddon.toc          -- Required: addon manifest
└── MyAddon.lua          -- Required: at least one Lua file
```

Multi-file layout (typical production addon):

```
Interface/Addons/MyAddon/
├── MyAddon.toc
├── Core.lua             -- Initialization, event frame
├── Config.lua           -- SavedVariables + defaults
├── UI.lua               -- Frame creation
└── Utils.lua            -- Shared helpers
```

File load order is determined by the order listed in the `.toc`. Files load top-to-bottom.

---

## 2. Namespace Pattern

WoW's Lua environment is a single shared global table. To avoid collisions with other addons, every file in your addon should use the two-argument vararg passed to each file by the loader.

```lua
-- MyAddon.lua (and every other file in the addon)
local AddonName, ns = ...
-- AddonName (string): "MyAddon" — matches the folder name
-- ns (table):         shared namespace table, same reference in all files
```

Define shared state in one file, access it everywhere:

```lua
-- Core.lua
local AddonName, ns = ...
ns.db = {}         -- will hold SavedVariables
ns.version = 1

-- UI.lua
local AddonName, ns = ...
local version = ns.version   -- reads from the shared table
```

Why this works: the loader creates `ns` once per addon and passes the same table reference to every file. No globals needed.

---

## 3. SavedVariables

### TOC Declaration

```toc
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB
```

`SavedVariables` are restored by the game engine before `ADDON_LOADED` fires for your addon. Declaring them in the TOC is required — undeclared variables are not saved.

### Accessing in ADDON_LOADED

```lua
local AddonName, ns = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == AddonName then
        self:UnregisterEvent("ADDON_LOADED")
        MyAddon_Init()
    end
end)
```

### Version-Gated Defaults

Always check whether `SavedVariables` exists and whether the stored schema version matches before applying defaults. This prevents overwriting user data on upgrade and handles first-run initialization.

```lua
local CURRENT_VERSION = 2

local function InitDB()
    -- First run: MyAddonDB is nil (game never saved it)
    if MyAddonDB == nil then
        MyAddonDB = {}
    end

    -- Version gate: apply defaults if schema is old or missing
    if (MyAddonDB.version or 0) < CURRENT_VERSION then
        -- Set any missing keys to defaults; preserve existing values
        if MyAddonDB.showGreeting == nil then
            MyAddonDB.showGreeting = true
        end
        if MyAddonDB.greetingText == nil then
            MyAddonDB.greetingText = "Hello, Azeroth!"
        end
        MyAddonDB.version = CURRENT_VERSION
    end
end
```

Call `InitDB()` from your `ADDON_LOADED` handler before reading any `MyAddonDB` fields.

---

## 4. Slash Commands

Register slash commands using two globals: `SlashCmdList` holds the handler function; `SLASH_<KEY>1` (and optionally `SLASH_<KEY>2`, etc.) holds the command string(s).

```lua
-- The KEY must match between SlashCmdList and SLASH_<KEY>N
SlashCmdList["MYADDON"] = function(msg)
    local cmd = strtrim(msg):lower()
    if cmd == "help" or cmd == "" then
        print("|cff00ff00MyAddon|r commands:")
        print("  /myaddon help    — show this message")
        print("  /myaddon status  — show current status")
        print("  /myaddon reset   — reset to defaults")
    elseif cmd == "status" then
        print("MyAddon is loaded. Version:", MyAddonDB and MyAddonDB.version or "?")
    elseif cmd == "reset" then
        MyAddonDB = nil
        print("MyAddon: settings reset. Reload UI to apply.")
    else
        print("MyAddon: unknown command '" .. cmd .. "'. Type /myaddon help.")
    end
end

SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"   -- optional second alias
```

Rules:
- The key in `SlashCmdList` and in the `SLASH_<KEY>N` variable name must be identical and uppercase.
- Register these at file scope (not inside a function) so they are available as soon as the file loads.

---

## 5. Event Handling

### Creating an Event Frame

```lua
local frame = CreateFrame("Frame", "MyAddonEventFrame", UIParent)
```

The second argument (name) is optional but useful for debugging — named frames appear in `/fstack` output.

### Registering Events

```lua
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
```

### OnEvent Dispatcher Pattern

Use an if/elseif chain inside a single `OnEvent` handler. This is more efficient than one frame per event.

```lua
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == AddonName then
            self:UnregisterEvent("ADDON_LOADED")
            OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        OnPlayerLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        OnEnteringWorld(isInitialLogin, isReloadingUi)
    end
end)
```

### Unregistering Events

Always unregister one-shot events (like `ADDON_LOADED`) after handling them to avoid unnecessary callbacks.

```lua
self:UnregisterEvent("ADDON_LOADED")
```

---

## 6. Complete Hello World

A minimal but fully functional addon that demonstrates all patterns above.

### MyAddon.toc

```toc
## Interface: 120001
## Title: MyAddon
## Notes: A minimal WoW 12.0 Hello World addon
## Author: YourName
## Version: 1.0.0
## SavedVariables: MyAddonDB

MyAddon.lua
```

### MyAddon.lua

```lua
-- MyAddon.lua
-- Minimal WoW 12.0 addon. Interface: 120001

local AddonName, ns = ...

-- Constants
local CURRENT_VERSION = 1

-- Forward declarations
local OnAddonLoaded, OnPlayerLogin

-- Version-gated SavedVariables initialization
local function InitDB()
    if MyAddonDB == nil then
        MyAddonDB = {}
    end
    if (MyAddonDB.version or 0) < CURRENT_VERSION then
        if MyAddonDB.greeting == nil then
            MyAddonDB.greeting = "Hello from MyAddon!"
        end
        MyAddonDB.version = CURRENT_VERSION
    end
    ns.db = MyAddonDB
end

-- Called when this addon's saved variables are ready
OnAddonLoaded = function()
    InitDB()
    -- Slash command registered here so ns.db is available
    SlashCmdList["MYADDON"] = function(msg)
        print("|cff00ff00MyAddon|r: " .. (ns.db.greeting or "Hi!"))
    end
    SLASH_MYADDON1 = "/myaddon"
    print("|cff00ff00MyAddon|r loaded. Type /myaddon to say hello.")
end

-- Called when the player is fully in the world
OnPlayerLogin = function()
    print("|cff00ff00MyAddon|r: Welcome, " .. UnitName("player") .. "!")
end

-- Event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == AddonName then
            self:UnregisterEvent("ADDON_LOADED")
            OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        OnPlayerLogin()
    end
end)
```

### What This Addon Does

| Trigger | Output |
|---------|--------|
| Addon loads | Prints "MyAddon loaded. Type /myaddon to say hello." |
| Player enters world | Prints "MyAddon: Welcome, \<PlayerName\>!" |
| `/myaddon` | Prints the greeting stored in SavedVariables |

First run initializes `MyAddonDB` with `{ version = 1, greeting = "Hello from MyAddon!" }`. Subsequent loads skip initialization because `version == CURRENT_VERSION`.
