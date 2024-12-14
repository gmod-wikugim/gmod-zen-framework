module("zen", package.seeall)

---@class zen_TOOL
---@field id string
---@field Name string
---@field Category? string
---@field Description? string
---@field Icon? string
---@field sortID? number
---@field ServerAction? fun(self, data:table, who:Player)
---@field Reload? fun(self)
---@field Init fun(self)
---@field Render? fun(self, rendermode:number, priority:number, vw:table)
---@field CallServerAction? fun(self, data:table)
---@field OnButtonPress? fun(self, but:number, inkey:number, bind_name:string)
---@field OnButtonUnPress? fun(self, but:number, inkey:number, bind_name:string)
---@field OnDie? fun(self) Called when the tool data is destroyed
---@field OnCreated? fun(self) Called when the tool copied to use!
---@field DisableHooks? fun(self) Use can use it to safety disable your hooks
---@field EnableHooks? fun(self) Use can use it to safety enabled your hooks
---@field OnActivate? fun(self) Called when the tool is selected
---@field OnDeactivate? fun(self) Called when the tool is deselected
---@field Think? fun(self)


map_edit.TOOL_META = map_edit.TOOL_META or {}

local META = map_edit.TOOL_META
META.__index = META

function META:CallServerAction(data)
    assertTable(data)

    nt.Send("tool.ServerAction", {"string", "table"}, {self.id, data})
end

function META:_Die()
    if self.OnDie then self:OnDie() end
    if self.DisableHooks then self:DisableHooks() end
end

function META:_Created()
    if self.OnCreated then self:OnCreated() end
end

function META:_Selected()
    if self.EnableHooks then self:EnableHooks() end
    if self.OnActivate then self:OnActivate() end
end

function META:_UnSelected()
    if self.DisableHooks then self:DisableHooks() end
    if self.OnDeactivate then self:OnDeactivate() end
end