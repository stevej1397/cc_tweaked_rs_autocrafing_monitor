-- Maps an item id (e.g. "minecraft:diamond") to a CC color used for the
-- 2x2 swatch shown next to its name on the monitor.
--
-- Extend `palette` for items you craft often; the keyword fallbacks below
-- handle most modded items reasonably. Unknown items show purple.

local palette = {
    ["minecraft:diamond"]         = colors.cyan,
    ["minecraft:diamond_block"]   = colors.cyan,
    ["minecraft:iron_ingot"]      = colors.lightGray,
    ["minecraft:iron_block"]      = colors.lightGray,
    ["minecraft:gold_ingot"]      = colors.yellow,
    ["minecraft:gold_block"]      = colors.yellow,
    ["minecraft:redstone"]        = colors.red,
    ["minecraft:emerald"]         = colors.green,
    ["minecraft:emerald_block"]   = colors.green,
    ["minecraft:netherite_ingot"] = colors.brown,
    ["minecraft:netherite_block"] = colors.brown,
    ["minecraft:coal"]            = colors.black,
    ["minecraft:copper_ingot"]    = colors.orange,
    ["minecraft:lapis_lazuli"]    = colors.blue,
    ["minecraft:quartz"]          = colors.white,
}

local M = {}

function M.forItem(name)
    if not name then return colors.purple end
    if palette[name] then return palette[name] end
    if name:find("ingot")     then return colors.lightGray end
    if name:find("nugget")    then return colors.lightGray end
    if name:find("plate")     then return colors.lightGray end
    if name:find("gear")      then return colors.lightGray end
    if name:find("wire")      then return colors.orange end
    if name:find("circuit")   then return colors.lime end
    if name:find("processor") then return colors.lime end
    if name:find("planks")    then return colors.brown end
    if name:find("log")       then return colors.brown end
    if name:find("leaves")    then return colors.lime end
    if name:find("sapling")   then return colors.lime end
    if name:find("dust")      then return colors.gray end
    if name:find("dye")       then return colors.magenta end
    if name:find("wool")      then return colors.white end
    return colors.purple
end

function M.register(name, color)
    palette[name] = color
end

return M
