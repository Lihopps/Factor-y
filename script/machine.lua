local util = require("script.util")

local inputs_tank_pos = {
    { type = "lihop-tank-input", dir = 0, position = { x = -9, y = -4 } },
    { type = "lihop-tank-input", dir = 0, position = { x = -5, y = -4 } },
    { type = "lihop-tank-input", dir = 6, position = { x = -10, y = -2 } },
    { type = "lihop-tank-input", dir = 6, position = { x = -10, y = 2 } },
    { type = "lihop-tank-input", dir = 4, position = { x = -5, y = 4 } },
    { type = "lihop-tank-input", dir = 4, position = { x = -9, y = 4 } },
}

local outputs_tank_pos = {
    { type = "lihop-tank-output", dir = 0, position = { x = 9, y = -4 } },
    { type = "lihop-tank-output", dir = 0, position = { x = 5, y = -4 } },
    { type = "lihop-tank-output", dir = 2, position = { x = 10, y = -2 } },
    { type = "lihop-tank-output", dir = 2, position = { x = 10, y = 2 } },
    { type = "lihop-tank-output", dir = 4, position = { x = 5, y = 4 } },
    { type = "lihop-tank-output", dir = 4, position = { x = 9, y = 4 } },
}


--- return pos input, output
---@param dir Direction
---@param pos Position
---@return Position[]
local function positionChest(dir, pos)
    if dir == 0 or dir == defines.direction.north then
        return { { pos.x - 6, pos.y }, { pos.x + 6, pos.y } }
    elseif dir == 4 or dir == defines.direction.south then
        return { { pos.x + 6, pos.y }, { pos.x - 6, pos.y } }
    elseif dir == 2 or dir == defines.direction.east then
        return { { pos.x, pos.y - 6 }, { pos.x, pos.y + 6 } }
    elseif dir == 6 or dir == defines.direction.west then
        return { { pos.x, pos.y + 6 }, { pos.x, pos.y - 6 } }
    end
    return { pos, pos }
end

local function create_tank(tanks_def, entity)
    local tanks = {}
    for _, tank in pairs(tanks_def) do
        local t = entity.surface.create_entity { name = tank.type, position = util.calc_position(entity, tank.position), force = entity.force, direction = (tank.dir + entity.direction) % 8 }
        if t then
            t.destructible = false
            t.rotatable = false
            table.insert(tanks, t)
        end
    end
    return tanks
end

local function allMachine(machines, contents)
    for name, count in pairs(machines) do
        if contents[name] then
            if contents[name] < count then
                return false
            end
        else
            return false
        end
    end
    return true
end

local function allinput(inputs, inputchest, inputs_tank)
    local contentinput = inputchest.get_inventory(defines.inventory.chest).get_contents()
    for _, tank in pairs(inputs_tank) do
        for name, count in pairs(tank.get_fluid_contents()) do
            if contentinput[name] then
                contentinput[name] = contentinput[name] + count
            else
                contentinput[name] = count
            end
        end
    end
    for name, obj in pairs(inputs) do
        if obj.count > 0 then
            if not contentinput[name] then
                return false
            else
                if contentinput[name] < math.ceil(obj.count) then
                    return false
                end
            end
        end
    end
    return true
end

local function remove_in_tank(name, obj, inputs_tank)
    local count = math.ceil(obj.count)
    local tot = 1
    while count > 0 or tot <= 6 do
        count = count - inputs_tank[tot].remove_fluid { name = name, amount = count }
        tot = tot + 1
    end
end

local function removeall(inputs, inputchest, inputs_tank)
    for name, obj in pairs(inputs) do
        if obj.count > 0 then
            if obj.type == "item" then
                inputchest.get_inventory(defines.inventory.chest).remove({ name = name, count = math.ceil(obj.count) })
            elseif obj.type == "fluid" then
                remove_in_tank(name, obj, inputs_tank)
            end
        end
    end
end

local function add_in_tank(name, obj, outputs_tank)
    local count = math.floor(obj.count)
    for _, tank in pairs(outputs_tank) do
        count = count - tank.insert_fluid({ name = name, amount = count })
        if count <= 0 then
            break
        end
    end
end

local function addin(outputs, outputchest, outputs_tank, errors)
    for name, obj in pairs(outputs) do
        if obj.type == "item" then
            if math.floor(obj.count) >= 1 then
                errors["lose"] = nil
                outputchest.get_inventory(defines.inventory.chest).insert({ name = name, count = math.floor(obj.count) })
            else
                util.add_errors(errors, "lose")
            end
        elseif obj.type == "fluid" then
            add_in_tank(name, obj, outputs_tank)
        end
    end
