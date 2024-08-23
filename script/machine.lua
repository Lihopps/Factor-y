local gui = require("__flib__.gui-lite")
local format = require("__flib__.format")
local util = require("script.util")

--global.machine_index
--global.machine

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

--- @param e EventData.on_gui_click
local function on_requestmachine_button_click(e)
    local unit_number=e.element.tags.number
    local recipe=global.machine[unit_number].recipe
    local recipechest=global.machine[unit_number].recipechest
    if not recipechest or not recipechest.valid then return end
    for i=1,recipechest.request_slot_count do
        recipechest.clear_request_slot(i)
    end
    if recipe["machines"] then
        local slot=1
        for name,count in pairs(recipe["machines"]) do
            recipechest.set_request_slot({name=name,count=count}, slot)
            slot=slot+1
        end
    end
end

--- @param e EventData.on_gui_click
local function on_requestinput_button_click(e)
    local multiplier=1
    if e.element then
        if e.element.parent then
            if e.element.parent.recipe_multipler then
                if e.element.parent.recipe_multipler.text ~="" then
                    multiplier=e.element.parent.recipe_multipler.text
                end
            end
        end
    end
    game.print(multiplier)
    local unit_number=e.element.tags.number
    local recipe=global.machine[unit_number].recipe
    local inputchest=global.machine[unit_number].inputchest
    if not inputchest or not inputchest.valid then return end
    for i=1,inputchest.request_slot_count do
        inputchest.clear_request_slot(i)
    end
    if recipe["inputs"] then
        local slot=1
        for name,obj in pairs(recipe["inputs"]) do
            if obj.type=="item" then
                inputchest.set_request_slot({name=name,count=math.ceil(obj.count)*multiplier}, slot)
                slot=slot+1
            end
        end
    end
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
        if not contentinput[name] then
            return false
        else
            if contentinput[name] < math.ceil(obj.count) then
                return false
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
        if obj.type == "item" then
            inputchest.get_inventory(defines.inventory.chest).remove({ name = name, count = math.ceil(obj.count) })
        elseif obj.type == "fluid" then
            remove_in_tank(name, obj, inputs_tank)
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

local function getNumberItem(name, obj, unit_number, type)
    if type == "recipe" then
        local recipechest = global.machine[unit_number].recipechest
        local contentrecipe = recipechest.get_inventory(defines.inventory.chest).get_contents()
        return contentrecipe[name] or 0
    elseif type == "input" then
        if obj.type == "item" then
            local inputchest = global.machine[unit_number].inputchest
            local contentrecipe = inputchest.get_inventory(defines.inventory.chest).get_contents()
            return contentrecipe[name] or 0
        elseif obj.type == "fluid" then
            local contentrecipe = 0
            for _, entity in pairs(global.machine[unit_number].inputs_tank) do
                contentrecipe = contentrecipe + entity.get_fluid_count(name)
            end
            return contentrecipe
        end
    end
    return 0
end

local function action_button(name,unit_number,caption, tooltip, handler)
    return {
        type = "button",
        name = name,
        --style = "frame_action_button",
        tooltip = tooltip,
        caption=caption,
        mouse_button_filter = { "left" },
        tags={number=unit_number},
        handler = { [defines.events.on_gui_click] = handler },

    }
end

local function make_errors_flow(flow, errors)
    flow.clear()
    if not next(errors) then return end
    for name, bool in pairs(errors) do
        gui.add(flow, { type = "label", caption = { "", "-", { "gui." .. name } } })
    end
end

