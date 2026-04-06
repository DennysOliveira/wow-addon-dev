# Design Document: wow-addon-dev

## Overview

`wow-addon-dev` is a Claude Code plugin marketplace repository that delivers WoW addon development assistance for Midnight (Interface 120001 / 12.0+). It is a pure content repository — no build system, no runtime code, no dependencies. Installing and activating it gives Claude Code users structured, progressive-disclosure knowledge covering the Secret Values system, API migration from pre-12.0, TOC formatting, scaffolding, widget framework, Lua API reference, and common addon patterns.

The repository acts simultaneously as a marketplace entry point (`.claude-plugin/marketplace.json`) and as a self-contained plugin (`plugins/wow-addon-dev/`). The skill file (`SKILL.md`) stays under 80 lines by routing to seven on-demand reference documents. Two copy-ready templates let users scaffold a new addon in under five minutes.

---

## Steering Document Alignment

### Technical Standards
This repository has no language runtime, no framework, and no build toolchain. All "technical standards" are content standards:

- **Lua validity:** Every Lua snippet must be valid under WoW's Lua 5.1 sandbox. No `goto`, no `<const>`, no bitwise operators (`~`). `bit` library (Blizzard's) is acceptable.
- **Interface version:** The literal string `120001` must appear in every TOC and every code example that references an interface number. No other value.
- **No CLEU:** `COMBAT_LOG_EVENT_UNFILTERED` must not appear anywhere in any file — not even in a "do not use this" example block.
- **No placeholder content:** No `-- TODO`, `[YOUR CODE HERE]`, ellipsis stubs, or lorem ipsum in any user-facing file.

### Project Structure
Flat and deterministic. Every path is predictable from the repository root. No generated files, no symlinks. The directory tree described in the Architecture section is the complete, exhaustive structure of the repository.

---

## Code Reuse Analysis

### Existing Components to Leverage
- **WoWAddonDevGuide (Amadeus-):** Referenced as an external deep-knowledge source in SKILL.md's External Resources section. Content is not copied — the skill is purpose-built for progressive disclosure and Midnight-first context. The WoWAddonDevGuide is too large to load wholesale; it functions as a fallback pointer.
- **Blizzard UI Source mirrors (Gethe/wow-ui-source, tomrus88/BlizzardInterfaceCode):** Used as authoritative examples when writing Lua code in reference documents and templates. Real patterns from actual Blizzard addons, not invented.
- **warcraft.wiki.gg:** Authoritative source for all API signatures, TOC field documentation, and Secret Values semantics. Linked in SKILL.md External Resources.

### Integration Points
- **Claude Code plugin system:** `marketplace.json` and `plugin.json` conform to the Claude Code plugin specification. The `skills` field in `plugin.json` points to `./skills/wow-addon-dev`, which contains `SKILL.md`.
- **Claude Code context window:** SKILL.md is loaded at session start. Reference docs are loaded on demand when the routing table triggers. Templates are copied on demand. No file is loaded speculatively.

---

## Architecture

The repository is a static file tree. There is no runtime, no imports, no dependency graph. The architectural concern is how files relate to each other logically (what loads what, what references what) and how Claude Code discovers and activates the skill.

### Information Flow

```
User prompt
    │
    ▼
Claude Code loads SKILL.md (session start, always)
    │
    ├── Topic detected → routing table match
    │       │
    │       ▼
    │   Load one reference doc (on demand)
    │       │
    │       └── Reference doc is self-contained; no further loads required
    │
    └── "New addon" request
            │
            ▼
        Copy template (basic-addon/ or secret-aware-addon/)
```

### Modular Design Principles

