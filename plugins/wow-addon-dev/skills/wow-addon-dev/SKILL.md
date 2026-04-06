---
name: wow-addon-dev
version: "1.0.0"
triggers: [wow, world-of-warcraft, addon, lua, wowaddon, "secret values", issecretvalue, midnight, "interface 120001", widget, frame, ace3, libstub, toc]
description: >
  WoW addon development skill for Midnight (12.0+). Use when creating, debugging, migrating,
  or maintaining World of Warcraft addons. Covers Lua API, Secret Values system, widget framework,
  TOC structure, Ace3/LibStub libraries, and addon scaffolding. Trigger this skill whenever the user
  mentions WoW addons, World of Warcraft UI, .toc files, WoW Lua, Secret Values, CLEU migration,
  or any addon-related development task — even if they don't explicitly say "use wow skill".
---

# WoW Addon Development Skill (Midnight 12.0+)

## What

- WoW uses Lua 5.1 + XML for UI. Current: Midnight 12.0.x (Interface: 120001)
- Biggest API change since launch: Secret Values restrict combat data in addon code
- Test with `issecretvalue(val)` — use Curve/ColorCurve objects to process secret data

## Routing

| User asks about... | Read |
|---|---|
| Secret Values, issecretvalue, Curves | `${CLAUDE_SKILL_DIR}/references/secret-values.md` |
| Migration, deprecated APIs, CLEU replacement | `${CLAUDE_SKILL_DIR}/references/api-migration-12.md` |
| TOC files, Interface version, packaging | `${CLAUDE_SKILL_DIR}/references/toc-structure.md` |
| New addon, scaffold, boilerplate | `${CLAUDE_SKILL_DIR}/references/addon-scaffolding.md` |
| API function lookup, which APIs are secret | `${CLAUDE_SKILL_DIR}/references/lua-api-quick-ref.md` |
| Frames, widgets, XML, UI elements | `${CLAUDE_SKILL_DIR}/references/widget-framework.md` |
| Ace3, LibStub, SavedVariables, comms | `${CLAUDE_SKILL_DIR}/references/common-patterns.md` |
| New addon from scratch | Copy from `${CLAUDE_SKILL_DIR}/../templates/basic-addon/` or `secret-aware-addon/` |

## Critical Rules

1. ALWAYS use Interface 120001 in TOC files
2. NEVER use COMBAT_LOG_EVENT_UNFILTERED (CLEU) — removed in 12.0
3. ALWAYS call issecretvalue() before operating on health/power/combat values
4. Use Curve/ColorCurve to transform secret values for display
5. Addon communications (SendAddonMessage) are blocked inside instances in 12.0
6. Reference doc paths use ${CLAUDE_SKILL_DIR} prefix

## External Resources

- warcraft.wiki.gg/wiki/World_of_Warcraft_API
- github.com/Amadeus-/WoWAddonDevGuide
- github.com/Gethe/wow-ui-source
