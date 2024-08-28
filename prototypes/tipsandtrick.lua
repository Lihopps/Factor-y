data:extend({
	{
		type = "tips-and-tricks-item-category",
		name = "lihop-big-factory",
		order = "l-[BigFactory]",
	},
	{
		type = "tips-and-tricks-item",
		name = "lihop-big-factory-0",
		localised_description={"tips-and-tricks-item-description.lihop-big-factory-0",{"gui.bp-description"}},
		category = "lihop-big-factory",
		order = "0",
		starting_status = "locked",
		trigger =
		{
			type = "research",
			technology = "lihop-big-factory"
		},
		tag = "[img=lihop-rate-tool]",
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