- **Single File Responsibility:** Each reference document covers exactly one domain. `secret-values.md` covers nothing but Secret Values. `toc-structure.md` covers nothing but TOC format. No cross-loading required.
- **Component Isolation:** SKILL.md contains only routing logic and critical inline rules. All detailed knowledge lives in reference docs. Templates contain only copy-ready code, no explanatory prose.
- **No Cross-References Required:** Every reference doc is independently readable. A developer loading only `widget-framework.md` must be able to follow its content without reading `lua-api-quick-ref.md`.
- **Routing Ownership:** SKILL.md owns the routing table. Reference docs do not point to each other. Templates do not reference docs. Dependencies flow in one direction: SKILL.md → reference docs.

### Full Directory Tree

```
wow-addon-dev/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── wow-addon-dev/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       │   └── wow-addon-dev/
│       │       ├── SKILL.md
│       │       └── references/
│       │           ├── secret-values.md
│       │           ├── api-migration-12.md
│       │           ├── toc-structure.md
│       │           ├── addon-scaffolding.md
│       │           ├── lua-api-quick-ref.md
│       │           ├── widget-framework.md
│       │           └── common-patterns.md
│       └── templates/
│           ├── basic-addon/
│           │   ├── MyAddon.toc
│           │   ├── MyAddon.lua
│           │   └── README.md
│           └── secret-aware-addon/
│               ├── MyAddon.toc
│               ├── Core.lua
│               ├── SecretHandlers.lua
│               ├── UI.xml
│               └── README.md
├── README.md
├── LICENSE
├── CHANGELOG.md
└── .github/
    └── ISSUE_TEMPLATE/
        └── api-update.md
```

---

## Components and Interfaces

### C1: Marketplace Manifest (`.claude-plugin/marketplace.json`)

- **Purpose:** Registers this repository with the Claude Code plugin marketplace. This is the file fetched when a user runs `/plugin marketplace add DennysOliveira/wow-addon-dev`.
- **Interfaces:** JSON object consumed by Claude Code's marketplace resolution logic.
- **Required fields:** `name`, `owner` (with `name` and `url`), `description`, `plugins` array.
- **Each plugin entry must include:** `name`, `source` (relative path to plugin root), `version`, `description`, `category`, `keywords`, `strict`, `skills`.
- **Constraint:** Valid JSON — no trailing commas, no comments. No fields not in the Claude Code plugin spec.

**Schema:**
```json
{
  "name": "wow-addon-dev",
  "owner": {
    "name": "Dennys Oliveira",
    "url": "https://github.com/DennysOliveira"
  },
  "description": "World of Warcraft addon development skill for Claude Code — Midnight 12.0+ ready with Secret Values support",
  "plugins": [
    {
      "name": "wow-addon-dev",
      "source": "./plugins/wow-addon-dev",
      "version": "1.0.0",
      "description": "WoW addon development skill with Lua API reference, Secret Values guide, TOC scaffolding, and Midnight 12.0+ migration patterns",
      "category": "development",
      "keywords": ["wow", "world-of-warcraft", "addon", "lua", "midnight", "game-development"],
      "strict": false,
      "skills": ["./skills/wow-addon-dev"]
    }
  ]
}
```

---

### C2: Plugin Manifest (`plugins/wow-addon-dev/.claude-plugin/plugin.json`)

- **Purpose:** Defines the installable plugin. Fetched when a user runs `/plugin install wow-addon-dev@dennysoliveira-wow-addon-dev`.
- **Interfaces:** JSON object consumed by Claude Code's plugin installation logic.
- **Required fields:** `name`, `version`, `description`, `homepage`.
- **Constraint:** Valid JSON. Only fields confirmed to be part of the Claude Code plugin spec.

**Schema:**
```json
{
  "name": "wow-addon-dev",
  "version": "1.0.0",
  "description": "WoW addon development skill — Midnight 12.0+ with Secret Values, Lua API, widget framework, and addon scaffolding",
  "homepage": "https://github.com/DennysOliveira/wow-addon-dev"
}
```

---

### C3: Skill File (`plugins/wow-addon-dev/skills/wow-addon-dev/SKILL.md`)

