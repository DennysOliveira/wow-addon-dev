# WoW Addon Development Skill — Deep Research Document

**Date:** 2026-04-06
**Target:** Claude Code CLAUDE.md skill for WoW Addon Development (Midnight / 12.0+)
**Format:** Standalone open-source repo with CLAUDE.md + reference docs

---

## 1. Existing Work — WoWAddonDevGuide by Amadeus-

There is already a comprehensive repo designed specifically for Claude AI use:
**https://github.com/Amadeus-/WoWAddonDevGuide**

### What it covers (12 guides + extracted data):
| File | Content |
|------|---------|
| `00_MASTER_PROMPT.md` | Master overview and entry point |
| `01_API_Reference.md` | 513 API functions by category |
| `02_Event_System.md` | Complete event system docs |
| `03_UI_Framework.md` | XML, frames, widgets, templates, mixins |
| `04_Addon_Structure.md` | TOC files, file organization, load order |
| `05_Patterns_And_Best_Practices.md` | Coding patterns, performance |
| `06_Data_Persistence.md` | Saved variables, database management |
| `07_Blizzard_UI_Examples.md` | Real working code examples from Blizzard UI |
| `08_Community_Addon_Patterns.md` | Ace3, LibStub, community frameworks |
| `09_Addon_Libraries_Guide.md` | Complete library reference |
| `10_Advanced_Techniques.md` | Production-level patterns |
| `11_API_Migration_Guide.md` | API version migration (NEW for 12.0) |
| `12a_Secret_Safe_APIs.md` | Complete 12.0+ Secret Values API reference |

### Extracted reference data:
- `api_extracted/` — 513 API files
- `events_extracted/` — Complete event reference
- `file_lists/` — 281 Blizzard addons categorized

### Analysis:
- **Strengths:** Very thorough TWW (11.2.7) coverage, already has 12.0 migration guide and Secret Values reference
- **Weaknesses:** Only 3 commits, may not be actively maintained. Built as a knowledge base dump, not as a CLAUDE.md skill optimized for context window efficiency (progressive disclosure). Files are very large and would blow up context if loaded wholesale.

### Conclusion:
We should **NOT fork this** — instead, build a new skill that is:
1. Optimized for CLAUDE.md progressive disclosure (compact SKILL.md + reference docs loaded on demand)
2. Focused on the 3 pillars the user selected (Lua API/Widget, Midnight breaking changes, Scaffolding/packaging)
3. References WoWAddonDevGuide as a deeper knowledge source when needed

---

## 2. The "Addon Apocalypse" — Midnight API Changes (12.0.0)

### 2.1 Core Philosophy Change
Blizzard's Midnight expansion implements the most sweeping changes to the WoW addon API since the game launched. The core change: **combat-related information is now protected via "Secret Values"** — a black-box mechanism that prevents addons from performing complex logic on combat data.

### 2.2 Secret Values System
- Secret Values are opaque Lua values returned by combat-related APIs
- Tainted (addon) code **cannot** perform operations on them (comparisons, arithmetic, string manipulation)
- Tainted code **can** store them in variables and pass them to certain native APIs (e.g., `StatusBar:SetValue()`)
- When execution is **not tainted** (secure/Blizzard code), secret values behave as normal values
- Test with `issecretvalue(value)` → returns true if secret
- Test object state with `FrameScriptObject:HasSecretValues()` and `FrameScriptObject:HasSecretAspect(aspect)`

### 2.3 New Lua Constructs for Secret Values
| Construct | Purpose | Creation API |
|-----------|---------|-------------|
| **Curve** | Map secret numeric inputs to outputs (e.g., health % → bar width) | `C_CurveUtil.CreateCurve()` |
| **ColorCurve** | Map secret values to colors (e.g., health → green/red gradient) | `C_CurveUtil.CreateColorCurve()` |
| **Duration** | Perform time calculations on secret data natively | `C_DurationUtil.CreateDuration()` |
| **UnitHealPredictionCalculator** | Replicate heal prediction without accessing raw values | `CreateUnitHealPredictionCalculator()` |

### 2.4 Secret Aspects System
- When a secret value is passed to a widget API, that widget gets "secret aspects" applied
- Other APIs on the same widget may then return secret values
- Auto-generated API docs list aspects connected to each API
- Objects marked as having secrets affect anchoring and positioning APIs

