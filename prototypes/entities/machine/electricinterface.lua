local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")



data:extend({
    {
        type = "recipe",
        name = "lihop-machine-electric-interface",
        energy_required = 4,
        enabled = true,
        ingredients =
        {
            { "concrete",         100 },
            { "steel-plate",      50 },
            { "advanced-circuit", 100 },
            { "radar",            5 },
            { "roboport",         2 }
        },
        result = "lihop-machine-electric-interface",
        requester_paste_multiplier = 10
    },
    {
        type = "item",
        name = "lihop-machine-electric-interface",
        icon = "__base__/graphics/icons/steel-plate.png",
        icon_size = 64,
        icon_mipmaps = 4,
        place_result = "lihop-machine-electric-interface",
        subgroup = "logistic-network",
        order = "d",
        stack_size = 50
    },
    {
        type = "electric-energy-interface",
        name = "lihop-machine-electric-interface",
        icons = { { icon = "__base__/graphics/icons/steel-plate.png", tint = { r = 1, g = 0.8, b = 1, a = 1 } } },
        icon_size = 64,
        icon_mipmaps = 4,
        flags = { "placeable-neutral", "player-creation" },
        minable = { mining_time = 0.1, result = "lihop-machine-electric-interface" },
        max_health = 150,
        corpse = "medium-remnants",
        subgroup = "other",
        collision_box = { { -10.4, -4.4 }, { 10.4, 4.4 } },
        selection_box = { { -10.5, -4.5 }, { 10.5, 4.5 } },
        selection_priority=50,
        damaged_trigger_effect = hit_effects.entity(),
        gui_mode = "all",
        allow_copy_paste = true,
        energy_source =
        {
            type = "electric",
            usage_priority = "secondary-input",
            buffer_capacity="1667J",
            emissions_per_minute = 4
        },
        energy_usage = "100kW",
        
        pictures = {
            north = {
                filename = "__Factor-y__/graphics/entities/machine/droite.png",
                priority = "medium",
                width = 700,
                height = 300,
                scale=0.9
            },
            south = {
                filename = "__Factor-y__/graphics/entities/machine/gauche.png",
                priority = "medium",
                width = 700,
                height = 300,
                scale=0.9
            },
            east = {
                filename = "__Factor-y__/graphics/entities/machine/bas.png",
                priority = "medium",
                width = 300,
                height = 700,
                scale=0.9
            },
            west = {
                filename = "__Factor-y__/graphics/entities/machine/haut.png",
                priority = "medium",
                width = 300,
                height = 700,
                scale=0.9
            }
        },
        open_sound = sounds.machine_open,
        close_sound = sounds.machine_close,
        vehicle_impact_sound = sounds.generic_impact
    },
})
