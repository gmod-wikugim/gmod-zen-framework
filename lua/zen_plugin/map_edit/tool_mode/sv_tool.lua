module("zen", package.seeall)

map_edit.t_PlayersTools = map_edit.t_PlayersTools or {}
local P_TOOLS = map_edit.t_PlayersTools

function map_edit.GetUserTool(ply, tool_id)
    if !P_TOOLS[ply] then P_TOOLS[ply] = {} end
    if !P_TOOLS[ply][tool_id] then
        P_TOOLS[ply][tool_id] = tool.GetCopy(tool_id)
    end

    return P_TOOLS[ply][tool_id]
end

local function ClearTool(tool_id)
    for ply, tools in pairs(P_TOOLS) do
        local TOOL = tools[tool_id]
        if TOOL then
            if TOOL._Die then TOOL:_Die() end
            tools[tool_id] = nil
        end
    end
end

ihook.Listen("tool.Updated", "engine:ClearPlayerTOOLCache", function(tool_id, TOOL)
    ClearTool(tool_id)
end)

ihook.Listen("tool.Register", "engine:ClearPlayerTOOLCache", function(tool_id, TOOL)
    ClearTool(tool_id)
end)

function map_edit.StartServerAction(ply, tool_id, data)
    local USER_TOOL = map_edit.GetUserTool(ply, tool_id)

    USER_TOOL:ServerAction(data, ply)
end



nt.RegisterChannel("tool.ServerAction", nil, {
    types = {"string", "table"},
    OnRead = function(self, ply, tool_id, data)
        if not ply:zen_HasPerm("map_edit") then return false, "no has permission" end

        local TOOL = tool.Get(tool_id)
        if !TOOL then return false, "TOOL Don't exists" end

        if !TOOL.ServerAction then return false, "TOOL Don't have ServerAction" end

        data.ply = ply

        map_edit.StartServerAction(ply, tool_id, data)
    end,
})
