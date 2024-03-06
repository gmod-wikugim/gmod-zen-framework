module("zen", package.seeall)

---@class zen_TOOL
---@field id string
---@field Name string
---@field Description? string
---@field Icon? string
---@field ServerAction? fun(self:zen_TOOL, data:table)
---@field Reload? fun(self:zen_TOOL)
---@field Init fun(self:zen_TOOL)
---@field Render? fun(self:zen_TOOL, rendermode:number, priority:number, vw:table)
---@field CallServerAction? fun(self:zen_TOOL, data:table)
---@field OnButtonPress? fun(self:zen_TOOL, data:table)
---@field OnButtonUnPress? fun(self:zen_TOOL, data:table)

map_edit.TOOL_META = map_edit.TOOL_META or {}

local META = map_edit.TOOL_META
META.__index = META

function META:_Setup()

    if self.Init then
        self:Init(self)
    end
end

function META:CallServerAction(data)
    assertTable(data)

    nt.Send("map_edit.tool_mode.ServerAction", {"string", "table"}, {self.id, data})
end