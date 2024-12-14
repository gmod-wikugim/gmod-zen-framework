module("zen", package.seeall)


function map_edit.ToggleMenu()
    if map_edit.IsMenuEnabled then
        map_edit.CloseMenu()
    else
        if vgui.CursorVisible() then return end
        map_edit.OpenMenu()
    end
end

ihook.Handler("zen.map_edit.OnButtonPress", "engine:map_edit_spawnmenu:menu:OnButtonPress:ToogleMenu", function (ply, but, in_key, bind_name, char, isKeyFree)
    if bind_name == "+menu" then
        if map_edit.IsMenuEnabled then
            map_edit.CloseMenu()
        else
            map_edit.OpenMenu()
        end
        return true
    end
end)

function map_edit.OpenMenu()
    map_edit.IsMenuEnabled = true

    if IsValid(zen.zspawn_menu ) then
        zen.zspawn_menu:Remove()
    end
    
    zen.zspawn_menu = gui.Create("zspawn_menu")
    zen.zspawn_menu:SetSize(1800, 1000)
    zen.zspawn_menu:Center()

    -- map_edit.LoadMenu()
end

function map_edit.CloseMenu()
    map_edit.IsMenuEnabled = false

    if IsValid(zen.zspawn_menu ) then
        zen.zspawn_menu:Remove()
    end
end

map_edit.tSheets = map_edit.tSheets or {}
function map_edit.RegisterSheet(META)
    assert(istable(META), "SHEET must be a table")
    assert(isstring(META.id), "SHEET.id must be a string")
    assert(isstring(META.Name), "SHEET.Name must be a string")
    assert(isfunction(META.Init), "SHEET.Init must be a function")

    local NEW_SHEET = {}
    setmetatable(NEW_SHEET, {__index = META})
    map_edit.tSheets[NEW_SHEET.id] = NEW_SHEET

    META:Init()
end


function map_edit.LoadMenu()
    if _CFG.bZen_Developer and IsValid(map_edit.pnlMenu) then map_edit.pnlMenu:Remove() end


    map_edit.pnlMenu = gui.Create("DFrame", nil, {
        size = {ScrW()-50, ScrH()-100}, "center", title = "Zen Mapper", "popup",
    }, "Zen Mapper")

    map_edit.pnlMenu.Paint = function(self, w, h)
        draw.BoxOutlined(2, 0, 0, w, h, COLOR.W)
        draw.WhiteBGAlpha(0,0,w,h, 50)
    end

    local sheet = gui.Create("DPropertySheet", map_edit.pnlMenu, {
        "dock_fill", "-paint"
    })

    local function CreateSheet(SHEET)
        local pnlContent = gui.Create("EditablePanel", sheet, {})
        pnlContent.PaintOver = function(self, w, h)
            draw.BoxOutlined(1, 0, 0, w, h, COLOR.W)
        end
        local sheet = sheet:AddSheet( SHEET.Name, pnlContent, SHEET.Icon )
        SHEET:Create(pnlContent)
        sheet.Tab:SetTextColor(COLOR.BLACK)
        gui.ApplyParams(sheet.Tab, {"-paint"})
    end

    for k, SHEET in pairs(map_edit.tSheets) do
        CreateSheet(SHEET)
    end

    -- do
    --     local sheet_props = gui.Create("EditablePanel", sheet, {})
    --     sheet:AddSheet( "Props", sheet_props, "icon16/brick.png" )
    --     map_edit.LoadProps(sheet_props)
    -- end

    -- do
    --     local sheet_entity = gui.Create("EditablePanel", sheet, {})
    --     sheet:AddSheet( "Entity", sheet_entity, "icon16/bricks.png" )
    --     map_edit.LoadEntities(sheet_entity)
    -- end

end
