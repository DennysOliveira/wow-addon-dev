# MyAddon — Basic Addon Template

A minimal, copy-ready WoW addon scaffold targeting Midnight (Interface 120001 / 12.0+).

## What This Addon Does

- Loads saved variables on `ADDON_LOADED`, initialising defaults when no prior data exists or when upgrading from an older version.
- Prints a greeting message to the chat frame on `PLAYER_LOGIN`.
- Registers the slash command `/myaddon` which prints the current addon status.

## Installation

1. Copy the `MyAddon/` folder into your WoW retail installation:

```
_retail_/Interface/Addons/MyAddon/
```

The full path on a default Windows install looks like:

```
C:\Program Files (x86)\World of Warcraft\_retail_\Interface\Addons\MyAddon\
```

2. Launch WoW. Enable **MyAddon** in the AddOns list on the character select screen.
3. Log in. You should see the greeting message in your chat frame.

## Customisation Guide

### Rename the addon

1. Rename the folder from `MyAddon/` to `YourAddonName/`.
2. Rename `MyAddon.toc` to `YourAddonName.toc`.
3. Rename `MyAddon.lua` to `YourAddonName.lua` (or keep it as-is — the filename is arbitrary).
4. In `YourAddonName.toc`, update the file list entry to match the new Lua filename.
5. In `YourAddonName.toc`, update `## Title:`, `## Author:`, and `## SavedVariables:` to your addon name.
6. In `YourAddonName.lua`, update the `AddonName` comparison in the `ADDON_LOADED` handler — it matches the folder name automatically via `...`, so no hardcoded string change is needed.
7. Update the `SavedVariables` global (`MyAddonDB`) to match your new `## SavedVariables:` value in the TOC and throughout the Lua file.

### Change the slash command

In `MyAddon.lua`, change the two slash command lines:

```lua
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
```

Replace `/myaddon` with your desired command (e.g. `/mya`) and `MYADDON` with a unique uppercase key (e.g. `MYA`). The `SlashCmdList` key must be unique across all loaded addons — prefix it with your addon name to avoid collisions.

### Change the output

Edit the `DEFAULTS.greeting` value in `MyAddon.lua` to change the login message. To change the status output, edit the `SlashCmdList["MYADDON"]` function body. Use `|cffRRGGBB...|r` colour codes for coloured text.

### Add more saved variables

Add new keys to the `DEFAULTS` table. The version-gated initialisation block will apply them on first load or after a version bump. To trigger a reset on upgrade, increment the `version` value in `DEFAULTS` and add migration logic inside the `if MyAddonDB.version < N` branch.
