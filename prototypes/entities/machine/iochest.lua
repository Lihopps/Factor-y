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
        type = "logistic-container",
        name = "lihop-iochest-requester",
        icon = "__Factor-y__/graphics/entities/machine/item.png" ,
        icon_size = 64,
        icon_mipmaps = 4,
        flags = { "placeable-player", "player-creation","not-blueprintable","hidden" },
        max_health = 350,
        collision_box = { { -4.40, -4.40 }, { 4.40, 4.40 } },
        selection_box = { { -4.5, -4.5 }, { 4.5, 4.5 } },
        selection_priority=100,
        placeable_by = {item = "lihop-machine-electric-interface", count = 1},
        damaged_trigger_effect = hit_effects.entity(),
        resistances =
        {
            {
                type = "fire",
                percent = 90
            },
            {
                type = "impact",
                percent = 60
            }
        },
        fast_replaceable_group = "container",
        inventory_type="with_filters_and_bar",
        inventory_size = 512,
        logistic_mode = "requester",
        open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume = 0.43 },
        close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
        animation_sound = sounds.logistics_chest_open,
        vehicle_impact_sound = sounds.generic_impact,
        opened_duration = logistic_chest_opened_duration,
        animation =
        {
            layers ={ empty }
        },
        landing_location_offset={0, 0},
        circuit_wire_connection_points = { 
                red = { -1.5, -0.5 },
                green = { 1.5, -0.5 },
                copper = { 0, -0.5 }
        },
        circuit_connector_sprites = sprite,
        circuit_wire_max_distance = default_circuit_wire_max_distance,
    },
})

local lihop_iochest_provider = table.deepcopy(data.raw["logistic-container"]["lihop-iochest-requester"])
lihop_iochest_provider.name="lihop-iochest-provider"
lihop_iochest_provider.logistic_mode="passive-provider"
lihop_iochest_provider.inventory_type="with_bar"


data:extend{lihop_iochest_provider}