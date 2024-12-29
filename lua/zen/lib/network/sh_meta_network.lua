module("zen")


-- TODO: Move init network to another network

local WriteString = net.WriteString
local ReadString = net.ReadString
local WriteUInt = net.WriteUInt
local ReadUInt = net.ReadUInt
local WriteType = net.WriteType
local ReadType = net.ReadType
local Receive = net.Receive
local Start = net.Start
local SendToServer = net.SendToServer
local Broadcast = net.Broadcast
local ReadBool = net.ReadBool
local WriteBool = net.WriteBool
local Send = net.Send

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

if CLIENT then
    meta_network.bNetworkReady = meta_network.bNetworkReady or false
end

---@type table<string, zen.META_NETWORK>
meta_network.mt_ListObjects = meta_network.mt_ListObjects or {}

---@type table<number, zen.META_NETWORK>
meta_network.mt_ListObjectsIndex = meta_network.mt_ListObjectsIndex or {}

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
    WriteUInt(code, CODES_BITS)
end

---@return zen.meta_network.code
local function ReadCode()
    local codeID = ReadUInt(CODES_BITS)
    local CODE = CODES_INDEX[codeID]

    assert(CODE != nil, "Unknown code " .. tostring(codeID))
    return CODE
end

Receive("zen.meta_network", function(len, who)
    local NetworkID = ReadNetworkID()

    print("Receive network: ", NetworkID, " ", who)


    local NETWORK_OBJECT = meta_network.mt_ListObjectsIndex[NetworkID]

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
    ASSIGN_NETWORK_ID                    = 1,
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
    WriteUInt(code, CODES_SCHEMA_BITS)
end


---@return zen.meta_network.code_schema
local function ReadCodeSchema()
    local codeID = ReadUInt(CODES_SCHEMA_BITS)
    local CODE = CODES_SCHEMA_INDEX[codeID]

    assert(CODE != nil, "Unknown code schema " .. tostring(codeID))
    return CODE
end

Receive("zen.meta_network.schema", function(len, ply)

    print("Receive schema: ", ply)

    if SERVER then return end -- Players can't edit schemas

    local NetworkID = ReadNetworkID()

    local NETWORK_OBJECT = meta_network.mt_ListObjectsIndex[NetworkID]

    assert(NETWORK_OBJECT != nil, "NETWORK_OBJECT with id `" .. tostring(NetworkID) .. "` not exists")

    local code_name = ReadCodeSchema()

    NETWORK_OBJECT:OnMessageScheme(code_name, ply, len)
end)


--================== CODE-SCHEMA ===================--
------------------------------------------------------

------------------------------------------------------
--================== CODE-NETWORK ==================--

---@enum (key) zen.meta_network.code_network
local CODES_NETWORK = {
    ASSIGN_NETWORK_ID                    = 1,
    NETWORK_BITS                         = 2,
    NETWORK_LIST                         = 3,
}

---@type table<number, zen.meta_network.code_network>
local CODES_NETWORK_INDEX = {}
for k, v in pairs(CODES_NETWORK) do CODES_NETWORK_INDEX[v] = k end

--- REAL-TIME CODE BITS
CODES_NETWORK_BITS = countBits(table.Count(CODES_NETWORK))

---@param code_name zen.meta_network.code_network
local function WriteCodeNetwork(code_name)
    local code = CODES_NETWORK[code_name]
    WriteUInt(code, CODES_NETWORK_BITS)
end


---@return zen.meta_network.code_network
local function ReadCodeNetwork()
    local codeID = ReadUInt(CODES_NETWORK_BITS)
    local CODE = CODES_NETWORK_INDEX[codeID]

    assert(CODE != nil, "Unknown code schema " .. tostring(codeID))
    return CODE
end


function meta_network.SendFullUpdate(target, networkID)



end

Receive("zen.meta_network.networks", function(_, ply)
    local code_name = ReadCodeNetwork()

    print("Receive network: ", code_name, " ", ply)

    if SERVER then

        if code_name == "NETWORK_LIST" then
            Start("zen.meta_network.networks")
                WriteCodeNetwork("NETWORK_LIST")

                -- Networks Bytes
                WriteUInt(meta_network.NetworkCountBits, 32)

                local ObjectAmount = table.Count(meta_network.mt_ListObjects)

                WriteUInt(ObjectAmount, meta_network.NetworkCountBits)

                for k, v in pairs(meta_network.mt_ListObjects) do
                    WriteUInt(v.NetworkID, meta_network.NetworkCountBits)
                    WriteString(v.uniqueID)
                end
            Send(ply)
        end

    end

    if CLIENT then

        if code_name == "NETWORK_LIST" then

            print("NETWORK_LIST Reading")
            -- Networks Bytes
            meta_network.NetworkCountBits = ReadUInt(32)

            local ObjectAmount = ReadUInt(meta_network.NetworkCountBits)

            for k = 1, ObjectAmount do
                local NetworkID = ReadUInt(meta_network.NetworkCountBits)
                local uniqueID = ReadString()

                meta_network.GetNetworkObject(uniqueID)
            end
            for k, v in pairs(meta_network.mt_ListObjects) do
                WriteUInt(v.NetworkID)
                WriteString(v.uniqueID)
            end
        elseif code_name == "ASSIGN_NETWORK_ID" then
            local networkID = ReadUInt(meta_network.NetworkCountBits)
            local uniqueID = ReadString()

            meta_network.GetNetworkObject(uniqueID)
        elseif code_name == "NETWORK_BITS" then
            local networkBits = ReadUInt(32)
            meta_network.NetworkCountBits = networkBits
        end
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
    return ReadUInt(self.IndexBits)
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
        WriteType(value)
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
                WriteUInt(IndexBits, 32)
            end)

            rawset(self, "IndexBits", IndexBits)
        end

        self:SendNetworkSchema(function()
            WriteCodeSchema("NEW_INDEX")
            WriteUInt(IndexCounter, self.IndexBits)
            WriteType(any)
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

    Start("zen.fix_network")
    if CLIENT then
        SendToServer()
    else
        Broadcast()
    end
end

---@param func fun(self: zen.META_NETWORK|self)
function META:SendNetwork(func, target)
    if CLIENT and !meta_network.bNetworkReady then return end

    xpcall(
    function()
        Start("zen.meta_network")
            WriteNetworkID(self.NetworkID)
        func(self)
        if CLIENT then
            SendToServer()
        else
            if target then
                Send(target)
            else
                Broadcast()
            end
        end
    end,
    fix_network)
end

---@param func fun(self: zen.META_NETWORK|self)
function META:SendNetworkSchema(func, target)
    if CLIENT and !meta_network.bNetworkReady then return end

    xpcall(
    function()
        Start("zen.meta_network.schema")
            WriteNetworkID(self.NetworkID)
        func(self)
        if CLIENT then
            SendToServer()
        else
            if target then
                Send(target)
            else
                Broadcast()
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
            self:SendNetwork(function()
                WriteCode("PULL_VARIABLES")

                local ObjectAmount = table.Count(self.ValueVariablesIndex)

                WriteUInt(ObjectAmount, self.IndexBits)

                for IndexID, Value in pairs(self.ValueVariablesIndex) do
                    WriteUInt(IndexID, self.IndexBits)
                    WriteType(Value)
                end
            end)

        end

    end

    if CLIENT then

        if !meta_network.bNetworkReady then return end

        if CODE == "PING" then
            self:Ping()
        elseif CODE == "PUSH_TABLE" then
            --
        elseif CODE == "CLEAR_TABLE" then
            --
        elseif CODE == "UPDATE_VARIABLE" then
            local indexKey = self:ReadKey()
            local value = ReadType()

            local key = self.Index[indexKey]
            self.ValueVariables[key] = value
            self.ValueVariablesIndex[indexKey] = value

            print("GetVariable ", indexKey, " ", key, " ", value)
        elseif CODE == "EMPTY_VARIABLE" then
            --
        elseif CODE == "PING_VARIBLE" then
            --
        elseif CODE == "CL_VAR_CHANGE_REQUEST" then
            --
        elseif CODE == "PULL_VARIABLES" then
            local ObjectAmount = ReadUInt(self.IndexBits)

            for k = 1, ObjectAmount do
                local IndexID = ReadUInt(self.IndexBits)
                local Value = ReadType()

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

                    WriteUInt(IndexID, self.IndexBits)
                    WriteString(ValueType)
                    WriteType(Value)
                end

            end, who)
        end

    end


    if CLIENT then

        if CODE == "INDEX_BITS" then
            if !meta_network.bNetworkReady then return end

            local IndexBits = ReadUInt(32)
            rawset(self, "IndexBits", IndexBits)
        elseif CODE == "NEW_INDEX" then
            if !meta_network.bNetworkReady then return end

            local IndexID = ReadUInt(self.IndexBits)
            local Value = ReadType()

            assert(Value != nil, "New index `" .. tostring(IndexID) .. "` can't be nil")

            self.Index[IndexID] = Value
            self.IndexType[IndexID] = type(Value)

            self.IndexRe[Value] = IndexID
        elseif CODE == "FULL_SCHEMA" then
            rawset(self, "IndexBits", ReadUInt(32))

            local ObjectAmount = ReadUInt(self.IndexBits)

            for k = 1, ObjectAmount do
                local IndexID = ReadUInt(self.IndexBits)
                local ValueType = ReadString()
                local Value = ReadType()

                assert(Value != nil, "New index `" .. tostring(IndexID) .. "` can't be nil")


                self.Index[IndexID] = Value
                self.IndexType[IndexID] = ValueType

                self.IndexRe[Value] = IndexID
            end

            meta_network.bNetworkReady = true

            self:SendNetwork(function()
                WriteCode("PULL_VARIABLES")
            end)
        end

    end
end

---Assign NetworkID to UniqueID
---@param uniqueID string
---@param NetworkID number? (SERVER:  Place -1 to create new NetworkID)
function meta_network.AssignNetworkID(uniqueID, NetworkID)
    assert(type(uniqueID) == "string", "uniqueID not is string")
    assert(type(NetworkID) == "number", "NetworkID not is string")

    local NETWORK_OBJECT = meta_network.mt_ListObjects[uniqueID]
    assert(NETWORK_OBJECT != nil, "NETWORK_OBJECT with uniqueID `" .. tostring(uniqueID) .. "` not exists")

    if SERVER then
        if NetworkID == -1 then
            if SERVER then
                meta_network.mi_NetworkObjectCounter = meta_network.mi_NetworkObjectCounter + 1
                NetworkID = meta_network.mi_NetworkObjectCounter
            end

            -- Update network amounts bits
            if meta_network.mi_NetworkObjectCounter > maxValue(meta_network.NetworkCountBits) then
                meta_network.NetworkCountBits= countBits(meta_network.mi_NetworkObjectCounter)

                Start("zen.meta_network.networks")
                    WriteCodeNetwork("NETWORK_BITS")
                    WriteUInt(meta_network.NetworkCountBits, 32)
                Broadcast()
            end

            Start("zen.meta_network.networks")
                WriteCodeNetwork("ASSIGN_NETWORK_ID")
                WriteUInt(meta_network.mi_NetworkObjectCounter, meta_network.NetworkCountBits)
                WriteString(uniqueID)
            Broadcast()
        end
    end


    if NetworkID == -1 then
        error("Can't assign networkID `-1` to uniqueID `" .. tostring(uniqueID) .. "`")
    end

    rawset(NETWORK_OBJECT, "NetworkID", NetworkID)
    meta_network.mt_ListObjectsIndex[NetworkID] = NETWORK_OBJECT
end


---Create/load shared-network table
---@param uniqueID string
function meta_network.GetNetworkObject(uniqueID)
    local NETWORK_DATA = meta_network.mt_ListObjects[uniqueID]


    if NETWORK_DATA == nil then
        ---@diagnostic disable-next-line: missing-fields
        NETWORK_DATA = {
            Index = {},
            IndexRe = {},
            IndexType = {},
            ValueType = {},
            ValueVariables = {},
            ValueVariablesIndex = {},
            NetworkID = -1,
            IndexCounter = 0,
            IndexBits = 0,
            uniqueID = uniqueID,
        }

        setmetatable(NETWORK_DATA, META)

        meta_network.mt_ListObjects[uniqueID] = NETWORK_DATA

        if SERVER then
            meta_network.AssignNetworkID(uniqueID, -1)
        end

        return NETWORK_DATA
    end

    setmetatable(NETWORK_DATA, META)

    return NETWORK_DATA
end

-- TODO: Request NetworkList
-- TODO: Create separeate push netvars

function meta_network.InitClient()
    Start("zen.meta_network.networks")
        WriteCodeNetwork("NETWORK_LIST")
        WriteBool(false)
    SendToServer()
end

if CLIENT then
    -- if meta_network.bNetworkReady then return end
    meta_network.InitClient()
end

hook.Add("InitPostEntity", "meta_network", function()
    if CLIENT then
        meta_network.InitClient()
    end
end)

local SOME_OBJECT = meta_network.GetNetworkObject("Network09")
if SERVER then
    SOME_OBJECT.Var01 = 1
    SOME_OBJECT.Var02 = 2
    SOME_OBJECT.Var03 = 2
    SOME_OBJECT.Var04 = 2
end

PrintTable(SOME_OBJECT)

timer.Simple(1, function()
    PrintTable(SOME_OBJECT.ValueVariables)
end)

concommand.Add("test_network", function()
    PrintTable(SOME_OBJECT)
end)