# Proximity Pickup

Pick up one item from a pile, and the whole pile comes with it.

Crafting stations and the Dismantle Bench drop their output one item at a time, so a big batch of anything leaves a pile of single items: craft 100 items, and you press the pickup key 100 times. With this mod, you pick up one of them by hand, and the items of the same type that lie near it go into your inventory too.

## Features

- **Pile pickup**: pick up one item by hand, and every item of the same type within 2 m comes with it, on the ground, a shelf, or a workbench. Works for crafting and Dismantle Bench output, items you dropped, and loot.
- **Arrows**: pick up one arrow, and the other arrows of the same type within 2 m come with it, on the ground or stuck in a body.
- **Same rules**: your inventory limits apply as usual. When it fills up, the rest of the pile stays where it lies. A bag with items in it never comes with the pile, so its contents are safe.

## Save safety

The mod stores nothing in your save, so you can remove it at any time.

## Multiplayer

Tested only in single player. In co-op, only the host needs the mod: the pile pickup then works for every player. A player who joins a host without the mod gets the normal pickup, with or without the mod.

## Works well with

- [Custom Stack Size](https://www.nexusmods.com/permafrost/mods/5): bigger stacks, so more of each pile fits in your inventory.

## Requirements

- Permafrost (Early Access), the update of 30 October 2026 or later.
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases) 3.0.1 or later. Vortex installs it for you.

## Installation

**Vortex (recommended):**

1. Click **Vortex** at the top of the [Nexus page](https://www.nexusmods.com/permafrost/mods/40) *(needs the [Permafrost Vortex Extension](https://www.nexusmods.com/site/mods/2466), which also installs UE4SS)*.

**Manual installation:**

1. Install [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases).
2. Extract this mod's zip into the game folder (the folder with Permafrost.exe). The mod lands in Permafrost\Binaries\Win64\ue4ss\Mods. Full path example:
   `C:\Program Files (x86)\Steam\steamapps\common\Permafrost\Permafrost\Binaries\Win64\ue4ss\Mods\ProximityPickup`

## Uninstall

In Vortex, remove the mod on the Mods page. After a manual install, delete the `ProximityPickup` folder from the `ue4ss\Mods` folder.

## Configuration

To change mod settings, edit `ue4ss\Mods\ProximityPickup\config.lua` while the game is closed (see [CONFIG.md](CONFIG.md) for every setting). Changes apply at the next game start.

## Development

The logic files (`Scripts/*_logic.lua`) have unit tests that run with plain Lua 5.4, from the repo root:

```
lua tests/run.lua
```

`./package.ps1` makes the install zip in `dist/`.

## License

Licensed under the GNU General Public License v3.0. Copyright (C) 2026 ivmakk.

Do not reupload this mod or a changed copy without credit and a link to this repository.
