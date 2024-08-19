local gui = require("__flib__.gui-lite")
local constructor = {}

local function frame_action_button(name, sprite, tooltip, handler)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    handler = { [defines.events.on_gui_click] = handler },

  }
end

local function isIntermediatesOk(intermediates)
  for _, num in pairs(intermediates) do
    if num < 0 then return false end
  end
  return true
end


--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  if e.element then
    if e.element.name == "rcalc_window" then
      game.print("la")
      constructor.build(e.element)
    end
  end
end


--- @param e EventData.on_gui_click
local function on_constructor_button_click(e)
  if e.element then
    if e.element.name == "lihop_constructor_button" then
      local guiData = remote.call("RateCalculator", "getGuidata", e.player_index)
      if guiData then
        local selected_index = guiData.selected_set_index
        local set = guiData.sets[selected_index]
        local recipe = constructor.createRecipe(set, selected_index, game.players[e.player_index])
        game.write_file("set.json", game.table_to_json(set))
      end
    end
  end
end

function constructor.build(element)
  if element.children[1].lihop_constructor_button then --already present
    return
  end
  child_index = #element.children[1].children
  gui.add(element.children[1],
    frame_action_button("lihop_constructor_button", "utility/technology", { "gui.create-recipe" },
      on_constructor_button_click))
  element.children[1].swap_children(child_index, child_index + 1)
end

function constructor.createRecipe(set, index, player)
  --game.write_file("set.json", game.table_to_json(set))
  --Structure of recipe
  --input{}
  --output{}
  --machine{}    machine du set + beacon + module
  --energy
  --pollution
  if not player then return end

  local inputs = {}
  local outputs = {}
  local intermediates = {}
  local machines = {}
  local energy = 0
  local polution = 0
  for path, rates in pairs(set.rates) do
    local output = rates.output
    local input = rates.input

    if path == "item/rcalc-power-dummy" then
      energy = input.rate - output.rate
      goto continue
    elseif path == "item/rcalc-pollution-dummy" then
      polution = output.rate
      goto continue
    elseif path == "item/rcalc-heat-dummy" then
      goto continue
    end

    local sorting_rate = 0
    if output.rate > 0 and input.rate > 0 then
      -- category = "intermediates"
      sorting_rate = output.rate - input.rate
      intermediates[rates.name] = sorting_rate
      for machine, num in pairs(output.machine_counts) do
        if machines[machine] then machines[machine] = machines[machine] + num else machines[machine] = num end
      end
    elseif input.rate > 0 then
      -- category = "ingredients"
      sorting_rate = input.rate
      inputs[rates.name] = { type = rates.type, count = sorting_rate }
    else
      -- category = "products"
      sorting_rate = output.rate
      outputs[rates.name] = { type = rates.type, count = sorting_rate }
      for machine, num in pairs(output.machine_counts) do
        if machines[machine] then machines[machine] = machines[machine] + num else machines[machine] = num end
      end
    end

    ::continue::
  end

  if isIntermediatesOk(intermediates) then
    for name, count in pairs(global.buildings[index]) do
      machines[name] = count
      --game.print(name.." : "..count)
    end
    local recipe = {
      inputs = inputs,
      outputs = outputs,
      machines = machines,
      energy = energy,
      polution = polution

    }
    player.cursor_stack.set_stack({ name = "lihop-factoryrecipe", count = 1 })
    player.cursor_stack.tags = recipe
    return recipe
  else
    game.print("not good")
    return -1
  end
end

constructor.events = {
  [defines.events.on_gui_opened] = on_gui_opened,
}

gui.add_handlers({
  on_constructor_button_clic = on_constructor_button_click,
})


return constructor
