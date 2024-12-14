module("zen", package.seeall)

---@class zen.map_edit.tool
tool = _GET("map_edit.tool")

-- Table with all registered map edit tools.
tool.mt_tool_list = tool.mt_tool_list or {}

---@param id string
---@return zen_TOOL
local function CreateEmptyTool(id)

end


---@param id string
---@return zen_TOOL
function tool.Init(id)
    if !tool.mt_tool_list[id] then
        tool.Register({id = id})
    else
        timer.Simple(0, function()
            ihook.Run("tool.Updated", id)
        end)
    end


    return tool.mt_tool_list[id]
end

---@param TOOL zen_TOOL
function tool.Register(TOOL)
    assertStringNice(TOOL.id, "No ID specified for tool.")

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
    tool.mt_tool_list[TOOL.id] = TOOL

    TOOL.Category = TOOL.Category or "default"
    TOOL.sortID = TOOL.sortID or 0

    ihook.Run("tool.Register", TOOL.id, TOOL)

    return TOOL
end

-- Function getting the tool with the given id.
---@return zen_TOOL
function tool.Get(id)
    return tool.mt_tool_list[id]
end

function tool.GetCopy(id)
    local BASE_TOOL = tool.Get(id)
    assertTable(BASE_TOOL, "BASE_TOOL")
    local BASE_META = getmetatable(BASE_TOOL)
    local USER_TOOL = setmetatable(table.Copy(BASE_TOOL), BASE_META)

    if USER_TOOL._Created then
        USER_TOOL:_Created()
    end

    return USER_TOOL
end

-- Function to get all registered tools.
function tool.GetAll()
    return tool.mt_tool_list
end
