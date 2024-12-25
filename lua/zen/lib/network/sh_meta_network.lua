module("zen")


local net_WriteString = net.WriteString
local net_ReadString = net.ReadString
local net_WriteUInt = net.WriteUInt
local net_ReadUInt = net.ReadUInt
local net_WriteType = net.WriteType
local net_ReadType = net.ReadType
local WriteUInt = net_WriteUInt
local ReadUInt = net_ReadUInt
local net_Receive = net.Receive
local net_Start = net.Start
local net_SendToServer = net.SendToServer
local net_Broadcast = net.Broadcast
local net_ReadBool = net.ReadBool
local net_WriteBool = net.WriteBool
local net_Send = net.Send

local ErrorNoHaltWithStack = ErrorNoHaltWithStack
local CLIENT = CLIENT
local SERVER = SERVER

if SERVER then
    util.AddNetworkString("zen.fix_network")
    util.AddNetworkString("zen.meta_network")
    util.AddNetworkString("zen.meta_network.schema")
    util.AddNetworkString("zen.meta_network.networks")
end

---@class zen.meta_network
meta_network = _GET("meta_network")

---@type table<string, zen.META_NETWORK>
meta_network.mt_ListObjects = meta_network.mt_ListObjects or {}
meta_network.mi_NetworkObjectCounter = meta_network.mi_NetworkObjectCounter or 0


---@class zen.META_NETWORK
---@field Index table<number, any>
---@field IndexRe table<any, number>
---@field IndexType table<number, type>
---@field ValueType table<number, string>
---@field ValueVariables table<any, any>
---@field ValueVariablesIndex table<number, any>
---@field IndexCounter number
---@field IndexBits number
---@field NetworkID number
---@field uniqueID string
local META = {}

local bit_rshift = bit.rshift
local function countBits(n)
    if n < 0 then
        error("Input must be a non-negative integer")
    end
    if n == 0 then
        return 1  -- 0 is represented as 0 in binary, which takes 1 bit
    end

    local bits = 0
    while n > 0 do
        n = bit_rshift(n, 1)  -- Right shift n by 1 using bitwise operation
        bits = bits + 1
    end
    return bits
end

meta_network.NetworkCountBits = countBits(meta_network.mi_NetworkObjectCounter)

local function maxValue(bits)
    if bits < 1 then return 1 end

    return (2 ^ bits) - 1
end

---@param networkID number
local function WriteNetworkID(networkID)
    WriteUInt(networkID, meta_network.NetworkCountBits)
end

---@return number
local function ReadNetworkID()
    return ReadUInt(meta_network.NetworkCountBits)
end



------------------------------------------------------
--====================== CODE ======================--

---@enum (key) zen.meta_network.code
local CODES = {
    PING                           = 1,
    PUSH_TABLE                     = 2,
    CLEAR_TABLE                    = 3,
    UPDATE_VARIABLE                = 4,
    EMPTY_VARIABLE                 = 5,
    PING_VARIBLE                   = 6,

    CL_VAR_CHANGE_REQUEST          = 7,
    PULL_VARIABLES                 = 8,
}

---@type table<number, zen.meta_network.code>
local CODES_INDEX = {}
for k, v in pairs(CODES) do CODES_INDEX[v] = k end

--- REAL-TIME CODE BITS
CODES_BITS = countBits(table.Count(CODES))


---@param code_name zen.meta_network.code
local function WriteCode(code_name)
    local code = CODES[code_name]
    net_WriteUInt(code, CODES_BITS)
end

---@return zen.meta_network.code
local function ReadCode()
    local codeID = net_ReadUInt(CODES_BITS)
    local CODE = CODES_INDEX[codeID]

    assert(CODE != nil, "Unknown code " .. tostring(codeID))
    return CODE
end

net_Receive("zen.meta_network", function(len, who)
    local NetworkID = ReadNetworkID()

    local NETWORK_OBJECT = meta_network.mt_ListObjects[NetworkID]

    assert(type(NETWORK_OBJECT) == "table", "NETWORK_OBJECT with id `" .. tostring(NetworkID) .. "` not exists")

    local code_name = ReadCode()

    NETWORK_OBJECT:OnMessage(code_name, who, len)
end)


--====================== CODE ======================--
------------------------------------------------------


------------------------------------------------------
--================== CODE-SCHEMA ===================--

---@enum (key) zen.meta_network.code_schema
local CODES_SCHEMA = {
    NEW_NETWORK                          = 1,
    NETWORK_AMOUNT                       = 2,
    INDEX_BITS                           = 3,
    NEW_INDEX                            = 4,
    FULL_SCHEMA                          = 5,
}

---@type table<number, zen.meta_network.code_schema>
local CODES_SCHEMA_INDEX = {}
for k, v in pairs(CODES_SCHEMA) do CODES_SCHEMA_INDEX[v] = k end

