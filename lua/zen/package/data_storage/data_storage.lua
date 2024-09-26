scp_code.data_storage = scp_code.data_storage or {}
scp_code.data_storage.mt_Structures = scp_code.data_storage.mt_Structures or {}
scp_code.data_storage.mt_Providers = scp_code.data_storage.mt_Providers or {}
scp_code.data_storage.mt_WaitInit = scp_code.data_storage.mt_WaitInit or {}

--- Print Message to Console, If linux it will use bash colors
function scp_code.data_storage.ServerLog(...)
    if system.IsLinux() then
        local args = {...}
        local text = ""

        -- Add blue '|' sumbol and next white color
        text = text .. "\27[38;2;0;0;255m| \27[38;2;255;255;255m"

        for k, v in pairs(args) do
            if istable(v) then
                text = text .. string.format("\27[38;2;%s;%s;%sm", v.r, v.g, v.b)
            else
                text = text .. v
            end
        end

        text = text .. "\27[0m"

        print(text)
    else
        print(...)
    end
end
local ServerLog = scp_code.data_storage.ServerLog

scp_code.ConfigListener("database", "core.database.initialized", function(CFG)
    if MySQLite.databaseObject then
        if MySQLite.isMySQL() then
            ServerLog("Disconnecting from database..")
            MySQLite.databaseObject:disconnect()
        end
    end

    ServerLog("Connecting to database..")

    scp_code.DB = MySQLite.initialize(CFG)
end)


hook.Add("DatabaseInitialized", "core.database", function()
    local Provider = MySQLite.isMySQL() and "MySQL" or "SQLite"

    ServerLog("--------------------")
    ServerLog(Color(0,255,0), "DataBase Connected, Provider: " .. Provider)
    ServerLog("--------------------")


    hook.Run("scp_code.DatabaseInitialized")
end)

local color_good = Color(0, 255, 0)
local color_bad = Color(255, 0, 0)
local color_warning = Color(255, 255, 0)

local color_table = Color(0, 125, 255)
local color_field = Color(255, 255, 0)

---@enum (key) scp_code.data_storage.item.type
scp_code.data_storage.item_type = {
    NULL = 0,
    BOOLEAN = 1,
    TEXT = 2,
    NUMBER = 3,
    ARRAY = 4,
    TABLE = 5,
    VECTOR = 6,
    ANGLE = 7,
}

local TYPE_IGNORE_LENGTH = {
    ["NULL"] = true,
    ["BOOLEAN"] = true,
    ["ARRAY"] = true,
    ["TABLE"] = true,
}

---@class scp_code.data_storage.key
---@field name string
---@field type scp_code.data_storage.item.type
---@field id? string
---@field length? number
---@field default? string|number
---@field optional? boolean|false

---@class scp_code.data_storage.value
---@field name string
---@field type scp_code.data_storage.item.type
---@field id? string
---@field length? number
---@field default? string|number

---@class scp_code.data_storage.inputFields
---@field keys table<string, scp_code.data_storage.key>
---@field values table<string, scp_code.data_storage.value>

---@class scp_code.data_storage.struct
---@field uniqueID string
---@field fields table<string, scp_code.data_storage.key|scp_code.data_storage.value>
---@field keys table<string, scp_code.data_storage.key>
---@field values table<string, scp_code.data_storage.value>
local META = {}
META.__index = META

function META:GetProvider()
    if MySQLite then
        if MySQLite.isMySQL() then
            return "MySQL"
        else
            return "SQLite"
        end
    end

    return "SQLite"
end

function META:IsProvider(provider)
    return self:GetProvider() == provider
end

function META:CallProviderFunction(funcName, ...)
    local provider = self:GetProvider()
    local providerData = scp_code.data_storage.mt_Providers[provider]

    if providerData then
        local func = providerData[funcName]
        if func then
            return func(self, ...)
        else
            ServerLog("Provider function not found: ", funcName, " in ", provider)
        end
    else
        error("Provider not found: " .. provider)
    end
end

local color_table = Color(0, 125, 255)

