module("zen", package.seeall)

map_edit.t_ToolModeCache = map_edit.t_ToolModeCache or {}

ihook.Listen("zen.map_edit.OnButtonPress", "zen:map_edit:tool:engine:OpenContextMenu", function(ply, but, in_key, bind_name, char, isKeyFree)
    if isKeyFree and bind_name == "+menu_context" then
        map_edit.OpenToolMode()
        return true
    end
end)

ihook.Listen("zen.map_edit.OnButtonUnPress", "zen:map_edit:tool:engine:CloseContextMenu", function(ply, but, in_key, bind_name, char, isKeyFree)
    if bind_name == "+menu_context" then
        map_edit.CloseToolMode()
    end
end)


local function RenderHUD()
    local text_level = ui_y(-20)

    local TOOL = tool.GetActiveToolTable()

    if TOOL and !vgui.CursorVisible() then
        draw.Text("Tool: ".. language.GetPhrase(TOOL.Name), 18, 10, text_level, COLOR.W, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, COLOR.BLACK)
        text_level = text_level - 10
    end
end

ihook.Listen("zen.map_edit.Render", "engine:tool:HUDInfo", function(rendermode, priority)
    if rendermode != RENDER_2D then return end
    if priority != RENDER_POST then return end

    RenderHUD()
end)

function map_edit.OpenToolMode()
    map_edit.IsToolModeEnabled = true

    if IsValid(map_edit.pnlFather) then
        map_edit.pnlFather:SetVisible(true)
    else
        map_edit.LoadToolMode()
    end
end

function map_edit.CloseToolMode()
    map_edit.IsToolModeEnabled = false

    if IsValid(map_edit.pnlFather) then
        map_edit.pnlFather:SetVisible(false)
    end
end


map_edit.tToolMode_PanelList = {}
-- Returns the currently selected map edit tool mode.
function map_edit.GetSelectedMode()
    return tool.ms_ActiveTool
end

--

function tool.GetInitializedTool(tool_id)
    if !map_edit.t_ToolModeCache[tool_id] then
        map_edit.t_ToolModeCache[tool_id] = tool.GetCopy(tool_id)
    end

    return map_edit.t_ToolModeCache[tool_id]
end

function tool.ActivateLastTool()
    -- Activating last active tools
    local tool_id = map_edit.GetSelectedMode()
    if tool_id then
        map_edit.SetSelectedToolMode(tool_id)
    end
end

function tool.DeactivateLastTool()
    local TOOL = tool.GetActiveToolTable()
    if TOOL then
        TOOL:_Die()
    end
end

function tool.ClearInitializedTool(tool_id)
    local TOOL = map_edit.t_ToolModeCache[tool_id]
    if TOOL then
        if TOOL._Die then TOOL:_Die() end
        map_edit.t_ToolModeCache[tool_id] = nil
    end

    tool.ActivateLastTool()
end

ihook.Listen("tool.Updated", "engine:ClearPlayerTOOLCache", function(tool_id, TOOL)
    print("Tool updated: ", tool_id)
    tool.ClearInitializedTool(tool_id)
end)
ihook.Listen("tool.Register", "engine:ClearPlayerTOOLCache", function(tool_id, TOOL)
    tool.ClearInitializedTool(tool_id)
end)

function map_edit.SetSelectedToolMode(tool_id)
    local ACTIVE_TOOL = tool.GetActiveToolTable()
    if ACTIVE_TOOL and ACTIVE_TOOL.id != tool_id then
        if ACTIVE_TOOL._UnSelected then ACTIVE_TOOL:_UnSelected() end
    end

    tool.ms_ActiveTool = tool_id

    local TOOL = tool.GetInitializedTool(tool_id)
    if TOOL._Selected then TOOL:_Selected() end

    ihook.Run("zen.map_edit.OnToolModeSelect", tool_id, TOOL)
end

---@return zen_TOOL
function tool.GetActiveToolTable()
    local tool_id = tool.ms_ActiveTool
    if !tool_id then return end
    local TOOL = tool.GetInitializedTool(tool_id)

    return TOOL
end

function map_edit.SendActiveToolAction(key, ...)
    local TOOL = tool.GetActiveToolTable()
    if !TOOL then return end
    warn("Active Tool: ", TOOL.id, " action: ", key)

    -- Assert is function
    local func = TOOL[key]
    if !func then return end

    assertFunction(func, "func")

    return func(TOOL,...)
end

