local util = require("script.util")

local function fp_to_recipe(factories,player)
    local recipe={
        machines={},
        polution=0,
        energy=0,
        inputs={},
        outputs={}
    }
    local divisor=factories.timescale
    --- il faut tout recalculer avec ce mod donc traintement plus tard


    return {recipe=recipe,name=factories.name,description=factories.notes}
end

local function read(player, factory_text)
    local ok, err = pcall(function()
        factory_text = game.decode_string(factory_text)
    end)
    if not (ok) then
        return nil
    end
    util.debug(player, "factoryp.json", factory_text, true)
    local factories=game.json_to_table(factory_text).factories
    if not factories then return nil end
    return factories[1]
end

local fp_util = {}

function fp_util.create_bp(e)
    local player = game.players[e.player_index]
    if not player then return end
    local tags = e.element.tags
    if not next(tags) then return end     --text sur le pointeur
    local factory_text = tags.text
    if not factory_text then return end   --text sur le pointeur
    factory_text = string.gsub(factory_text, "%s+", "")
    if factory_text == "" then return end --text sur le pointer
    local table = read(player, factory_text)
    if not table then return end          -- text sur le pointeur
    local recipe=fp_to_recipe(table,player)
    -- local str2 = util.get_bp(recipe)
    -- local blueprint_item_str = "0" .. game.encode_string(str2)
    -- util.debug(player,"final_string.txt",blueprint_item_str,true)
    -- player.cursor_stack.import_stack(blueprint_item_str)
end

return fp_util
