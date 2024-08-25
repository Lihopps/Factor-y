local type_filters = {
  "assembling-machine",
  "beacon",
  "furnace",
  "rocket-silo",
}

data:extend({
  {
    type = "blueprint",
    name = "lihop-factoryrecipe",
    icon = "__Factor-y__/graphics/items/bigfactoryrecipe.png",
    icon_size = 64, icon_mipmaps = 4,
    flags = { "spawnable","hidden"},
    stack_size = 1,
    draw_label_for_cursor_render = true,
    selection_color = {57, 156, 251},
    alt_selection_color = {0.3, 0.8, 1},
    selection_count_button_color = {43, 113, 180},
    alt_selection_count_button_color = {0.3, 0.8, 1},
    selection_mode = {"blueprint"},
    alt_selection_mode = {"blueprint"},
    selection_cursor_box_type = "copy",
    alt_selection_cursor_box_type = "copy",
    open_sound = {filename =  "__base__/sound/item-open.ogg", volume = 1},
    close_sound = {filename = "__base__/sound/item-close.ogg", volume = 1}
  },
   {
    type = "selection-tool",
    name = "lihop-factoryrecipe-selection-tool",
    order = "d[tools]-r[rate-calculator]",
    icons = {
      { icon = "__Factor-y__/graphics/items/bigfactoryrecipe.png", icon_size = 32, mipmap_count = 2 },
    },

    selection_color = { r = 1, g = 1 },
    selection_cursor_box_type = "entity",
    selection_mode = { "buildable-type", "friend" },
    entity_type_filters = type_filters,

    alt_selection_color = { a = 0  },
    alt_selection_mode = { "nothing" },
    alt_selection_cursor_box_type = "entity",

    reverse_selection_color = { a = 0 },
    reverse_selection_mode = { "nothing" },

    alt_reverse_selection_color = { a = 0  },
    alt_reverse_selection_mode = { "nothing"},
    alt_reverse_cursor_box_type = "entity",

    stack_size = 1,
    flags = { "hidden", "only-in-cursor", "not-stackable", "spawnable" },
  },
    {
    type = "custom-input",
    name = "factor-y-get-selection-tool",
    key_sequence = "ALT + M",
    action = "lua",
  },
  })