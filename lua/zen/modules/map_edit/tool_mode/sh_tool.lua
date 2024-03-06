module("zen", package.seeall)

map_edit.tool_mode = map_edit.tool_mode or {}

-- Table with all registered map edit tools.
map_edit.tool_mode.mt_tool_list = map_edit.tool_mode.mt_tool_list or {}

---@param TOOL zen_TOOL
function map_edit.tool_mode.Register(TOOL)
    assertStringNice(TOOL.id, "No ID specified for tool.")
    assertStringNice(TOOL.Name, "No Name specified for tool.")
    assertFunction(TOOL.Init, "No Init specified for tool.")

    -- Check if all strings are set.
    if TOOL.Description then assertStringNice(TOOL.Description, "No Description specified for tool.") end
    if TOOL.Icon then assertStringNice(TOOL.Icon, "No Icon specified for tool.") end

    -- Check if all functions are set.  
    if TOOL.ServerAction then assertFunction(TOOL.ServerAction, "No FirstAction specified for tool.") end
    if TOOL.Reload then assertFunction(TOOL.Reload, "No Reload specified for tool.") end
    if TOOL.HUDDraw then assertFunction(TOOL.HUDDraw, "No HUDDraw specified for tool.") end
    if TOOL.OnButtonPress then assertFunction(TOOL.OnButtonPress, "No OnButtonPress specified for tool.") end
    if TOOL.OnButtonUnPress then assertFunction(TOOL.OnButtonUnPress, "No OnButtonUnPress specified for tool.") end

    setmetatable(TOOL, map_edit.TOOL_META)
    map_edit.tool_mode.mt_tool_list[TOOL.id] = TOOL

    ihook.Run("map_edit.tool_mode.Register", TOOL.id, TOOL)

    return TOOL
end

-- Function getting the tool with the given id.
---@return zen_TOOL
function map_edit.tool_mode.Get(id)
    return map_edit.tool_mode.mt_tool_list[id]
end

function map_edit.tool_mode.GetCopy(id)
    local BASE_TOOL = map_edit.tool_mode.Get(id)
    assertTable(BASE_TOOL, "BASE_TOOL")
    local BASE_META = getmetatable(BASE_TOOL)
    local USER_TOOL = setmetatable(table.Copy(BASE_TOOL), BASE_META)
    return USER_TOOL
end

-- Function to get all registered tools.
function map_edit.tool_mode.GetAll()
    return map_edit.tool_mode.mt_tool_list
end
