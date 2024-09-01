--- Most of code from : https://github.com/raiguard/RateCalculator

local flib_math = require("__flib__.math")
local flib_format = require("__flib__.format")
local util = require("script.util")
local inputView =require("script.input_gui")


local entity_blacklist = {
    -- Transport Drones
    ["buffer-depot"] = true,
    ["fluid-depot"] = true,
    ["fuel-depot"] = true,
    ["request-depot"] = true,
}

local calculation = {}

local function addmachine(set, entity)
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

local function get_fluid(fluidbox, index)
    local fluid = fluidbox.get_filter(index)
    if not fluid then
        fluid = fluidbox[index] --[[@as FluidBoxFilter?]]
    end
    if fluid then
        return game.fluid_prototypes[fluid.name]
    end
end

local function rounded_recipe(set)
    local precision = 5
    for name, recipe in pairs(set.recipe) do
        for name, count in pairs(recipe.inputs) do
            recipe.inputs[name] = util.round(count, precision)
        end
        for name, count in pairs(recipe.outputs) do
            recipe.outputs[name] = util.round(count, precision)
        end
    end
    set.polution = util.round(set.polution, precision)
end

local function process_intermediate(set) -- make tree
    for name, recipe in pairs(set.recipe) do
        for output, count in pairs(recipe.outputs) do
            for other_name, other_recipe in pairs(set.recipe) do --tourne en rond ?
                if other_recipe.inputs[output] then
                    table.insert(recipe.children, other_name)
                    if other_name == name then
                        other_recipe.parent = false
                    else
                        other_recipe.parent = true
                    end
                end
            end
        end
    end
end

local function make_intuitive_input(set)
    for name, recipe in pairs(set.recipe) do
        for input_name,input in pairs(recipe.inputs) do
            if not set.forced_input[input_name] then
                local bool=false
                for other_name,other_recipe in pairs(set.recipe) do
                    if  other_recipe.outputs[input_name] then
                        bool=true
                        break
                    end
                end
                if not bool then
                    set.forced_input[input_name]=true
                else
                    set.forced_input[input_name]=false
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
    set.polution = set.polution + emissions_per_second
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

        set.energy = set.energy + amount * 60
        added_emissions = electric_energy_source_prototype.emissions * (max_energy_usage * consumption_bonus) * 60
    end

    --on rajoute un if si on doit prendre en compte la production d'energy

    return emissions_per_second + added_emissions
end

function process_burner(set, entity, emissions_per_second)
    local entity_prototype = entity.prototype
    local burner_prototype = entity_prototype.burner_prototype --[[@as LuaBurnerPrototype]]
    local burner = entity.burner --[[@as LuaBurner]]
    game.print("burner1")
    local currently_burning = burner.currently_burning
    if not currently_burning then
        local item_name = next(burner.inventory.get_contents())
        if item_name then
            currently_burning = game.item_prototypes[item_name]
        end
    end
    if not currently_burning then
        --calc_util.add_error(set, "no-fuel")
        return emissions_per_second
    end
    game.print("burner2")
    local max_energy_usage = entity_prototype.max_energy_usage * (entity.consumption_bonus + 1)
    local burns_per_second = 1 / (currently_burning.fuel_value / (max_energy_usage / burner_prototype.effectivity) / 60)



    local burnt_result = currently_burning.burnt_result
    if not burnt_result then
        burnt_result = { name = "none" }
    end
    if not set.recipe[currently_burning.name .. "-to-" .. burnt_result.name] then
        set.recipe[currently_burning.name .. "-to-" .. burnt_result.name] = {
            inputs = {},
            outputs = {},
            divisor = 1,
            parent = false,
            children = {},
            completed = false,
            output_mod={}
        }
    end
    if not set.recipe[currently_burning.name .. "-to-" .. burnt_result.name].inputs[currently_burning.name] then
        set.recipe[currently_burning.name .. "-to-" .. burnt_result.name].inputs[currently_burning.name] =
            burns_per_second
    else
        set.recipe[currently_burning.name .. "-to-" .. burnt_result.name].inputs[currently_burning.name] = set.recipe
            [currently_burning.name .. "-to-" .. burnt_result.name].inputs[currently_burning.name] + burns_per_second
    end
    if burnt_result.name ~= "none" then
        if not set.recipe[currently_burning.name .. "-to-" .. burnt_result.name].outputs[burnt_result.name] then
            set.recipe[currently_burning.name .. "-to-" .. burnt_result.name].outputs[burnt_result.name] =
                burns_per_second
        else
            set.recipe[currently_burning.name .. "-to-" .. burnt_result.name].outputs[burnt_result.name] = set.recipe
                [currently_burning.name .. "-to-" .. burnt_result.name].outputs[burnt_result.name] + burns_per_second
        end
    end

    local emissions = burner_prototype.emissions * 60 * max_energy_usage * currently_burning.fuel_emissions_multiplier
    return emissions_per_second + emissions
end

