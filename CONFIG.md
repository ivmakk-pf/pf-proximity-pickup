# Configuration

Every setting lives in `Permafrost\Binaries\Win64\ue4ss\Mods\ProximityPickup\config.lua`, written the first time you run the game with the mod installed. Edit it with any text editor while the game is closed. Changes apply at the next game start. A mod update keeps this file.

| Setting | Default | Values | What it does |
|---|---|---|---|
| `pickup_radius_m` | `2` | `0` to `10` | How close, in metres, an item of the same type must lie to the item you pick up to come with it. `0` turns the pile pickup off. |
| `verbose` | `false` | `true`, `false` | Writes extra lines to `UE4SS.log` for troubleshooting. Keep it off in normal play. |

A value outside its range applies as the nearest limit. A value of the wrong type applies as the default. When the game cannot read the file (for example after a typo), every setting applies as the default, and the file stays as it is.
