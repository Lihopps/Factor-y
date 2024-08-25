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
  })