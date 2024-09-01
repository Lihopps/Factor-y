local debug = false

local gui = require("__flib__/gui-lite")
local util = require("script.util")

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler function
local function frame_action_button(name, sprite, tooltip, handler)
    return {
        type = "sprite-button",
        name = name,
        style = "frame_action_button",
        sprite = sprite .. "_white",
        hovered_sprite = sprite .. "_black",
        clicked_sprite = sprite .. "_black",
        tooltip = tooltip,
        handler = handler,
    }
end

local function action_button(name, caption, tooltip, handler)
    return {
        type = "button",
        name = name,
        caption = caption,
        style_mods = { horizontally_stretchable = true },
        tooltip = tooltip,
        mouse_button_filter = { "left" },
        handler = { [defines.events.on_gui_click] = handler },

    }
end



--- @param e EventData.on_gui_click
local function show(e, elems)
    elems.lihop_input_gui.visible       = true
    game.players[e.player_index].opened = elems.lihop_input_gui
end

local function show_p(player, elems)
    elems.lihop_input_gui.visible = true
    player.opened                 = elems.lihop_input_gui
end

--- @param e EventData.on_gui_click
local function hide(e, elems)
    if not elems then
        elems = global.lihop_input_gui_state[e.player_index].elems
    end
    elems.lihop_input_gui.visible = false
    game.players[e.player_index].opened = nil
end



--- @param e EventData.on_gui_click
local function toggle_visible(e)
    local elems = global.lihop_input_gui_state[e.player_index].elems
    if elems.lihop_input_gui.visible then
        hide(e, elems)
    else
        show(e, elems)
    end
end

local function on_button_confirm_clicked(e)
    local elems = global.lihop_input_gui_state[e.player_index].elems
    local set = global.lihop_input_gui_state[e.player_index].set

    for _, flow in pairs(elems.inputs_flow.children) do
        local check_state = flow.children[1]
        set.forced_input[flow.name] = check_state.state
    end
    --le gui retourne : le set update et le player
    hide(e, elems)
    util.set_calc_blueprint_p2(set, game.players[e.player_index])
end

local function update(set, elems, player)
    global.lihop_input_gui_state[player.index].set = set
    elems.inputs_flow.clear()
    for name, state in pairs(set.forced_input) do
        local type
        if game.item_prototypes[name] then
            type = "item"
        else
            type = "fluid"
        end
        local flow = {
            type = "flow",
            direction = "horizontal",
            style_mods = { vertical_align = "center" },
            name = name,
            {
                type = "checkbox",
                state = state,

            },
            {
                type = "label",
                caption = { "", "[", type, "=", name, "]", " ", { "?", { "item-name." .. name }, { "entity-name." .. name }, { "fluid-name." .. name } } }
            },
        }
        gui.add(elems.inputs_flow, flow)
    end
end

local input = {}

--- @param e EventData.on_gui_closed
function input.on_gui_closed(e)
    hide(e, nil)
end

--- Build the GUI for the given player.
--- @param player LuaPlayer
function input.build(player)
    local elems = gui.add(player.gui.screen, {
        type = "frame",
        name = "lihop_input_gui",
        direction = "vertical",
        style_mods = { size = { 500, 700 } },
        elem_mods = { auto_center = true },
        {
            type = "flow",
            style = "flib_titlebar_flow",
            drag_target = "lihop_input_gui",

            { type = "label",        style = "frame_title",               caption = { "gui.input_chooser" }, ignored_by_interaction = true },
            { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
            frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, hide),
        },
        {
            type = "frame",
            style = "inside_shallow_frame",
            style_mods = { horizontally_stretchable = true }, --{ width = 500 },
            direction = "vertical",
            {
                type = "flow",
                direction = "horizontal",
                {
                    type = "flow",
                    direction = "vertical",
                    style_mods = {horizontal_align ="center",vertical_align="bottom"},
                    {
                        type = "label",
                        caption = {"gui.input"},
                        style_mods = {horizontal_align ="center",vertical_align="bottom"},
                    },
                    {
                        type = "label",
                        caption = {"gui.input_choser_help"},
                        style_mods = {horizontal_align ="center",vertical_align="bottom"},
                    },
                    {
                        type = "scroll-pane",
                        style = "flib_naked_scroll_pane_no_padding",
                        style_mods = { horizontally_stretchable = true, },
                        {
                            type = "flow",
                            name = "inputs_flow",
                            style_mods = { vertical_spacing = 8, padding = 12, vertically_squashable = true },
                            direction = "vertical",
                        },
                    },
                },
            },
            {
                type = "frame",
                style = "subheader_frame",
                action_button("confirm", { "gui.confirm" }, { "gui.tagconfirm" }, on_button_confirm_clicked),
            },
        },
    })
    elems.lihop_input_gui.visible = false
    global.lihop_input_gui_state[player.index] = {
        elems = elems,
        player = player,
        set = nil
    }
end

function input.update_and_show(set, player)
    local elems = global.lihop_input_gui_state[player.index].elems
    update(set, elems, player)
    show_p(player, elems)
end

gui.add_handlers({
    hide = hide,
    toggle_visible = toggle_visible,
    on_button_confirm_clicked = on_button_confirm_clicked

})




return input
