# Copilot code-review instructions

This repo is a UE4SS Lua mod for *Permafrost*, a co-op Unreal Engine 5.4 game. The mod runs in UE4SS (Lua 5.4): it hooks game UFunctions with `RegisterHook`, watches new objects with `NotifyOnNewObject`, and reads and writes UObject properties at runtime. Review with these traps in mind; a general Lua review misses most of them.

## This mod

ProximityPickup has one feature, on while `pickup_radius_m` is above 0: when a player picks up an item from the ground by hand, the mod also picks up the other items of the same type within the radius.

- **Hook.** The pre callback of the native RPC `/Script/Permafrost.PlayerKnowledgeComponent:SERVER_HandleItemPickup`, registered at mod start. The game's `Pickup` calls it before it adds the item and destroys the actor, so the item still exists there. The callback reads the item into plain values and defers the pile pickup with `ExecuteWithDelay` and then `ExecuteInGameThread`, so the game finishes its own pickup first.
- **Host side.** The callback acts only when the item has authority (`HasAuthority()`). The multiplayer kind is Host: in co-op, only the host needs the mod.
- **The game's own pickup.** Each extra item goes through the item's own `Pickup(controller)`, so the inventory rules, the full-inventory message, and the sound stay the game's. Flag any inventory grant that bypasses it (for example a direct `AddItem`).
- **Same type.** Two items have the same type when their `Item Config Loaded` objects have the same full name. The walk is `FindAllOf(<class short name of the picked item>)`, one time for each manual pickup, never in a per-frame path.

Invariants:

- **No re-entry.** The `picking` flag is set while the mod calls `Pickup` itself, so its own calls do not start another pile pickup. Flag a change that can leave it set or skip it.
- **A destroyed item looks valid.** A picked-up item stays `IsValid()` and in `FindAllOf` for a while, but loses its root component at once. The mod tests "on the ground" with `K2_GetRootComponent()`. Flag a test that uses `IsValid()` alone.
- **Stop at the first item that stays.** When a `Pickup` call leaves the item on the ground, the inventory is full: the loop stops, so the game shows its message one time.
- **Bags stay.** An item whose `ItemInventory` is not empty, or cannot be read, is never picked up by the mod: the game opens such an item in place of a pickup, so a `Pickup` call could lose its contents.

## UE4SS traps

- **Object life.** A UObject can be destroyed at any time. Flag a stored object reference that is used without an `IsValid()` check.
- **Hook callbacks must not break the game.** Each callback body runs in `pcall`, and an error logs once. Flag a callback without `pcall`, and a log call in a per-call path with no once-only guard.
- **Blueprint hooks.** A Blueprint UFunction (`/Game/...`) exists only after its asset loads. Flag a `RegisterHook` on a `/Game/` path at mod start with no retry or load hook.
- **Full paths.** `RegisterHook` and `NotifyOnNewObject` need the full path (`/Script/Permafrost.Class:Function`, `/Game/.../BP_X.BP_X_C`). Flag a short class name.
- **Parameters.** Hook parameters are `RemoteUnrealParam`: read with `:get()`, write with `:set()`. Flag a direct use of the parameter as a value.
- **New objects.** The properties of an object from `NotifyOnNewObject` are not set at the callback. Flag a property read in that callback with no deferral.
- **Game thread.** Key bind and `LoopAsync` callbacks run outside the game thread. Flag UObject work there that is not inside `ExecuteInGameThread`.
- **Native crashes.** `pcall` does not catch a native crash. Flag a read of a whole struct or of soft object fields when the code needs only one field.
- **The Lua `debug` library.** Flag a local named `debug`, `print`, or another standard name that hides a library.

## Multiplayer

- **Side.** A `SERVER_` function body, `AUTHORITY_` functions, and inventory grants run on the host. Flag code that changes shared state (damage, loot, inventory) on a client, and host logic with no `HasAuthority()` check where both sides run the code.
- **Multiplayer kind.** The README states who must install the mod (Local only, Host, Every player). Flag a change that moves code to the other side without a README update.

## Performance

- Flag `FindAllOf`, `FindFirstOf`, `StaticFindObject`, string building, or table building in a tick hook, a `LoopAsync` with a short interval, or a hook of a function that runs often.

## Compatibility

- The mod must work with the vanilla game and with the mods named in the README. Flag a write of a game property that another named mod also writes, and an inventory grant that bypasses the game's own pickup path.

## Structure and tests

- **Pure logic is separated and tested.** Logic that does not need the running game lives in a `*_logic.lua` file with no UE4SS global and no UObject, tested under `tests/`. Flag new pure logic in a hook callback, and new pure logic with no test.
- **One function for each hook target,** named `<feature>On<Target>`.

## Release and config hygiene

- **Verbose ships off.** The `verbose` default is `false`. Debug lines go behind it; without it only the load line, warnings, and errors log.
- **The mod folder name never changes.** It is the `ue4ss\Mods\` folder and the home of the player's `config.lua`. Flag any rename.
- **The config file belongs to the player.** The mod writes `config.lua` only when it is missing. Flag code that overwrites it, and a `config.lua` in the repo or the zip.
- **The version** is the `VERSION` constant in `Scripts/main.lua`, printed in the load line.
- **No committed package output.** Flag `dist/` or a zip in the diff.
- **No game content.** Flag a header pasted from the UE4SS dump or an extracted game asset.
- **Changelog matches the change.** A player-visible change adds an `[Unreleased]` entry to `CHANGELOG.md` in player-facing wording. An internal-only refactor gets none.
