module("zen", package.seeall)

player_data = _GET("player_data")

player_data.mt_PlayerSessionData = player_data.mt_PlayerSessionData or {}
local PLYS_SESSION_DATA = player_data.mt_PlayerSessionData

player_data.mt_AutoPlayerTables = player_data.mt_AutoPlayerTables or {}
local AUTO_PLAYER_TABLES = player_data.mt_AutoPlayerTables

player_data.mt_OnInitialize = player_data.mt_OnInitialize or {}
player_data.mt_OnClear = player_data.mt_OnClear or {}

_LISTEN("nt.RegisterChannels", "player_data", function()

    nt.RegisterChannel("player_data.Initialize", nil, {
        types = {"player"},
        OnRead = function(self, ply, ply)
            if CLIENT then
                player_data.Initialize(ply)
            end
        end,
    })

    nt.RegisterChannel("player_data.Clear", nil, {
        types = {"player"},
        OnRead = function(self, ply, ply)
            if CLIENT then
                player_data.Clear(ply)
            end
        end,
    })

end)


--------------------
---- Initialize ----
--------------------

---@param ply Player
function player_data.Initialize(ply)
    for uniqueID, callback in pairs(player_data.mt_OnInitialize) do
        xpcall(callback, ErrorNoHaltWithStack, callback, ply)
    end

    if SERVER then
        nt.SendToChannel("player_data.Initialize", nil, ply)
    end

    PLYS_SESSION_DATA[ply] = {}
end

---@param uniqueID string
---@param callback fun(ply:Player)
function player_data.OnInitialize(uniqueID, callback)
    player_data.mt_OnInitialize[uniqueID] = callback
end


--------------------
------ Clear -------
--------------------


---@param ply Player
function player_data.Clear(ply)
    for uniqueID, callback in pairs(player_data.mt_OnClear) do
        xpcall(callback, ErrorNoHaltWithStack, callback, ply)
    end

    if SERVER then
        nt.SendToChannel("player_data.Clear", nil, ply)
    end

    for ply in pairs(PLYS_SESSION_DATA) do
        PLYS_SESSION_DATA[ply] = nil
    end
end


---@param uniqueID string
---@param callback fun(ply:Player)
function player_data.OnClear(uniqueID, callback)
    player_data.mt_OnClear[uniqueID] = callback
end

--------------------
---- PlayerData ----
--------------------

---@param ply Player
---@return any
function player_data.GetPlayerData(ply, key)
    if !PLYS_SESSION_DATA[ply] then PLYS_SESSION_DATA[ply] = {} end

    return PLYS_SESSION_DATA[ply][key]
end
_PLY_GET = player_data.GetPlayerData

---@param ply Player
---@param key string|number
---@param value any
function player_data.SetPlayerData(ply, key, value)
    if !PLYS_SESSION_DATA[ply] then PLYS_SESSION_DATA[ply] = {} end

    PLYS_SESSION_DATA[ply][key] = value
end
_PLY_SET = player_data.SetPlayerData


--------------------
---- Table Data ----
--------------------

---@class player_data.AutoTable.get: function
---@field ply Player
---@field key string|number
---@return any

---@class player_data.AutoTable.set: function
---@field ply Player
---@field key string|number
---@field value any

---@param uniqueID string
function player_data.AutoTable(uniqueID)
    if !AUTO_PLAYER_TABLES[uniqueID] then
        AUTO_PLAYER_TABLES[uniqueID] = {}
    end

    local AUTO_TABLE = AUTO_PLAYER_TABLES[uniqueID]



    local rawget = rawget
    local rawset = rawset

    ---@param ply Player
    ---@param key string|number
    ---@return any
    local function get(ply, key)
        local PLY_DATA = rawget(AUTO_TABLE, ply)
        if !PLY_DATA then return end

        return rawget(PLY_DATA, key)
    end


    ---@param ply Player
    ---@param key string|number
    ---@param value any
    local function set(ply, key, value)
        local PLY_DATA = rawget(AUTO_TABLE, ply)
        if !PLY_DATA then
            PLY_DATA = {}
            rawset(AUTO_TABLE, ply, PLY_DATA)
        end

        return rawset(PLY_DATA, key, value)
    end

    ---@param ply Player
    ---@return table<string|number, any>
    local function get_player_data(ply)
        local PLY_DATA = rawget(AUTO_TABLE, ply)
        if !PLY_DATA then
            PLY_DATA = {}
            rawset(AUTO_TABLE, ply, PLY_DATA)
        end

        return PLY_DATA
    end

    return get, set, get_player_data
end


