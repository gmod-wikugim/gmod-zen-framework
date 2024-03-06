module("zen", package.seeall)

map_edit.t_ToolModeCache = map_edit.t_ToolModeCache or {}

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

    -- if IsValid(map_edit.pnlToolMenu_Base) then
    --     map_edit.pnlToolMenu_Base:SetVisible(true)
    --     return
    -- end

    map_edit.LoadToolMode()
end

function map_edit.CloseToolMode()
    map_edit.IsToolModeEnabled = false

    if IsValid(map_edit.pnlToolMenu_Base) then
        map_edit.pnlToolMenu_Base:SetVisible(false)
    end
end


map_edit.tToolMode_PanelList = {}
-- Returns the currently selected map edit tool mode.
function map_edit.GetSelectedMode()
    return map_edit.SelectedToolMode
end

-- 

function map_edit.tool_mode.GetInitializedTool(tool_id)
    if !map_edit.t_ToolModeCache[tool_id] then
        map_edit.t_ToolModeCache[tool_id] = map_edit.tool_mode.GetCopy(tool_id)
    end

    return map_edit.t_ToolModeCache[tool_id]
end

function map_edit.tool_mode.ClearInitializedTool(tool_id)
    if map_edit.t_ToolModeCache[tool_id] then
        map_edit.t_ToolModeCache[tool_id] = nil
    end
end

ihook.Listen("map_edit.tool_mode.Register", "engine:ClearPlayerTOOLCache", function(tool_id, TOOL)
    map_edit.tool_mode.ClearInitializedTool(tool_id)
end)

function map_edit.SetSelectedToolMode(tool_id)
    map_edit.SelectedToolMode = tool_id

    local TOOL = map_edit.tool_mode.GetInitializedTool(tool_id)

    if !TOOL.bInitialized then
        TOOL:Init()
        TOOL.bInitialized = true
    end

    ihook.Run("zen.map_edit.OnToolModeSelect", tool_id, TOOL)
end

function map_edit.GetActiveTool()
    local tool_id = map_edit.SelectedToolMode
    if !tool_id then return end
    local TOOL = map_edit.tool_mode.GetInitializedTool(tool_id)

    return TOOL
end

function map_edit.SendActiveToolAction(key, ...)
    local TOOL = map_edit.GetActiveTool()
    if !TOOL then return false end
    warn("Active Tool: ", TOOL.id, " action: ", key)

    -- Assert is function
    local func = TOOL[key]
    if !func then return false end

    assertFunction(func, "func")

    return func(TOOL,...)
end


function map_edit.LoadToolMode()
    if IsValid(map_edit.pnlToolMenu_Base) then map_edit.pnlToolMenu_Base:Remove() end

    map_edit.pnlToolMenu_Base = gui.Create("EditablePanel", nil, {
        "dock_fill", "popup"
    }, "Tool Menu Settings")

    local pnlModeSelect = gui.Create("EditablePanel", map_edit.pnlToolMenu_Base, {
        wide = 50, "dock_left"
    })
    pnlModeSelect.Paint = function(self, w, h)
        draw.Box(0,0,w,h,COLOR.BLACK)
    end

    local pnlModeSettins = gui.Create("EditablePanel", map_edit.pnlToolMenu_Base, {
        wide = 300, "dock_left"
    })

    local layout = gui.Create("DIconLayout", pnlModeSelect, {"dock_fill"})
    layout:SetSpaceY( 5 )
    layout:SetSpaceX( 5 )


    local function CreateNode(name, icon)
        local new_node = layout:Add("DButton")
        new_node:SetImage(icon)
        new_node:SetText("")
        new_node:SetCursor("hand")
        new_node.Paint = function (self, w, h)
            if self:IsHovered() then
                draw.BoxOutlined(2,0,0,w,h,COLOR.W)
            end
        end
        local tsArray = {}
        local function AddInfo(data) table.insert(tsArray, data) end
        AddInfo{name, 10, 0, 0, COLOR.W}
        new_node:zen_SetHelpTextArray(tsArray)
        new_node:SetSize(50,50)

        return new_node
    end

    local last_node, last_list
    local function CreateMode(tool_id)
        local TOOL = map_edit.tool_mode.Get(tool_id)
        local name = TOOL.Name
        local icon = TOOL.Icon
        local new_node = CreateNode(name, icon)
        local new_list = gui.Create("EditablePanel", pnlModeSettins, {"dock_fill", visible = false})
        local new_layout = gui.Create("DIconLayout", new_list, {"dock_fill"})

        map_edit.tToolMode_PanelList[tool_id] = {
            node = new_node,
            list = new_list,
            layout = new_layout
        }

        new_node.DoClick = function()
            if last_node and last_list then
                last_node:SetSelected(false)
                last_list:SetVisible(false)
            end

            new_node:SetSelected(true)
            new_list:SetVisible(true)

            last_node = new_node
            last_list = new_list

            map_edit.SetSelectedToolMode(tool_id)
        end

        return new_node, new_list, new_layout
    end

    for k, TOOL in pairs(map_edit.tool_mode.GetAll())  do
        CreateMode(TOOL.id)
    end
end

ihook.Listen("zen.map_edit.OnToolModeSelect", "engine:Setup", function(name, TOOL)
    ihook.Remove("zen.map_edit.Render", "engine:toool_mode:Draw")
    ihook.Remove("Think", "zen.map_edit.engine:toool_mode:Think")

    if TOOL.Render then
        local func = TOOL.Render
        ihook.Listen("zen.map_edit.Render", "engine:toool_mode:Draw", function(rendermode, priority, vw)
            func(TOOL, rendermode, priority, vw)
        end)

        print("Setup draw function for toolmode: ", TOOL.Name)
    end

    if TOOL.Think then
        local func = TOOL.Think
        ihook.Listen("Think", "zen.map_edit.engine:toool_mode:Think", function()
            func(TOOL)
        end)

        print("Setup think function for toolmode: ", TOOL.Name)
    end
end)

ihook.Listen("zen.map_edit.OnDisabled", "engine:tools:StopHooks", function ()
    ihook.Remove("zen.map_edit.Render", "engine:toool_mode:Draw")
    ihook.Remove("Think", "zen.map_edit.engine:toool_mode:Think")
end)

ihook.Handler("zen.map_edit.OnButtonPress", "menu.Toggle", function (ply, but, in_key, bind_name, vw)
    local prevent = map_edit.SendActiveToolAction("OnButtonPress", but, in_key, bind_name, vw)
    if prevent then return true end
end)

ihook.Handler("zen.map_edit.OnButtonUnPress", "menu.Toggle", function (ply, but, in_key, bind_name, vw)
    local prevent = map_edit.SendActiveToolAction("OnButtonUnPress", but, in_key, bind_name, vw)
    if prevent then return true end
end)