--- REAL-TIME CODE BITS
CODES_SCHEMA_BITS = countBits(table.Count(CODES_SCHEMA))

---@param code_name zen.meta_network.code_schema
local function WriteCodeSchema(code_name)
    local code = CODES_SCHEMA[code_name]
    net_WriteUInt(code, CODES_SCHEMA_BITS)
end


---@return zen.meta_network.code_schema
local function ReadCodeSchema()
    local codeID = net_ReadUInt(CODES_SCHEMA_BITS)
    local CODE = CODES_SCHEMA_INDEX[codeID]

    assert(CODE != nil, "Unknown code schema " .. tostring(codeID))
    return CODE
end

net_Receive("zen.meta_network.schema", function(len, ply)
    if SERVER then return end -- Players can't edit schemas

    local NetworkID = ReadNetworkID()

    local NETWORK_OBJECT = meta_network.mt_ListObjects[NetworkID]

    assert(type(NETWORK_OBJECT) == "table", "NETWORK_OBJECT with id `" .. tostring(NetworkID) .. "` not exists")

    local code_name = ReadCodeSchema()

    NETWORK_OBJECT:OnMessageScheme(code_name, ply, len)
end)


--================== CODE-SCHEMA ===================--
------------------------------------------------------

------------------------------------------------------
--================== CODE-NETWORK ==================--

---@enum (key) zen.meta_network.code_network
local CODES_NETWORK = {
    NEW_NETWORK                          = 1,
    NETWORK_BITS                         = 2,
    NETWORK_LIST                          = 3,
}

---@type table<number, zen.meta_network.code_network>
local CODES_NETWORK_INDEX = {}
for k, v in pairs(CODES_NETWORK) do CODES_NETWORK_INDEX[v] = k end

--- REAL-TIME CODE BITS
CODES_NETWORK_BITS = countBits(table.Count(CODES_NETWORK))

---@param code_name zen.meta_network.code_network
local function WriteCodeNetwork(code_name)
    local code = CODES_NETWORK[code_name]
    net_WriteUInt(code, CODES_NETWORK_BITS)
end


---@return zen.meta_network.code_network
local function ReadCodeNetwork()
    local codeID = net_ReadUInt(CODES_NETWORK_BITS)
    local CODE = CODES_NETWORK_INDEX[codeID]

    assert(CODE != nil, "Unknown code schema " .. tostring(codeID))
    return CODE
end


function meta_network.SendFullUpdate(target, networkID)



end

net_Receive("zen.meta_network.networks", function(_, ply)
    local code_name = ReadCodeNetwork()

    if SERVER then

        if code_name == "NETWORK_LIST" then
            net_Start("zen.meta_network.networks")
                -- Networks Bytes
                net_WriteUInt(meta_network.NetworkCountBits, 32)

                local ObjectAmount = table.Count(meta_network.mt_ListObjects)

                net_WriteUInt(ObjectAmount, meta_network.NetworkCountBits)

                for k, v in pairs(meta_network.mt_ListObjects) do
                    net_WriteUInt(v.NetworkID, meta_network.NetworkCountBits)
                    net_WriteString(v.uniqueID)
                end
            net_Send(ply)
        end
    end

    if SERVER then return end -- Players can't edit network

    if code_name == "NETWORK_LIST" then
        -- Networks Bytes
        meta_network.NetworkCountBits = net_ReadUInt(32)

        local ObjectAmount = net_ReadUInt(meta_network.NetworkCountBits)

        for k = 1, ObjectAmount do
            local NetworkID = net_ReadUInt(meta_network.NetworkCountBits)
            local uniqueID = net_ReadString()

            meta_network.GetNetworkObject(uniqueID, NetworkID)
        end
        for k, v in pairs(meta_network.mt_ListObjects) do
            net_WriteUInt(v.NetworkID)
            net_WriteString(v.uniqueID)
        end
    elseif code_name == "NEW_NETWORK" then
        local networkID = net_ReadUInt(meta_network.NetworkCountBits)
        local uniqueID = net_ReadString()

        meta_network.GetNetworkObject(uniqueID, networkID)
    elseif code_name == "NETWORK_BITS" then
        local networkBits = net_ReadUInt(32)
        meta_network.NetworkCountBits = networkBits
    end
end)


--================== CODE-NETWORK ==================--
------------------------------------------------------


local rawset = rawset
local rawget = rawget


---@enum (key) zen.meta_network.key_type
local KEYS_TYPES = {
    number      =  1,
    string      =  2,
    any         =  3,
}

---@type table<number, zen.meta_network.key_type>
local KEYS_TYPES_INDEX = {}
for k, v in pairs(KEYS_TYPES) do KEYS_TYPES_INDEX[v] = k end