end

--------------------------------------------------------------------------------------------------
----------------------------------------- MACHINE ------------------------------------------------
--------------------------------------------------------------------------------------------------

local machine = {}

function machine.build(entity)
    local dir = entity.direction
    entity.rotatable = false
    local recipechest = entity.surface.create_entity {
        name = "lihop-recipechest",
        position = entity.position,
        force = entity.force
    }
    recipechest.destructible = false

    local inputchest = entity.surface.create_entity {
        name = "lihop-iochest-requester",
        position = positionChest(dir, entity.position)[1],
        force = entity.force
    }
    inputchest.destructible = false

    local outputchest = entity.surface.create_entity {
        name = "lihop-iochest-provider",
        position = positionChest(dir, entity.position)[2],
        force = entity.force
    }
    outputchest.destructible = false

    local inputs_tank = create_tank(inputs_tank_pos, entity)
    local outputs_tank = create_tank(outputs_tank_pos, entity)


    global.machine_index[#global.machine_index + 1] = entity.unit_number
    global.machine[entity.unit_number] = {
        index = #global.machine_index,
        electric = entity,
        recipechest = recipechest,
        inputchest = inputchest,
        outputchest = outputchest,
        inputs_tank = inputs_tank,
        outputs_tank = outputs_tank,
        recipe = {},
        errors = {}
    }
end

function machine.marked(entity)
    if util.test_entity(global.machine[entity.unit_number].recipechest) then
        global.machine[entity.unit_number]
            .recipechest.order_deconstruction(entity.force)
    end
    if util.test_entity(global.machine[entity.unit_number].inputchest) then
        global.machine[entity.unit_number]
            .inputchest.order_deconstruction(entity.force)
    end
    if util.test_entity(global.machine[entity.unit_number].outputchest) then
        global.machine[entity.unit_number]
            .outputchest.order_deconstruction(entity.force)
    end
    if global.machine[entity.unit_number].inputs_tank then
        for _, entity in pairs(global.machine[entity.unit_number].inputs_tank) do
            if util.test_entity(entity) then
                entity.order_deconstruction(entity.force)
            end
        end
    end
    if global.machine[entity.unit_number].outputs_tank then
        for _, entity in pairs(global.machine[entity.unit_number].outputs_tank) do
            if util.test_entity(entity) then
                entity.order_deconstruction(entity.force)
            end
        end
    end
end

function machine.destroy_by_player(entity, player)
    local tot = 0
    if util.test_entity(global.machine[entity.unit_number].recipechest) then
        if util.insert_stack(global.machine[entity.unit_number].recipechest, player) then
            tot = tot + 1
        end
    end
    if util.test_entity(global.machine[entity.unit_number].inputchest) then
        if util.insert_stack(global.machine[entity.unit_number].inputchest, player) then
            tot = tot + 1
        end
    end
    if util.test_entity(global.machine[entity.unit_number].outputchest) then
        if util.insert_stack(global.machine[entity.unit_number].outputchest, player) then
            tot = tot + 1
        end
    end

    if tot == 3 then
        global.machine[entity.unit_number].recipechest.destroy()
        global.machine[entity.unit_number].inputchest.destroy()
        global.machine[entity.unit_number].outputchest.destroy()

        if global.machine[entity.unit_number].inputs_tank then
            for _, entity in pairs(global.machine[entity.unit_number].inputs_tank) do
                if util.test_entity(entity) then
                    entity.destroy()
                end
            end
        end
        if global.machine[entity.unit_number].outputs_tank then
            for _, entity in pairs(global.machine[entity.unit_number].outputs_tank) do
                if util.test_entity(entity) then
                    entity.destroy()
                end
            end
        end

        global.machine_index[global.machine[entity.unit_number].index] = nil
        global.machine[entity.unit_number] = nil
    else
        --il faut break la construction
        local entity_tmp = entity.surface.create_entity { name = entity.name, direction = entity.direction, position = entity.position, force = entity.force }
        global.machine[entity_tmp.unit_number] = global.machine[entity.unit_number]
        global.machine_index[global.machine[entity_tmp.unit_number].index] = entity_tmp.unit_number
        --game.print("on break")
    end
end

function machine.destroy(entity)
    if util.test_entity(global.machine[entity.unit_number].recipechest) then
        global.machine[entity.unit_number]
            .recipechest.destroy()
    end
    if util.test_entity(global.machine[entity.unit_number].inputchest) then
        global.machine[entity.unit_number]
            .inputchest.destroy()
    end
    if util.test_entity(global.machine[entity.unit_number].outputchest) then
        global.machine[entity.unit_number]
            .outputchest.destroy()
    end
    if global.machine[entity.unit_number].inputs_tank then
        for _, entity in pairs(global.machine[entity.unit_number].inputs_tank) do
            if util.test_entity(entity) then
                entity.destroy()
            end
        end
    end
    if global.machine[entity.unit_number].outputs_tank then
        for _, entity in pairs(global.machine[entity.unit_number].outputs_tank) do
            if util.test_entity(entity) then
                entity.destroy()
            end
        end
    end

    global.machine_index[global.machine[entity.unit_number].index] = nil
    global.machine[entity.unit_number] = nil
end

function machine.update(unit_number)
    if not unit_number then return end
    if not global.machine[unit_number] then return end
    local electric = global.machine[unit_number].electric
    local recipechest = global.machine[unit_number].recipechest
    local inputchest = global.machine[unit_number].inputchest
    local outputchest = global.machine[unit_number].outputchest
    local inputs_tank = global.machine[unit_number].inputs_tank
    local outputs_tank = global.machine[unit_number].outputs_tank
    if not global.machine[unit_number].errors then
        global.machine[unit_number].errors = {}
    end

    if electric and recipechest and inputchest and outputchest then
        if electric.valid and recipechest.valid and inputchest.valid and outputchest.valid then
            local contentrecipe = recipechest.get_inventory(defines.inventory.chest).get_contents()
            if contentrecipe["lihop-factoryrecipe"] == 1 then
                local recipe_item = recipechest.get_inventory(defines.inventory.chest).find_item_stack(
                    "lihop-factoryrecipe")
                if recipe_item then
                    local recipe = recipe_item.get_blueprint_entity_tags(1)
                    if next(recipe) then
                        global.machine[unit_number].errors["bp_probleme"] = nil
                        global.machine[unit_number].recipe = recipe
                        electric.electric_buffer_size = recipe["energy"] / 60
                        electric.power_usage = recipe["energy"]
                        if electric.energy == electric.electric_buffer_size then
                            if allMachine(recipe["machines"], contentrecipe) then
                                global.machine[unit_number].errors["missingMachine"] = nil
                                if not outputchest.get_inventory(defines.inventory.chest).is_full() then
                                    if allinput(recipe["inputs"], inputchest, inputs_tank) then
                                        removeall(recipe["inputs"], inputchest, inputs_tank)
                                        if global.machine[unit_number].errors then global.machine[unit_number].errors = {} end
                                        addin(recipe["outputs"], outputchest, outputs_tank,
                                            global.machine[unit_number].errors)
                                        electric.surface.pollute(electric.position, recipe["polution"])
                                    end
                                end
                            else
                                util.add_errors(global.machine[unit_number].errors, "missingMachine")
                            end
                            global.machine[unit_number].errors["energy"] = nil
                        else
                            util.add_errors(global.machine[unit_number].errors, "energy")
                        end
                    else
                        util.add_errors(global.machine[unit_number].errors, "bp_probleme")
                    end
                end
                global.machine[unit_number].errors["noRecipe"] = nil
                global.machine[unit_number].errors["moreRecipe"] = nil
            else
                global.machine[unit_number].recipe = {}
                electric.electric_buffer_size = 100000 / 60
                electric.power_usage = 100000
                if contentrecipe["lihop-factoryrecipe"] == 0 or not next(contentrecipe) or not contentrecipe["lihop-factoryrecipe"] then
                    global.machine[unit_number].errors["moreRecipe"] = nil
                    util.add_errors(global.machine[unit_number].errors, "noRecipe")
                elseif contentrecipe["lihop-factoryrecipe"] > 1 then
                    global.machine[unit_number].errors["noRecipe"] = nil
                    util.add_errors(global.machine[unit_number].errors, "moreRecipe")
                end
            end
            if outputchest.get_inventory(defines.inventory.chest).is_full() then
                util.add_errors(global.machine[unit_number].errors, "output_full")
            else
                global.machine[unit_number].errors["output_full"] = nil
            end
            global.machine[unit_number].errors["invalideEntity"] = nil
        else
            util.add_errors(global.machine[unit_number].errors, "invalideEntity")
        end
        global.machine[unit_number].errors["missingEntity"] = nil
    else
        util.add_errors(global.machine[unit_number].errors, "missingEntity")
    end
    if next(global.machine[unit_number].errors) then
        util.entity_flying_text(electric, util.make_caption_errors(global.machine[unit_number].errors),
            { r = 1, g = 0, b = 0 }, nil)
    end
end

return machine
