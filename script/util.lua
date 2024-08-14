local util={}

function util.construct_table(entities)
    local machine={}
    for _,entity in pairs(entities) do
        if entity.type=="beacon" then
            if machine[entity.name] then machine[entity.name]=machine[entity.name]+1 else machine[entity.name]=1 end
        end
        local mod_inv=entity.get_module_inventory()
        if mod_inv then
            local content=mod_inv.get_contents()
            for name,count in pairs(content)do
                if machine[name] then machine[name]=machine[name]+count else machine[name] = count end
            end
        end
    end
    return machine
end

function util.update_construc_table(machine,entities,add)
    local mult =1
    if not add then mult=-1 end
    for _,entity in pairs(entities) do
        if entity.type=="beacon" then
            if machine[entity.name] then machine[entity.name]=machine[entity.name]+(mult*1) else machine[entity.name]=(mult*1) end
            if machine[entity.name]<0 then machine[entity.name]=nil end
        end
        local mod_inv=entity.get_module_inventory()
        if mod_inv then
            local content=mod_inv.get_contents()
            for name,count in pairs(content)do
                if machine[name] then machine[name]= machine[name]+(mult*count) else machine[name]=(mult*count) end
                if machine[name]<0 then machine[name]=nil end
            end
        end
    end
end

function util.change(pos,rotation)
  rotation=(rotation/2)+1
  local cos={1,0,-1,0}
  local sin={0,-1,0,1}
  return {
    x=pos.x*cos[rotation]+pos.y*sin[rotation],
    y=-pos.x*sin[rotation]+pos.y*cos[rotation]
  }
end

function util.calc_position(entity,position)
  local new_pos=util.change(position,entity.direction)
  return {
    x=entity.position.x+new_pos.x,
    y=entity.position.y+new_pos.y
  }
end
return util