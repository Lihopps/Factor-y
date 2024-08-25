--- @param e EventData.CustomInputEvent|EventData.on_lua_shortcut
local function on_shortcut(e)
  local name = e.input_name or e.prototype_name
  if name ~= "factor-y-get-selection-tool" then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local cursor_stack = player.cursor_stack
  if not cursor_stack or not player.clear_cursor() then
    return
  end
  cursor_stack.set_stack({ name = "lihop-factoryrecipe-selection-tool", count = 1 })
end

local shortcut = {}

shortcut.events = {
  [defines.events.on_lua_shortcut] = on_shortcut,
  ["factor-y-get-selection-tool"] = on_shortcut,
}

return shortcut