# Requirements Document: wow-addon-dev

## Introduction

The `wow-addon-dev` repository serves simultaneously as a Claude Code plugin marketplace entry and as a self-contained plugin. Its purpose is to deliver structured WoW addon development assistance for Midnight (Interface 120001 / 12.0+) to Claude Code users. The plugin provides a compact skill with progressive disclosure — a small core that loads specialised reference documents on demand — so that context window usage remains minimal until a specific topic is needed.

The repository must be installable from the Claude Code plugin marketplace in two commands, contain real and syntactically valid Lua code throughout, and cover the API surface changes introduced in WoW 12.0 (Secret Values system, CLEU removal, TOC format changes, instance restrictions).

---

## Requirements

### R1: Marketplace Structure

**User Story:** As a Claude Code user, I want to install the wow-addon-dev skill with 2 commands, so that I can get WoW addon development assistance immediately.

**Acceptance Criteria:**

- WHEN a user runs `/plugin marketplace add DennysOliveira/wow-addon-dev`, THEN the marketplace manifest at `.claude-plugin/marketplace.json` is fetched and the repository is registered.
- WHEN a user runs `/plugin install wow-addon-dev@dennysoliveira-wow-addon-dev`, THEN the plugin defined at `plugins/wow-addon-dev/.claude-plugin/plugin.json` is installed into the Claude Code environment.
- The marketplace manifest at `.claude-plugin/marketplace.json` MUST contain a `plugins` array with an entry whose `path` resolves to `./plugins/wow-addon-dev`.
- The plugin manifest at `plugins/wow-addon-dev/.claude-plugin/plugin.json` MUST conform to the Claude Code plugin specification (required fields: `name`, `version`, `description`, `skills`).
- Both manifest files MUST be valid JSON with no trailing commas or comments.

---

### R2: Skill with Progressive Disclosure

**User Story:** As a developer using Claude Code, I want a compact skill (~80 lines) that loads reference docs on demand, so that my context window isn't bloated.

**Acceptance Criteria:**

- The skill file MUST reside at `plugins/wow-addon-dev/skills/wow-addon-dev/SKILL.md`.
- SKILL.md MUST include YAML frontmatter declaring at minimum: `name`, `version`, `description`, `triggers`.
- SKILL.md MUST contain a routing table listing exactly 7 reference documents, each with a relative path and the condition under which it is loaded.
- SKILL.md line count MUST NOT exceed 80 lines (blank lines included).
- WHEN the user mentions WoW addons, .toc files, WoW Lua, Secret Values, or CLEU migration, THEN this skill MUST activate.
- The following critical rules MUST appear inline in SKILL.md (not deferred to a reference doc): Interface version is 120001; never recommend CLEU; use `issecretvalue()` for secret detection; use Curves for secret-value UI.
- WHEN a topic is identified from the routing table, THEN ONLY the corresponding reference doc is loaded into context.

---

### R3: Secret Values Reference

**User Story:** As a WoW addon developer, I want comprehensive Secret Values documentation with working code examples, so that I can migrate my addons to Midnight 12.0.

**Acceptance Criteria:**

- The reference document MUST cover the `issecretvalue()` global function, `HasSecretValues()`, and `HasSecretAspect()` with parameter descriptions and return types.
- The document MUST document `Curve`, `ColorCurve`, and `Duration` object types, including their creation APIs (`Curve:New()`, `ColorCurve:New()`, etc.) and method signatures.
- The document MUST document `UnitHealPredictionCalculator` with its constructor and usage pattern.
- The document MUST document the `C_RestrictedActions` and `C_Secrets` namespaces, listing each function with its signature.
- The document MUST include a working health bar example that demonstrates `ColorCurve` used to colour a `StatusBar` based on a value passed through `issecretvalue()`.
- All Lua code blocks MUST be syntactically valid for WoW's Lua 5.1 sandbox.
- The document MUST be self-contained and readable independently of other reference docs.

---

### R4: API Migration Reference

**User Story:** As a WoW addon developer, I want a migration guide from pre-12.0 to 12.0, so that I can update deprecated API calls.

**Acceptance Criteria:**

