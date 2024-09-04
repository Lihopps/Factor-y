local gui = require("__flib__.gui-lite")
local fp_util =require("script.factoryplanner.factoryplanner_util")

local function on_button_export_clicked(e)
    fp_util.create_bp(e)
end

local function removebutton(flow)
    if flow.lihop_factory_planner then
        flow.lihop_factory_planner.destroy()
    end
end

local function addbutton(flow)
    if not flow.lihop_factory_planner then
        local factory_text=flow.children[2].text
        local bouton = {
            type = "sprite-button",
            sprite="lihop-rate-tool",
            name="lihop_factory_planner",
            tooltip = {"gui.exporttofactory"},
            style_mods = { size = 28 },
            tags = { text = factory_text },
            handler = { [defines.events.on_gui_click] = on_button_export_clicked },
        }
        gui.add(flow, bouton)
        flow.swap_children(2,3)
    end
end




local function on_gui_click(e)
    local tags=e.element.tags
	if not next(tags) then return end
	if tags["on_gui_click"]=="export_factories" then
        local parent =e.element.parent.parent
        local tableau=parent.children[1].children[1].children[1]
        local state=true
        local tot=0
        for i=1,#tableau.children,4 do
            if i==1 then
                if tableau.children[i].state==true then
                    state=false
                    break
                end
            elseif tableau.children[i].state==true then
                tot=tot+1
                if tot>=2 then
                    state=false
                    break
                end
            end
        end
        if state then
            addbutton(parent.children[2])
        else
            removebutton(parent.children[2])
        end
	end
end
local factoryplanner={}

factoryplanner.events = {
    [defines.events.on_gui_click] = on_gui_click
}

gui.add_handlers({
    on_button_export_clicked = on_button_export_clicked
})

return factoryplanner