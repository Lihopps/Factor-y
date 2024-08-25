local gui = require("__flib__.gui-lite")
local util =require("script.util")
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

--- @param e EventData.on_gui_click
local function on_constructor_button_click(e)
  if e.element then
    if e.element.name == "lihop_constructor_button" then
      local guiData = remote.call("RateCalculator", "getGuidata", e.player_index)
      if guiData then
        local selected_index = guiData.selected_set_index
        local set = guiData.sets[selected_index]
        util.syncset(#guiData.sets)
        local recipe = constructor.createRecipe(set, selected_index, game.players[e.player_index])
        --game.write_file("set.json", game.table_to_json(set))
      end
    end
  end
end

local function build_tooltip()
  
  return  { "gui.create-recipe" }
end

function constructor.build(element)
  if element.children[1].lihop_constructor_button then --already present
    return
  end
  child_index = #element.children[1].children
  gui.add(element.children[1],
    frame_action_button("lihop_constructor_button", "utility/technology",build_tooltip(),
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

    if string.match(path, "dummy") then
      goto continue --on ne veut des items cacher // on ajoutera les catcher ici pour la compat des mods
    end

    local sorting_rate = 0
    if output.rate > 0 and input.rate > 0 then
      -- category = "intermediates"
      sorting_rate = output.rate - input.rate
      if sorting_rate>0 then
        --outputs[rates.name] = { type = rates.type, count = math.floor(sorting_rate) }
      elseif sorting_rate<0 then
        inputs[rates.name] = { type = rates.type, count = -math.ceil(sorting_rate) }
      end
      for machine, num in pairs(output.machine_counts) do
        if machines[machine] then machines[machine] = machines[machine] + num else machines[machine] = num end
      end
    elseif input.rate > 0 then
      -- category = "ingredients"
      sorting_rate = input.rate
      inputs[rates.name] = { type = rates.type, count = math.ceil(sorting_rate)  }
    else
      -- category = "products"
      sorting_rate = output.rate
      outputs[rates.name] = { type = rates.type, count = math.floor(sorting_rate) }
      for machine, num in pairs(output.machine_counts) do
        if machines[machine] then machines[machine] = machines[machine] + num else machines[machine] = num end
      end
    end
  
    ::continue::
  end


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

  local str2=util.get_bp(recipe)
  str2="0"..game.encode_string(str2)
  player.clear_cursor()
  game.print(player.cursor_stack.import_stack(str2))


  local tmp=player.cursor_stack.get_blueprint_entity_tags(1)
  game.write_file("set.json", game.table_to_json(set))
  game.write_file("recipeT.json", game.table_to_json(tmp))

  return recipe
end

gui.add_handlers({
  on_constructor_button_clic = on_constructor_button_click,
})


return constructor
