# WoW Lua API Quick Reference (April 2026)

Quick-reference tables for the most commonly used WoW Lua APIs in Midnight 12.0. Interface version: 120001.

---

## Legend

| Marker | Meaning |
|--------|---------|
| 🔒 | Secret-value-affected — result may be a secret value; do NOT perform arithmetic, comparison, or string operations on it. Pass directly to accepted native APIs (e.g., `StatusBar:SetValue()`). |
| ✅ | Safe to use directly — result is a normal Lua value. |

---

## Table of Contents

1. [Unit APIs (12)](#1-unit-apis)
2. [Spell APIs (10)](#2-spell-apis)
3. [Combat APIs (8)](#3-combat-apis)
4. [UI / Frame APIs (12)](#4-ui--frame-apis)
5. [Utility APIs (8)](#5-utility-apis)

---

## 1. Unit APIs

| Function Signature | Description | Marker |
|--------------------|-------------|--------|
| `UnitHealth(unit)` → number | Current health of the unit. Returns a secret value in instances/combat for enemy units. | 🔒 |
| `UnitHealthMax(unit)` → number | Maximum health. Non-secret for the player unit since beta relaxation; may still be secret for enemies in instances. | 🔒 |
| `UnitPower(unit [, powerType])` → number | Current power (mana, rage, energy, etc.). Secret in combat for most units. | 🔒 |
| `UnitPowerMax(unit [, powerType])` → number | Maximum power for the given power type. | 🔒 |
| `UnitName(unit)` → name, realm | Display name and realm of the unit. Realm may be nil for same-realm players. | ✅ |
| `UnitLevel(unit)` → number | Level of the unit. Returns -1 for scaled/boss creatures. | ✅ |
| `UnitClass(unit)` → className, classFile, classID | Localized class name, English file token (e.g., "WARRIOR"), and numeric class ID. | ✅ |
| `UnitRace(unit)` → raceName, raceFile, raceID | Localized race name, English file token, and numeric race ID. | ✅ |
| `UnitExists(unit)` → boolean | Returns true if the unit token refers to an existing unit. | ✅ |
| `UnitIsDeadOrGhost(unit)` → boolean | Returns true if the unit is dead or in ghost form. | ✅ |
| `UnitAffectingCombat(unit)` → boolean | Returns true if the unit is in combat. Replaces the old `UnitInCombat` for most uses. | ✅ |
| `UnitGUID(unit)` → string\|nil | Returns the GUID string for the unit, or nil. GUID is secret for enemies in instances. | 🔒 |

---

## 2. Spell APIs

| Function Signature | Description | Marker |
|--------------------|-------------|--------|
| `GetSpellInfo(spellID)` → name, rank, icon, ... | **Deprecated in 12.0.** Returns spell metadata by ID. Use `C_Spell.GetSpellInfo` instead. | ✅ |
| `C_Spell.GetSpellInfo(spellID)` → SpellInfo\|nil | Returns a `SpellInfo` table: `{ name, iconID, castTime, minRange, maxRange, spellID }`. Preferred 12.0 form. | ✅ |
| `C_Spell.GetSpellName(spellID)` → string\|nil | Returns only the spell name. Lightweight alternative when only the name is needed. | ✅ |
| `C_Spell.GetSpellCooldown(spellID)` → startTime, duration, isEnabled, modRate | Cooldown data for the spell. `startTime` of 0 means no cooldown active. | ✅ |
| `C_Spell.GetSpellCharges(spellID)` → charges, maxCharges, start, duration, chargeModRate | Charge data for spells with multiple charges. Returns nil if the spell has no charges. | ✅ |
| `IsUsableSpell(spellID)` → isUsable, notEnoughMana | **Deprecated in 12.0.** Use `C_Spell.IsSpellUsable` instead. | ✅ |
| `C_Spell.IsSpellUsable(spellID)` → isUsable, notEnoughMana | Returns whether the spell can be cast (not on cooldown, sufficient resources). | ✅ |
| `GetSpellTexture(spellID)` → fileDataID | **Deprecated in 12.0.** Returns the icon texture ID for a spell. Use `C_Spell.GetSpellTexture`. | ✅ |
| `C_Spell.GetSpellTexture(spellID)` → fileDataID\|nil | Returns the icon texture file data ID for the spell. Preferred 12.0 form. | ✅ |
| `CastSpellByID(spellID [, target])` → void | Casts the spell by numeric ID. Taint-restricted in combat; must be called from secure code or hardware event. | ✅ |

---

## 3. Combat APIs

| Function Signature | Description | Marker |
|--------------------|-------------|--------|
| `UnitAura(unit, index [, filter])` → name, icon, count, ... | **Deprecated in 12.0.** Returns aura data at the given index. Use `C_UnitAuras` APIs instead. | 🔒 |
| `C_UnitAuras.GetAuraDataByIndex(unit, index [, filter])` → AuraData\|nil | Returns a `AuraData` table for the aura at the given index. Preferred 12.0 form. | 🔒 |
| `C_UnitAuras.GetPlayerAuraBySpellID(spellID)` → AuraData\|nil | Returns the player's own aura matching the spell ID, or nil if not present. | 🔒 |
| `UnitCastingInfo(unit)` → name, text, texture, startTime, endTime, ... | Returns information about the spell the unit is currently casting. `startTime`/`endTime` may be secret in instances. | 🔒 |
| `UnitChannelInfo(unit)` → name, text, texture, startTime, endTime, ... | Returns information about the spell the unit is currently channeling. | 🔒 |
| `UnitThreatSituation(unit [, mob])` → status | Threat status: 0 = no threat, 1 = lower, 2 = tanking but not highest, 3 = tanking and highest. | ✅ |
| `UnitDetailedThreatSituation(unit, mob)` → isTanking, status, scaledPercent, rawPercent, threatValue | Detailed threat breakdown. `threatValue` may be secret in instances. | 🔒 |
| `InCombatLockdown()` → boolean | Returns true if the player is in combat lockdown. Secure code cannot be called while this returns true. | ✅ |

---

## 4. UI / Frame APIs

| Function Signature | Description | Marker |
|--------------------|-------------|--------|
| `CreateFrame(frameType [, name, parent, template, id])` → Frame | Creates a new widget. `frameType` is a string like `"Frame"`, `"Button"`, `"StatusBar"`. Returns the new frame object. | ✅ |
| `frame:SetPoint(point [, relativeTo, relativePoint, xOfs, yOfs])` | Anchors the frame. `point` is a string like `"CENTER"`, `"TOPLEFT"`. Clears conflicting anchor first if needed. | ✅ |
| `frame:Show()` | Makes the frame visible. Triggers `OnShow` script if set. | ✅ |
| `frame:Hide()` | Hides the frame. Triggers `OnHide` script if set. | ✅ |
| `frame:RegisterEvent(event)` | Registers the frame to receive the named event. `OnEvent` script will be called when it fires. | ✅ |
| `frame:SetScript(handler, func)` | Sets a script handler function (e.g., `"OnEvent"`, `"OnUpdate"`). Pass `nil` to clear. | ✅ |
| `StatusBar:SetValue(value)` | Sets the current fill value of a StatusBar. Accepts secret values — the only safe way to display secret numeric data. | 🔒 |
| `StatusBar:SetMinMaxValues(min, max)` | Sets the range for the StatusBar fill. Use with secret min/max where applicable. | 🔒 |
| `StatusBar:SetStatusBarColor(r, g, b [, a])` | Sets the fill color. Accepts output from `ColorCurve:Evaluate()` directly. | ✅ |
| `frame:GetWidth()` → number | Returns the frame's current width in pixels. | ✅ |
| `frame:GetHeight()` → number | Returns the frame's current height in pixels. | ✅ |
| `frame:SetSize(width, height)` | Sets both width and height in one call. Equivalent to calling `SetWidth` + `SetHeight`. | ✅ |

---

## 5. Utility APIs

| Function Signature | Description | Marker |
|--------------------|-------------|--------|
| `C_Timer.After(seconds, callback)` | Schedules `callback` to be called once after `seconds` delay. Not cancellable; use `NewTicker` for that. | ✅ |
| `C_Timer.NewTicker(seconds, callback [, iterations])` → ticker | Schedules `callback` repeatedly every `seconds`. Returns a ticker object; call `ticker:Cancel()` to stop. | ✅ |
| `GetTime()` → number | Returns the current client time in seconds (float). Use for elapsed-time calculations in `OnUpdate`. | ✅ |
| `format(fmt, ...)` → string | WoW alias for `string.format`. Formats a string using C-style format specifiers. | ✅ |
| `tinsert(table [, pos], value)` | WoW alias for `table.insert`. Appends or inserts a value into a table. | ✅ |
| `tremove(table [, pos])` → value | WoW alias for `table.remove`. Removes and returns a value from a table. | ✅ |
| `wipe(table)` → table | Clears all entries from a table in-place. Faster than creating a new table for reuse. | ✅ |
| `print(...)` | Prints arguments to the default chat frame. Uses `tostring()` on each argument. | ✅ |
