local function calcdiv(set,recipe_name,recipe,div)
    if recipe.completed then return end --already computed
    recipe.completed = true
    local tmp_div = 1
    for name,count in pairs(recipe.inputs) do
        if set.forced_input[name] then
            tmp_div=math.min(tmp_div,1)
        else
            local tmp_output_count=0
            for _,parent_name in pairs(recipe.parents) do
                local parent=set.recipe[parent_name]
                local delta_parent_recipe=((parent.outputs[name] or 0)*parent.divisor-(parent.inputs[name] or 0)*parent.divisor)
                
                tmp_output_count=tmp_output_count+math.max(0,delta_parent_recipe)
            end
            tmp_div = math.min(tmp_div, tmp_output_count / count)
        end
    end
    recipe.divisor = math.min(tmp_div, div)
end

local function rate_calc(set)
    local level_max=0
    for name, recipe in pairs(set.recipe) do
        level_max=math.max(recipe.level,level_max)
    end

    for i=0,level_max do
        for name, recipe in pairs(set.recipe) do
            if recipe.level==i then
                calcdiv(set,name,recipe,1)
            end
        end
    end

end

local function addcalc(rset, category, name, type, count)
    if not type then
        if game.fluid_prototypes[name] then
            type = "fluid"
        else
            type = "item"
        end
    end
    if not turn then turn = false end
    local path = type .. "/" .. name
    if not rset.rates[path] then
        rset.rates[path] = { type = type, name = name, input = { rate = 0 }, output = { rate = 0 } }
    end
    rset.rates[path][category].rate = rset.rates[path][category].rate + count
end

local function make_rate_set(set) --TODO recette qui tourne en rond
    local rset = { rates = {} }
    for name_recipe, recipe in pairs(set.recipe) do
        for name,count in pairs(recipe.inputs) do
            addcalc(rset, "input", name, nil, count * recipe.divisor)
        end
         for name,count in pairs(recipe.outputs) do
            addcalc(rset, "output", name, nil, count * recipe.divisor)
        end
    end
    if set.energy >= 0 then
        addcalc(rset, "input", "rcalc-power-dummy", "item", set.energy)
    else
        addcalc(rset, "output", "rcalc-power-dummy", "item", set.energy)
    end
    if set.polution >= 0 then
        addcalc(rset, "input", "rcalc-pollution-dummy", "item", set.polution)
    else
        addcalc(rset, "output", "rcalc-pollution-dummy", "item", set.polution)
    end
    rset.machines = set.machines
    rset.forced_input=set.forced_input
    return rset
end


local util = {}

function util.createRecipe(set)
    --game.write_file("set.json", game.table_to_json(set))
    --Structure of recipe
    --input{}
    --output{}
    --machine{}    machine du set + beacon + module
    --energy
    --pollution
    local inputs = {}
    local outputs = {}
    local energy = 0
    local polution = 0
    for path, rates in pairs(set.rates) do
        local output = rates.output
        local input = rates.input

        if path == "item/rcalc-power-dummy" then
            energy = input.rate - output.rate
            goto continue
        elseif path == "item/rcalc-pollution-dummy" then
            polution = input.rate - output.rate
            goto continue
        elseif path == "item/rcalc-heat-dummy" then
            goto continue
        end

        if string.match(path, "dummy") then
            goto continue --on ne veut pas des items cacher // on ajoutera les catcher ici pour la compat des mods
        end

        local sorting_rate = 0
        if output.rate > 0 and input.rate > 0 then
            if set.forced_input[rates.name] then
                sorting_rate = output.rate - input.rate
                if sorting_rate > 0 then
                    outputs[rates.name] = { type = rates.type, count = util.rounded(sorting_rate),real_count=sorting_rate }
                elseif sorting_rate < 0 then
                    inputs[rates.name] = { type = rates.type, count = util.rounded(sorting_rate),real_count=-sorting_rate }
                end
            end
        elseif input.rate > 0 then
            -- category = "ingredients"
            sorting_rate = input.rate
            inputs[rates.name] = { type = rates.type, count = util.rounded(sorting_rate),real_count=sorting_rate }
        else
            -- category = "products"
            sorting_rate = output.rate
            outputs[rates.name] = { type = rates.type, count = util.rounded(sorting_rate),real_count=sorting_rate }
        end
        -- if input.rate>0 then
        --     inputs[rates.name] = { type = rates.type, count = util.rounded(input.rate),real_count=input.rate }
        -- end
        -- if output.rate>0 then
        --     outputs[rates.name] = { type = rates.type, count = util.rounded(output.rate),real_count=output.rate }
        -- end

        ::continue::
    end

    local recipe = {
        inputs = inputs,
        outputs = outputs,
        machines = set.machines,
        energy = energy,
        polution = polution

    }
    return recipe
end


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

function util.insert_stack(entity, player)
    local inv = entity.get_inventory(defines.inventory.chest)
    local player_inv = player.get_main_inventory()
    if not inv then return false end
    if not player_inv then return false end
    inv.sort_and_merge()
    player_inv.sort_and_merge()
    if inv.is_full() then return false end
    if player_inv.is_full() then return false end

    for i = 1, #inv do
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

function util.set_calc_blueprint_p2(set, player)
    rate_calc(set)
    util.debug(player,"set4.json",set)
    local rate_set = make_rate_set(set)
    util.debug(player,"rate_set.json",rate_set)
    local recipe = util.createRecipe(rate_set)
    util.debug(player,"recipe.json",recipe)
    local str2 = util.get_bp(recipe)
    local blueprint_item_str = "0" .. game.encode_string(str2)
    util.debug(player,"final_string.txt",blueprint_item_str,true)
    player.cursor_stack.import_stack(blueprint_item_str)
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
        if tot >= 4 then break end
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
    if a >= 0 then
        return math.floor(a + 0.5)
    else
        return math.floor(-a + 0.5)
    end
end

function util.round(num, dp)
    local c = 2 ^ 52 + 2 ^ 51
    local mult = 10 ^ (dp or 0)

    return ((num * mult + c) - c) / mult
end

function util.recipe_emerg()
    local recipe_emg = {}
    if settings.global["lihop-prevent-emergence"].value == true then
        for name, recipe in pairs(game.recipe_prototypes) do
            if not next(recipe.ingredients) then
                recipe_emg[name]=true
                
            end
        end
    end
    game.write_file("recipe_emg.json", game.table_to_json(recipe_emg))
    return recipe_emg
end

function util.debug(player,filename,data,bool)
    if settings.get_player_settings(player)["lihop-multiplier-recipe"].value then
        if bool then
            game.write_file(filename,data)
        else
            game.write_file(filename,game.table_to_json(data))
        end
    end
end

function util.make_help_tooltip()
    
    return ""
end

--separate string
function util.split (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end

return util