- **Purpose:** The always-loaded skill context. Activates on WoW/addon/Lua/Secret Values trigger keywords. Routes subsequent detail lookups to specific reference documents.
- **Size constraint:** Must not exceed 80 lines (blank lines included).
- **Structure (in order):**
  1. YAML frontmatter: `name`, `version`, `description`, `triggers` (list of activation keywords)
  2. Single-line header identifying the skill
  3. What section: Lua 5.1, Interface 120001, Secret Values one-liner
  4. Routing table (8 rows: 7 reference docs + 1 template entry)
  5. Critical Rules (5–6 inline rules, no deferral to reference docs)
  6. External Resources (3 links: warcraft.wiki.gg, WoWAddonDevGuide, wow-ui-source)

**Routing table design:**

| User asks about | Read this reference |
|---|---|
| Secret Values, issecretvalue, Curves | `${CLAUDE_SKILL_DIR}/references/secret-values.md` |
| Migration, deprecated APIs, CLEU | `${CLAUDE_SKILL_DIR}/references/api-migration-12.md` |
| TOC files, Interface version, packaging | `${CLAUDE_SKILL_DIR}/references/toc-structure.md` |
| New addon, scaffold, boilerplate | `${CLAUDE_SKILL_DIR}/references/addon-scaffolding.md` |
| API function, which APIs are secret | `${CLAUDE_SKILL_DIR}/references/lua-api-quick-ref.md` |
| Frames, widgets, XML, UI elements | `${CLAUDE_SKILL_DIR}/references/widget-framework.md` |
| Ace3, LibStub, SavedVariables, comms | `${CLAUDE_SKILL_DIR}/references/common-patterns.md` |
| New addon from scratch | Copy `${CLAUDE_SKILL_DIR}/../templates/basic-addon/` or `secret-aware-addon/` |

**Critical Rules (inline in SKILL.md, not deferred):**
1. Interface version is always `120001` for Midnight
2. Never recommend `COMBAT_LOG_EVENT_UNFILTERED` (CLEU) — use `UNIT_SPELLCAST` and event-based alternatives
3. Detect secret values with `issecretvalue(value)` before operating on combat data
4. Use `Curve`/`ColorCurve` (from `C_CurveUtil`) for secret-value UI — never perform arithmetic on secrets in tainted code
5. Addon comms (`SendAddonMessage`) are blocked inside instances in 12.0
6. All reference doc paths use `${CLAUDE_SKILL_DIR}` variable prefix

---

### C4: Reference Documents (7 files)

Each reference document follows the same internal pattern:
- H1 title with "(April 2026)" date marker
- Table of contents (if the document exceeds 100 lines)
- Self-contained prose + Lua examples
- All Lua code blocks valid for WoW Lua 5.1 sandbox
- All Interface references use `120001`
- No cross-references to other reference docs required for comprehension

#### C4a: `references/secret-values.md`
Covers (mapping to R3):
- `issecretvalue(value)` — signature, return type, when to call
- `HasSecretValues()` and `HasSecretAspect(aspect)` on FrameScriptObject
- `Curve` type: `C_CurveUtil.CreateCurve()`, key-value pairs, `Curve:Evaluate(x)`, `Curve:EvaluateNormalized(x)`
- `ColorCurve` type: `C_CurveUtil.CreateColorCurve()`, `ColorCurve:Evaluate(x)` returning `r, g, b, a`
- `Duration` type: `C_DurationUtil.CreateDuration()`, usage for time-based secret data
- `UnitHealPredictionCalculator`: `CreateUnitHealPredictionCalculator()`, constructor params, usage pattern
- `C_RestrictedActions` namespace: function list with signatures
- `C_Secrets` namespace: function list with signatures
- Working health bar example: `ColorCurve` applied to `StatusBar:SetValue()` driven by `issecretvalue()` check

