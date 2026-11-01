-- ProximityPickup: an item picked up by hand from the ground also picks up the items of the same
-- type that lie near it, through the game's own pickup of each item.
local MOD = "ProximityPickup"
local VERSION = "1.0.0"

local SCHEMA = require("pp_schema")

local function log(message)
    print("[" .. MOD .. "] " .. message .. "\n")
end

local warned = {}
local function warnOnce(key, message)
    if warned[key] then return end
    warned[key] = true
    log("WARN " .. message)
end

local config = require("pp_config_file").load(SCHEMA, log)

-- Not named "debug": that would hide the Lua debug library.
local function trace(message)
    if config.verbose then log(message) end
end

---@param fn fun(): any
---@return any
local function try(fn)
    local ok, value = pcall(fn)
    if ok then return value end
    return nil
end

local function valid(obj)
    return obj ~= nil and try(function()
        return obj:IsValid()
    end) == true
end

local function guard(key, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then warnOnce(key, key .. ": " .. tostring(err)) end
    end
end

local logic = require("pp_pickup_logic")

local HOOK = "/Script/Permafrost.PlayerKnowledgeComponent:SERVER_HandleItemPickup"
-- The pile pickup waits until the game finished its own pickup of the first item.
local DEFER_MS = 100

---@param obj any
---@return string?
local function nameOf(obj)
    return try(function()
        return obj:GetFName():ToString()
    end)
end

---@param item ABP_StaticMasterItem_C
---@return string?
local function classShort(item)
    return nameOf(try(function()
        return item:GetClass()
    end))
end

-- Two items have the same type when their item configs have the same full name.
---@param item ABP_StaticMasterItem_C
---@return string?
local function typeKeyOf(item)
    local itemConfig = try(function()
        return item["Item Config Loaded"]
    end)
    if not valid(itemConfig) then return nil end
    return try(function()
        return itemConfig:GetFullName()
    end)
end

---@param item ABP_StaticMasterItem_C
---@return Pos?
local function posOf(item)
    local loc = try(function()
        return item:K2_GetActorLocation()
    end)
    if not loc then return nil end
    return { X = loc.X, Y = loc.Y, Z = loc.Z }
end

-- A destroyed item stays valid and in FindAllOf for a while, but it loses its root component
-- at once, in the same call as the game's pickup.
---@param item ABP_StaticMasterItem_C
---@return boolean
local function onGround(item)
    return valid(item) and valid(try(function()
        return item:K2_GetRootComponent()
    end))
end

-- The game opens such an item in place of a pickup, so a Pickup call could lose its contents.
---@param item ABP_StaticMasterItem_C
---@return boolean
local function holdsItems(item)
    -- A failed read counts as a bag with contents, so the item stays on the ground. An item
    -- with no inventory (most items) is not a bag.
    local ok, inv = pcall(function()
        return item.ItemInventory
    end)
    if not ok then return true end
    return valid(inv) and try(function()
        return inv:GetIsEmpty()
    end) ~= true
end

local picking = false -- true while the mod calls Pickup itself

---@class PickedItem : PileEntry
---@field item ABP_StaticMasterItem_C
---@field short string

---@param picked PickedItem
---@param controller any
local function pickupPile(picked, controller)
    if onGround(picked.item) then
        trace("pickup of " .. picked.name .. " did not take the item (inventory full?); no pile pickup")
        return
    end
    local start = os.clock()
    local all = FindAllOf(picked.short) or {} ---@type ABP_StaticMasterItem_C[]
    local entries = {}
    for _, item in ipairs(all) do
        -- The location first: the other reads only for the items within the radius.
        local pos = valid(item) and posOf(item) or nil
        if pos and logic.inRadius(picked.pos, pos, config.pickup_radius_m) then
            local name, typeKey = nameOf(item), typeKeyOf(item)
            if name and typeKey then
                entries[#entries + 1] = {
                    item = item,
                    name = name,
                    typeKey = typeKey,
                    pos = pos,
                    holdsItems = holdsItems(item),
                    destroyed = not onGround(item),
                }
            end
        end
    end
    local pile = logic.selectPile(picked, entries, config.pickup_radius_m)
    local walkMs = (os.clock() - start) * 1000
    local taken = 0
    picking = true
    local ok, err = pcall(function()
        for _, entry in ipairs(pile) do
            if not valid(controller) then break end
            if onGround(entry.item) then
                entry.item:Pickup(controller)
                if onGround(entry.item) then break end -- the inventory is full: the game showed its message
                taken = taken + 1
            end
        end
    end)
    picking = false
    if not ok then
        warnOnce("pickup call", "a pile pickup call failed; the rest stays on the ground: " .. tostring(err))
    end
    trace(
        string.format(
            "pile %s candidates=%d pile=%d picked=%d walk %.2fms total %.2fms",
            picked.short,
            #all,
            #pile,
            taken,
            walkMs,
            (os.clock() - start) * 1000
        )
    )
end

-- Runs on the host: the body of the server RPC that the game's Pickup calls before it adds and
-- destroys the item, so the item still exists here.
local function onItemPickup(self, itemParam)
    if picking then return end
    local item = itemParam:get() ---@type ABP_StaticMasterItem_C
    if not try(function()
        return item:HasAuthority()
    end) then return end
    local component = self:get() ---@type UPlayerKnowledgeComponent
    local owner = try(function()
        return component:GetOwner()
    end)
    local controller = valid(owner) and try(function()
        return owner:GetController()
    end) or nil
    if not valid(controller) then
        warnOnce("controller", "no player controller for a pickup; no pile pickup")
        return
    end
    local name, short, typeKey, pos = nameOf(item), classShort(item), typeKeyOf(item), posOf(item)
    if not (name and short and typeKey and pos) then
        warnOnce("item read", "cannot read a picked item (a game change?); no pile pickup")
        return
    end
    ---@type PickedItem
    local picked = {
        item = item,
        name = name,
        short = short,
        typeKey = typeKey,
        pos = pos,
        holdsItems = false,
        destroyed = false,
    }
    ExecuteWithDelay(DEFER_MS, function()
        ExecuteInGameThread(guard("pile pickup", function()
            pickupPile(picked, controller)
        end))
    end)
end

local enabled = config.pickup_radius_m > 0
if enabled then
    local ok, err = pcall(RegisterHook, HOOK, guard("item pickup", onItemPickup))
    if ok then
        trace("pickup hook armed")
    else
        warnOnce("hook", "pickup hook failed; the mod is off: " .. tostring(err))
    end
end

log(
    string.format(
        "v%s loaded (pile pickup %s, radius %s m)",
        VERSION,
        enabled and "on" or "off",
        tostring(config.pickup_radius_m)
    )
)
