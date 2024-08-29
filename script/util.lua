local util = {}

function util.construct_table(entities)
    local machine = {}
    for _, entity in pairs(entities) do
        if entity.type == "beacon" then
            if machine[entity.name] then machine[entity.name] = machine[entity.name] + 1 else machine[entity.name] = 1 end
        end
        local mod_inv = entity.get_module_inventory()
        if mod_inv then
            local content = mod_inv.get_contents()
            for name, count in pairs(content) do
                if machine[name] then machine[name] = machine[name] + count else machine[name] = count end
            end
        end
    end
    return machine
end

function util.update_construc_table(machine, entities, add)
    local mult = 1
    if not add then mult = -1 end
    for _, entity in pairs(entities) do
        if entity.type == "beacon" then
            if machine[entity.name] then machine[entity.name] = machine[entity.name] + (mult * 1) else machine[entity.name] = (mult * 1) end
            if machine[entity.name] < 0 then machine[entity.name] = nil end
        end
        local mod_inv = entity.get_module_inventory()
        if mod_inv then
            local content = mod_inv.get_contents()
            for name, count in pairs(content) do
                if machine[name] then machine[name] = machine[name] + (mult * count) else machine[name] = (mult * count) end
                if machine[name] < 0 then machine[name] = nil end
            end
        end
    end
end

function util.change(pos, rotation)
    rotation = (rotation / 2) + 1
    local cos = { 1, 0, -1, 0 }
    local sin = { 0, -1, 0, 1 }
    return {
        x = pos.x * cos[rotation] + pos.y * sin[rotation],
        y = -pos.x * sin[rotation] + pos.y * cos[rotation]
    }
end

function util.calc_position(entity, position)
    local new_pos = util.change(position, entity.direction)
    return {
        x = entity.position.x + new_pos.x,
        y = entity.position.y + new_pos.y
    }
end

function util.test_entity(entity)
    if entity then
        if entity.valid then
            return true
        else
            return false
        end
    else
        return false
    end
end

function util.insert_stack(entity,player)
    local inv = entity.get_inventory(defines.inventory.chest)
    local player_inv=player.get_main_inventory()
    if not inv then return false end
    if not player_inv then return false end
    inv.sort_and_merge()
    player_inv.sort_and_merge()
    if inv.is_full() then return false end
    if player_inv.is_full() then return false end
    
    for i=1,#inv do
        local item = inv[i]
        if item.valid_for_read then
            local first_empty_in_player = player_inv.find_empty_stack()
            if not first_empty_in_player then return false end
            if not first_empty_in_player.transfer_stack(item) then
                return false
            end
        end
    end
    return true
end

function util.insert2(inv, player)
    for name, count in pairs(inv.get_contents()) do
        return player.can_insert({ name = name, count = count })
    end
    return false
end

function util.add_errors(errors, error)
    if not errors[error] then
        errors[error] = true
    end
end

function util.make_caption_errors(errors, default)
    local caption = { "", }
    if not next(errors) then return default end
    for name, bool in pairs(errors) do
        table.insert(caption, "- ")
        table.insert(caption, { "gui." .. name })
        table.insert(caption, "\n")
    end
    return caption
end

---- create flying text
function util.entity_flying_text(entity, text, color, pos)
    local posi = nil
    if not entity.valid then return end
    if pos then posi = pos else posi = entity.position end
    entity.surface.create_entity({
        type = "flying-text",
        text_alignment = "left",
        name = "flying-text",
        position = posi,
        text = text,
        color = color,
    })
end

function util.get_bp(recipe)
    local icons = {}
    icons[1] = {
        signal = {
            type = "item",
            name = "lihop-machine-electric-interface"
        },
        index = 1
    }
    local tot = 1
    for name, obj in pairs(recipe.outputs) do
        if tot > 4 then break end
        tot = tot + 1
        icons[tot] = {
            signal = {
                type = obj.type,
                name = name
            },
            index = tot
        }
    end

    local bp = {
        blueprint = {
            description = "",
            icons = icons,
            entities = {
                {
                    entity_number = 1,
                    name = "lihop-machine-electric-interface",
                    position = {
                        x = 8.5,
                        y = -9.5
                    },
                    tags = recipe,
                    power_usage = 100000,
                    buffer_size = 1667
                }
            },
            item = "lihop-factoryrecipe",
            version = 281479278821376
        }
    }

    return game.table_to_json(bp)
end

function util.rounded(a)
    if a>=0 then
        return math.floor(a+0.5)
    else
        return math.floor(-a+0.5)
    end
end

function util.round(num, dp)
    local c=2^52+2^51
    local mult = 10^(dp or 0)

    return ((num*mult+c)-c)/mult
end

function util.recipe_emerg()
    local recipe_emg={}
    if settings.global["lihop-prevent-emergence"].value==true then
        for name,recipe in pairs(game.recipe_prototypes) do
            if not next(recipe.ingredients) then
                table.insert(recipe_emg,name)
            end
        end
    end
    game.write_file("recipe_emg.json",game.table_to_json(recipe_emg))
    return recipe_emg
end

return util
