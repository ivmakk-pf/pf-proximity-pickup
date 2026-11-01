local logic = require("pp_pickup_logic")

local function item(name, x, props)
    local e = { name = name, typeKey = "Ingot", pos = { X = x, Y = 0, Z = 0 }, holdsItems = false, destroyed = false }
    for k, v in pairs(props or {}) do
        e[k] = v
    end
    return e
end

local function names(list)
    local out = {}
    for _, e in ipairs(list) do
        out[#out + 1] = e.name
    end
    return table.concat(out, ",")
end

local picked = item("P", 0)

describe("selectPile", function()
    it("returns the items of the same type within the radius, nearest first", function()
        local pile = logic.selectPile(picked, { item("C", 150), item("A", 50), item("B", -100) }, 2)
        assert_eq(names(pile), "A,B,C")
    end)

    it("keeps an item at the radius edge and drops one just past it", function()
        local pile = logic.selectPile(picked, { item("Edge", 200), item("Out", 201) }, 2)
        assert_eq(names(pile), "Edge")
    end)

    it("measures in three dimensions", function()
        local pile = logic.selectPile(picked, { item("High", 0, { pos = { X = 0, Y = 150, Z = 150 } }) }, 2)
        assert_eq(names(pile), "")
    end)

    it("returns an empty pile for an empty list", function()
        assert_eq(#logic.selectPile(picked, {}, 2), 0)
    end)

    it("returns an empty pile for a radius of 0", function()
        assert_eq(#logic.selectPile(picked, { item("A", 0) }, 0), 0)
    end)

    it("skips an item of another type in range", function()
        local pile = logic.selectPile(picked, { item("Coal", 10, { typeKey = "Coal" }), item("A", 20) }, 2)
        assert_eq(names(pile), "A")
    end)

    it("skips an item that holds other items", function()
        local pile = logic.selectPile(picked, { item("Bag", 10, { holdsItems = true }), item("A", 20) }, 2)
        assert_eq(names(pile), "A")
    end)

    it("skips an item that is already destroyed", function()
        local pile = logic.selectPile(picked, { item("Gone", 10, { destroyed = true }), item("A", 20) }, 2)
        assert_eq(names(pile), "A")
    end)

    it("skips the picked item itself", function()
        local pile = logic.selectPile(picked, { item("P", 0), item("A", 20) }, 2)
        assert_eq(names(pile), "A")
    end)
end)