### 2.5 Instance/Combat Restrictions
- **In instances:** Chat messages become secret, addon comms are blocked
- **In combat/instances:** Creature names, GUIDs, IDs become secret
- **COMBAT_LOG_EVENT_UNFILTERED (CLEU):** Effectively removed/restricted — this is THE biggest breaking change
- **New event-based system:** `UNIT_SPELLCAST` and similar events replace CLEU for many use cases
- Player's own spellcasts: non-secret when outside combat

### 2.6 Deprecated & Removed APIs (12.0.0)
Key deprecated Lua files:
- `Deprecated_BattleNet.lua`
- `Deprecated_ChatInfo.lua`
- `Deprecated_ChatFrame.lua`
- `Deprecated_CombatLog.lua` — The big one
- `Deprecated_SpellBook.lua`
- `Deprecated_InstanceEncounter.lua`
- `Deprecated_SpellScript.lua`

Several APIs in `C_UnitAuras`, `C_Spell`, and `C_ActionBar` removed (replaced by Duration objects).

### 2.7 New APIs Added
- `C_CurveUtil.EvaluateColorFromBoolean` / `C_CurveUtil.EvaluateColorValueFromBoolean` — convert secret booleans to colors
- Castbar spell sequence ID — incremented per spellcast, never secret
- `C_RestrictedActions` namespace — test current addon restriction states
- `C_Secrets` namespace — evaluate secret predicates directly
- Various numeric formatting APIs (e.g., `AbbreviateNumbers`) now callable with secrets
- New event for unit death (GUID payload secret in same cases as cooldowns/auras)
- Native smooth status bar transitions
- Timer status bars (auto-update based on current time)
- Secret color text wrapping

### 2.8 Relaxed Restrictions (Beta → Launch)
Blizzard relaxed several restrictions during beta:
- Healing and absorb prediction limitations loosened (`UnitHealPredictionCalculator`)
- Specific spell whitelisting (Shaman Maelstrom Weapon, DH Soul Fragments, Skyriding charges)
- `UnitHealthMax`/`UnitPowerMax` no longer secret for player units
- More cast bar flexibility
- Empowered cast data (stages, percentages) no longer secret
- Unit power APIs (`UnitPowerDisplayMod`, etc.) improvements

### 2.9 Pre-patch Timing
- Restrictions active in **12.0.0 pre-patch**, not waiting for 12.0.1
- Blizzard continues making changes through 12.0.1 and beyond
- Last-minute hotfixes still happening (as of March 2026, days before Mythic+ Season 1)

### 2.10 Community Impact
- WeakAuras: Major functionality loss in combat
- Boss Mods (DBM/BigWigs): Adapting with new event-based approach
- Damage Meters (Details!): Significantly reduced functionality
- ElvUI: Somewhat working with workarounds
- Many standalone addons created to replace WA functionality (Cursor Ring+, Viserio Cooldowns, etc.)

---

## 3. TOC File Structure for 12.0

### Interface Version
- **Mainline (Midnight):** `120001` (12.0.1)
- **Pre-patch:** `120000` (12.0.0)
- Supports comma-delimited versions: `## Interface: 120001, 50503, 11508`

### Edition-specific TOC files
```
MyAddon/
├── MyAddon.toc           # Default (retail/mainline)
├── MyAddon_Classic.toc   # All Classic clients
├── MyAddon_Vanilla.toc   # Classic Era only
└── MyAddon_Cata.toc      # Cataclysm Classic
```

### New TOC Fields (11.x → 12.0)
- `## Category:` and `## Group:` — Addon categorization (11.1.0)
- `## AllowAddOnTableAccess:` — Addon table access permission (11.1.7)
- `## LoadSavedVariablesFirst:` — Control saved variable load order
- `## AllowLoadGameType:` — Conditional loading by game type
- `## LoadFirst:` — Priority loading (renamed from GuardedAddOn)
- Per-file directives and inline `TextLocale` variable support

---

## 4. Key Reference Sources

### Primary Documentation
| Source | URL | Notes |
|--------|-----|-------|
| Warcraft Wiki API | `warcraft.wiki.gg/wiki/World_of_Warcraft_API` | Up to date for 12.0.1 |
| Warcraft Wiki Secret Values | `warcraft.wiki.gg/wiki/Secret_Values` | Definitive reference |
| Warcraft Wiki TOC Format | `warcraft.wiki.gg/wiki/TOC_format` | Latest TOC spec |
| Warcraft Wiki 12.0 API Changes | `warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes` | Diff from 11.x |
| Warcraft Wiki Planned Changes | `warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes` | Blizzard comms compiled |

