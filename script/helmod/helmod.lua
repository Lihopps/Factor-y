local gui = require("__flib__.gui-lite")
local util = require("script.util")
local helmod_util = require("script.helmod.helmod_util")


--- @param e EventData.on_gui_click
local function on_button_clicked(e)
    helmod_util.create_bp(e)
end

local helmod_comp = {}

local function on_gui_click(e)
    if helmod_comp.is_button_handler(e.element.name) and e.element.get_mod() == "helmod" then
        helmod_comp.add_button(e)
    end
end

--- @param e EventData.on_gui_click
function helmod_comp.add_button(e)
    local player = game.players[e.player_index]
    if not player then return end
    local window = player.gui.screen.HMDownload
    if not window then return end
    local upload = window.content_panel.upload
    if not upload then return end
    local factory_text = upload["data-text"].text
    local bouton = {
        type = "button",
        caption = {"gui.exporttofactory"},
        style = "helmod_button_default",
        tags = { text = factory_text },
        handler = { [defines.events.on_gui_click] = on_button_clicked },
    }
    gui.add(upload, bouton)
end

function helmod_comp.is_button_handler(name)
    --"HMDownload=OPEN=model_2=upload"
    local array = util.split(name, "=")
    if #array ~= 4 then return false end
    if array[1] == "HMDownload" and array[2] == "OPEN" and array[4] == "upload" then
        return true
    end
    return false
end

helmod_comp.events = {
    [defines.events.on_gui_click] = on_gui_click
}

gui.add_handlers({
    on_button_clicked = on_button_clicked
})

return helmod_comp