function META:ServerLog(...)
    ServerLog(color_table, self.uniqueID, color_white, " (", color_table, self:GetProvider(), color_white, ")> ", ...)
end

function META:ErrorLog(...)
    local debug_trace = debug.traceback("", 2)
    ServerLog(color_table, self.uniqueID, color_white, " (", color_table, self:GetProvider(), color_white, ")> ", color_bad, ...)
    local pathes_only = string.Explode("\n", debug_trace)
    table.remove(pathes_only, 1)
    table.remove(pathes_only, 1)
    local path_only = table.concat(pathes_only, "\n")

    ServerLog(path_only)
end

function META:WarningLog(...)
    ServerLog(color_table, self.uniqueID, color_white, " (", color_table, self:GetProvider(), color_white, ")> ", color_warning, ...)
end


---@param callback fun(bExists: boolean)
function META:Provider_IsObjectExists(callback)
    self:CallProviderFunction("IsObjectExists", callback)
end

---@param callback? fun()
function META:Provider_CreateObject(callback)
    self:CallProviderFunction("CreateObject", callback)
end

---@param inspectTarget? string
---@param callback? fun()
function META:Provider_InspectObject(inspectTarget, callback)
    self:CallProviderFunction("InspectObject", inspectTarget, callback)
end

function META:OnObjectReady()
    scp_code.data_storage.RunObjectInit(self.uniqueID)
end


function META:InitObject()

    if !scp_code.data_storage.bDatabaseReady then
        ServerLog("DataStorage registered: " .. self.uniqueID)
        return
    end

    self:Provider_IsObjectExists(function(bExists)
        if bExists then
            self:ServerLog("Table exists, inspecting..")
            self:Provider_InspectObject(nil, function()
                self:OnObjectReady()
            end)
        else
            self:ServerLog("Table not exists, creating..")

            self:Provider_CreateObject(function()
                self:Provider_InspectObject(nil, function()
                    self:OnObjectReady()
                end)
            end)
        end
    end)
end

local GMOD_TypeEqual = {
    ["NULL"]    = "NULL",
    ["nil"]     = "NULL",
    ["tinyint"] = "BOOLEAN",
    ["boolean"] = "BOOLEAN",
    ["string"]  = "TEXT",
    ["number"]  = "NUMBER",
    ["table"]   = "TABLE",
    ["Angle"]  = "ANGLE",
    ["Vector"]  = "VECTOR",
}

local bit_rshift = bit.rshift
local function GetBitsCount(number)
    local bits = 0
    while number > 0 do
        number = bit_rshift(number, 1)
        bits = bits + 1
    end
    return bits
end

function META:CheckInputValid(inputTable)
    -- Check all keys have same type
    for key, value in pairs(inputTable) do
        local selfInfo = self.fields[key]
        if !selfInfo then
            self:ErrorLog("Key not found: ", key)
            return
        end

        local require_type = selfInfo.type
        local value_type = type(value)

        local converted_type = GMOD_TypeEqual[value_type]

        if !converted_type then
            self:ErrorLog("Key type not found: ", key, " (", value_type, ")")
            return
        end

        if require_type != converted_type then
            self:ErrorLog("Value type mismatch: ", key, "(expected: ", require_type, ", got: ", converted_type, ")")
            return
        end

        -- Check Limit text length
        if converted_type == "TEXT" and selfInfo.length then
            if string.len(value) > selfInfo.length then
                self:ErrorLog("Key length limit exceeded: ", key, " (", selfInfo.length, ")")
                return
            end
        end

        /*
        -- Check Limit number length // TODO: Fix length check
        if converted_type == "NUMBER" and selfInfo.length then
            -- self:ServerLog("Check number: ", key, " (", value, ")", " bits: ", GetBitsCount(value), " limit: ", selfInfo.length)
            if GetBitsCount(value) > selfInfo.length then
                self:ErrorLog("Key length limit exceeded: ", key, " (", selfInfo.length, ")")
                return
            end
        end
        */
    end

    return true
end

