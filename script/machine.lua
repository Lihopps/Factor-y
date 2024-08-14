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

local function allinput(inputs, inputchest,inputs_tank)
    local contentinput = inputchest.get_inventory(defines.inventory.chest).get_contents()
    for _,tank in pairs(inputs_tank)do
        for name,count in pairs(tank.get_fluid_contents())do
            if contentinput[name] then
                contentinput[name]=contentinput[name]+count
            else
                contentinput[name]=count
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

local function remove_in_tank(name,obj,inputs_tank)
    local count=math.ceil(obj.count)
    local tot=0
    while count >0  or tot<6 do
        count=count-inputs_tank[tot].remove_fluid{name=name, amount=count}
        tot=tot+1
    end
end

local function removeall(inputs, inputchest,inputs_tank)
    for name, obj in pairs(inputs) do
        if obj.type=="item" then
            inputchest.get_inventory(defines.inventory.chest).remove({ name = name, count = math.ceil(obj.count) })
        elseif type=="fluid" then
            remove_in_tank(name,obj,inputs_tank)
        end
    end
end

local function add_in_tank(name,obj,outputs_tank)
    local count=math.floor(obj.count)
    for _,tank in pairs(outputs_tank) do
        count=count-tank.insert_fluid({name=name,amount=count})
        if count<=0 then
            break
        end
    end
end

local function addin(outputs, outputchest,outputs_tank)
    for name, obj in pairs(outputs) do
        if obj.type=="item" then
            outputchest.get_inventory(defines.inventory.chest).insert({ name = name, count = math.floor(obj.count) })
        elseif type=="fluid" then
            add_in_tank(name,obj,outputs_tank)
        end
    end
end

local function getNumberItem(name,obj, unit_number, type)
    if type == "recipe" then
        local recipechest = global.machine[unit_number].recipechest
        local contentrecipe = recipechest.get_inventory(defines.inventory.chest).get_contents()
        return contentrecipe[name] or 0
    elseif type == "input" then
        if obj.type=="item" then
            local inputchest = global.machine[unit_number].inputchest
            local contentrecipe = inputchest.get_inventory(defines.inventory.chest).get_contents()
            return contentrecipe[name] or 0
        elseif obj.type=="fluid" then
            local contentrecipe=0
            game.print("la"..name)
            for _,entity in pairs(global.machine[unit_number].inputs_tank) do
                contentrecipe=contentrecipe+entity.get_fluid_count(name)
            end
            return contentrecipe
        end
    end
    return 0
end

