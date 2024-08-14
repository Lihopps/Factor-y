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

data:extend({
    {
        type = "item",
        name = "lihop-recipechest",
        icons = { { icon = "__base__/graphics/icons/accumulator.png", tint = { r = 1, g = 0.8, b = 1, a = 1 } } },
        icon_size = 64,
        icon_mipmaps = 4,
        flags = { "hidden" },
        subgroup = "other",
        order = "a[electric-energy-interface]-b[electric-energy-interface]",
        place_result = "lihop-recipechest",
        stack_size = 50
    },
    {
        type = "logistic-container",
        name = "lihop-recipechest",
        icon = "__base__/graphics/icons/logistic-chest-requester.png",
        icon_size = 64,
        icon_mipmaps = 4,
        flags = { "placeable-player", "player-creation" },
        max_health = 350,
        corpse = "requester-chest-remnants",
        dying_explosion = "requester-chest-explosion",
        collision_box = { { -3.4, -3.4 }, { 3.4, 3.4 } },
        selection_box = { { -3.5, -3.5 }, { 3.5, 3.5 } },
        selection_priority = 100,
        placeable_by = { item = "lihop-machine-electric-interface", count = 1 },
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
        inventory_size = 64,
        logistic_mode = "requester",
        open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume = 0.43 },
        close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
        animation_sound = sounds.logistics_chest_open,
        vehicle_impact_sound = sounds.generic_impact,
        opened_duration = logistic_chest_opened_duration,
        animation =
        {
            layers = { empty }
        },
        landing_location_offset = { 0, 0 }
    },
})
