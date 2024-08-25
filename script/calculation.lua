--- Most of code from : https://github.com/raiguard/RateCalculator

local flib_math = require("__flib__.math")
local util = require("script.util")


local entity_blacklist = {
    -- Transport Drones
    ["buffer-depot"] = true,
    ["fluid-depot"] = true,
    ["fuel-depot"] = true,
    ["request-depot"] = true,
}

local calculation = {}


local function addcalc(rset, category, name, type, count)
    local path = type .. "/" .. name
    if not rset.rates[path] then
        rset.rates[path] = { type = type, name = name, input = { rate = 0 }, output = { rate = 0 } }
    end
    rset.rates[path][category].rate = rset.rates[path][category].rate + count
end

local function rate_calc(set)
    local rset = { rates = {} }
    for recipename, data in pairs(set.recipe) do
        for input, count in pairs(data.inputs) do
            if game.item_prototypes[input] then
                addcalc(rset, "input", input, "item", count * data.divisor)
            elseif game.fluid_prototypes[input] then
                addcalc(rset, "input", input, "fluid", count * data.divisor)
            end
        end
        for output, count in pairs(data.outputs) do
            if game.item_prototypes[output] then
                addcalc(rset, "output", output, "item", count * data.divisor)
            elseif game.fluid_prototypes[output] then
                addcalc(rset, "output", output, "fluid", count * data.divisor)
            end
        end
    end
    rset.machines=set.machines
    return rset
end

local function process_intermediate(set)
    for name, count in pairs(set.products) do
        if set.ingredients[name] then
            game.print(count .. " : " .. set.ingredients[name])
            local divisor = math.min(1, count / set.ingredients[name])
            for recipe_name, data in pairs(set.recipe) do
                if data.inputs[name] then
                    data.divisor = math.min(data.divisor, divisor)
                    data.level = data.level + 1
                    set.level_max = math.max(set.level_max, data.level)
                end
            end
        end
    end
end

--- Source: https://github.com/ClaudeMetz/FactoryPlanner/blob/0f0aeae03386f78290d932cf51130bbcb2afa83d/modfiles/data/handlers/generator_util.lua#L364
--- @param prototype LuaEntityPrototype
--- @return number?
function get_seconds_per_rocket_launch(prototype)
    local rocket_prototype = prototype.rocket_entity_prototype
    if not rocket_prototype then
        return nil
    end

    local rocket_flight_threshold = 0.5 -- hardcoded in the game files
    local launch_steps = {
        lights_blinking_open = (1 / prototype.light_blinking_speed) + 1,
        doors_opening = (1 / prototype.door_opening_speed) + 1,
        doors_opened = prototype.rocket_rising_delay + 1,
        rocket_rising = (1 / rocket_prototype.rising_speed) + 1,
        rocket_ready = 14, -- estimate for satellite insertion delay
        launch_started = prototype.launch_wait_time + 1,
        engine_starting = (1 / rocket_prototype.engine_starting_speed) + 1,
        -- This calculates a fractional amount of ticks. Also, math.log(x) calculates the natural logarithm
        rocket_flying = math.log(
            1 + rocket_flight_threshold * rocket_prototype.flying_acceleration / rocket_prototype.flying_speed
        ) / math.log(1 + rocket_prototype.flying_acceleration),
        lights_blinking_close = (1 / prototype.light_blinking_speed) + 1,
        doors_closing = (1 / prototype.door_opening_speed) + 1,
    }

    local total_ticks = 0
    for _, ticks_taken in pairs(launch_steps) do
        total_ticks = total_ticks + ticks_taken
    end

    return (total_ticks / 60) -- retured value is in seconds
end

local function get_rocket_adjusted_crafts_per_second(entity, crafts_per_second)
    local prototype = entity.prototype
    local seconds_per_launch = get_seconds_per_rocket_launch(prototype)
    local normal_crafts = prototype.rocket_parts_required
    local missed_crafts = seconds_per_launch * crafts_per_second * (entity.productivity_bonus + 1)
    local ratio = normal_crafts / (normal_crafts + missed_crafts)
    return crafts_per_second * ratio