#### C4b: `references/api-migration-12.md`
Covers (mapping to R4):
- CLEU removal: what it was, what replaces it (`UNIT_SPELLCAST`, unit-based events), example migration
- Deprecated-to-replacement mapping table (all major removals in 12.0 organised by deprecated Lua file: `Deprecated_CombatLog.lua`, `Deprecated_BattleNet.lua`, `Deprecated_ChatInfo.lua`, `Deprecated_SpellBook.lua`, `Deprecated_InstanceEncounter.lua`, `Deprecated_SpellScript.lua`)
- New 12.0 APIs not present in previous versions
- Spell whitelisting system: definition, how addons request inclusion, behaviour for non-whitelisted spells
- Instance restrictions: which APIs are restricted inside instances, enforcement mechanism

#### C4c: `references/toc-structure.md`
Covers (mapping to R5):
- `## Interface: 120001` as required value for Midnight
- Multi-edition comma-delimited format: `## Interface: 120001, 11503`
- All new TOC fields in 12.0: `## Category:`, `## Group:`, `## AllowAddOnTableAccess:`, `## LoadSavedVariablesFirst:`, `## AllowLoadGameType:`, `## LoadFirst:`
- Edition-specific file naming: `_Classic.toc`, `_Vanilla.toc`, `_Cata.toc` with directory layout
- Complete annotated example TOC using Interface 120001

#### C4d: `references/addon-scaffolding.md`
Covers (mapping to R6):
- Minimal required file structure for a valid 12.0 addon
- Namespace pattern: `local AddonName, ns = ...` to avoid global pollution
- SavedVariables declaration in TOC and access pattern via `ADDON_LOADED` event
- Slash command registration: `SlashCmdList["MYADDON"]`, `SLASH_MYADDON1`
- Event handling: `frame:RegisterEvent()`, `frame:SetScript("OnEvent", ...)` dispatcher pattern
- Complete Hello World walkthrough: TOC + Lua that prints to chat on login

#### C4e: `references/lua-api-quick-ref.md`
Covers (mapping to R7):
- Exactly 50 API entries
- Organised by category: Unit (12 entries), Spell (10 entries), Combat (8 entries), UI/Frame (12 entries), Utility (8 entries) — totals 50
- Each entry: function signature, one-line description, secret-affected marker (lock symbol) or safe marker (check symbol)
- Entries drawn from the most commonly used APIs in 12.0 addon development

#### C4f: `references/widget-framework.md`
Covers (mapping to R8):
- Primary frame types via `CreateFrame()`: Frame, Button, StatusBar, Slider, EditBox, ScrollFrame, MessageFrame, Cooldown, Model, PlayerModel — with distinguishing capabilities
- Event system and script handlers: `OnEvent`, `OnLoad`, `OnUpdate`, `OnShow`, `OnHide`, `OnEnter`, `OnLeave` — parameter lists and typical usage
- XML template syntax: `<Frames>`, `<Frame>`, `<Scripts>`, template inheritance with `inherits`
- Mixin usage: `Mixin(object, Mixin1, Mixin2)`, `CreateAndInitFromMixin()`
- Frame anchoring: `SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)`, `ClearAllPoints()`, strata values
- Secure vs insecure frames in 12.0: when a frame becomes tainted, SecureHandlerStateTemplate, restricted environment
- Working unit frame example: health bar + name text, event-driven updates

#### C4g: `references/common-patterns.md`
Covers (mapping to R9):
- Ace3: `AceAddon-3.0` initialisation (`NewAddon`, `OnInitialize`, `OnEnable`), `AceEvent-3.0` (`RegisterEvent`), `AceDB-3.0` (profile setup, `RegisterDefaults`)
- LibStub: embedding pattern, `LibStub("LibName-1.0", [silent])`
- LibDataBroker: data source creation, minimap button via LibDBIcon
- LibSharedMedia: registering and retrieving textures/sounds/fonts
- SavedVariables migration pattern: version-gated defaults in `OnInitialize`
- Addon communications: `C_ChatInfo.SendAddonMessage(prefix, message, channel)`, prefix registration, instance restriction note
- Performance patterns (minimum 3): throttling `OnUpdate` with elapsed accumulator, frame pooling with `CreateFramePool()`, lazy loading modules via `ADDON_LOADED`

