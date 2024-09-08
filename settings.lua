local util=require("script.util")

data:extend(
    {
        {
            type = "double-setting",
            name = "lihop-multiplier-recipe",
            setting_type = "runtime-per-user",
            default_value = 1.5,
            minimum_value = 0,
        },
        {
            type = "bool-setting",
            name = "lihop-prevent-emergence",
            setting_type = "runtime-global",
            default_value = true,
        },
        {
            type = "bool-setting",
            name = "lihop-allow-factory-exportation",
            setting_type = "runtime-global",
            default_value = false,
            localised_description={"",{"mod-setting-description.lihop-allow-factory-exportation"},util.tooltip_table(util.compat,"-")}
        },
        {
            type = "bool-setting",
            name = "lihop-debug-mod",
            setting_type = "runtime-per-user",
            default_value = false,
        }
    })