end

local function process_emission(set, emissions_per_second)
    if not set.recipe["rcalc-pollution-dummy"] then
        set.recipe["rcalc-pollution-dummy"] = { inputs = {}, outputs = {}, divisor = 1, level = 0 }
        set.recipe["rcalc-pollution-dummy"].inputs["rcalc-pollution-dummy"] = 0
    end
    set.recipe["rcalc-pollution-dummy"].inputs["rcalc-pollution-dummy"] = set.recipe["rcalc-pollution-dummy"].inputs
        ["rcalc-pollution-dummy"] + emissions_per_second
end

local function process_electric_energy_source(set, entity, emissions_per_second)
    local entity_prototype = entity.prototype
    local electric_energy_source_prototype = entity_prototype
        .electric_energy_source_prototype --[[@as LuaElectricEnergySourcePrototype]]

    local added_emissions = 0
    local max_energy_usage = entity_prototype.max_energy_usage or 0
    if max_energy_usage > 0 and max_energy_usage < flib_math.max_int53 then
        local consumption_bonus = (entity.consumption_bonus + 1)
        local drain = electric_energy_source_prototype.drain
        local amount = max_energy_usage * consumption_bonus
        if max_energy_usage ~= drain then
            amount = amount + drain
        end
        if not set.recipe["rcalc-power-dummy"] then
            set.recipe["rcalc-power-dummy"] = { inputs = {}, outputs = {}, divisor = 1, level = 0 }
            set.recipe["rcalc-power-dummy"].inputs["rcalc-power-dummy"] = 0
        end
        set.recipe["rcalc-power-dummy"].inputs["rcalc-power-dummy"] = set.recipe["rcalc-power-dummy"].inputs
            ["rcalc-power-dummy"] + amount * 60
        added_emissions = electric_energy_source_prototype.emissions * (max_energy_usage * consumption_bonus) * 60
    end

    --on rajoute un if si on doit prendre en compte la production

    return emissions_per_second + added_emissions
end

local function process_crafter(set, entity, emissions_per_second)
    local recipe = entity.get_recipe()
    if not recipe and entity.type == "furnace" then
        recipe = entity.previous_recipe
    end
    if not recipe then return emissions_per_second end
    if not set.machines[entity.name] then
        set.machines[entity.name] = 1
    else
        set.machines[entity.name] = set.machines[entity.name] + 1
    end
    local mod_inv = entity.get_module_inventory()
    if mod_inv then
        for name, count in pairs(mod_inv.get_contents()) do
            if not set.machines[name] then
                set.machines[name] = count
            else
                set.machines[name] = set.machines[name] + count
            end
        end
    end

    local crafts_per_second = entity.crafting_speed / recipe.energy

    -- Rocket silos will lose time to the launch animation
    if entity.type == "rocket-silo" then
        crafts_per_second = get_rocket_adjusted_crafts_per_second(entity, crafts_per_second)
    end

    -- The game engine has a hard limit of one craft per tick, or 60 crafts per second
    if crafts_per_second > 60 then
        crafts_per_second = 60
    end

    if not set.recipe[recipe.name] then set.recipe[recipe.name] = { inputs = {}, outputs = {}, divisor = 1, level = 0 } end
    if not set.ingredients then set.ingredients = {} end
    if not set.products then set.products = {} end

    for _, ingredient in pairs(recipe.ingredients) do
        local amount = ingredient.amount * crafts_per_second
        if not set.recipe[recipe.name].inputs[ingredient.name] then
            set.recipe[recipe.name].inputs[ingredient.name] = amount
        else
            set.recipe[recipe.name].inputs[ingredient.name] = set.recipe[recipe.name].inputs[ingredient.name] + amount
        end
        if not set.ingredients[ingredient.name] then
            set.ingredients[ingredient.name] = amount
        else
            set.ingredients[ingredient.name] = set.ingredients[ingredient.name] + amount
        end
    end

    local productivity = entity.productivity_bonus + 1

    for _, product in pairs(recipe.products) do
        local adjusted_crafts_per_second = crafts_per_second * (product.probability or 1)

        -- Take the average amount if there is a min and max
        local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
        local catalyst_amount = math.min(product.catalyst_amount or 0, amount)

        -- Catalysts are not affected by productivity
        local amount = (catalyst_amount + ((amount - catalyst_amount) * productivity)) * adjusted_crafts_per_second

        if not set.recipe[recipe.name].outputs[product.name] then
            set.recipe[recipe.name].outputs[product.name] = amount
        else
            set.recipe[recipe.name].outputs[product.name] = set.recipe[recipe.name].outputs[product.name] + amount
        end
        if not set.products[product.name] then
            set.products[product.name] = amount
        else
            set.products[product.name] = set.products[product.name] + amount
        end
    end
    return emissions_per_second * recipe.prototype.emissions_multiplier * (1 + entity.pollution_bonus)