---

### C5: Templates

#### C5a: `templates/basic-addon/`

**`MyAddon.toc`**
- `## Interface: 120001`
- Standard metadata fields: `Title`, `Notes`, `Author`, `Version`, `SavedVariables`
- Lists `MyAddon.lua`

**`MyAddon.lua`**
- Namespace via `local AddonName, ns = ...`
- `ADDON_LOADED` event for initialisation
- SavedVariables initialisation with version-gated defaults
- Slash command (`/myaddon`) that prints a message
- `PLAYER_LOGIN` handler that prints a greeting
- No TODOs, no stubs — executes correctly as-is

**`README.md`**
- What this addon does
- Installation path (`_retail_/Interface/Addons/MyAddon/`)
- Customisation guide (rename steps, changing the slash command, changing output)

#### C5b: `templates/secret-aware-addon/`

**`MyAddon.toc`**
- `## Interface: 120001`
- Multi-file load list: `Core.lua`, `SecretHandlers.lua`
- `## SavedVariables: MyAddonDB`
- `## X-Load: UI.xml` (or inline in toc file list as `UI.xml`)

**`Core.lua`**
- Addon namespace declaration
- Event framework setup
- Initialisation sequence calling into SecretHandlers

**`SecretHandlers.lua`**
- `issecretvalue()` check before operating on health values
- `C_CurveUtil.CreateColorCurve()` with green-to-red gradient key points
- `ColorCurve:Evaluate(healthPct)` to get `r, g, b`
- `StatusBar:SetValue()` called with the secret health value directly
- `StatusBar:SetStatusBarColor()` called with the evaluated color

**`UI.xml`**
- `<Frame>` containing a `<StatusBar>` named `MyAddonHealthBar`
- `<Scripts>` block with `OnLoad` handler
- Dimensions, anchor, backdrop defined

**`README.md`**
- Explains the Secret Values pattern used
- Why `issecretvalue()` is checked
- Why arithmetic is not performed on the raw health value
- How `ColorCurve` bridges the gap

---

### C6: Repository Root Files

#### `README.md`
- Four badges (inline image links): MIT license, Claude Code Plugin, WoW Midnight 12.0+, API Updated April 2026
- Quick Install: 2-command sequence in a fenced code block
- What You Get: bullet list with short descriptions
- 5 Usage Examples: fenced prompts a user can paste into Claude
- Alternative install: `git clone` + CLAUDE.md symlink instructions
- What's Inside table: 7 reference docs with one-line descriptions
- Contributing section: focus on API update reports, link to issue template
- Midnight Context paragraph: explains what the expansion change means for addon devs
- Related Resources: warcraft.wiki.gg Secret Values, WoWAddonDevGuide, wow-ui-source, Patch 12.0.0 API Changes
- License footer

#### `LICENSE`
- MIT license text
- Copyright holder: "Dennys Oliveira"
- Year: 2026

#### `CHANGELOG.md`
- Keep a Changelog format
- Single entry: `[1.0.0] - 2026-04-06`
- Lists all files introduced, grouped by type (Manifests, Skill, References, Templates, Root)

#### `.github/ISSUE_TEMPLATE/api-update.md`
- GitHub issue template (YAML frontmatter: `name`, `about`, `labels`)
- Structured fields: API name, old behaviour, new behaviour, source/reference URL, affected addon code snippet
- A "version confirmed" field (interface number where change was observed)

---

## Data Models