local KEYS_TYPES_BITS = countBits(table.Count(KEYS_TYPES))

function META:WriteKey(IndexID)
    WriteUInt(IndexID, self.IndexBits)
end

function META:ReadKey()
    return net_ReadUInt(self.IndexBits)
end

---@private
function META:__index(key)
    local M = rawget(META, key)
    if M != nil then
        return M
    end

    local VALUE = rawget(self, key)
    if VALUE != nil then
        return VALUE
    else
        return rawget(rawget(self, "ValueVariables"), key)
    end
end

---@private
function META:__newindex(key, value)
    local IndexID = self:GetIndexID(key)

    self.ValueVariables[key] = value
    self.ValueVariablesIndex[IndexID] = value

    self:SendNetwork(function()
        WriteCode("UPDATE_VARIABLE")
        self:WriteKey(IndexID)
        net_WriteType(value)
    end)
end

function META:GetIndexID(any)
    local IndexID = self.Index[any]

    if IndexID == nil then
        local IndexCounter = rawget(self, "IndexCounter")

        IndexCounter = IndexCounter + 1
        rawset(self, "IndexCounter", IndexCounter)

        if IndexCounter > maxValue(self.IndexBits) then
            local IndexBits = countBits(IndexCounter)

            self:SendNetworkSchema(function()
                WriteCodeSchema("INDEX_BITS")
                net_WriteUInt(IndexBits, 32)
            end)

            rawset(self, "IndexBits", IndexBits)
        end

        self:SendNetworkSchema(function()
            WriteCodeSchema("NEW_INDEX")
            net_WriteUInt(IndexCounter, self.IndexBits)
            net_WriteType(any)
        end)

        self.Index[any] = IndexCounter
        self.IndexRe[IndexCounter] = any
        self.IndexType[IndexCounter] = type(any)

        return IndexCounter
    end

    return IndexID
end

function META:RawSet(key, value)
    rawset(self, key, value)
end

function META:RawGet(key)
    return rawget(self, key)
end


local function fix_network(...)
    ErrorNoHaltWithStack(...)

    net_Start("zen.fix_network")
    if CLIENT then
        net_SendToServer()
    else
        net_Broadcast()
    end
end

---@param func fun(self: zen.META_NETWORK|self)
function META:SendNetwork(func, target)
    xpcall(
    function()
        net_Start("zen.meta_network")
            WriteNetworkID(self.NetworkID)
        func(self)
        if CLIENT then
            net_SendToServer()
        else
            if target then
                net_Send(target)
            else
                net_Broadcast()
            end
        end
    end,
    fix_network)
end

---@param func fun(self: zen.META_NETWORK|self)
function META:SendNetworkSchema(func, target)
    xpcall(
    function()
        net_Start("zen.meta_network.schema")
            WriteNetworkID(self.NetworkID)
        func(self)
        if CLIENT then
            net_SendToServer()
        else
            if target then
                net_Send(target)
            else
                net_Broadcast()
            end
        end
    end,
    fix_network)
end



function META:Ping()
    self:SendNetwork(function()
        WriteCode("PING")
    end)
end

---@param CODE zen.meta_network.code
---@param who Player|nil|`NULL`
---@param len number
function META:OnMessage(CODE, who, len)

    if SERVER then

        if CODE == "PULL_VARIABLES" then
            local ObjectAmount = table.Count(self.ValueVariablesIndex)

            net_WriteUInt(ObjectAmount, self.IndexBits)

            for IndexID, Value in pairs(self.ValueVariablesIndex) do
                net_WriteUInt(IndexID, self.IndexBits)
                net_WriteType(Value)
            end
        end

    end

    if CLIENT then

        if CODE == "PING" then
            self:Ping()
        elseif CODE == "PUSH_TABLE" then
            --
        elseif CODE == "CLEAR_TABLE" then
            --
        elseif CODE == "UPDATE_VARIABLE" then
            local indexKey = self:ReadKey()
            local value = net_ReadType()

            local key = self.Index[indexKey]
            self.ValueVariables[key] = value
            self.ValueVariablesIndex[indexKey] = value

            print("GetVariable", indexKey, key, value)
        elseif CODE == "EMPTY_VARIABLE" then
            --
        elseif CODE == "PING_VARIBLE" then
            --
        elseif CODE == "CL_VAR_CHANGE_REQUEST" then
            --
        elseif CODE == "PULL_VARIABLES" then
            local ObjectAmount = net_ReadUInt(self.IndexBits)

            for k = 1, ObjectAmount do
                local IndexID = net_ReadUInt(self.IndexBits)
                local Value = net_ReadType()

                local Key = self.Index[IndexID]

                self.ValueVariables[Key] = Value
                self.ValueVariablesIndex[IndexID] = Value
            end

        end
    end

