-- Core.lua
-- Event framework and initialisation for MyAddon (Midnight 12.0+)

local AddonName, ns = ...

-- Default saved variable values
local DEFAULTS = {
    version = 1,
}

-- Global OnLoad callbacks referenced by UI.xml
function MyAddonFrame_OnLoad(self)
    -- Main container frame loaded; nothing to do here at load time.
end

function MyAddonHealthBar_OnLoad(self)
    -- Health bar frame loaded; set initial bar texture and range.
    self:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    self:SetMinMaxValues(0, 1)
    self:SetValue(1)
    self:SetStatusBarColor(0, 1, 0)  -- default: green
end

-- Main event dispatch frame
local frame = CreateFrame("Frame")
ns.frame = frame

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_HEALTH")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == AddonName then
            -- Version-gated SavedVariables initialisation
            if MyAddonDB == nil or MyAddonDB.version == nil or MyAddonDB.version < 1 then
                MyAddonDB = {}
                for k, v in pairs(DEFAULTS) do
                    MyAddonDB[k] = v
                end
            end
            ns.db = MyAddonDB

            -- Initialise secret-value handlers after saved variables are ready
            ns.SecretHandlers.Init()
        end
    elseif event == "PLAYER_LOGIN" then
        print("|cff00ff00[MyAddon]|r Loaded. Secret-aware health bar active.")
    elseif event == "UNIT_HEALTH" then
        local unit = ...
        if unit == "player" then
            ns.SecretHandlers.UpdateHealthBar(unit)
        end
    end
end)
