local util = require("script.util")
local inputView =require("script.input_gui")
local machine = require("script.machine")
local calculation =require("script.calculation")


local function on_runtime_mod_setting_changed(e)
	if e.setting=="lihop-prevent-emergence" then
		global.emerg_recipe=util.recipe_emerg()
	end
end

local function on_built_entity(e)
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
	if entity.name == "lihop-machine-electric-interface" then
		machine.build(entity)
	end
end

local function on_pre_player_mined_item(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	local player = game.players[e.player_index]
	if not player then return end
	if entity.name == "lihop-machine-electric-interface" then
		machine.destroy_by_player(entity, player)
	end
end

local function on_robot_pre_mined(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	if entity.name == "lihop-machine-electric-interface" then
		machine.marked(entity)
	end
end

local function on_player_mined_entity(e)

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
end

local function on_entity_died(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	if entity.name == "lihop-machine-electric-interface" then
		machine.destroy(entity)
	end
end

local function on_marked_for_deconstruction(e)
	local entity = e.entity
	if not entity or not entity.valid then
		return
	end
	if entity.name == "lihop-machine-electric-interface" then
		machine.marked(entity)
	end
end

local function on_player_created(e)
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    inputView.build(player)
end

local function on_player_selected_area(e)
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
end

local function on_short_cut(e)
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


-- script.on_event({
-- 	defines.events.on_surface_cleared,
-- 	defines.events.on_surface_deleted,
-- }, function(e)

-- end)



local main={}

function main.on_init()
	if not global.machine_index then global.machine_index = {} end
	if not global.machine then global.machine = {} end
	if not global.gui then global.gui = {} end
	if not global.lihop_input_gui_state then global.lihop_input_gui_state = {} end
	if not global.emerg_recipe then global.emerg_recipe =util.recipe_emerg() end

end


function main.on_configuration_changed()
	if not global.machine_index then global.machine_index = {} end
	if not global.machine then global.machine = {} end
	if not global.gui then global.gui = {} end
	global.emerg_recipe =util.recipe_emerg()
	global.lihop_input_gui_state = {}
    for _,player in pairs(game.players) do
        if player.gui.screen.lihop_input_gui then
            player.gui.screen.lihop_input_gui.destroy()
        end
        inputView.build(player)
    end
end

main.events={
    [defines.events.on_runtime_mod_setting_changed]=on_runtime_mod_setting_changed,
    [defines.events.on_built_entity]=on_built_entity,
	[defines.events.on_robot_built_entity]=on_built_entity,
    [defines.events.on_pre_player_mined_item]=on_pre_player_mined_item,
    [defines.events.on_robot_pre_mined]=on_robot_pre_mined,
    [defines.events.on_player_mined_entity]=on_player_mined_entity,
    [defines.events.on_marked_for_deconstruction]=on_marked_for_deconstruction,
    [defines.events.on_entity_died]=on_entity_died,
    [defines.events.on_player_created]=on_player_created,
    [defines.events.on_player_selected_area]=on_player_selected_area,
    [defines.events.on_lua_shortcut]=on_short_cut,
    ["factor-y-get-selection-tool"]=on_short_cut,
    
}

return main