local function makeMachine(recipe, unit_number)
    local flow =
    {
        type = "flow",
        direction = "vertical",
        children = {
            {
                type = "label",
                style_mods = { horizontal_align = "center" },
                caption = { "gui.MachineDef" }
            }
        }
    }
    for name, count in pairs(recipe.machines) do
        local realNumber = getNumberItem(name, nil, unit_number, "recipe")
        local color = { 0, 1, 0 }
        local type = "entity"
        if string.find(name, "module") then type = "item" end
        if realNumber < count then
            color = { 1, 0, 0 }
        end
        local sflow =
        {
            type = "flow",
            direction = "horizontal",
            style_mods = { left_padding = 10 },
            {
                type = "label",
                style = "rcalc_machines_label",
                caption = { "", "[", type, "=", name, "]", " x ", format.number(realNumber, true, 2), " / ", format.number(count, true, 2) },
                style_mods = { font_color = color },
                tooltip = { "", { "?", { "item-name." .. name }, { "entity-name." .. name } }, " : ", realNumber }

            }
        }
        flow.children[#flow.children + 1] = sflow
    end
    return flow
end

local function makeRecipe(recipe, unit_number)
    local gflow =
    {
        type = "flow",
        direction = "vertical",
        children = {
            {
                type = "label",
                caption = { "gui.recipe" },
                style_mods = { horizontal_align = "center" },
            },
        }
    }
    local flow =
    {
        type = "flow",
        direction = "horizontal",
        children = {

        }
    }
    local inputs_flow =
    {
        type = "flow",
        direction = "vertical",
        children = {
            {
                type = "label",
                caption = { "gui.input" },
                style_mods = { left_padding = 10 },
            }
        }
    }
    for name, obj in pairs(recipe.inputs) do
        local realNumber = getNumberItem(name, obj, unit_number, "input")
        local color = { 0, 1, 0 }
        if math.ceil(obj.count) > 0 then
            if realNumber < math.ceil(obj.count) then
                color = { 1, 0, 0 }
            end
            local sflow =
            {
                type = "flow",
                direction = "horizontal",
                style_mods = { left_padding = 20 },
                {
                    type = "label",
                    style = "rcalc_machines_label",
                    style_mods = { font_color = color },
                    caption = "[" ..
                        obj.type ..
                        "=" ..
                        name ..
                        "] x " ..
                        format.number(realNumber, true, 2) .. " / " .. format.number(math.ceil(obj.count), true, 2),
                    tooltip = { "", { "?", { "item-name." .. name }, { "entity-name." .. name }, { "fluid-name." .. name } }, " : ", realNumber }

                }
            }
            inputs_flow.children[#inputs_flow.children + 1] = sflow
        end
    end
    flow.children[#flow.children + 1] = inputs_flow
    flow.children[#flow.children + 1] = { type = "line", direction = "vertical" }
    local outputs_flow =
    {
        type = "flow",
        direction = "vertical",
        children = {
            {
                type = "label",
                caption = { "gui.output" },
                style_mods = { left_padding = 10 },
            }
        }
    }
    for name, obj in pairs(recipe.outputs) do
        if math.floor(obj.count) > 0 then
            local sflow =
            {
                type = "flow",
                direction = "horizontal",
                style_mods = { left_padding = 20 },
                {
                    type = "label",
                    style = "rcalc_machines_label",
                    caption = "[" .. obj.type .. "=" .. name .. "] x " .. format.number(math.floor(obj.count), true, 2),
                    tooltip = { "", { "?", { "item-name." .. name }, { "entity-name." .. name }, { "fluid-name." .. name } }, " : ", math.floor(obj.count) }
                }
            }
            outputs_flow.children[#outputs_flow.children + 1] = sflow
        end
    end
    flow.children[#flow.children + 1] = outputs_flow
    gflow.children[#gflow.children + 1] = flow
    return gflow
end

local function recipegui(unit_number)
    local recipe = global.machine[unit_number].recipe
    local flow = {
        type = "flow",
        direction = "horizontal",
        name = "recipegui",
        children = {}
    }
    if next(recipe) ~= nil then
        flow.children[1] = makeMachine(recipe, unit_number)
        flow.children[2] = { type = "line", direction = "vertical" }
        flow.children[3] = makeRecipe(recipe, unit_number)
        global.machine[unit_number].errors["noRecipe"] = nil
    else
        util.add_errors(global.machine[unit_number].errors, "noRecipe")
    end
    return flow
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
        if util.insert(global.machine[entity.unit_number].recipechest, player) then
            tot = tot + 1
        end
    end
    if util.test_entity(global.machine[entity.unit_number].inputchest) then
        if util.insert(global.machine[entity.unit_number].inputchest, player) then
            tot = tot + 1
        end
    end
    if util.test_entity(global.machine[entity.unit_number].outputchest) then
        if util.insert(global.machine[entity.unit_number].outputchest, player) then
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
    local electric = global.machine[unit_number].electric
    local recipechest = global.machine[unit_number].recipechest
    local inputchest = global.machine[unit_number].inputchest
    local outputchest = global.machine[unit_number].outputchest
    local inputs_tank = global.machine[unit_number].inputs_tank
    local outputs_tank = global.machine[unit_number].outputs_tank
    local errors = global.machine[unit_number].errors
    if not errors then
        global.machine[unit_number].errors = {}
        errors = global.machine[unit_number].errors
    end

    if electric and recipechest and inputchest and outputchest then
        if electric.valid and recipechest.valid and inputchest.valid and outputchest.valid then
            local contentrecipe = recipechest.get_inventory(defines.inventory.chest).get_contents()
            if contentrecipe["lihop-factoryrecipe"] == 1 then
                local recipe = recipechest.get_inventory(defines.inventory.chest).find_item_stack("lihop-factoryrecipe")
                if recipe then
                    global.machine[unit_number].recipe = recipe.tags
                    electric.electric_buffer_size = recipe.tags["energy"] / 60
                    electric.power_usage = recipe.tags["energy"]
                    if electric.energy == electric.electric_buffer_size then
                        if allMachine(recipe.tags["machines"], contentrecipe) then
                            if allinput(recipe.tags["inputs"], inputchest, inputs_tank) then
                                removeall(recipe.tags["inputs"], inputchest, inputs_tank)
                                addin(recipe.tags["outputs"], outputchest, outputs_tank, errors)
                                if errors then errors = {} end
                            end
                            errors["missingMachine"] = nil
                        else
                            util.add_errors(errors, "missingMachine")
                        end
                        errors["energy"] = nil
                    else
                        util.add_errors(errors, "energy")
                    end
                end
                errors["noRecipe"] = nil
                errors["moreRecipe"] = nil
            else
                global.machine[unit_number].recipe = {}
                electric.electric_buffer_size = 100000 / 60
                electric.power_usage = 100000
                if contentrecipe["lihop-factoryrecipe"] == 0 or not next(contentrecipe) or not contentrecipe["lihop-factoryrecipe"] then
                    errors["moreRecipe"] = nil
                    util.add_errors(errors, "noRecipe")
                elseif contentrecipe["lihop-factoryrecipe"] > 1 then
                    errors["noRecipe"] = nil
                    util.add_errors(errors, "moreRecipe")
                end
            end
            errors["invalideEntity"] = nil
        else
            util.add_errors(errors, "invalideEntity")
        end
        errors["missingEntity"] = nil
    else
        util.add_errors(errors, "missingEntity")
    end
    if next(errors) then
        util.entity_flying_text(electric, util.make_caption_errors(errors), { r = 1, g = 0, b = 0 }, nil)
    end
end

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------  GUI  -----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
--- @param player LuaPlayer
--- @return GuiData
function machine.create_gui(player, unit_number)
    if not player.gui.relative.lihop_machine then
        local elems = gui.add(player.gui.relative,
            {
                type = "frame",
                direction = "vertical",
                name = "lihop_machine",
                style_mods = { size = { 500, 700 } },
                anchor = {
                    gui = defines.relative_gui_type.container_gui,
                    position = defines.relative_gui_position.right,
                    names = { "lihop-recipechest" }
                },
                {
                    type = "flow",
                    style = "flib_titlebar_flow",
                    {
                        type = "label",
                        style = "frame_title",
                        caption = { "gui.titleBigFactory" },
                        ignored_by_interaction = true,
                    },
                    { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
                },
                {
                    type = "frame",
                    style = "inside_shallow_frame",
                    direction = "vertical",
                    {
                        type = "flow",
                        name = "power",
                        style_mods = { margin = 5, vertical_align = "center" },
                        direction = "horizontal",
                        {
                            type = "label",
                            style_mods = { left_padding = 3 },
                            caption = { "", { "gui.power" }, " :" }
                        },
                        {
                            type = "progressbar",
                            style_mods = { left_padding = 3 },
                            value = 0.5
                        },
                        {
                            type = "label",
                            style_mods = { left_padding = 3 },
                            caption = { "", { "gui.consumption" }, " :" }
                        },
                        {
                            type = "label",
                            style_mods = { left_padding = 3 },
                            caption = 0
                        },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        style_mods = { margin = 7 },
                        name="button_flow",
                        action_button("requestmachine_button",unit_number, { "gui.requestmachine" },{ "gui.requestmachine_t" },
                            on_requestmachine_button_click),
                        action_button("requestinput_button",unit_number, { "gui.requestinput" },{ "gui.requestinput_t" }, on_requestinput_button_click),
                        {
                            type="textfield",
                            name="recipe_multipler",
                            tooltip={"gui.recipe_multipler"},
                            numeric=true,
                            allow_decimal=true,
                            text=settings.get_player_settings(player)["lihop-multiplier-recipe"].value,
                            style_mods = { maximal_width = 50,horizontal_align="center" },

                        }
                    },

                    {
                        type = "flow",
                        direction = "vertical",
                        name = "errorflow",
                        style_mods = { margin = 7 },
                        children = {}
                    },
                    {
                        type = "scroll-pane",
                        direction = "horizontal",
                        name = "scrollRecipe",
                        style_mods = { margin = 7 },
                        recipegui(unit_number),
                    }
                }
            })
        make_errors_flow(elems.errorflow, global.machine[unit_number].errors)
        --{ type = "label", caption = util.make_caption_errors(global.machine[unit_number].errors, { "gui.noError" }) },
        --- @type GuiData
        local self = {
            elems = elems,
            unit_number = unit_number
        }
        global.gui[player.index] = self
        machine.update_gui(self)
        return self
    end
    return nil
end

function machine.update_gui(opened, bool)
    --update power
    local electric = global.machine[opened.unit_number].electric
    opened.elems.power.children[4].caption = format.number(electric.power_usage, true, 3) .. "W"
    if electric.electric_buffer_size > 0 then
        opened.elems.power.children[2].value = electric.energy / electric.electric_buffer_size
    else
        opened.elems.power.children[2].value = 0
    end
    --update machine and recipe
    if bool then
        opened.elems.scrollRecipe.clear()
        make_errors_flow(opened.elems.errorflow, global.machine[opened.unit_number].errors)
        gui.add(opened.elems.scrollRecipe, recipegui(opened.unit_number))
    end
end

--- @param player_index number
function machine.destroy_gui(player_index)
    local self = global.gui[player_index]
    if not self then
        return
    end
    global.gui[player_index] = nil
    local window = self.elems.lihop_machine
    if not window.valid then
        return
    end
    window.destroy()
end

gui.add_handlers({
    on_requestmachine_button_clic = on_requestmachine_button_click,
    on_requestinput_button_clic = on_requestinput_button_click,
})

return machine
