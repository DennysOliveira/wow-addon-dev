# wow-addon-dev

Claude Code skill plugin for World of Warcraft addon development — Midnight 12.0+ APIs, Secret Values, and production patterns.

![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-blue)
![WoW Midnight](https://img.shields.io/badge/WoW-Midnight_12.0%2B-orange)
![API Updated](https://img.shields.io/badge/API_Updated-April_2026-purple)

---

## Quick Install

```
/plugin marketplace add DennysOliveira/wow-addon-dev
/plugin enable wow-addon-dev
```

---

## What You Get

- **wow-addon-dev skill** — always-loaded routing context that directs Claude to the right reference doc for any WoW addon question
- **secret-values.md** — complete Secret Values system: `issecretvalue()`, `HasSecretValues()`, `Curve`, `ColorCurve`, `Duration`, `UnitHealPredictionCalculator`, `C_RestrictedActions`, `C_Secrets`, and a working health bar example
- **api-migration-12.md** — CLEU removal and replacement events, full deprecated-to-replacement mapping table across all six deprecated Lua files, new 12.0 APIs, spell whitelisting, and instance restrictions
- **toc-structure.md** — Interface 120001, multi-edition TOC format, all new 12.0 TOC fields, edition-specific file naming, and a complete annotated example
- **addon-scaffolding.md** — minimal addon file structure, namespace pattern, SavedVariables initialization, slash commands, event handling, and a full Hello World walkthrough
- **lua-api-quick-ref.md** — 50 API entries in five categories (Unit, Spell, Combat, UI/Frame, Utility) with secret-value safety markers
- **widget-framework.md** — `CreateFrame()` types, script handlers, XML templates, Mixin, frame anchoring, secure vs insecure frames, and a working unit frame example
- **common-patterns.md** — Ace3, LibStub, LibDataBroker, LibSharedMedia, SavedVariables migration, addon communications, and performance patterns
- **basic-addon template** — copy-ready starter addon with namespace pattern, SavedVariables, slash command, and PLAYER_LOGIN handler
- **secret-aware-addon template** — multi-file addon demonstrating correct `issecretvalue()` usage, `ColorCurve` health bar coloring, and secure UI via XML

---

## Usage Examples

Paste any of these prompts directly into Claude Code after installing the plugin:

```
How do I detect if a health value is secret?
```

```
Show me the API migration from CLEU to Midnight events
```

```
Create a new addon skeleton
```

```
How do I create a health bar with ColorCurve?
```

```
What TOC fields are new in 12.0?
```

---

## Alternative Install

Clone the repository and make the plugin available to Claude Code:

```bash
git clone https://github.com/DennysOliveira/wow-addon-dev.git
```

Then either symlink or copy the plugin directory into your Claude Code plugins path:

```bash
# Symlink (recommended — gets updates automatically)
ln -s /path/to/wow-addon-dev/plugins/wow-addon-dev ~/.claude/plugins/wow-addon-dev

# Or copy
cp -r /path/to/wow-addon-dev/plugins/wow-addon-dev ~/.claude/plugins/wow-addon-dev
```

Add the skill to your project's `CLAUDE.md`:

```
@~/.claude/plugins/wow-addon-dev/skills/wow-addon-dev/SKILL.md
```

---

## What's Inside

| Document | What It Covers |
|---|---|
| `secret-values.md` | Secret Values system introduced in Midnight 12.0 — `issecretvalue()`, `Curve`, `ColorCurve`, `Duration`, heal prediction, restricted action APIs, and a working health bar |
| `api-migration-12.md` | Migrating addons from pre-12.0 to Midnight — deprecated function replacement tables, CLEU removal and unit-based event replacements, spell whitelisting, instance API restrictions |
| `toc-structure.md` | TOC file format for Interface 120001 — multi-edition comma-delimited syntax, all new 12.0 TOC fields with valid values, edition-specific file naming |
| `addon-scaffolding.md` | Building a WoW addon from scratch — namespace pattern, SavedVariables initialization, slash command registration, event dispatcher, and a complete Hello World addon |
| `lua-api-quick-ref.md` | 50 Lua API quick-reference entries in five categories with secret-value safety markers and function signatures |
| `widget-framework.md` | Blizzard widget system — `CreateFrame()` types, script handlers, XML template syntax, Mixin, frame anchoring, secure frame restrictions, and a working unit frame |
| `common-patterns.md` | Ace3 lifecycle, LibStub embedding, LibDataBroker minimap buttons, LibSharedMedia, SavedVariables migration, addon messaging with instance restrictions, and performance patterns |

---

## Contributing

Contributions focused on **API update reports** are most valuable. When a WoW patch changes an API this plugin documents, please open an issue using the API Update Report template:

[.github/ISSUE_TEMPLATE/api-update.md](.github/ISSUE_TEMPLATE/api-update.md)

The template captures the API name, old behaviour, new behaviour, the source or patch notes URL, an affected code snippet, and the interface version where the change was observed.

Pull requests that update reference docs with verified API changes are welcome. Please include the patch notes URL or warcraft.wiki.gg link as evidence.

---

## Midnight Context

World of Warcraft: Midnight (Interface 120001) introduced the **Secret Values** system, which wraps sensitive combat data — health, power, absorb amounts — in opaque types that cannot be used in arithmetic. Addons must call `issecretvalue(value)` before operating on any value that might be secret, and use `Curve` / `ColorCurve` APIs to perform calculations inside the protected sandbox. In the same expansion, `COMBAT_LOG_EVENT_UNFILTERED` was removed entirely; addons that tracked spell casts or combat events must migrate to unit-based events such as `UNIT_SPELLCAST_START` and `UNIT_SPELLCAST_SUCCEEDED`.

---

## Related Resources

- [warcraft.wiki.gg — Secret Values](https://warcraft.wiki.gg/wiki/Secret_values)
- [WoWAddonDevGuide by Amadeus](https://github.com/Amadeus-/WoWAddonDevGuide)
- [wow-ui-source by Gethe](https://github.com/Gethe/wow-ui-source)
- [Patch 12.0.0 API Changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)

---

MIT © 2026 Dennys Oliveira