local function process_crafter(set, entity, emissions_per_second)
    local recipe = entity.get_recipe()
    if not recipe and entity.type == "furnace" then
        recipe = entity.previous_recipe
    end
    if not recipe then return emissions_per_second end
    addmachine(set, entity)
    if global.emerg_recipe[recipe.name] then return emissions_per_second end
    local crafts_per_second = entity.crafting_speed / recipe.energy

    -- Rocket silos will lose time to the launch animation
    if entity.type == "rocket-silo" then
        crafts_per_second = get_rocket_adjusted_crafts_per_second(entity, crafts_per_second)
    end

    -- The game engine has a hard limit of one craft per tick, or 60 crafts per second
    if crafts_per_second > 60 then
        crafts_per_second = 60
    end

    if not set.recipe[recipe.name] then
        set.recipe[recipe.name] = {
            inputs = {},
            outputs = {},
            divisor = 1,
            parent = false,
            children = {},
            completed = false,
            output_mod={}
        }
    end


    for _, ingredient in pairs(recipe.ingredients) do
        local amount = ingredient.amount * crafts_per_second
        amount = amount + 0

        if not set.recipe[recipe.name].inputs[ingredient.name] then
            set.recipe[recipe.name].inputs[ingredient.name] = amount
        else
            set.recipe[recipe.name].inputs[ingredient.name] = set.recipe[recipe.name].inputs[ingredient.name] + amount
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
        amount = amount + 0

        if not set.recipe[recipe.name].outputs[product.name] then
            set.recipe[recipe.name].outputs[product.name] = amount
        else
            set.recipe[recipe.name].outputs[product.name] = set.recipe[recipe.name].outputs[product.name] + amount
        end
    end
    return emissions_per_second * recipe.prototype.emissions_multiplier * (1 + entity.pollution_bonus)
end

local function process_beacon(set, entity)
    addmachine(set, entity)
    return 0
end

local function process_boiler(set, entity)
    local entity_prototype = entity.prototype
    local fluidbox = entity.fluidbox

    local input_fluid = get_fluid(fluidbox, 1)
    if not input_fluid then
        input_fluid = {}
        input_fluid.name = "none"
    end
    local output_fluid = get_fluid(fluidbox, 2)
    if not output_fluid then
        output_fluid = {}
        output_fluid.name = "none"
    end
    addmachine(set, entity)

    if not set.recipe[input_fluid.name .. "-to-" .. output_fluid.name] then
        set.recipe[input_fluid.name .. "-to-" .. output_fluid.name] = {
            inputs = {},
            outputs = {},
            divisor = 1,
            parent = false,
            children = {},
            completed = false,
            output_mod={}
        }
    end
    local fluid_usage = 0
    if input_fluid.name ~= "none" then
        local minimum_temperature = fluidbox.get_prototype(1).minimum_temperature or input_fluid.default_temperature
        local energy_per_amount = (entity_prototype.target_temperature - minimum_temperature) * input_fluid
            .heat_capacity
        fluid_usage = entity_prototype.max_energy_usage / energy_per_amount * 60
        if not set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].inputs[input_fluid.name] then
            set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].inputs[input_fluid.name] = fluid_usage
        else
            set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].inputs[input_fluid.name] = set.recipe
                [input_fluid.name .. "-to-" .. output_fluid.name].inputs[input_fluid.name] + fluid_usage
        end
    end
    if entity_prototype.boiler_mode == "heat-water-inside" then
        if not set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].outputs[input_fluid.name] then
            set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].outputs[input_fluid.name] = fluid_usage
        else
            set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].outputs[input_fluid.name] = set.recipe
                [input_fluid.name .. "-to-" .. output_fluid.name].outputs[input_fluid.name] + fluid_usage
        end
        return
    end

    if output_fluid.name ~= "none" then
        if not set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].outputs[output_fluid.name] then
            set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].outputs[output_fluid.name] = fluid_usage
        else
            set.recipe[input_fluid.name .. "-to-" .. output_fluid.name].outputs[output_fluid.name] = set.recipe
                [input_fluid.name .. "-to-" .. output_fluid.name].outputs[output_fluid.name] + fluid_usage
        end
    end
end

local function make_recipe(entities,player)
    --   local recipe = {
    --     inputs = inputs,
    --     outputs = outputs,
    --     div=0
    --      parent
    --          children
    --      completed
    --   }
    local set = {
        machines = {},
        recipe = {},
        forced_input={};
        energy = 0,
        polution = 0
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

        if entity.burner then
            emissions_per_second = process_burner(set, entity, emissions_per_second)
        end


        if type == "assembling-machine" or type == "furnace" or type == "rocket-silo" then
            emissions_per_second = process_crafter(set, entity, emissions_per_second)
        elseif type == "beacon" then
            emissions_per_second = process_beacon(set, entity)
        elseif type == "boiler" then
            process_boiler(set, entity)
        end

        process_emission(set, emissions_per_second)
        ::continue::
    end
    rounded_recipe(set)
    game.write_file("set1.json", game.table_to_json(set))
    process_intermediate(set) --make tree
    game.write_file("set2.json", game.table_to_json(set))
    make_intuitive_input(set)
    game.write_file("set3.json", game.table_to_json(set))
    inputView.update_and_show(set,player)
    
end

function calculation.set_calc_bleuprint(entities, player)
    player.cursor_stack.clear()
    make_recipe(entities,player)
    
end

return calculation