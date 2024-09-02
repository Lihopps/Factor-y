local util = require("script.util")
local machine = require("script.machine")
local calculation =require("script.calculation")
local inputView =require("script.input_gui")
local handler = require("__core__.lualib.event_handler")



handler.add_libraries({
  	require("__flib__.gui-lite"),
	require("script.machine"),
	require("script.input_gui"),

	require("script.helmod.helmod")
})


--gui.handle_events()

script.on_event({
	defines.events.on_runtime_mod_setting_changed,
}, function(e)
	if e.setting=="lihop-prevent-emergence" then
		global.emerg_recipe=util.recipe_emerg()
	end
end)
--------------------------------------------------------------------------------------------------------
------------------------------------------- EVENT Surface -----------------------------------------------
--------------------------------------------------------------------------------------------------------

script.on_event({
	defines.events.on_surface_cleared,
	defines.events.on_surface_deleted,
}, function(e)

end)

script.on_event({ defines.events.on_tick }, function(e)
	local a = (e.tick % 60) + 1
	if #global.machine_index >= a then
		for i = a, #global.machine_index, 60 do
			machine.update(global.machine_index[i])
			--game.print(global.machine_index[i])
		end
	end
end)

script.on_nth_tick(30, function(e)
	--updategui if opened
	for _, opened in pairs(global.gui) do
		machine.update_gui(opened, true)
	end
end)

--------------------------------------------------------------------------------------------------------
------------------------------------------- EVENT ENTITY -----------------------------------------------
--------------------------------------------------------------------------------------------------------

script.on_event({
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
}, function(e)
	local entity = e.entity or e.created_entity
	local constructeur = nil
	if e.player_index then
		constructeur = game.players[e.player_index]
	else
		constructeur = e.robot
	end
	if not entity or not entity.valid then
		return
	end
	if not constructeur or not constructeur.valid then
		return
	end
	local entity_name = entity.name
	if entity.name == "lihop-machine-electric-interface" then
		machine.build(entity)
	end
end)

script.on_event({
	defines.events.on_pre_player_mined_item,
}, function(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	local player = game.players[e.player_index]
	if not player then return end
	if entity.name == "lihop-machine-electric-interface" then
		machine.destroy_by_player(entity, player)
	end
end)

script.on_event({
	defines.events.on_robot_pre_mined,
}, function(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	if entity.name == "lihop-machine-electric-interface" then
		machine.marked(entity)
	end
end)

script.on_event({
	defines.events.on_player_mined_entity,
}, function(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	local player = game.players[e.player_index]
	if not player then return end
	if entity.name == "lihop-machine-electric-interface" then
		if not util.insert2(e.buffer, player) then
			e.buffer.clear()
		end
	end
end)

script.on_event({
	defines.events.on_entity_died,
}, function(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	if entity.name == "lihop-machine-electric-interface" then
		machine.destroy(entity)
	end
end)

script.on_event({
	defines.events.on_marked_for_deconstruction,
}, function(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	if entity.name == "lihop-machine-electric-interface" then
		machine.marked(entity)
	end
end)


--------------------------------------------------------------------------------------------------------
--------------------------------------- Gestion des Gui ------------------------------------------------
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
------------------------------------------ PLAYER ------------------------------------------------------
--------------------------------------------------------------------------------------------------------
script.on_event({
    defines.events.on_player_created
}, function(e)
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    inputView.build(player)
end)

script.on_event(defines.events.on_player_selected_area, function(e)
	if e.item ~= "lihop-factoryrecipe-selection-tool" then
		return
	end
	if not next(e.entities) then
		return
	end
	local player = game.get_player(e.player_index)
	if not player then
		return
	end
	calculation.set_calc_bleuprint(e.entities,player)
end)

script.on_event(
	{
		defines.events.on_lua_shortcut,
		"factor-y-get-selection-tool",
	}, function(e)
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
end)