---@param keys table
---@param values table
---@param callback? fun()
function META:Save(keys, values, callback)
    -- Check database is ready
    if !scp_code.data_storage.bDatabaseReady then
        self:ErrorLog("Database not ready")
        return
    end

    -- Check keys is not empty
    if table.IsEmpty(keys) then
        self:ErrorLog("Keys is empty")
        return
    end

    -- Check values is not empty
    if table.IsEmpty(values) then
        self:ErrorLog("Values is empty, nothing to save")
        return
    end

    -- Check all keys exists
    for key, keyInfo in pairs(self.keys) do
        if keys[key] == nil and keyInfo.optional != true then
            self:ErrorLog("Key not found: ", key)
            return
        end
    end

    -- Check Forbidden keys
    for key, _ in pairs(keys) do
        if self.keys[key] == nil then
            self:ErrorLog("Key not allowed: ", key)
            return
        end
    end

    -- Check Forbidden values
    for key, _ in pairs(values) do
        if self.values[key] == nil then
            self:ErrorLog("Value not allowed: ", key)
            return
        end
    end

    do -- Check Keys
        local bNice = self:CheckInputValid(keys)
        if !bNice then
            self:WarningLog("Keys inspects failed, please fix errors")
            return
        end
    end

    do -- Check Values
        local bNice = self:CheckInputValid(values)
        if !bNice then
            self:ServerLog("Values inspects failed, please fix errors")
            return
        end
    end

    self:CallProviderFunction("Save", keys, values, callback)
end

---@param keys table<string, any>
---@param callback fun(values?: table<string, any>)
function META:Load(keys, callback)
    -- Check database is ready
    if !scp_code.data_storage.bDatabaseReady then
        self:ErrorLog("Database not ready")
        return
    end

    -- Check keys exists
    if !next(keys) then
        self:ErrorLog("Keys is empty")
        return
    end

    -- Check Forbidden keys
    for key, _ in pairs(keys) do
        if self.keys[key] == nil then
            self:ErrorLog("Key not allowed: ", key)
            return
        end
    end

    do -- Check Keys
        local bNice = self:CheckInputValid(keys)
        if !bNice then
            self:WarningLog("Keys inspects failed, please fix errors")
            return
        end
    end

    self:CallProviderFunction("Load", keys, callback)
end


--- Remove All values from database
--- @param callback? fun()
function META:RemoveAll(callback)
    -- Check database is ready
    if !scp_code.data_storage.bDatabaseReady then
        self:ErrorLog("Database not ready")
        return
    end

    self:CallProviderFunction("RemoveAll", callback)
end

-- Remove values from database by keys
---@param keys table<string, any>
---@param callback? fun()
function META:Remove(keys, callback)
    -- Check database is ready
    if !scp_code.data_storage.bDatabaseReady then
        self:ErrorLog("Database `not ready")
        return
    end

    -- Check keys exists
    if !next(keys) then
        self:ErrorLog("Keys is empty")
        return
    end

    -- Check Forbidden keys
    for key, _ in pairs(keys) do
        if self.keys[key] == nil then
            self:ErrorLog("Key not allowed: ", key)
            return
        end
    end

    do -- Check Keys
        local bNice = self:CheckInputValid(keys)
        if !bNice then
            self:WarningLog("Keys inspects failed, please fix errors")
            return
        end
    end

    self:CallProviderFunction("Remove", keys, callback)
end

-- LoadMass
---@param keys table<string, any>
---@param callback fun(values?: table<number, table<string, any>>)
function META:LoadMass(keys, callback)
    -- Check database is ready
    if !scp_code.data_storage.bDatabaseReady then
        self:ErrorLog("Database not ready")
        return
    end

    -- Check keys exists
    if !next(keys) then
        self:ErrorLog("Keys is empty")
        return
    end

    -- Check Forbidden keys
    for key, _ in pairs(keys) do
        if self.keys[key] == nil then
            self:ErrorLog("Key not allowed: ", key)
            return
        end
    end

    do -- Check Keys
        local bNice = self:CheckInputValid(keys)
        if !bNice then
            self:WarningLog("Keys inspects failed, please fix errors")
            return
        end
    end

    self:CallProviderFunction("LoadMass", keys, callback)
end