end

local function process_beacon(set, entity)
    if not set.machines[entity.name] then
        set.machines[entity.name] = 1
    else
        set.machines[entity.name] = set.machines[entity.name] + 1
    end
    local mod_inv = entity.get_module_inventory()
    if mod_inv then
        for name, count in pairs(mod_inv.get_contents()) do
            if not set.machines[name] then
                set.machines[name] = count
            else
                set.machines[name] = set.machines[name] + count
            end
        end
    end
end

local function createRecipe(set)
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
            polution = output.rate
            goto continue
        elseif path == "item/rcalc-heat-dummy" then
            goto continue
        end

        if string.match(path, "dummy") then
            goto continue --on ne veut pas des items cacher // on ajoutera les catcher ici pour la compat des mods
        end

        local sorting_rate = 0
        if output.rate > 0 and input.rate > 0 then
            -- category = "intermediates"
            sorting_rate = output.rate - input.rate
            if sorting_rate > 0 then
                --outputs[rates.name] = { type = rates.type, count = math.floor(sorting_rate) }
            elseif sorting_rate < 0 then
                inputs[rates.name] = { type = rates.type, count = -math.ceil(sorting_rate) }
            end
        elseif input.rate > 0 then
            -- category = "ingredients"
            sorting_rate = input.rate
            inputs[rates.name] = { type = rates.type, count = math.ceil(sorting_rate) }
        else
            -- category = "products"
            sorting_rate = output.rate
            outputs[rates.name] = { type = rates.type, count = math.floor(sorting_rate) }
        end

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
local function make_recipe(entities)
    --   local recipe = {
    --     inputs = inputs,
    --     outputs = outputs,
    --     machines = machines,
    --     energy = energy,
    --     polution = polution
    --   }
    local set = {
        machines = {},
        recipe = {},
        ingredients = {},
        products = {},
        level_max = 0,
    }
    for _, entity in pairs(entities) do
        if entity_blacklist[entity.name] then
            goto continue
        end

        local emissions_per_second = entity.prototype.emissions_per_second
        local type = entity.type
        if type ~= "burner-generator" and entity.prototype.electric_energy_source_prototype then
            emissions_per_second = process_electric_energy_source(set, entity, emissions_per_second)
        end

        if type == "assembling-machine" or type == "furnace" or type == "rocket-silo" then
            emissions_per_second = process_crafter(set, entity, emissions_per_second)
        elseif type == "beacon" then
            emissions_per_second = process_beacon(set, entity)
        end

        process_emission(set, emissions_per_second)
        ::continue::
    end

    process_intermediate(set)
    local rate_set = rate_calc(set)

    game.write_file("setFac.json", game.table_to_json(rate_set))
    local recipe = createRecipe(rate_set)
    return recipe
end

function calculation.set_calc_bleuprint(entities, player)
    player.cursor_stack.clear()
    local recipe = make_recipe(entities)
    local str2 = util.get_bp(recipe)
    local blueprint_item_str = "0" .. game.encode_string(str2)
    player.cursor_stack.import_stack(blueprint_item_str)
end

return calculation