### Blizzard Official
| Source | URL | Notes |
|--------|-----|-------|
| Addon Disarmament Post | `news.blizzard.com/en-us/article/24246290` | Ion's philosophy post |
| WoWUI Discord | Private/invite-only | Primary addon dev communication channel |

### GitHub Repos
| Repo | URL | Notes |
|------|-----|-------|
| WoWAddonDevGuide (Claude-optimized) | `github.com/Amadeus-/WoWAddonDevGuide` | 12 guides + extracted data |
| Blizzard UI Source (Gethe) | `github.com/Gethe/wow-ui-source` | Official UI code mirror |
| BlizzardInterfaceCode (tomrus88) | `github.com/tomrus88/BlizzardInterfaceCode` | Alternative mirror |
| BigWigsMods/WoWUI | `github.com/BigWigsMods/WoWUI` | BigWigs team mirror |
| TOC Interface Updater | `github.com/p3lim/toc-interface-updater` | Auto-update TOC versions |
| Cell addon 12.0 PR | `github.com/enderneko/Cell/pull/457` | Real-world migration example |

### Community Addon Patterns (12.0 adapted)
- **Danders Frames** — Party/raid frames rebuilt for Secret Values
- **Sensei Class Resource Bar** — Resource tracking with new APIs
- **Platynator** — Nameplate addon using new restrictions
- **Enhanced Cooldown Manager** — Working with Blizzard's Cooldown Manager API
- **Dominos Action Bars Enhanced** — OmniCC-style with secret-aware swipes

---

## 5. Claude Code Plugin Architecture

### How CLAUDE.md skills work
- `CLAUDE.md` is auto-loaded at session start by Claude Code
- It becomes part of the system prompt — every conversation starts with this context
- Can be placed at repo root (shared with team), parent dirs (monorepo), or `~/.claude/` (global)
- **Context is precious** — keep under 60 lines ideally, max ~150-200 instructions
- Use progressive disclosure: compact CLAUDE.md → point to reference docs → Claude reads on demand

### Skill structure for our repo
```
wow-addon-skill/
├── CLAUDE.md                          # Main skill file (compact, <80 lines)
├── README.md                          # Human-readable repo docs
├── references/
│   ├── secret-values.md               # Secret Values deep dive
│   ├── api-migration-12.md            # 12.0 breaking changes & migration patterns
│   ├── toc-structure.md               # TOC format, interface versions, multi-edition
│   ├── addon-scaffolding.md           # Project structure, file organization, libs
│   ├── lua-api-quick-ref.md           # Most-used API functions by category
│   ├── widget-framework.md            # Frames, events, hooks, XML templates
│   └── common-patterns.md             # Ace3, LibStub, SavedVariables, slash commands
└── templates/
    ├── basic-addon/                   # Minimal addon scaffold
    │   ├── MyAddon.toc
    │   ├── MyAddon.lua
    │   └── MyAddon.xml
    └── secret-aware-addon/            # 12.0+ addon with secret value handling
        ├── MyAddon.toc
        ├── Core.lua
        ├── SecretHandlers.lua
        └── UI.xml
```

### Key design decisions
1. **CLAUDE.md stays compact** — routing logic + essential context only
2. **Progressive disclosure** — reference docs loaded via `Read references/X.md` when needed
3. **Templates are copy-ready** — Claude can scaffold a new addon by copying + modifying templates
4. **12.0-first** — Everything assumes Midnight; legacy patterns documented as migration notes

---

## 6. Risk Assessment

### Things that are still changing
- Blizzard is **still hotfixing** addon API changes (last-minute changes before Mythic+ Season 1, March 2026)
- Spell whitelisting is ongoing — more spells may become non-secret
- Community is still discovering workarounds and patterns
- The WoWAddonDevGuide repo has only 3 commits — may go stale

### Mitigation
- Include update instructions in the skill README
- Reference authoritative sources (warcraft.wiki.gg) that stay current
- Structure skill so individual reference docs can be updated independently
- Add a `LAST_UPDATED.md` or version date to track freshness