---@param uniqueID string
---@param STRUCT scp_code.data_storage.inputFields
---@return scp_code.data_storage.struct
function scp_code.data_storage.CreateStorage(uniqueID, STRUCT)
    -- Asserts
    assert(type(uniqueID) == "string", "uniqueID must be a string")
    assert(type(STRUCT) == "table", "STRUCT must be a table")

    -- Asserts Keys
    assert(type(STRUCT.keys) == "table", "STRUCT.keys must be a table")
    for key, keyInfo in pairs(STRUCT.keys) do
        assert(type(key) == "string", "STRUCT.keys key must be a string")
        assert(type(keyInfo) == "table", "STRUCT.keys value must be a table")
        assert(type(keyInfo.name) == "string", "STRUCT.keys.name must be a string")
        assert(type(keyInfo.type) == "string", "STRUCT.keys.type must be a number")

        keyInfo.id = key
        if keyInfo.optional == nil then
            keyInfo.optional = false
        end

        if TYPE_IGNORE_LENGTH[keyInfo.type] then
            if keyInfo.length then
                ServerLog("Please disable length for key: ", key, " (", keyInfo.type, ")")
            end

            keyInfo.length = nil
        end
    end

    -- Asserts Values
    assert(type(STRUCT.values) == "table", "STRUCT.values must be a table")
    for key, valueInfo in pairs(STRUCT.values) do
        assert(type(key) == "string", "STRUCT.values key must be a string")
        assert(type(valueInfo) == "table", "STRUCT.values value must be a table")
        assert(type(valueInfo.name) == "string", "STRUCT.values.name must be a string")
        assert(type(valueInfo.type) == "string", "STRUCT.values.type must be a number")

        valueInfo.id = key

        if TYPE_IGNORE_LENGTH[valueInfo.type] then
            if valueInfo.length then
                ServerLog("Please disable length for key: ", key, " (", valueInfo.type, ")")
            end

            valueInfo.length = nil
        end
    end

    -- Fields
    ---@diagnostic disable-next-line: inject-field
    STRUCT.fields = {}

    -- Insert Keys
    for key, keyInfo in pairs(STRUCT.keys) do
        STRUCT.fields[key] = keyInfo
    end

    -- Insert Values with duplicate check
    for key, valueInfo in pairs(STRUCT.values) do
        if STRUCT.fields[key] then
            error("Duplicate key: " .. key)
        end

        STRUCT.fields[key] = valueInfo
    end

    scp_code.data_storage.mt_Structures[uniqueID] = STRUCT

    ---@diagnostic disable-next-line: inject-field
    STRUCT.uniqueID = uniqueID


    setmetatable(STRUCT, META)

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast STRUCT scp_code.data_storage.struct

    STRUCT:InitObject()

    return STRUCT
end

---@class scp_code.data_storage.provider_data: scp_code.data_storage.struct
---@field name string
---@field CreateObject fun(self)

---@param name string
---@param DATA scp_code.data_storage.provider_data
function scp_code.data_storage.RegisterProvider(name, DATA)
    scp_code.data_storage.mt_Providers[name] = DATA
end

-- Wait Initialize callback
function scp_code.data_storage.WaitObjectInit(objectID, uniqueID, callback)
    if !scp_code.data_storage.mt_WaitInit[objectID] then
        scp_code.data_storage.mt_WaitInit[objectID] = {}
    end

    local Callbacks = scp_code.data_storage.mt_WaitInit[objectID]
    Callbacks[uniqueID] = callback
end

-- Run Initialize callback
function scp_code.data_storage.RunObjectInit(objectID)
    local Callbacks = scp_code.data_storage.mt_WaitInit[objectID]

    if Callbacks then
        for uniqueID, callback in pairs(Callbacks) do
            callback()
        end
    end
end


-- DataBase INit
hook.Add("scp_code.DatabaseInitialized", "_gamemode", function()
    scp_code.data_storage.bDatabaseReady = true

    for uniqueID, STRUCT in pairs(scp_code.data_storage.mt_Structures) do

        -- Call Wait hooks
        STRUCT:InitObject()

    end
end)