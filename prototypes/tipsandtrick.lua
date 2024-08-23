local simulations = {}

simulations.recipe_creation =
{	
	mods={"RateCalculator-Lf","Factor-y"},
	init =
	[[
	
	player = game.create_test_player{name = "big k"}
    player.teleport({0, 2.5})
	player.force="player"
    game.camera_player = player
    game.camera_player_cursor_position = player.position
    game.camera_alt_info = true
	game.camera_zoom=0.7

	game.surfaces[1].create_entities_from_blueprint_string
    {
      string = "0eNqNkWFPwyAQhv/LfYZl0M5O/ooxC6XXjgRoA1StDf9d6HRZnFH5xJHc8z53rNCaGSevXQSxglajCyCeVgh6cNKUt7hMCAJ0RAsEnLSlkiGgbY12A7VSnbVDWkEioF2HbyBYIn8i0KCKXiuKDv2w0KyAvpcKbzg8PRNAF3XUePHaiuXkZtuiz0G/GxGYxpCbR1c0MpDudwcCS76w3SHneFT64uZHRweUnr6eEU3uLLahtIUJsaN27GZTmKJOZbpvIvwqEuY2RLll3sXXn9k/Eap/bOYOyPgXkUA79z36U9DvGcL211N2uK1e3Hw2gRf0YQPxI6ubR94cj5xVzUNKH5MNsCg=",
      position = {-1,0},
    }
	player.cursor_stack.set_stack{name = "rcalc-selection-tool", count = 1}

	reset=function()
		player.cursor_stack.set_stack{name = "rcalc-selection-tool", count = 1}
      step_1()
	end

	step_1 = function()
      script.on_nth_tick(1, function()
        if game.move_cursor{position = {-10, -2}} then
          game.activate_selection()
          step_2()
        end
      end)
    end
	
	step_2 = function()
      script.on_nth_tick(1, function()
        if game.move_cursor{position = {-5, 1}} then
          game.finish_selection()
          reset()
        end
      end)
    end

    

    step_1()

  ]]
}

data:extend({
	{
		type = "tips-and-tricks-item-category",
		name = "lihop-big-factory",
		order = "l-[BigFactory]",
	},
	{
		type = "tips-and-tricks-item",
		name = "lihop-big-factory-0",
		category = "lihop-big-factory",
		order = "0",
		starting_status = "locked",
		trigger =
		{
			type = "research",
			technology = "lihop-big-factory"
		},
		tag = "[item=lihop-factoryrecipe]",
		is_title = false,
		image = "__Factor-y__/graphics/gui/recipe_creation.png",
	},
	{
		type = "tips-and-tricks-item",
		name = "lihop-big-factory-1",
		category = "lihop-big-factory",
		order = "0",
		starting_status = "locked",
		trigger =
		{
			type = "research",
			technology = "lihop-big-factory"
		},
		tag = "[item=lihop-factoryrecipe]",
		is_title = false,
		dependencies = {"lihop-big-factory-0"},
		image = "__Factor-y__/graphics/gui/see_tags.png",
	},
	{
		type = "tips-and-tricks-item",
		name = "lihop-big-factory-2",
		category = "lihop-big-factory",
		order = "2",
		starting_status = "locked",
		trigger =
		{
			type = "research",
			technology = "lihop-big-factory"
		},
		tag = "[item=lihop-machine-electric-interface]",
		is_title = false,
		image = "__Factor-y__/graphics/gui/def_machine.png",
	},
	{
		type = "tips-and-tricks-item",
		name = "lihop-big-factory-3",
		category = "lihop-big-factory",
		order = "2",
		starting_status = "locked",
		trigger =
		{
			type = "research",
			technology = "lihop-big-factory"
		},
		tag = "[item=lihop-machine-electric-interface]",
		dependencies = {"lihop-big-factory-2"},
		image = "__Factor-y__/graphics/gui/machine_gui.png",
		is_title = false,
		
	},
})
