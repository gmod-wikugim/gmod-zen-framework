module("zen", package.seeall)

local ui, gui, map_edit = zen.Init("ui", "gui", "map_edit")


function map_edit.ToggleMenu()
    if map_edit.IsMenuEnabled then
        map_edit.CloseMenu()
    else
        map_edit.OpenMenu()
    end
end

ihook.Handler("zen.map_edit.OnButtonUnPress", "menu.Toggle", function (ply, but, in_key, bind_name, vw)
    if bind_name == "+menu" then
        map_edit.ToggleMenu()
    end
end)

function map_edit.OpenMenu()
    map_edit.IsMenuEnabled = true

    map_edit.LoadMenu()
end

function map_edit.CloseMenu()
    map_edit.IsMenuEnabled = false

    map_edit.pnlMenu:Remove()
end

function map_edit.LoadMenu()
    if IsValid(map_edit.pnlMenu) then map_edit.pnlMenu:Remove() end


    map_edit.pnlMenu = gui.Create("DFrame", nil, {
        size = {ScrW()-50, ScrH()-100}, "center", title = "Zen Mapper", "popup"
    }, "Zen Mapper")


    local sheet = gui.Create("DPropertySheet", map_edit.pnlMenu, {
        "dock_fill"
    })

    local sheet_props = gui.Create("EditablePanel", sheet, {})
    sheet:AddSheet( "Props", sheet_props, "icon16/brick.png" )

    map_edit.LoadProps(sheet_props)
end
