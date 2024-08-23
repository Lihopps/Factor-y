data:extend({
	{
    type = "technology",
    name = "lihop-big-factory",
    icon_size = 256, icon_mipmaps = 4,
    icon = "__Factor-y__/graphics/technologies/techno-machine.png",
    effects =
    {
		{
			type = "unlock-recipe",
			recipe = "lihop-machine-electric-interface"
		},
	},
    prerequisites = {"space-science-pack"},
    unit =
    {
		  count = 1000,
		  ingredients =
		  {
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
			{"production-science-pack", 1},
			{"utility-science-pack", 1},
			{"space-science-pack", 1}
		  },
		  time = 30
	},
    order = "a-b-b"
	}})