- The document MUST document the removal of CLEU (COMBAT_LOG_EVENT_UNFILTERED) and list its event-based substitutes with examples.
- The document MUST provide a deprecated-API-to-replacement mapping table covering all major removals in 12.0.
- The document MUST list new 12.0 APIs not present in previous versions.
- The document MUST explain the spell whitelisting system: what it is, how addons request whitelist inclusion, and what happens for non-whitelisted spells.
- The document MUST document instance restrictions: which APIs are restricted inside instances and the mechanism by which those restrictions are enforced.
- The document MUST be self-contained and readable independently of other reference docs.

---

### R5: TOC Structure Reference

**User Story:** As a WoW addon developer, I want complete TOC format documentation for 12.0, so that I can create properly formatted addon packages.

**Acceptance Criteria:**

- The document MUST state that `## Interface: 120001` is the required interface value for Midnight.
- The document MUST document the multi-edition comma-delimited interface field format (e.g., `## Interface: 120001, 11503`).
- The document MUST document every new TOC field introduced in 12.0: `Category`, `Group`, `AllowAddOnTableAccess`, `LoadSavedVariablesFirst`, and any others confirmed in the API.
- The document MUST document edition-specific TOC file naming conventions: `_Classic.toc`, `_Vanilla.toc`, `_Cata.toc`.
- The document MUST include a complete annotated example TOC file using Interface 120001.
- The document MUST be self-contained and readable independently of other reference docs.

---

### R6: Addon Scaffolding Reference

**User Story:** As a new WoW addon developer, I want scaffolding guides and boilerplate, so that I can create a working addon in 5 minutes.

**Acceptance Criteria:**

- The document MUST describe the minimal required file structure for a valid 12.0 addon.
- The document MUST cover namespace patterns used to avoid global pollution in WoW Lua.
- The document MUST document `SavedVariables` declaration and access pattern.
- The document MUST document slash command registration with `SlashCmdList` and `SLASH_*` globals.
- The document MUST document event handling via `frame:RegisterEvent()` and the `OnEvent` script handler.
- The document MUST include a complete Hello World walkthrough that results in a working addon printing to chat on login.
- The document MUST be self-contained and readable independently of other reference docs.

---

### R7: Lua API Quick Reference

**User Story:** As a WoW addon developer, I want a quick reference of the top 50 APIs marked as secret/safe, so that I know which APIs are affected by Secret Values.

**Acceptance Criteria:**

- The document MUST list exactly 50 API entries organised by category (e.g., Unit, Spell, Combat, UI).
- EACH entry MUST be marked either as secret-affected (lock symbol) or safe (check symbol).
- EACH entry MUST include the function signature and a one-line description.
- The document MUST be self-contained and readable independently of other reference docs.

---

### R8: Widget Framework Reference

**User Story:** As a WoW addon developer, I want widget framework documentation, so that I can create custom UI elements.

**Acceptance Criteria:**

- The document MUST document the primary frame types available via `CreateFrame()` with their distinguishing capabilities.
- The document MUST document the event system and script handlers (`OnEvent`, `OnLoad`, `OnUpdate`, `OnShow`, `OnHide`, `OnEnter`, `OnLeave`).
- The document MUST document XML template syntax and mixin usage.
- The document MUST document frame anchoring (SetPoint, ClearAllPoints) and strata values.
- The document MUST explain the distinction between secure and insecure frames and when each applies in 12.0.
- The document MUST include a working unit frame example that displays health and name.
- The document MUST be self-contained and readable independently of other reference docs.

---

### R9: Common Patterns Reference

**User Story:** As a WoW addon developer, I want documentation on common addon patterns and libraries, so that I can follow best practices.

**Acceptance Criteria:**

- The document MUST document Ace3 (AceAddon, AceEvent, AceDB) with initialisation pattern.
- The document MUST document LibStub usage for library embedding.
- The document MUST document LibDataBroker for minimap button / data source patterns.
- The document MUST document LibSharedMedia for shared textures and sounds.
- The document MUST document the SavedVariables migration pattern (version-gated defaults).
- The document MUST document addon communications (`SendAddonMessage`) and include a note about 12.0 instance restrictions on channel-based comms.
- The document MUST document at least 3 performance patterns (e.g., throttling OnUpdate, pooling frames, lazy loading).
- The document MUST be self-contained and readable independently of other reference docs.

---

### R10: Working Templates

