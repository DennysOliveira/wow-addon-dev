# TOC File Structure (April 2026)

Complete reference for WoW addon `.toc` file format targeting Midnight (Interface 120001). Covers interface version encoding, multi-edition support, all new 12.0 fields, and edition-specific file naming.

---

## Table of Contents

1. [Interface Version Encoding](#interface-version-encoding)
2. [Multi-Edition Comma-Delimited Interface](#multi-edition-comma-delimited-interface)
3. [New 12.0 TOC Fields](#new-120-toc-fields)
4. [Edition-Specific File Naming](#edition-specific-file-naming)
5. [Complete Annotated TOC Example](#complete-annotated-toc-example)

---

## Interface Version Encoding

The `## Interface:` field contains a 6-digit integer that encodes the WoW client version as `MMmmpp`:

| Segment | Meaning | Example |
|---------|---------|---------|
| `MM` | Major version (expansion number) | `12` = Midnight |
| `mm` | Minor version (patch number) | `00` = .0 |
| `pp` | Patch number (hotfix level) | `01` = .1 |

**Midnight release versions:**

| Version String | Interface Value | Meaning |
|---------------|----------------|---------|
| 12.0.0 | `120000` | Pre-patch (Midnight pre-patch) |
| 12.0.1 | `120001` | Midnight launch / Season 1 |

So `120001` decodes as: major=12, minor=0, patch=1 → **WoW 12.0.1**.

**Always use `120001`** for addons targeting the Midnight live client as of April 2026. Using `120000` targets only the pre-patch client.

```
## Interface: 120001
```

The client loads an addon only if its interface version is compatible with or lower than the running client version (within the same major version band). Setting too low a number causes a "This addon may be incompatible" warning; setting higher than the client version causes the addon to be skipped.

---

## Multi-Edition Comma-Delimited Interface

A single `.toc` file can declare compatibility with multiple WoW client editions using a comma-separated list in `## Interface:`.

```
## Interface: 120001, 11503
```

This tells the client: "Load this addon on Midnight 12.0.1 **or** Classic Era 1.15.3."

**Common multi-edition combinations:**

| Declaration | Compatible Clients |
|-------------|-------------------|
| `120001` | Midnight only |
| `120001, 11503` | Midnight + Classic Era |
| `120001, 50503` | Midnight + Cataclysm Classic |
| `120001, 50503, 11503` | Midnight + Cata Classic + Classic Era |
| `120001, 11503, 50503` | Same as above (order does not matter) |

**When to use comma-delimited vs. edition files:**

- Use comma-delimited when your addon code is fully compatible across editions (pure UI, no combat APIs)
- Use edition-specific `.toc` files (see below) when editions need different file lists or feature sets

---

## New 12.0 TOC Fields

These fields were introduced in 11.x and are fully supported in 12.0. All are optional unless noted.

### `## Category:`

Declares the addon's primary category for display in the addon list UI.

```
## Category: Unit Frames
```

**Purpose:** Groups addons by type in the addon manager. Allows users to filter and find addons by category.

**Valid values (examples):** `Unit Frames`, `Action Bars`, `Bags & Inventory`, `Combat`, `Map & Minimap`, `Raid`, `Tooltip`, `Data Broker`. Freeform string — Blizzard may normalize known categories.

**Introduced:** 11.1.0

### `## Group:`

Declares a group name for addons that ship as a suite. All addons with the same `Group` value appear together in the addon list.

```
## Group: MyAddon Suite
```

**Purpose:** Keeps multi-component addons (core + modules + libraries) grouped in the UI. Users can enable/disable the group together.

**Valid values:** Any freeform string. Conventionally matches the main addon name.

**Introduced:** 11.1.0

### `## AllowAddOnTableAccess:`

Controls whether other addons can access this addon's global table (`_G["AddonName"]`).

```
## AllowAddOnTableAccess: 1
```

| Value | Behavior |
|-------|----------|
| `1` | Other addons may read/write this addon's global table |
| `0` (default) | Global table access from other addons is restricted |

**Purpose:** Part of the addon isolation model introduced with Midnight's security changes. Set to `1` only for library addons or addons explicitly designed for inter-addon access.

**Introduced:** 11.1.7

### `## LoadSavedVariablesFirst:`

Controls when this addon's `SavedVariables` are loaded relative to addon Lua files.

```
## LoadSavedVariablesFirst: 1
```

| Value | Behavior |
|-------|----------|
| `1` | SavedVariables loaded before the addon's Lua files execute |
| `0` (default) | SavedVariables loaded after all addon Lua files (standard behavior) |

**Purpose:** Allows `OnLoad` and file-level Lua code to reference saved variable data immediately at load time, without waiting for `ADDON_LOADED` event.

**Use when:** Your addon initializes data structures from saved variables at the module level (not in an event handler).

### `## AllowLoadGameType:`

Restricts the addon to load only in specific game types.

```
## AllowLoadGameType: Mainline
```

| Value | Loads In |
|-------|----------|
| `Mainline` | Retail / Midnight client only |
| `Classic` | All Classic clients |
| `ClassicEra` | Classic Era (vanilla) only |
| `Cataclysm` | Cataclysm Classic only |

**Purpose:** When combined with a comma-delimited `## Interface:`, this provides an extra guard to prevent loading on unintended clients. Useful when a single TOC is used for multiple editions but certain files should only activate on one.

### `## LoadFirst:`

Marks this addon to load before other addons in the load order. Formerly `GuardedAddOn` in some pre-12.0 documentation.

```
## LoadFirst: 1
```

| Value | Behavior |
|-------|----------|
| `1` | Addon loads in the first pass, before normal addons |
| `0` (default) | Normal load order |

**Purpose:** For foundational library addons (e.g., LibStub, CallbackHandler) that must be available before any consumer addon initializes. Only use when your addon is a shared dependency that others rely on at load time.

**Note:** Renamed from `GuardedAddOn` — update any old TOC files that use `GuardedAddOn`.

---

## Edition-Specific File Naming

When an addon must ship different file lists for different WoW client editions, create edition-specific `.toc` files in the same directory:

### Directory Layout

```
MyAddon/
├── MyAddon.toc              # Default — loaded by Midnight (retail) client
├── MyAddon_Classic.toc      # Loaded by all Classic clients (any Classic edition)
├── MyAddon_Vanilla.toc      # Loaded by Classic Era (vanilla) client only
├── MyAddon_Cata.toc         # Loaded by Cataclysm Classic client only
├── Core.lua                 # Shared code (referenced in all TOC files)
├── Midnight.lua             # Midnight-specific code
├── Classic.lua              # Classic-specific code
└── Libs/
    └── LibStub.lua
```

### Client-to-File Mapping

| Client | TOC File Loaded |
|--------|----------------|
| Midnight (12.x) | `MyAddon.toc` |
| The War Within Classic (hypothetical) | `MyAddon_Classic.toc` |
| Classic Era (1.x) | `MyAddon_Vanilla.toc` |
| Cataclysm Classic (4.x) | `MyAddon_Cata.toc` |

**Selection priority:** The client looks for the most-specific match first (`_Vanilla`, `_Cata`), falls back to `_Classic`, then falls back to the default `MyAddon.toc`.

### Edition TOC Example

```
# MyAddon_Vanilla.toc — Classic Era (1.15.x)
## Interface: 11503
## Title: MyAddon
## Version: 1.0.0
## Notes: Classic Era edition

Libs\LibStub.lua
Core.lua
Classic.lua
```

```
# MyAddon.toc — Midnight (12.0.x)
## Interface: 120001
## Title: MyAddon
## Version: 1.0.0
## Notes: Midnight edition

Libs\LibStub.lua
Core.lua
Midnight.lua
```

---

## Complete Annotated TOC Example

A fully annotated `.toc` file for a Midnight 12.0.1 addon with all commonly used fields. Every field is commented inline.

```
## Interface: 120001
# ^ Interface version: 12.0.1 (Midnight launch). Encodes as MM=12, mm=00, pp=01.
# Use comma-separated for multi-edition: 120001, 11503, 50503

## Title: MyAddon
# ^ Display name shown in the addon list. Can include |c color codes.

## Title-zhCN: 我的插件
# ^ Localized title for Simplified Chinese client. Optional; falls back to Title.

## Notes: A secret-value-aware health display for WoW Midnight.
# ^ Short description shown in the addon tooltip in the addon list.

## Notes-deDE: Ein geheimnissicheres Gesundheitsdisplay für WoW Midnight.
# ^ Localized notes. Optional; locale suffix matches WoW locale identifiers.

## Version: 1.2.0
# ^ Addon version string. Freeform; shown in addon list. Conventionally semver.

## Author: YourName
# ^ Author name. Shown in addon list tooltip.

## Category: Unit Frames
# ^ Primary category for addon manager grouping. Introduced 11.1.0.

## Group: MyAddon Suite
# ^ Groups related addons in the UI. Useful for multi-component suites. Introduced 11.1.0.

## AllowAddOnTableAccess: 0
# ^ 0 = restrict other addons from accessing _G["MyAddon"] (default, recommended).
# Set to 1 only for library addons that explicitly expose a public API table.

## LoadSavedVariablesFirst: 1
# ^ 1 = load SavedVariables before Lua files execute.
# Allows file-level code to reference saved data without waiting for ADDON_LOADED.

## AllowLoadGameType: Mainline
# ^ Restrict loading to Midnight (retail) only. Prevents accidental load on Classic.
# Valid: Mainline, Classic, ClassicEra, Cataclysm

## LoadFirst: 0
# ^ 0 = normal load order (default). Set to 1 for foundational library addons only.
# Renamed from GuardedAddOn in pre-12.0 documentation.

## SavedVariables: MyAddonDB
# ^ Global variable name(s) persisted between sessions. Space or comma separated.
# These are loaded by the client and injected as globals before addon Lua runs.

## SavedVariablesPerCharacter: MyAddonCharDB
# ^ Per-character saved variables. Separate from SavedVariables (account-wide).

## DefaultState: enabled
# ^ enabled (default) or disabled. Sets initial state for new installs.

## OptionalDeps: SomeLibrary, AnotherAddon
# ^ Addons to load before this one if present, but not required.
# Contrast with ## Dependencies: which is required (blocks load if missing).

# ── File list ────────────────────────────────────────────────────────────────
# Files are loaded in the order listed. Paths use backslash or forward slash.
# All paths are relative to the addon directory.

Libs\LibStub\LibStub.lua
# ^ Third-party library: load first so other files can use LibStub.

Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua
# ^ Callback system library; used by AceEvent and similar.

Core.lua
# ^ Main addon initialization. Sets up the addon table and registers events.

SecretHandlers.lua
# ^ Secret Values API wrappers. Requires Core.lua to be loaded first.

HealthBar.lua
# ^ Health bar UI. Uses ColorCurve and issecretvalue(); requires SecretHandlers.lua.

UI.xml
# ^ XML frame definitions. Loaded after Lua so templates are available at parse time.
```