end

---@param CODE zen.meta_network.code_schema
function META:OnMessageScheme(CODE, who, len)

    if SERVER then

        if CODE == "FULL_SCHEMA" then
            self:SendNetworkSchema(function (self)
                WriteCodeSchema("FULL_SCHEMA")
                WriteUInt(self.IndexBits, 32)

                local ObjectAmount = table.Count(self.Index)
                WriteUInt(ObjectAmount, self.IndexBits)

                for IndexID, Value in pairs(self.Index) do
                    local ValueType = type(Value)

                    net_WriteUInt(IndexID, self.IndexBits)
                    net_WriteString(ValueType)
                    net_WriteType(Value)
                end

            end, who)
        end

    end


    if CLIENT then

        if CODE == "INDEX_BITS" then
            local IndexBits = net_ReadUInt(32)
            rawset(self, "IndexBits", IndexBits)
        elseif CODE == "NEW_INDEX" then
            local IndexID = net_ReadUInt(self.IndexBits)
            local Value = net_ReadType()

            assert(Value != nil, "New index `" .. tostring(IndexID) .. "` can't be nil")

            self.Index[IndexID] = Value
            self.IndexType[IndexID] = type(Value)

            self.IndexRe[Value] = IndexID
        elseif CODE == "FULL_SCHEMA" then
            rawset(self, "IndexBits", ReadUInt(32))

            local ObjectAmount = ReadUInt(self.IndexBits)

            for k = 1, ObjectAmount do
                local IndexID = net_ReadUInt(self.IndexBits)
                local ValueType = net_ReadString()
                local Value = net_ReadType()

                assert(Value != nil, "New index `" .. tostring(IndexID) .. "` can't be nil")


                self.Index[IndexID] = Value
                self.IndexType[IndexID] = ValueType

                self.IndexRe[Value] = IndexID
            end

            self:SendNetwork(function()
                WriteCode("PULL_VARIABLES")
            end)
        end

    end
end


---Create/load shared-network table
---@param uniqueID string
---@param NetworkID? number Only for client
function meta_network.GetNetworkObject(uniqueID, NetworkID)
    local NETWORK_DATA = meta_network.mt_ListObjects[uniqueID]


    if NETWORK_DATA == nil then
        if SERVER then
            assert(NetworkID == nil, "Server meta-network cannot input NetworkID")
            meta_network.mi_NetworkObjectCounter = meta_network.mi_NetworkObjectCounter + 1
            NetworkID = meta_network.mi_NetworkObjectCounter
        else
            assert(type(NetworkID) == "number", "Client meta-network should have NetworkID")
            assert(NetworkID >= 0, "Client meta-network NetworkID should be more than 0")
        end

        ---@diagnostic disable-next-line: missing-fields
        NETWORK_DATA = {
            Index = {},
            IndexRe = {},
            IndexType = {},
            ValueType = {},
            ValueVariables = {},
            ValueVariablesIndex = {},
            NetworkID = NetworkID,
            IndexCounter = 0,
            IndexBits = 0,
            uniqueID = uniqueID,
        }

        setmetatable(NETWORK_DATA, META)

        if SERVER then
            -- Update network amounts bits
            if meta_network.mi_NetworkObjectCounter > maxValue(meta_network.NetworkCountBits) then
                meta_network.NetworkCountBits= countBits(meta_network.mi_NetworkObjectCounter)

                NETWORK_DATA:SendNetworkSchema(function(self)
                    WriteCodeNetwork("NETWORK_BITS")
                    net_WriteUInt(meta_network.NetworkCountBits, 32)
                end)
            end

            NETWORK_DATA:SendNetworkSchema(function(self)
                WriteCodeNetwork("NEW_NETWORK")
                net_WriteUInt(meta_network.mi_NetworkObjectCounter, meta_network.NetworkCountBits)
                net_WriteString(uniqueID)
            end)
        end

        meta_network.mt_ListObjects[uniqueID] = NETWORK_DATA

        if CLIENT then
            NETWORK_DATA:SendNetworkSchema(function(self)
                WriteCodeSchema("FULL_SCHEMA")
            end)
        end

        return NETWORK_DATA
    end


    setmetatable(NETWORK_DATA, META)

    return NETWORK_DATA
end


local SOME_OBJECT = meta_network.GetNetworkObject("Network09")

if SERVER then
    SOME_OBJECT.Var01 = 10
else
    print(SOME_OBJECT.Var01)
end

hook.Add("InitPostEntity", "meta_network", function()
    if CLIENT then
        net.Start("zen.meta_network.networks")
            WriteCodeNetwork("NETWORK_LIST")
            net_WriteBool(false)
        net.SendToServer()
    end

end)