function map_edit.LoadToolMode()
    if IsValid(map_edit.pnlFather) then map_edit.pnlFather:Remove() end

    map_edit.pnlFather = gui.Create("EditablePanel", nil, {
        "dock_fill", "popup"
    })
    hook.Add("zen.map_edit.OnDisabled", map_edit.pnlFather, function(self)
        if IsValid(self) then self:Remove() end
    end)


    local pnlNavigatePanel = map_edit.pnlFather:zen_AddStyled("base", {
        tall = 20, "dock_top", cc = {
            Paint = function(this, w, h)
                draw.Box(0,0,w,h,COLOR.FILL_20)

                draw.Line(0, h-1, w, h-1, COLOR.WHITE)
            end
        }
    })


    local pnlViewPanels = pnlNavigatePanel:zen_AddStyled("text_button", {
        "dock_left", text = "view", "size_content_x", cc = {
            DoClick = function(this)
                print("DoClick")
            end
        }
    })

    local pnlContent = map_edit.pnlFather:zen_AddStyled("base", {
        "dock_fill"
    })

    local panelSelectTool_Holder = pnlContent:zen_AddStyled("free", {
        size = {150,  ScrH()}, title = "Tools", pos = {0, 0}, cc = {
            Paint = function(self, w, h)
                draw.Box(0,0,w,h,COLOR.FILL_30)
            end
        }
    })
    local panelSelectTool_List = panelSelectTool_Holder:zen_AddStyled("scroll_list", {"dock_fill"})

    local panelToolMenu_Holder = pnlContent:zen_AddStyled("free", {
        size = {250,  500}, title = "ToolSettings", pos = {150, 0}, cc = {
            Paint = function(self, w, h)
                draw.Box(0,0,w,h,COLOR.FILL_60)
            end
        }
    })
    local panelToolMenu_List = panelToolMenu_Holder:zen_AddStyled("scroll_list", {"dock_fill"})


    local function CreateToolMenu(TOOL, STOOL)
        panelToolMenu_List:Clear()
        local ControlPanel = panelToolMenu_List:zen_Add("ControlPanel", {"dock_fill"})
        ControlPanel:InvalidateLayout(true)
        ControlPanel:SetName(TOOL.Name)

        if STOOL.BuildCPanel then
            STOOL.BuildCPanel(ControlPanel)
        end

        panelToolMenu_List:InvalidateLayout(true)
    end

    local mt_Categories = {}

    ---@param category_name string
    local function GetCategory(category_name)
        if IsValid(mt_Categories[category_name]) then return mt_Categories[category_name] end

        local pnlContainer = panelSelectTool_List:zen_AddStyled("content", {
            "dock_top", margin = {0,0,0,0},
        })
        mt_Categories[category_name] = pnlContainer


        local pnlText = pnlContainer:zen_AddStyled("text", {
            text = category_name, font = ui.ffont(16), "dock_top", margin = {0,0,0,0}, cc = {
                Paint = function(this, w, h)
                    draw.Box(0,0,w,h,COLOR.FILL_40)
                end
            }
        })

        return pnlContainer
    end

    ---@param TOOL zen_TOOL
    local function CreateMode(TOOL)
        local pnlContainer = GetCategory(TOOL.Category)

        local pnlName = pnlContainer:zen_AddStyled("text_button", {
            "dock_top", tall = 20, text = TOOL.Name or TOOL.id, font = ui.ffont(14), cursor = "hand", "mouse_input", z_pos = TOOL.sortID, cc = {
                -- Paint = function(this, w, h)
                --     draw.Box(0,0,w,h,COLOR.FILL_40)
                -- end,
                DoClick = function(this)
                    if !TOOL.IsSandBoxTool then return end

                    panelToolMenu_Holder:SetTitle(TOOL.Name)

                    map_edit.SetSelectedToolMode(TOOL.id)

                    local STOOL = TOOL.STOOL

                    CreateToolMenu(TOOL, STOOL)

                    PrintTable(STOOL)
                end
            }
        })
    end


    for k, TOOL in pairs(tool.GetAll())  do
        CreateMode(TOOL)
    end

    local pnlDrawSettings = gui.CreateStyled("free", pnlContent, {
        pos = {ScrW() - 300, 200},
        size = {200, 500},
        cc = {
            colorBG = Color(30,30,30,255),
            Paint = function(this, w, h)
                draw.Box(0,0,w,h,this.colorBG)
            end
        }
    })

    local function LoadFeatures()
        local feature_list = feature.GetList()
        for k, feature_name in pairs(feature_list) do
            if !feature_name:find("map_edit.") then continue end

            local FEATURE = feature.GetInitialized(feature_name)

            local pnlHolder = pnlDrawSettings:zen_AddStyled("check_box_label", {
                "dock_top", text = FEATURE.name, value = FEATURE:IsActive(), cc = {
                    OnChange = function(this, bNewValue)
                        if bNewValue then
                            FEATURE:Enable()
                        else
                            FEATURE:Disable()
                        end
                    end
                }
            })
        end
    end


    LoadFeatures()
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
    tool.DeactivateLastTool()
end)

ihook.Listen("zen.map_edit.OnEnabled", "engine:tools:StopHooks", function ()
    tool.ActivateLastTool()
end)


ihook.Listen("zen.map_edit.OnButtonPress", "zen:map_edit:tool:engine:TOOL:RunButtonPress", function (ply, but, in_key, bind_name, vw)
    map_edit.SendActiveToolAction("OnButtonPress", but, in_key, bind_name, vw)
end)

ihook.Listen("zen.map_edit.OnButtonUnPress", "zen:map_edit:tool:engine:TOOL:RunButtonUnPress", function (ply, but, in_key, bind_name, vw)
    map_edit.SendActiveToolAction("OnButtonUnPress", but, in_key, bind_name, vw)
end)