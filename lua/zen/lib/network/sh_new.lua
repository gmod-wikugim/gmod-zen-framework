module("zen", package.seeall)

nt.new = nt.new or {}
nt.unique = nt.unique or {}

local rawset = rawset
local rawget = rawget
local next = next

---@class zen.network.new.table
local NETWORK_TABLE_META = {}

---@package
NETWORK_TABLE_META.__tostring = function(self) return "Network table (" .. #self .. ")" end

---@package
NETWORK_TABLE_META.__index = NETWORK_TABLE_META

---@package
NETWORK_TABLE_META.__newindex = NETWORK_TABLE_META

---@package
NETWORK_TABLE_META.__len = function(self)
    return self.mb_count
end

---@package
NETWORK_TABLE_META.__pairs = function(self, key)
    return next(self.t_Data, key)
end

---@package
NETWORK_TABLE_META.__ipairs = function(self, key)
    return next(self.t_Data, key)
end

---@package
function NETWORK_TABLE_META:Init()
    self.mb_count = 0
    self.t_Data = {}
end

---@param key string|number
---@param value any
function NETWORK_TABLE_META:Set(key, value)
    local last_value = self.t_Data[key]

    self.t_Data[key] = value

    if value == nil and last_value != nil then
        self.mb_count = self.mb_count - 1
    elseif value != nil and last_value == nil then
        self.mb_count = self.mb_count + 1
    end
end

---@param key string|number
---@param default? any
---@return any
function NETWORK_TABLE_META:Get(key, default)
    local value = self.t_Data[key]

    if value == nil and default then
        self.t_Data[key] = default
        return default
    end

    return value
end



---@return zen.network.new.table nt_table
function nt.new.table()
    local NEW_TABLE = newproxy(true)

    debug.setmetatable(NEW_TABLE, NETWORK_TABLE_META)
    NEW_TABLE:Init()

    return NEW_TABLE
end

nt.mt_UniqueTables = nt.mt_UniqueTables or {}

---@param uniqueID string
---@return zen.network.new.table nt_table
function nt.unique.table(uniqueID)
    if !nt.mt_UniqueTables[uniqueID] then
        nt.mt_UniqueTables[uniqueID] = nt.new.table()
    end

    return nt.mt_UniqueTables[uniqueID]
end