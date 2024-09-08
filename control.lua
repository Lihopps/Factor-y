local machine = require("script.machine")
local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  	require("__flib__.gui-lite"),
	require("script.main"),
	require("script.machine"),
	require("script.input_gui"),
	require("script.helmod.helmod"),
	--require("script.factoryplanner.factoryplanner")
})

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