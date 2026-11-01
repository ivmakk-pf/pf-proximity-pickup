-- Game-free logic of the pile pickup: no UE4SS global and no UObject.
local M = {}

---@class Pos
---@field X number
---@field Y number
---@field Z number

---@class PileEntry
---@field name string
---@field typeKey string
---@field pos Pos Unreal units (cm)
---@field holdsItems boolean
---@field destroyed boolean

local CM_PER_M = 100

---@param a Pos
---@param b Pos
---@return number
local function distSq(a, b)
    local dx, dy, dz = a.X - b.X, a.Y - b.Y, a.Z - b.Z
    return dx * dx + dy * dy + dz * dz
end

-- Whether b is within radiusM metres of a. A radius of 0 or less takes nothing.
---@param a Pos
---@param b Pos
---@param radiusM number
---@return boolean
function M.inRadius(a, b, radiusM)
    return radiusM > 0 and distSq(a, b) <= (radiusM * CM_PER_M) ^ 2
end

-- The items of the pile around a picked item: same type, within radiusM metres, not the picked
-- item, not a bag with contents, not an item already destroyed. Nearest first.
---@generic T : PileEntry
---@param picked PileEntry
---@param entries T[]
---@param radiusM number
---@return T[]
function M.selectPile(picked, entries, radiusM)
    local pile, d = {}, {}
    for _, e in ipairs(entries) do
        if
            e.typeKey == picked.typeKey
            and e.name ~= picked.name
            and not e.holdsItems
            and not e.destroyed
            and M.inRadius(picked.pos, e.pos, radiusM)
        then
            pile[#pile + 1] = e
            d[e] = distSq(picked.pos, e.pos)
        end
    end
    table.sort(pile, function(a, b)
        return d[a] < d[b]
    end)
    return pile
end

return M