--- @param name string
--- @param sprite SpritePath
--- @param tooltip LocalisedString
--- @param handler GuiElemHandler
--- @return GuiElemDef
local function frame_action_button(name, sprite, tooltip, handler)
    return {
        type = "sprite-button",
        name = name,
        style = "frame_action_button",
        sprite = sprite .. "_white",
        hovered_sprite = sprite .. "_black",
        clicked_sprite = sprite .. "_black",
        tooltip = tooltip,
        mouse_button_filter = { "left" },
        handler = { [defines.events.on_gui_click] = handler },
    }
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
                caption = "Machine and Module needed"
            }
        }
    }
    for name, count in pairs(recipe.machines) do
        local realNumber = getNumberItem(name,nil, unit_number, "recipe")
        local color = { 0, 1, 0 }
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
                caption = "[entity=" .. name .. "] x " .. format.number(realNumber, true, 2) .. " / " .. format.number(count, true, 2),
                style_mods = { font_color = color },
                tooltip = "Total : " .. realNumber

            }
        }
        flow.children[#flow.children + 1] = sflow
    end
    return flow
end

local function makeRecipe(recipe, unit_number)
    local flow =
    {
        type = "flow",
        direction = "vertical",
        children = {
            {
                type = "label",
                caption = "Recipe",
                style_mods = { horizontal_align = "center" },
            },
            {
                type = "label",
                caption = "Inputs",
                style_mods = { left_padding = 10 },
            }
        }
    }
    for name, obj in pairs(recipe.inputs) do
        local realNumber = getNumberItem(name,obj, unit_number, "input")
        local color = { 0, 1, 0 }
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
                obj.type .. "=" .. name .. "] x" .. format.number(realNumber, true, 2) .. " / " ..format.number(math.ceil(obj.count), true, 2) ,
                tooltip = "Total : " .. realNumber

            }
        }
        flow.children[#flow.children + 1] = sflow
    end
    flow.children[#flow.children + 1] = { type = "line", direction = "horizontal" }
    flow.children[#flow.children + 1] = {
        type = "label",
        caption = "Ouputs",
        style_mods = { left_padding = 10 },
    }
    for name, obj in pairs(recipe.outputs) do
        local sflow =
        {
            type = "flow",
            direction = "horizontal",
            style_mods = { left_padding = 20 },
            {
                type = "label",
                style = "rcalc_machines_label",
                caption = "[" .. obj.type .. "=" .. name .. "] x" .. format.number(math.floor(obj.count), true, 2),
                tooltip = "Total : " .. math.ceil(obj.count)

            }
        }
        flow.children[#flow.children + 1] = sflow
    end

    return flow
end

local function recipegui(unit_number)
    local recipe = global.machine[unit_number].recipe
    local flow = {
        type = "flow",
        direction = "horizontal",
        name = "recipegui",
        children = {}
    }
    if recipe then
        flow.children[1] = makeMachine(recipe, unit_number)
        flow.children[2] = { type = "line", direction = "vertical" }
        flow.children[3] = makeRecipe(recipe, unit_number)
    else
        flow.children[1] = { type = "label", caption = "No Recipe Found" }
    end
    return flow
end

--- @param player_index number
local function destroy_gui(player_index)
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

--- @param e EventData.on_gui_click
local function on_close_button_click(e)
    local self = global.gui[e.player_index]
    if not self then
        return
    end
    self.elems.lihop_machine.visible = false
    if game.players[e.player_index] then
        if game.players[e.player_index].opened == self.elems.lihop_machine then
            game.players[e.player_index].opened = nil
        end
    end
    destroy_gui(e.player_index)
end

--- @param e EventData.on_gui_click
local function on_window_closed(e)
    local self = global.gui[e.player_index]
    self.elems.lihop_machine.visible = false
    destroy_gui(e.player_index)
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
    game.print("ici")
    if e.entity then
        if e.entity.name == "lihop-machine-electric-interface" then
            local player = game.players[e.player_index]
            if not player then return end
            player.opened = e.entity
            create_gui(player, e.entity.unit_number)
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
        outputs_tank= outputs_tank,
        recipe = {}
    }
end

function machine.destroy(entity)
    if global.machine[entity.unit_number].recipechest then global.machine[entity.unit_number].recipechest.destroy() end
    if global.machine[entity.unit_number].inputchest then global.machine[entity.unit_number].inputchest.destroy() end
    if global.machine[entity.unit_number].outputchest then global.machine[entity.unit_number].outputchest.destroy() end
    if global.machine[entity.unit_number].inputs_tank then
        for _, entity in pairs(global.machine[entity.unit_number].inputs_tank) do
            if entity then
                entity.destroy()
            end
        end
    end
    if global.machine[entity.unit_number].outputs_tank then
        for _, entity in pairs(global.machine[entity.unit_number].outputs_tank) do
            if entity then
                entity.destroy()
            end
        end
    end


    global.machine_index[global.machine[entity.unit_number].index] = nil
    global.machine[entity.unit_number] = nil
end

function machine.update(unit_number)
    local electric = global.machine[unit_number].electric
    local recipechest = global.machine[unit_number].recipechest
    local inputchest = global.machine[unit_number].inputchest
    local outputchest = global.machine[unit_number].outputchest
    local inputs_tank=global.machine[unit_number].inputs_tank
    local outputs_tank=global.machine[unit_number].outputs_tank

    if electric and recipechest and inputchest and outputchest then
        if electric.valid and recipechest.valid and inputchest.valid and outputchest.valid then
            local contentrecipe = recipechest.get_inventory(defines.inventory.chest).get_contents()
            if contentrecipe["lihop-factoryrecipe"] == 1 then
                local recipe = recipechest.get_inventory(defines.inventory.chest).find_item_stack("lihop-factoryrecipe")
                if recipe then
                    global.machine[unit_number].recipe = recipe.tags
                    electric.electric_buffer_size = recipe.tags["energy"] / 60
                    electric.power_usage = recipe.tags["energy"]
                    if electric.energy == electric.electric_buffer_size and allMachine(recipe.tags["machines"], contentrecipe) then
                        if allinput(recipe.tags["inputs"], inputchest,inputs_tank) then
                            removeall(recipe.tags["inputs"], inputchest,inputs_tank)
                            addin(recipe.tags["outputs"], outputchest,outputs_tank)
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------  GUI  -----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
--- @param player LuaPlayer
--- @return GuiData
function create_gui(player, unit_number)
    local elems = gui.add(player.gui.screen,
        {
            type = "frame",
            direction = "vertical",
            name = "lihop_machine",
            style_mods = { size = { 500, 300 } },
            handler = { [defines.events.on_gui_closed] = on_window_closed },
            {
                type = "flow",
                style = "flib_titlebar_flow",
                drag_target = "lihop_machine",
                {
                    type = "label",
                    style = "frame_title",
                    caption = { "mod-name.RateCalculator" },
                    ignored_by_interaction = true,
                },
                { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
                frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, on_close_button_click),
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
                        caption = "Power :"
                    },
                    {
                        type = "progressbar",
                        style_mods = { left_padding = 3 },
                        value = 0.5
                    },
                    {
                        type = "label",
                        style_mods = { left_padding = 3 },
                        caption = "Consumption :"
                    },
                    {
                        type = "label",
                        style_mods = { left_padding = 3 },
                        caption = 0
                    },
                },
                {
                    type = "scroll-pane",
                    direction = "horizontal",
                    name = "scrollRecipe",
                    style_mods = { margin = 5 },
                    recipegui(unit_number),
                }
            }
        })

    player.opened = elems.lihop_machine
    elems.lihop_machine.visible = true
    elems.lihop_machine.bring_to_front()
    elems.lihop_machine.force_auto_center()
    --- @type GuiData
    local self = {
        elems = elems,
        unit_number = unit_number
    }
    global.gui[player.index] = self
    machine.update_gui(self)
    return self
end

function machine.update_gui(opened, bool)
    --update power
    local electric = global.machine[opened.unit_number].electric
    opened.elems.power.children[4].caption = format.number(electric.power_usage, true, 2) .. "W"
    opened.elems.power.children[2].value = electric.energy / electric.electric_buffer_size
    --update machine and recipe
    if bool then
        opened.elems.scrollRecipe.clear()
        gui.add(opened.elems.scrollRecipe, recipegui(opened.unit_number))
    end
end

machine.events = {
    [defines.events.on_gui_opened] = on_gui_opened,
}

gui.add_handlers({
    on_close_button_click = on_close_button_click,
    on_window_closed = on_window_closed,
})


return machine