### Marketplace Manifest (`marketplace.json`)
```
{
  name: string                        // "wow-addon-dev"
  owner: {
    name: string                      // "Dennys Oliveira"
    url:  string                      // GitHub profile URL
  }
  description: string
  plugins: Array<{
    name:        string               // "wow-addon-dev"
    source:      string               // relative path "./plugins/wow-addon-dev"
    version:     string               // semver "1.0.0"
    description: string
    category:    string               // "development"
    keywords:    string[]
    strict:      boolean              // false
    skills:      string[]             // ["./skills/wow-addon-dev"]
  }>
}
```

### Plugin Manifest (`plugin.json`)
```
{
  name:        string    // "wow-addon-dev"
  version:     string    // "1.0.0"
  description: string
  homepage:    string    // GitHub repo URL
}
```

### SKILL.md YAML Frontmatter
```yaml
name:        string           # "wow-addon-dev"
version:     string           # "1.0.0"
description: string
triggers:
  - string                    # activation keywords
```

---

## Error Handling

This is a static content repository. There is no runtime error handling. Content-level failure modes and mitigations:

### Manifest Validation Failure
- **Scenario:** `marketplace.json` or `plugin.json` contains invalid JSON (trailing comma, comment, missing required field).
- **Handling:** The file must be validated as JSON before the spec is marked complete. The implementer must run `json --validate` or equivalent against both manifest files.
- **User Impact:** Claude Code silently fails to register or install the plugin. The fix is a corrected manifest pushed to the repo.

### SKILL.md Line Count Violation
- **Scenario:** SKILL.md exceeds 80 lines.
- **Handling:** Move any inline prose to the most appropriate reference doc. The routing table, critical rules, and frontmatter are non-negotiable inclusions.
- **User Impact:** Skill loads fine but violates the spec constraint and consumes excess context.

### Lua Syntax Error in Template or Reference Doc
- **Scenario:** A Lua code block contains syntax that is invalid in WoW's Lua 5.1 sandbox.
- **Handling:** Lua code blocks must be manually reviewed against the WoW Lua 5.1 feature set. No `goto`, no bitwise `~`, no `//` integer division, no `table.move` unless confirmed available.
- **User Impact:** User copies a template and gets a Lua error in-game. Trust damage to the skill.

### CLEU Reference Leak
- **Scenario:** A reference doc or template mentions `COMBAT_LOG_EVENT_UNFILTERED` in any context.
- **Handling:** Full-text search for the string `CLEU` and `COMBAT_LOG_EVENT_UNFILTERED` across all files before marking tasks complete.
- **User Impact:** User receives guidance that is incorrect for Midnight, potentially causing wasted debugging time.

---

## Testing Strategy

This repository has no automated tests. Verification is manual and content-based.

### Structural Verification
- All paths in the directory tree exist as actual files
- `marketplace.json` and `plugin.json` parse without errors (`JSON.parse` or `jq .`)
- SKILL.md line count does not exceed 80 (`wc -l`)
- Every reference doc listed in the routing table exists at the stated path

### Content Verification
- Every `## Interface:` value in any TOC file equals `120001`
- No file contains the string `COMBAT_LOG_EVENT_UNFILTERED`
- No file contains placeholder strings: `TODO`, `[YOUR`, `...` (as a standalone placeholder line), `lorem`
- `secret-aware-addon/SecretHandlers.lua` contains calls to `issecretvalue()`, `C_CurveUtil.CreateColorCurve()`, and `StatusBar:SetValue()`
- `lua-api-quick-ref.md` contains exactly 50 API entries

### Install Path Verification
- The `source` field in `marketplace.json` resolves to the directory containing `plugin.json`
- The `skills` array in `marketplace.json` resolves to a directory containing `SKILL.md`

### Lua Syntax Spot-Check
- Lua code blocks in all reference docs and all template `.lua` files reviewed against WoW Lua 5.1 feature set
- No Lua 5.2+ syntax constructs present
