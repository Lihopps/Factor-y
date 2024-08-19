local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")


local empty = {
    filename = "__core__/graphics/empty.png",
    priority = "medium",
    width = 1,
    height = 1,
    frame_count = 1,
    line_length = 1,
}
local sprite = {
    led_red = empty,
    led_green = empty,
    led_blue = empty,
    led_light = { intensity = 0.5, size = 0 }
}

data:extend({
    {
        type = "item",
        name = "lihop-tank-input",
        icon = "__Factor-y__/graphics/entities/machine/item.png" ,
        icon_size = 64,
        icon_mipmaps = 4,
        flags = { "hidden" },
        subgroup = "other",
        order = "a[electric-energy-interface]-b[electric-energy-interface]",
        place_result = "lihop-tank-input",
        stack_size = 50
    },
    {
        type = "storage-tank",
        name = "lihop-tank-input",
        icon = "__Factor-y__/graphics/entities/machine/item.png" ,
        icon_size = 64,
        icon_mipmaps = 4,
        flags = { "placeable-player", "player-creation","not-blueprintable" },
        max_health = 500,
        selection_priority = 101,
        collision_box = { { -0.35, -0.35 }, { 0.35, 0.35 } },
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        placeable_by = { item = "lihop-machine-electric-interface", count = 1 },
        damaged_trigger_effect = hit_effects.entity(),
        fluid_box =
        {
            base_area = 1000,
            pipe_covers = pipecoverspictures(),
            pipe_connections =
            {
                { position = { 0, -1 }, type = "input" },

            },
        },
        --two_direction_only = true,
        window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
        pictures = {
            picture = empty,
            window_background = empty,
            fluid_background = empty,
            flow_sprite = empty,
            gas_flow = empty

        },
        flow_length_in_ticks = 360,
        vehicle_impact_sound = sounds.generic_impact,
        open_sound = sounds.machine_open,
        close_sound = sounds.machine_close,
        circuit_wire_connection_points = { {
            wire = {
                red = { -0.3, -0.5 },
                green = { 0.3, -0.5 },
                copper = { 0, -0.5 }
            },
            shadow = {}
        },
            {
                wire = {
                    red = { 0.3, -0.4 },
                    green = { 0.3, -0.7 },
                    copper = { 0, 0.5 }
                },
                shadow = {}
            },
            {
                wire = {
                    red = { -0.3, -0.4 },
                    green = { 0.3, -0.4 },
                    copper = { 0, 0.5 }
                },
                shadow = {}
            },
            {
                wire = {
                     red = { -0.3, -0.4 },
                    green = { -0.3, -0.7 },
                    copper = { 0, 0.5 }
                },
                shadow = {}
            }

        },
        circuit_connector_sprites = {sprite, sprite, sprite, sprite },
        circuit_wire_max_distance = default_circuit_wire_max_distance,
    },
})



local lihop_tank_output = table.deepcopy(data.raw["storage-tank"]["lihop-tank-input"])
lihop_tank_output.name = "lihop-tank-output"
lihop_tank_output.fluid_box.pipe_connections[1].type = "output"

local lihop_tank_output_item = table.deepcopy(data.raw["item"]["lihop-tank-input"])
lihop_tank_output_item.name = "lihop-tank-output"
lihop_tank_output_item.place_result = "lihop-tank-output"
data:extend { lihop_tank_output, lihop_tank_output_item }
