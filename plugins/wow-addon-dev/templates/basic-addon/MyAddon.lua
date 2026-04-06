-- MyAddon.lua
-- Minimal WoW addon for Midnight (Interface 120001 / 12.0+)

local AddonName, ns = ...

-- Default saved variable values
local DEFAULTS = {
    version = 1,
    greeting = "Hello from MyAddon!",
}

-- Main event frame
local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == AddonName then
            -- Version-gated initialisation of SavedVariables
            if MyAddonDB == nil or MyAddonDB.version == nil or MyAddonDB.version < 1 then
                MyAddonDB = {}
                for k, v in pairs(DEFAULTS) do
                    MyAddonDB[k] = v
                end
            end
            ns.db = MyAddonDB
        end
    elseif event == "PLAYER_LOGIN" then
        if ns.db then
            print("|cff00ff00[MyAddon]|r " .. ns.db.greeting)
        end
    end
end)

-- Slash command: /myaddon
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
    local cmd = strtrim(msg or "")
    if cmd == "" or cmd == "status" then
        print("|cff00ff00[MyAddon]|r Version " .. (ns.db and tostring(ns.db.version) or "unknown") .. " is loaded.")
    else
        print("|cff00ff00[MyAddon]|r Unknown command: " .. cmd)
        print("|cff00ff00[MyAddon]|r Usage: /myaddon [status]")
    end
end
