local gui = require("__flib__.gui-lite")
local flib_math = require("__flib__.math")
local format = require("__flib__.format")
local util = require("script.util")

local chest={"lihop-recipechest","lihop-iochest-requester","lihop-iochest-provider"}
local inchest=util.make_dict_from_array(chest)

local function action_button(name, unit_number, caption, tooltip, handler)
    return {
        type = "button",
        name = name,
        --style = "frame_action_button",
        tooltip = tooltip,
        caption = caption,
        mouse_button_filter = { "left" },
        tags = { number = unit_number },
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

local function makeRecipe(recipe, unit_number, divisor)
    local precision = 0.01
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
                    "] x " .. format.number(flib_math.round(realNumber / divisor, precision), true, 4) ..
                    " / " .. format.number(flib_math.round(math.ceil(obj.count) / divisor, precision), true, 4),
                tooltip = { "", { "?", { "item-name." .. name }, { "entity-name." .. name }, { "fluid-name." .. name } }, " : ", format.number(flib_math.round(realNumber / divisor, precision), true, 4), "\n", { "gui.conso" }, " : ", format.number(flib_math.round(obj.real_count / divisor, precision * precision), true, 4) }

            }
        }
        inputs_flow.children[#inputs_flow.children + 1] = sflow
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
        local sflow =
        {
            type = "flow",
            direction = "horizontal",
            style_mods = { left_padding = 20 },
            {
                type = "label",
                style = "rcalc_machines_label",
                caption = "[" ..
                    obj.type ..
                    "=" .. name .. "] x " .. format.number(flib_math.round(obj.count / divisor, precision), true, 4),
                tooltip = { "", { "?", { "item-name." .. name }, { "entity-name." .. name }, { "fluid-name." .. name } }, " : ", format.number(flib_math.round(math.floor(obj.count) / divisor, precision), true, 4), "\n", { "gui.prod" }, " : ", format.number(flib_math.round(obj.real_count / divisor, precision * precision), true, 4) }
            }
        }
        outputs_flow.children[#outputs_flow.children + 1] = sflow
    end
    flow.children[#flow.children + 1] = outputs_flow
    gflow.children[#gflow.children + 1] = flow
    return gflow
end

local function recipegui(unit_number, chooser)
    local divisor = 1
    if chooser then
        if chooser.elem_value then
            divisor = game.entity_prototypes[chooser.elem_value].belt_speed * 480
            --game.print(divisor)
        end
    end
    local recipe = global.machine[unit_number].recipe
    local flow = {
        type = "flow",
        direction = "horizontal",
        name = "recipegui",
        style_mods = { horizontally_squashable = true },
        children = {}
    }
    if next(recipe) ~= nil then
        flow.children[1] = makeMachine(recipe, unit_number)
        flow.children[2] = { type = "line", direction = "vertical" }
        flow.children[3] = makeRecipe(recipe, unit_number, divisor)
        global.machine[unit_number].errors["noRecipe"] = nil
    else
        util.add_errors(global.machine[unit_number].errors, "noRecipe")
    end
    return flow
end

--- @param e EventData.on_gui_click
local function on_requestmachine_button_click(e)
    local unit_number = e.element.tags.number
    local recipe = global.machine[unit_number].recipe
    local recipechest = global.machine[unit_number].recipechest
    if not recipechest or not recipechest.valid then return end
    for i = 1, recipechest.request_slot_count do
        recipechest.clear_request_slot(i)
    end
    if recipe["machines"] then
        local slot = 1
        for name, count in pairs(recipe["machines"]) do
            recipechest.set_request_slot({ name = name, count = count }, slot)
            slot = slot + 1
        end
    end
end

--- @param e EventData.on_gui_click
local function on_requestinput_button_click(e)
    local multiplier = 1
    if e.element then
        if e.element.parent then
            if e.element.parent.recipe_multipler then
                if e.element.parent.recipe_multipler.text ~= "" then
                    multiplier = tonumber(e.element.parent.recipe_multipler.text) --[[@as integer]]
                end
            end
        end
    end
    --game.print(multiplier)
    local unit_number = e.element.tags.number
    local recipe = global.machine[unit_number].recipe
    local inputchest = global.machine[unit_number].inputchest
    if not inputchest or not inputchest.valid then return end
    for i = 1, inputchest.request_slot_count do
        inputchest.clear_request_slot(i)
    end
    if recipe["inputs"] then
        local slot = 1
        for name, obj in pairs(recipe["inputs"]) do
            if obj.type == "item" then
                inputchest.set_request_slot({ name = name, count = math.ceil(obj.count) * multiplier }, slot)
                slot = slot + 1
            end
        end
    end
end

--- @param e EventData.on_gui_click
local function on_setfilter_button_click(e)
    local multiplier = 1
    if e.element then
        if e.element.parent then
            if e.element.parent.recipe_multipler then
                if e.element.parent.recipe_multipler.text ~= "" then
                    multiplier = tonumber(e.element.parent.recipe_multipler.text) --[[@as integer]]
                end
            end
        end
    end
    local unit_number = e.element.tags.number
    local recipe = global.machine[unit_number].recipe
    local inputchest = global.machine[unit_number].inputchest
    if not inputchest or not inputchest.valid then return end
    local inv = inputchest.get_inventory(defines.inventory.chest)
    if not inv or not inv.valid then return end
    local max = #inv
    for i = 1, max do
        inv.set_filter(i, nil)
    end
    inv.set_bar()
    if recipe["inputs"] then
        local slot = 1
        for name, obj in pairs(recipe["inputs"]) do
            if obj.type == "item" then
                local item = game.item_prototypes[name]
                local stacksize = item.stack_size
                local number_of_slot = math.ceil((obj.count / stacksize) * multiplier)
                for i = 1, number_of_slot do
                    inv.set_filter(slot, name)
                    slot = slot + 1
                    if slot > max then
                        return
                    end
                end
            end
        end
        inv.set_bar(slot)
    end
end

local machgui={}

--- @param player LuaPlayer
local function create_gui(player, unit_number)
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
                    names = chest
                },
                {
                    type = "flow",
                    style = "flib_titlebar_flow",
                    --drag_target = "lihop_machine",
                    {
                        type = "label",
                        style = "frame_title",
                        caption = { "gui.titleBigFactory" },
                        ignored_by_interaction = true,
                    },
                    { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
                    {
                        type = "sprite",
                        sprite = "lihop-question-tool",
                        tooltip = util.make_help_tooltip(),
                    }
                },
                {
                    type = "frame",
                    style = "inside_shallow_frame",
                    direction = "vertical",
                    {
                        type = "flow",
                        name = "power",
                        style_mods = { margin = 5 },
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
                        style_mods = { margin = 7, vertical_align = "center" },
                        name = "button_flow",
                        action_button("requestmachine_button", unit_number, { "gui.requestmachine" },
                            { "gui.requestmachine_t" },
                            on_requestmachine_button_click),
                        action_button("filtermachine_button", unit_number, { "gui.setfilter" },
                            { "gui.setfilter_t" },
                            on_setfilter_button_click),
                        action_button("requestinput_button", unit_number, { "gui.requestinput" },
                            { "gui.requestinput_t" }, on_requestinput_button_click),
                        {
                            type = "textfield",
                            name = "recipe_multipler",
                            tooltip = { "gui.recipe_multipler" },
                            numeric = true,
                            allow_decimal = true,
                            text = settings.get_player_settings(player)["lihop-multiplier-recipe"].value,
                            style_mods = { maximal_width = 50, horizontal_align = "center" },

                        },
                        {
                            type = "choose-elem-button",
                            name = "timescale_divisor",
                            elem_type = "entity",
                            elem_filters = { { filter = "type", type = "transport-belt" }, { filter = "hidden", invert = true, mode = "and" } },
                            tooltip = { "gui.rcalc-capacity-divisor-description" },
                            --handler = { [defines.events.on_gui_elem_changed] = on_divisor_elem_changed },
                        },

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
                        style_mods = { margin = 7, horizontally_squashable = true, horizontally_stretchable = true },
                        recipegui(unit_number, nil),
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
        machgui.update_gui(self)
        return self
    end
    return nil
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

local function on_gui_opened(e)
    if e.entity then
		if inchest[e.entity.name] then
			local player = game.players[e.player_index]
            if not player then return end
			local elecinterface = e.entity.surface.find_entity("lihop-machine-electric-interface", e.entity.position)
			if not elecinterface then return end
			create_gui(player, elecinterface.unit_number)
        elseif e.entity.name == "lihop-machine-electric-interface" then
			local player = game.players[e.player_index]
            if not player then return end
			local recipechest = e.entity.surface.find_entity("lihop-recipechest", e.entity.position)
			if not recipechest then return end
			player.opened = recipechest
        end
	end
end

local function on_gui_closed(e)
    if e.entity then
		if inchest[e.entity.name] then
			local player = game.players[e.player_index]
			if not player then return end
			destroy_gui(e.player_index)
		end
	end
end


function machgui.update_gui(opened, bool)
    --update power
    if not global.machine[opened.unit_number] then return end
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
        gui.add(opened.elems.scrollRecipe, recipegui(opened.unit_number, opened.elems.timescale_divisor))
    end
end


machgui.events={
    [defines.events.on_gui_opened]=on_gui_opened,
    [defines.events.on_gui_closed]=on_gui_closed
}

gui.add_handlers({
    on_requestmachine_button_clic = on_requestmachine_button_click,
    on_requestinput_button_clic = on_requestinput_button_click,
    on_setfilter_button_click = on_setfilter_button_click
})

return machgui