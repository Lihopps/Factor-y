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
        icon = "__Factor-y__/graphics/entities/machine/item.png",
        icon_size = 64,
        icon_mipmaps = 4,
        place_result = "lihop-machine-electric-interface",
        subgroup = "logistic-network",
        order = "d",
        stack_size = 1
    },
    {
        type = "electric-energy-interface",
        name = "lihop-machine-electric-interface",
        icon = "__Factor-y__/graphics/entities/machine/item.png" ,
        icon_size = 64,
        icon_mipmaps = 4,
        flags = { "placeable-neutral", "player-creation" },
        minable = { mining_time = 3, result = "lihop-machine-electric-interface" },
        max_health = 1000,
        corpse = "big-remnants",
        dying_explosion = "nuclear-reactor-explosion",
        subgroup = "other",
        is_military_target=true,
        collision_box = { { -10.4, -4.4 }, { 10.4, 4.4 } },
        selection_box = { { -10.5, -4.5 }, { 10.5, 4.5 } },
        selection_priority = 50,
        damaged_trigger_effect = hit_effects.entity(),
        gui_mode = "none",
        allow_copy_paste = true,
        energy_source =
        {
            type = "electric",
            usage_priority = "secondary-input",
            buffer_capacity = "1667J",
            emissions_per_minute = 4
        },
        energy_usage = "100kW",
        continuous_animation = true,
        animations = {
            north = {
                layers = {
                    {
                        filename = "__Factor-y__/graphics/entities/machine/droite.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 750,
                        height = 300,
                        frame_count = 32,
                        animation_speed=0.5,
                        shift = util.by_pixel(0, 0),
                    },
                    {
                        filename = "__Factor-y__/graphics/entities/machine/droite-shadow.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 750,
                        height = 300,
                        frame_count = 32,
                        draw_as_shadow = true,
                        shift = util.by_pixel(0, 0),
                    }
                }
            },
            south = {
                layers = {
                    {
                        filename = "__Factor-y__/graphics/entities/machine/gauche.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 750,
                        height = 300,
                        frame_count = 32,
                        run_mode="backward",
                        animation_speed=0.5,
                        shift = util.by_pixel(0, 0),
                    },
                    {
                        filename = "__Factor-y__/graphics/entities/machine/gauche-shadow.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 750,
                        height = 300,
                        frame_count = 32,
                        run_mode="backward",
                        draw_as_shadow = true,
                        animation_speed=0.5,
                        shift = util.by_pixel(0, 0),
                    } }
            },
            east = {
                layers = {
                    {
                        filename = "__Factor-y__/graphics/entities/machine/haut.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 272,
                        height = 649,
                        frame_count = 32,
                        scale=1.06,
                        run_mode="backward",
                        animation_speed=0.5,
                        shift = util.by_pixel(0, 0),
                    },
                     {
                        filename = "__Factor-y__/graphics/entities/machine/haut-shadow.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 272,
                        height = 649,
                        frame_count = 32,
                        scale=1.06,
                        run_mode="backward",
                        draw_as_shadow = true,
                        animation_speed=0.5,
                        shift = util.by_pixel(0, 0),
                    },
                     }
            },
            west = {
                layers = {
                    {
                        filename = "__Factor-y__/graphics/entities/machine/bas.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 272,
                        height = 649,
                        frame_count = 32,
                        scale=1.06,
                        animation_speed=0.5,
                        shift = util.by_pixel(0, 0),
                    },
                     {
                        filename = "__Factor-y__/graphics/entities/machine/bas-shadow.png",
                        priority = "extra-high",
                        line_length = 4,
                        width = 272,
                        height = 649,
                        frame_count = 32,
                        scale=1.06,
                        draw_as_shadow = true,
                        animation_speed=0.5,
                        shift = util.by_pixel(0, 0),
                    },
                     }
            }
        },
        open_sound = sounds.machine_open,
        close_sound = sounds.machine_close,
        vehicle_impact_sound = sounds.generic_impact
    },
})
