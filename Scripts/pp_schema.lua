-- The one source of the config keys, defaults, ranges, and comments.
-- Its own file, so the tests can read it without the UE4SS globals of main.lua.
---@type ConfigEntry[]
return {
    {
        key = "pickup_radius_m",
        default = 2,
        min = 0,
        max = 10,
        comment = "The items of the same type this close to the picked item are picked up too, in metres. 0 turns this off.",
    },
    { key = "verbose", default = false, comment = "Extra log lines in UE4SS.log. Keep off in normal play." },
}