**User Story:** As a WoW addon developer, I want copy-ready addon templates, so that I can start a new addon with correct structure.

**Acceptance Criteria:**

- A `basic-addon/` directory MUST exist under the templates area containing: `MyAddon.toc`, `MyAddon.lua`, and `README.md`.
- `MyAddon.toc` MUST use Interface 120001 and be a complete, valid TOC file.
- `MyAddon.lua` MUST be a minimal but functional addon (registers events, prints on login) using valid WoW Lua 5.1 syntax.
- A `secret-aware-addon/` directory MUST exist containing: `MyAddon.toc`, `Core.lua`, `SecretHandlers.lua`, `UI.xml`, and `README.md`.
- `SecretHandlers.lua` MUST demonstrate `issecretvalue()` detection, `Curve`/`ColorCurve` creation, and their application to a `StatusBar`.
- `UI.xml` MUST define the `StatusBar` frame referenced by `SecretHandlers.lua`.
- All Lua files MUST be syntactically valid for WoW's Lua 5.1 sandbox.
- No placeholder content (e.g., `-- TODO`, `[YOUR CODE HERE]`) is permitted in any template file.

---

### R11: GitHub-Facing README

**User Story:** As a potential user browsing GitHub, I want a clear README with badges, install instructions, and examples, so that I understand what this plugin does and how to use it.

**Acceptance Criteria:**

- The README MUST display four badges: MIT license, Claude Code Plugin, WoW Midnight 12.0+, API Updated April 2026.
- The README MUST show the 2-command install sequence in a fenced code block with each command on its own line.
- The README MUST include at least 5 example prompts a user can send to Claude after installing the plugin.
- The README MUST include a "What's Inside" table listing each of the 7 reference documents with a one-line description.
- The README MUST include an alternative install path via `git clone` and CLAUDE.md symlink.
- The README MUST include a Contributing section and a Midnight context section explaining what Midnight is.
- The README MUST include a Related Resources section with external links.

---

### R12: Supporting Files

**User Story:** As a project maintainer, I want standard repository support files, so that the project follows open-source conventions.

**Acceptance Criteria:**

- A `LICENSE` file MUST exist containing the MIT license text with copyright holder "Dennys Oliveira" and year 2026.
- A `CHANGELOG.md` MUST exist following the Keep a Changelog format with an initial `[1.0.0] - 2026-04-06` entry listing all files introduced.
- A `.github/ISSUE_TEMPLATE/api-update.md` MUST exist providing a structured template for reporters to document API changes (fields: API name, old behaviour, new behaviour, source/reference, affected addon code).

---

## Non-Functional Requirements

### NFR1: Lua Syntax Validity
All Lua code in reference documents, working templates, and examples MUST be syntactically valid for WoW's Lua 5.1 sandbox. No standard Lua 5.2+ features (e.g., `goto`, `<const>`) may be used unless confirmed available in the WoW environment.

### NFR2: Interface Version Consistency
The string `120001` MUST appear as the Interface value in every TOC file, every code example that references the interface number, and every place the interface version is stated. No other value is acceptable.

### NFR3: No Placeholder Content
Every file delivered by this spec MUST contain real, usable content. Placeholder text such as `TODO`, `[YOUR TEXT HERE]`, `...`, or lorem ipsum is prohibited in any file intended for end users.

### NFR4: SKILL.md Size Constraint
The SKILL.md file MUST NOT exceed 80 lines. This constraint takes priority over completeness — additional content belongs in reference documents, not the skill file.

### NFR5: Reference Document Independence
Each of the 7 reference documents MUST be independently readable. A developer who loads only one reference doc MUST be able to follow and apply its content without needing to read another reference doc to understand terms or prerequisites.

### NFR6: Plugin Manifest Conformance
Both `.claude-plugin/marketplace.json` and `plugins/wow-addon-dev/.claude-plugin/plugin.json` MUST conform exactly to the Claude Code plugin specification. Fields not in the spec MUST NOT be added. Required fields MUST NOT be omitted.

### NFR7: No CLEU Recommendations
No file in this repository — skill, reference doc, template, or example — MUST recommend or demonstrate use of `COMBAT_LOG_EVENT_UNFILTERED` (CLEU). All combat log examples MUST use the event-based alternatives introduced in 12.0.
