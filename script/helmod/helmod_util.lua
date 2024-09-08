local util=require("script.util")

local function calc_energy_pollution(children,recipe)
    for name,object in pairs(children) do
        if object.class =="Block" then
            calc_energy_pollution(object.children,recipe)
        elseif object.class=="Recipe" then
            local energy=object.factory.energy*util.rounded(object.factory.count)
            local polution=object.factory.pollution
            for _,beacon in ipairs(object.beacons) do
                energy=energy+beacon.energy*util.rounded(beacon.count)
            end
            recipe.energy=recipe.energy+energy
            recipe.polution=recipe.polution+polution
        end
    end
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function read(data_string)
    if data_string == nil then return nil end
    data_string = trim(data_string)
    if (string.sub(data_string, 1, 8) ~= "do local") then
        local ok, err = pcall(function()
            data_string = game.decode_string(data_string)
        end)
        if not (ok) then
            return nil
        end
    end
    local status, data_table = pcall(loadstring, data_string)
    if (status) then
        return data_table()
    end
    return nil
end

local function helmod_to_recipe(helmod_table,player)
    local recipe={
        machines={},
        polution=0,
        energy=0,
        inputs={},
        outputs={}
    }
    util.debug(player,"helmod_table_1.json",helmod_table)
    local divisor = helmod_table.time
    
    for name,obj in pairs(helmod_table.block_root.summary.factories) do
        if obj.count>0 then
            recipe.machines[name]=obj.count
        end
    end
    for name,obj in pairs(helmod_table.block_root.summary.modules) do
        if obj.count>0 then
            recipe.machines[name]=obj.count
        end
    end

    for name,obj in pairs(helmod_table.block_root.ingredients) do
        if obj.amount>0 then
            recipe.inputs[name]={type=obj.type,count=util.rounded(obj.amount/divisor),real_count=obj.amount/divisor}
        end
    end

    for name,obj in pairs(helmod_table.block_root.products) do
        if obj.amount>0 then
            recipe.outputs[name]={type=obj.type,count=util.rounded(obj.amount/divisor),real_count=obj.amount/divisor}
        end
    end

    calc_energy_pollution(helmod_table.block_root.children,recipe)

    local name=helmod_table.group
    local description=helmod_table.note

    return {recipe,name,description}
end

local helmod_util = {}

function helmod_util.create_bp(e)
    local player =game.players[e.player_index]
    if not player then return end
    local tags = e.element.tags
    if not next(tags) then return end     --text sur le pointeur
    local factory_text = tags.text
    if not factory_text then return end   --text sur le pointeur
    factory_text = string.gsub(factory_text, "%s+", "")
    if factory_text == "" then return end --text sur le pointer
    local table = read(factory_text)
    if not table then return end          -- text sur le pointeur
    local recipe=helmod_to_recipe(table,player)
    local str2 = util.get_bp(recipe[1],recipe[2],recipe[3])
    local blueprint_item_str = "0" .. game.encode_string(str2)
    util.debug(player,"final_string.txt",blueprint_item_str,true)
    player.cursor_stack.import_stack(blueprint_item_str)
end

return helmod_util
