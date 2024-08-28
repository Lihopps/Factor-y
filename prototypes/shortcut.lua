local icon = {
  filename = "__Factor-y__/graphics/items/factor-y-tool.png",
  size = 32,
  mipmap_count = 2,
  flags = { "gui-icon" },
}

data:extend({
  {
    type = "shortcut",
    name = "factor-y-get-selection-tool",
    order = "d[tools]-r[factor-y]",
    icon = icon,
    action = "lua",
    associated_control_input = "factor-y-get-selection-tool",
  },
  {
    type = "custom-input",
    name = "factor-y-get-selection-tool",
    key_sequence = "ALT + M",
    action = "lua",
  },
})
