# API Migration Guide: Pre-12.0 to Midnight (April 2026)

A complete guide for migrating WoW addons from pre-12.0 (The War Within / 11.x) to Midnight (12.0+). Covers removed APIs, deprecated Lua files, replacements, and new system behavior.

---

## Table of Contents

1. [CLEU Removal](#cleu-removal)
2. [Deprecated File Mapping](#deprecated-file-mapping)
3. [New 12.0 APIs](#new-120-apis)
4. [Spell Whitelisting](#spell-whitelisting)
5. [Instance Restrictions](#instance-restrictions)

---

## CLEU Removal

### What CLEU Was

`COMBAT_LOG_EVENT_UNFILTERED` (CLEU) was the primary event used by addon authors to intercept all combat activity in the game. Every damage event, heal, spell cast, aura application, and death fired through CLEU with structured payloads containing unit GUIDs, spell IDs, amounts, and flags. It was the backbone of damage meters (Details!, Skada), boss mods (DBM, BigWigs), WeakAuras combat triggers, and nearly every combat-tracking addon.

Typical pre-12.0 usage:

```lua
-- PRE-12.0 PATTERN — NO LONGER WORKS IN MIDNIGHT
-- DO NOT USE in 12.0+ addons

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, event)
    local timestamp, subevent, hideCaster,
          sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags,
          ... = CombatLogGetCurrentEventInfo()

    if subevent == "SPELL_DAMAGE" then
        local spellID, spellName, spellSchool, amount = ...
        -- Process damage: amount is now SECRET in 12.0, this line errors
        totalDamage = totalDamage + amount  -- INVALID in 12.0
    end
end)
```

### Why It Was Removed

Blizzard removed effective CLEU access as the centerpiece of the "addon disarmament" initiative in Midnight. The core problem: CLEU gave addon code raw access to combat numbers (damage, healing, absorbs, spell IDs, GUIDs) which:

- Enabled third-party damage meters to expose performance data Blizzard considers socially harmful in group content
- Allowed addons to reconstruct enemy cooldown and defensive states with high accuracy
- Provided data that could be used to identify and harass underperforming players

The `COMBAT_LOG_EVENT_UNFILTERED` event itself still fires in some limited contexts, but:
- All numeric payloads (damage amounts, heal amounts, absorbs) are **secret values** when in instances or combat
- GUIDs and unit names for non-player units are **secret** in instances
- Arithmetic on these values from addon (tainted) code is blocked

For practical purposes, CLEU-based damage tracking **does not work** in 12.0+ group content.

### What Replaces CLEU

For the use cases CLEU previously served, Midnight provides targeted event-based replacements:

| Old CLEU sub-event | New approach |
|-------------------|--------------|
| `SPELL_CAST_START` (own casts) | `UNIT_SPELLCAST_START` — non-secret outside combat |
| `SPELL_CAST_SUCCESS` (own) | `UNIT_SPELLCAST_SUCCEEDED` |
| `SPELL_CAST_FAILED` (own) | `UNIT_SPELLCAST_FAILED` |
| `SPELL_DAMAGE` (own damage) | Secret value; use `UnitHealPredictionCalculator` pattern |
| `UNIT_DIED` | New unit death event (GUID payload secret in instances) |
| Aura tracking | `UNIT_AURA` event (secret in instances) |
| Cooldown tracking | `GetSpellCooldown()` — returns `Duration` objects for secrets |

### Migration Example

```lua
-- BEFORE (pre-12.0): Track own spellcasts via CLEU
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, event)
    local _, subevent, _, sourceGUID, _, _, _,
          destGUID, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

    if subevent == "SPELL_CAST_SUCCESS" then
        local playerGUID = UnitGUID("player")
        if sourceGUID == playerGUID then  -- BROKEN: sourceGUID may be secret
            print("Cast: " .. spellName)  -- BROKEN: spellName may be secret
        end
    end
end)

-- AFTER (12.0+): Use UNIT_SPELLCAST events for own casts
local frame = CreateFrame("Frame")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    -- unit is "player" (non-secret)
    -- spellID is non-secret for player's own casts outside combat
    -- castGUID (sequence ID) is always non-secret
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        print("Cast: " .. spellInfo.name)
    end
end)
```

---

## Deprecated File Mapping

These Lua files ship with the 12.0 client in a `Deprecated_` state. Functions from them still exist but emit deprecation warnings and will be removed in a future patch. Migrate immediately.

### Deprecated_CombatLog.lua

The most critical deprecated file. Previously provided `CombatLogGetCurrentEventInfo()` and related helpers.

| Deprecated Function | Replacement | Notes |
|--------------------|-------------|-------|
| `CombatLogGetCurrentEventInfo()` | No direct equivalent | Use `UNIT_SPELLCAST_*` events for own casts |
| `CombatLogClearEntries()` | No equivalent | CLEU concept removed |
| `CombatLogSetCurrentEntry()` | No equivalent | CLEU concept removed |
| `CombatLogGetNumEntries()` | No equivalent | CLEU concept removed |

**Migration path:** Redesign around `UNIT_SPELLCAST_*` unit events. Accept that raw combat numbers are inaccessible in instances.

### Deprecated_BattleNet.lua

Battle.net social APIs consolidated into `C_BattleNet` namespace in 11.x, deprecated wrapper remains.

| Deprecated Function | Replacement |
|--------------------|-------------|
| `BNGetNumFriends()` | `C_BattleNet.GetFriendNumAccounts()` |
| `BNGetFriendInfo(friendIndex)` | `C_BattleNet.GetFriendAccountInfo(friendIndex)` |
| `BNGetNumFriendGameAccounts(friendIndex)` | `C_BattleNet.GetFriendNumGameAccounts(friendIndex)` |
| `BNGetFriendGameAccountInfo(friendIndex, accountIndex)` | `C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex)` |
| `BNSendWhisper(presenceID, message)` | `C_BattleNet.SendWhisper(gameAccountID, message)` |
| `BNGetGameAccountInfo(gameAccountID)` | `C_BattleNet.GetGameAccountInfoByID(gameAccountID)` |

### Deprecated_ChatInfo.lua

Chat system APIs moved to `C_ChatInfo` namespace.

| Deprecated Function | Replacement |
|--------------------|-------------|
| `GetChatWindowInfo(index)` | `C_ChatInfo.GetChatWindowInfo(index)` |
| `GetChatWindowSavedPosition(index)` | `C_ChatInfo.GetChatWindowSavedPosition(index)` |
| `GetChatWindowSavedDimensions(index)` | `C_ChatInfo.GetChatWindowSavedDimensions(index)` |
| `AddChatWindowChannel(index, channel)` | `C_ChatInfo.AddChatWindowChannel(index, channel)` |
| `RemoveChatWindowChannel(index, channel)` | `C_ChatInfo.RemoveChatWindowChannel(index, channel)` |
| `GetChannelDisplayInfo(index)` | `C_ChatInfo.GetChannelDisplayInfo(index)` |
| `RegisterAddonMessagePrefix(prefix)` | `C_ChatInfo.RegisterAddonMessagePrefix(prefix)` |
| `SendAddonMessage(prefix, text, type, target)` | `C_ChatInfo.SendAddonMessage(prefix, text, type, target)` |

**Note:** In instances, addon messages (SendAddonMessage) are **blocked**. Check `C_RestrictedActions.IsInRestrictedInstance()` before sending.

### Deprecated_SpellBook.lua

SpellBook APIs moved to `C_SpellBook` namespace.

| Deprecated Function | Replacement |
|--------------------|-------------|
| `GetSpellBookItemInfo(slot, bookType)` | `C_SpellBook.GetSpellBookItemInfo(slot, bookType)` |
| `GetSpellBookItemName(slot, bookType)` | `C_SpellBook.GetSpellBookItemName(slot, bookType)` |
| `GetNumSpellTabs()` | `C_SpellBook.GetNumSpellBookSkillLines()` |
| `GetSpellTabInfo(tabIndex)` | `C_SpellBook.GetSpellBookSkillLineInfo(tabIndex)` |
| `HasPetSpells()` | `C_SpellBook.HasPetSpells()` |
| `GetNumSpellTabs()` | `C_SpellBook.GetNumSpellBookSkillLines()` |
| `SpellBookItemHasRange(slot, bookType)` | `C_SpellBook.SpellBookItemHasRange(slot, bookType)` |
| `IsHarmfulSpell(slot, bookType)` | `C_SpellBook.IsHarmfulSpell(slot, bookType)` |
| `IsHelpfulSpell(slot, bookType)` | `C_SpellBook.IsHelpfulSpell(slot, bookType)` |

### Deprecated_InstanceEncounter.lua

Instance and encounter APIs moved to `C_EncounterJournal` and `C_Scenario`.

| Deprecated Function | Replacement |
|--------------------|-------------|
| `GetInstanceInfo()` | `C_Map.GetInstanceInfo()` (partial) / `IsInInstance()` |
| `GetCurrentEncounterID()` | `C_EncounterJournal.GetCurrentEncounter()` |
| `GetBossEmoteReturns()` | `C_EncounterJournal` namespace |
| `IsEncounterInProgress()` | `C_EncounterJournal.IsEncounterInProgress()` |
| `GetLFGDungeonEncounterInfo(dungeonID, index)` | `C_LFGList.GetEncounterInfo(dungeonID, index)` |
| `GetScenarioInfo()` | `C_Scenario.GetScenarioInfo()` |
| `GetScenarioStepInfo()` | `C_Scenario.GetStepInfo()` |

### Deprecated_SpellScript.lua

Spell scripting helpers moved to `C_Spell` namespace.

| Deprecated Function | Replacement |
|--------------------|-------------|
| `GetSpellInfo(spellID)` | `C_Spell.GetSpellInfo(spellID)` → returns table |
| `GetSpellDescription(spellID)` | `C_Spell.GetSpellDescription(spellID)` |
| `GetSpellCooldown(spellID)` | `C_Spell.GetSpellCooldown(spellID)` |
| `GetSpellCharges(spellID)` | `C_Spell.GetSpellCharges(spellID)` |
| `GetSpellPowerCost(spellID)` | `C_Spell.GetSpellPowerCost(spellID)` |
| `GetSpellTexture(spellID)` | `C_Spell.GetSpellTexture(spellID)` |
| `IsSpellKnown(spellID)` | `C_Spell.IsSpellKnown(spellID)` |
| `IsCurrentSpell(spellID)` | `C_Spell.IsCurrentSpell(spellID)` |
| `IsAutoRepeatSpell(spellID)` | `C_Spell.IsAutoRepeatSpell(spellID)` |

**Important:** `C_Spell.GetSpellInfo()` returns a **table** `{name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon}` instead of multiple return values. Update all callers.

```lua
-- BEFORE
local name, rank, icon, castTime = GetSpellInfo(spellID)

-- AFTER
local info = C_Spell.GetSpellInfo(spellID)
if info then
    local name = info.name
    local icon = info.iconID
    local castTime = info.castTime
end
```

---

## New 12.0 APIs

### C_CurveUtil

Maps secret numeric values to outputs without exposing raw data.

| Function | Signature | Returns | Purpose |
|----------|-----------|---------|---------|
| `CreateCurve` | `C_CurveUtil.CreateCurve(keyValues)` | `Curve` | Numeric-to-numeric mapping |
| `CreateColorCurve` | `C_CurveUtil.CreateColorCurve(colorKeyValues)` | `ColorCurve` | Numeric-to-RGBA mapping |
| `EvaluateColorFromBoolean` | `C_CurveUtil.EvaluateColorFromBoolean(secretBool, trueColor, falseColor)` | `r,g,b,a` | Color pick from secret boolean |
| `EvaluateColorValueFromBoolean` | `C_CurveUtil.EvaluateColorValueFromBoolean(secretBool, trueVal, falseVal)` | secret value | Value pick from secret boolean |

### C_DurationUtil

Wraps secret time values for use with timer widgets.

| Function | Signature | Returns | Purpose |
|----------|-----------|---------|---------|
| `CreateDuration` | `C_DurationUtil.CreateDuration(secretTime)` | `Duration` | Wrap secret time value |

### C_Secrets

Evaluates predicates on secret values, returning secret booleans.

| Function | Signature | Returns | Purpose |
|----------|-----------|---------|---------|
| `IsLessThan` | `C_Secrets.IsLessThan(a, b)` | secret boolean | Safe `a < b` for secrets |
| `IsGreaterThan` | `C_Secrets.IsGreaterThan(a, b)` | secret boolean | Safe `a > b` for secrets |
| `IsEqual` | `C_Secrets.IsEqual(a, b)` | secret boolean | Safe `a == b` for secrets |
| `Select` | `C_Secrets.Select(cond, ifTrue, ifFalse)` | secret value | Conditional pick without branching |

### C_RestrictedActions

Tests current restriction state.

| Function | Signature | Returns | Purpose |
|----------|-----------|---------|---------|
| `IsRestricted` | `C_RestrictedActions.IsRestricted()` | boolean | Any restriction active |
| `IsInRestrictedInstance` | `C_RestrictedActions.IsInRestrictedInstance()` | boolean | In restricted instance |
| `IsInRestrictedCombat` | `C_RestrictedActions.IsInRestrictedCombat()` | boolean | In restricted combat |
| `GetRestrictions` | `C_RestrictedActions.GetRestrictions()` | table | Active restriction flags |

### issecretvalue() Global

```lua
local isSecret = issecretvalue(value)  -- returns boolean
```

New global function. Safe to call on any value including `nil`.

### CreateUnitHealPredictionCalculator()

```lua
local calc = CreateUnitHealPredictionCalculator(unit)
```

Replaces direct heal prediction arithmetic. Drives prediction bars natively.

### StatusBar Enhancements

- `StatusBar:SetValue(secretValue)` — accepts secret values directly
- `StatusBar:SetMinMaxValues(min, secretMax)` — accepts secret max
- `StatusBar:SetStatusBarColor(r, g, b, a)` — accepts secret RGBA components
- Native smooth transitions built-in (no addon timer needed)
- Timer status bars: auto-update based on current time without addon polling

### Castbar Sequence ID

Every `UNIT_SPELLCAST_START` / `UNIT_SPELLCAST_SUCCEEDED` provides a `castGUID` (sequence ID) that:
- Increments monotonically per spellcast
- Is **never secret**
- Can be used to correlate cast start/end events

---

## Spell Whitelisting

### Definition

Blizzard maintains an internal whitelist of spells whose associated values (charges, resource amounts, cast data) are **explicitly exempted** from secret value treatment. These spells produce non-secret values from their APIs even during combat or in instances.

Whitelisting is determined by Blizzard and is not configurable by addon authors.

### Behavior

For whitelisted spells:
- `GetSpellCharges(spellID)` returns a plain number (not secret)
- Resource tracking APIs return plain values
- Addons can perform arithmetic on these values normally

For non-whitelisted spells in restricted contexts:
- Same APIs return secret values
- `issecretvalue()` returns `true`
- No arithmetic permitted

### Known Whitelisted Spells (as of 12.0.1, April 2026)

These were confirmed whitelisted during beta relaxation before launch:

| Spell | Class | Resource |
|-------|-------|----------|
| Maelstrom Weapon | Shaman (Enhancement) | Stacks/charges |
| Soul Fragments | Demon Hunter (Vengeance) | Fragment count |
| Skyriding (Vigor) charges | All | Vigor charges |

**Note:** Blizzard continues to add spells to the whitelist. Check `issecretvalue()` at runtime — do not hardcode assumptions. The whitelist grows with hotfixes.

```lua
-- Correct pattern: runtime check, not hardcoded assumption
local charges, maxCharges = GetSpellCharges(MAELSTROM_WEAPON_SPELL_ID)
if charges and not issecretvalue(charges) then
    -- Confirmed non-secret: safe arithmetic
    maelstromBar:SetMinMaxValues(0, maxCharges)
    maelstromBar:SetValue(charges)
    stackText:SetText(charges .. "/" .. maxCharges)
else
    -- Secret or nil: use secret-safe path
    if charges then
        maelstromBar:SetValue(charges)  -- SetValue accepts secret
    end
end
```

### Player Unit Exceptions (12.0 Launch Relaxation)

These APIs return **non-secret values for the player's own unit** (not other units):
- `UnitHealthMax("player")` — non-secret
- `UnitPowerMax("player", powerType)` — non-secret
- Empowered cast stages and percentages — non-secret
- Cast bar data for own casts — non-secret outside combat

---

## Instance Restrictions

### What Becomes Secret Inside Instances

| Data Type | Outside Instance | Inside Instance |
|-----------|-----------------|-----------------|
| `UnitHealth("target")` | Non-secret | **Secret** |
| `UnitHealthMax("target")` | Non-secret | **Secret** |
| `UnitHealth("player")` | Non-secret | Non-secret |
| `UnitHealthMax("player")` | Non-secret | Non-secret |
| Enemy GUIDs | Non-secret | **Secret** |
| Enemy names | Non-secret | **Secret** |
| Damage amounts | Non-secret | **Secret** |
| Heal amounts | Non-secret | **Secret** |
| Chat messages | Non-secret | **Secret** |

### Blocked APIs Inside Instances

These API categories are fully blocked (return `nil` or error) when inside a restricted instance:

| Category | Blocked Behavior |
|----------|-----------------|
| `C_ChatInfo.SendAddonMessage()` | Returns nil / blocked |
| `SendAddonMessage()` (deprecated) | Blocked |
| Inter-addon communication | All blocked |
| Enemy unit power values | Secret |
| Enemy cooldown state | Secret |

### Detecting Restriction State

```lua
-- Check before addon comm or sensitive operation
local function IsSafeToSendAddonMessage()
    return not C_RestrictedActions.IsInRestrictedInstance()
end

local function OnSomeEvent()
    if IsSafeToSendAddonMessage() then
        C_ChatInfo.SendAddonMessage("MYADDON", "data", "PARTY")
    end
end
```

### Design Pattern for Instance-Aware Addons

```lua
-- Maintain a restriction state flag, updated on zone change
local isRestricted = false

local restrictionFrame = CreateFrame("Frame")
restrictionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
restrictionFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
restrictionFrame:SetScript("OnEvent", function(self, event)
    isRestricted = C_RestrictedActions.IsRestricted()
    MyAddon:UpdateDisplayMode(isRestricted)
end)

function MyAddon:UpdateDisplayMode(restricted)
    if restricted then
        -- Switch to secret-safe display: no arithmetic on unit data
        self:EnableSecretMode()
    else
        -- Full functionality available
        self:EnableNormalMode()
    end
end
```
