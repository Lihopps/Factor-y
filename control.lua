local gui = require("__flib__.gui-lite")

local constructor = require("script.constructor")
local util = require("script.util")
local machine = require("script.machine")

local handler = require("__core__.lualib.event_handler")
handler.add_libraries({
	require("__flib__.gui-lite"),
	require("script.machine"),
	require("script.constructor")
})

--BOOTSTRAP
gui.handle_events()
script.on_init(function()
	if not global.buildings then global.buildings = {} end
	if not global.machine_index then global.machine_index = {} end
	if not global.machine then global.machine = {} end
	if not global.gui then global.gui = {} end
end)


script.on_configuration_changed(function(e)
	if not global.buildings then global.buildings = {} end
	if not global.machine_index then global.machine_index = {} end
	if not global.machine then global.machine = {} end
	if not global.gui then global.gui = {} end
end)


--------------------------------------------------------------------------------------------------------
------------------------------------------- EVENT Surface -----------------------------------------------
--------------------------------------------------------------------------------------------------------

script.on_event({
	defines.events.on_surface_cleared,
	defines.events.on_surface_deleted,
}, function(e)

end)

script.on_event({ defines.events.on_tick },
	function(e)
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
	for _,opened in pairs(global.gui) do
		machine.update_gui(opened,true)
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
	defines.events.on_robot_pre_mined,
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


--------------------------------------------------------------------------------------------------------
--------------------------------------- Gestion des Gui ------------------------------------------------
--------------------------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------------------------
------------------------------------------ PLAYER ------------------------------------------------------
--------------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_player_selected_area, function(e)
	if e.item ~= "rcalc-selection-tool" then
		return
	end
	if not next(e.entities) then
		return
	end
	local player = game.get_player(e.player_index)
	if not player then
		return
	end
	local building = util.construct_table(e.entities)
	global.buildings[#global.buildings + 1] = building
	if #global.buildings > 10 then
		table.remove(global.buildings, 1)
	end
end)

script.on_event(defines.events.on_player_alt_reverse_selected_area, function(e)
	if e.item ~= "rcalc-selection-tool" then
		return
	end
	if not next(e.entities) then
		return
	end
	local player = game.get_player(e.player_index)
	if not player then
		return
	end
	local guiData = remote.call("RateCalculator", "getGuidata", e.player_index)
	if guiData then
		local selected_index = guiData.selected_set_index
		if selected_index then
			util.update_construc_table(global.buildings[selected_index], e.entities, false)
		end
	end
end)

script.on_event(defines.events.on_player_alt_selected_area, function(e)
	if e.item ~= "rcalc-selection-tool" then
		return
	end
	if not next(e.entities) then
		return
	end
	local player = game.get_player(e.player_index)
	if not player then
		return
	end
	local guiData = remote.call("RateCalculator", "getGuidata", e.player_index)
	if guiData then
		local selected_index = guiData.selected_set_index
		if selected_index then
			util.update_construc_table(global.buildings[selected_index], e.entities, true)
		end
	end
end)
