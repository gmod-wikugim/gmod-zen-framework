module("zen", package.seeall)

map_edit.t_PlayersTools = map_edit.t_PlayersTools or {}
local P_TOOLS = map_edit.t_PlayersTools

function map_edit.GetUserTool(ply, tool_id)
    if !P_TOOLS[ply] then P_TOOLS[ply] = {} end
    if !P_TOOLS[ply][tool_id] then
        local BASE_TOOL = map_edit.tool_mode.Get(tool_id)
        local BASE_META = getmetatable(BASE_TOOL)
        local USER_TOOL = setmetatable(table.Copy(BASE_TOOL), BASE_META)
        P_TOOLS[ply][tool_id] = USER_TOOL
    end

    return P_TOOLS[ply][tool_id]
end

ihook.Listen("map_edit.tool_mode.Register", "engine:ClearPlayerTOOLCache", function(tool_id, TOOL)
    for ply, tools in pairs(P_TOOLS) do
        if tools[tool_id] then
            tools[tool_id] = nil
        end
    end
end)

function map_edit.StartServerAction(ply, tool_id, data)
    local USER_TOOL = map_edit.GetUserTool(ply, tool_id)
    
    USER_TOOL:ServerAction(data)
end



nt.RegisterChannel("map_edit.tool_mode.ServerAction", nil, {
    types = {"string", "table"},
    OnRead = function(self, ply, tool_id, data)
        if not ply:zen_HasPerm("map_edit") then return false, "no has permission" end

        local TOOL = map_edit.tool_mode.Get(tool_id)
        if !TOOL then return false, "TOOL Don't exists" end

        if !TOOL.ServerAction then return false, "TOOL Don't have ServerAction" end

        data.ply = ply

        map_edit.StartServerAction(ply, tool_id, data)
    end,
})
