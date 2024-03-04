module("zen", package.seeall)

local ui, gui, draw, map_edit = zen.Init("ui", "gui", "ui.draw", "map_edit")


ihook.Handler("zen.map_edit.OnButtonPress", "toolmode.Toggle", function(ply, but, in_key, bind_name, vw)
    if bind_name == "+menu_context" then
        map_edit.OpenToolMode()
    end
end)

ihook.Handler("zen.map_edit.OnButtonUnPress", "toolmode.Toggle", function(ply, but, in_key, bind_name, vw)
    if bind_name == "+menu_context" then
        map_edit.CloseToolMode()
    end
end)

function map_edit.OpenToolMode()
    map_edit.IsToolModeEnabled = true

    -- if IsValid(map_edit.pnlToolMode) then
    --     map_edit.pnlToolMode:SetVisible(true)
    --     return
    -- end

    map_edit.LoadToolMode()
end

function map_edit.CloseToolMode()
    map_edit.IsToolModeEnabled = false

    map_edit.pnlToolMode:SetVisible(false)
end


map_edit.tToolMode_PanelList = {}
-- Returns the currently selected map edit tool mode.
function map_edit.GetSelectedMode()
    return map_edit.SelectedToolMode
end

function map_edit.SetSelectedMode(mode)
    if map_edit.SelectedToolMode then
        local lastPanel = map_edit.tToolMode_PanelList[map_edit.SelectedToolMode]
        if IsValid(lastPanel) then
            lastPanel:SetSelected(false)
        end
    end

    map_edit.SelectedToolMode = mode
    local activePanel = map_edit.tToolMode_PanelList[mode]
    if IsValid(activePanel) then
        activePanel:SetSelected(true)
    end
end


function map_edit.LoadToolMode()
    if IsValid(map_edit.pnlToolMode) then map_edit.pnlToolMode:Remove() end

    map_edit.pnlToolMode = gui.Create("EditablePanel", nil, {
        wide = 50, "dock_left", "popup"
    }, "Tool Menu")
    map_edit.pnlToolMode.Paint = function(self, w, h)
        draw.Box(0,0,w,h,COLOR.BLACK)
    end

    local layout = gui.Create("DIconLayout", map_edit.pnlToolMode, {"dock_fill"})
    layout:SetSpaceY( 5 )
    layout:SetSpaceX( 5 )


    local function CreateMode(name, icon, DoClick)
        local newBtn = layout:Add("DButton")
        map_edit.tToolMode_PanelList[name] = newBtn
        newBtn:SetImage(icon)
        newBtn:SetText("")
        newBtn:SetCursor("hand")
        newBtn.Paint = function (self, w, h)
            -- draw.Box(0,0,w,h,COLOR.)
            if self:IsHovered() then
                draw.BoxOutlined(2,0,0,w,h,COLOR.W)
            end
        end

        local tsArray = {}
        local function AddInfo(data) table.insert(tsArray, data) end

        AddInfo{name, 10, 0, 0, COLOR.W}


        newBtn:zen_SetHelpTextArray(tsArray)
        -- newBtn:SetTex
        newBtn.DoClick = function ()
            map_edit.SetSelectedMode(name)

            if DoClick then
                DoClick()
            end
        end
        newBtn:SetSize(50,50)
    end

    CreateMode("Create Entity", "zen/map_edit/ent_create.png")
    CreateMode("Delete Entity", "zen/map_edit/delete.png")
    CreateMode("Create Box", "zen/map_edit/3d_cube.png")
    CreateMode("Hand", "zen/map_edit/hand.png")
    CreateMode("Zone", "zen/map_edit/activity_zone.png")
    CreateMode("Invisible Physics Zone", "zen/map_edit/frame_source.png")
    CreateMode("Perma Props", "zen/map_edit/save_as.png")
end
