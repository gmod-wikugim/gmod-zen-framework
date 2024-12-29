module("zen")

/*
    Zen MetaNetwork: Easely usage network with __index, __newindex support
    Like network table, but with real-time update, without call functions

    zen.nt (zen.network) will be deleted in future, meta_network will be maintained
*/

--- TODO: Create entity linked networks by EntityID
--- Should be created with FreeIndexes Table for EntityID
--- Also should garbage network after EntityRemove
--- FreeIndexes should give next free index for link to entity

-- TODO: Remove variable if new variable is nil.

-- TODO: Rename UPDATE_VARIABLE to SET_VARIABLE and DEL_VARIABLE and etc. more human-readable

-- TODO: Create signals.
-- Server-to-Client should use NetworkID (number)
-- Client-to-Server should use NetworkID (number), otherwise (string) if signal not exists

-- TODO: Add hooks support (hook.Run)
-- Add META:OnVarChanger META:OnSignal, etc

-- TODO: Create server-side function, and send interface to client example
/*
    if SERVER then
        NETWORK_OBJECT:RegisterFunction("SlayPlayer", {"Player", "boolean"}, function(self, ply, isSilent)
            -- Do function stuff
        end)
        -- or
        function NETWORK_OBJECT:f_SlayPlayer(ply, isSilent) -- For example use `f_` prefix
            -- Do function stuff
        end

    end

    if CLIENT then
        NETWORK_OBJECT:StartFunction("SlayPlayer", ply, true)
        -- or
        NETWORK_OBJECT:f_SlayPlayer(ply, true) -- For example use `f_` prefix
    end
*/


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
---@field t_Keys table<any, number> -- <key, index>
---@field t_KeysIndexes table<number, any> -- <index, key>
---@field t_Values table<number, any> -- <key, value>
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

meta_network.NetworkCountBits = meta_network.NetworkCountBits or countBits(meta_network.mi_NetworkObjectCounter)

local function maxValue(bits)
    if bits == 0 then return 0 end
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
    UPDATE_INDEX_BETS              = 7,

    CL_VAR_CHANGE_REQUEST          = 8,
    PULL_VARIABLES                 = 9,
    FULL_SYNC                      = 10,
    NEW_INDEX                      = 11,
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

    assert(NETWORK_OBJECT != nil, "NETWORK_OBJECT with id `" .. tostring(NetworkID) .. "` not exists")

    local code_name = ReadCode()

    NETWORK_OBJECT:OnMessage(code_name, who, len)
end)


--====================== CODE ======================--
------------------------------------------------------

------------------------------------------------------
--================== CODE-NETWORK ==================--

---@enum (key) zen.meta_network.code_network
local CODES_NETWORK = {
    ASSIGN_NETWORK_ID                    = 1,
    NETWORK_BITS                         = 2,
    NETWORK_LIST                         = 3,
    DATAVAR_LIST                         = 4,
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

    assert(CODE != nil, "Unknown code network: " .. tostring(codeID))
    return CODE
end

--- TODO: Make function usable
function meta_network.SendFullUpdate(target, networkID) end

--- TODO: Create signals, like net.Receive and net.Send
--- Should use SignalID (number). Error is signal not exists
function META:SendSignal() end

--- TODO: Should register signal on server, and send to client
function META:OnSignal() end


Receive("zen.meta_network.networks", function(_, ply)
    local code_name = ReadCodeNetwork()

    print("Receive network: ", code_name, " ", ply)

    if SERVER then

        if code_name == "NETWORK_LIST" then
            Start("zen.meta_network.networks")
                WriteCodeNetwork("NETWORK_LIST")

                -- Networks Bytes
                WriteUInt(meta_network.NetworkCountBits, 32)

                local ObjectAmount = table.Count(meta_network.mt_ListObjectsIndex)

                WriteUInt(ObjectAmount, meta_network.NetworkCountBits)

                for k, v in pairs(meta_network.mt_ListObjectsIndex) do
                    WriteUInt(v.NetworkID, meta_network.NetworkCountBits)
                    WriteString(v.uniqueID)
                end
            Send(ply)
        elseif code_name == "DATAVAR_LIST" then
            for NetworkID, NETWORK_DATA in pairs(meta_network.mt_ListObjectsIndex) do
                NETWORK_DATA:Sync(ply)
            end
        end
    end

    if CLIENT then

        if code_name == "NETWORK_LIST" then

            meta_network.NetworkCountBits = ReadUInt(32)

            local ObjectAmount = ReadUInt(meta_network.NetworkCountBits)

            for k = 1, ObjectAmount do
                local NetworkID = ReadUInt(meta_network.NetworkCountBits)
                local uniqueID = ReadString()

                meta_network.AssignNetworkID(uniqueID, NetworkID, true)
            end

            meta_network.bNetworkReady = true
        elseif code_name == "ASSIGN_NETWORK_ID" then
            local networkID = ReadUInt(meta_network.NetworkCountBits)
            local uniqueID = ReadString()

            meta_network.AssignNetworkID(uniqueID, networkID, true)
        elseif code_name == "NETWORK_BITS" then
            meta_network.NetworkCountBits = ReadUInt(32)
        end
    end
end)


--================== CODE-NETWORK ==================--
------------------------------------------------------


local rawset = rawset
local rawget = rawget

/*
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
*/

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
    assert(SERVER, "This is only server-side controlled")
    assert( rawget(META, key) == nil, "You can't assing `" .. tostring(key) .. "` this is meta-reserved")

    local IndexID = self:GetIndexID(key)

    local OldValue = self.t_Values[IndexID]

    if OldValue != value then
        self.t_Values[IndexID] = value

        if SERVER then
            self:SendNetwork(function()
                WriteCode("UPDATE_VARIABLE")
                self:WriteKey(IndexID)
                WriteType(value)
            end)
        end

        self:OnVariableChanged(key, OldValue, value)
    end
end

---Get numeric index from AnyKey
---@param any any
---@return number
function META:GetIndexID(any)
    local IndexID = self.t_Keys[any]

    if IndexID == nil then
        local IndexCounter = rawget(self, "IndexCounter")

        IndexCounter = IndexCounter + 1
        rawset(self, "IndexCounter", IndexCounter)

        if IndexCounter > maxValue(self.IndexBits) then
            local IndexBits = countBits(IndexCounter)

            self:SendNetwork(function()
                WriteCode("UPDATE_INDEX_BETS")
                WriteUInt(IndexBits, 32)
            end)

            rawset(self, "IndexBits", IndexBits)
        end

        self:SendNetwork(function()
            WriteCode("NEW_INDEX")
            self:WriteKey(IndexCounter)
            WriteType(any)
        end)

        self.t_Keys[any] = IndexCounter
        self.t_KeysIndexes[IndexCounter] = any

        return IndexCounter
    end

    assert(IndexID != nil and type(IndexID) == "number", "Cant assign / get Index for `" .. tostring(any) .. "` ")

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

-- TODO: Create separate push netvars, like netstream for big networks
function META:Sync(target)
    if SERVER then
        self:SendNetwork(function(self)
            WriteCode("FULL_SYNC")
            WriteUInt(meta_network.NetworkCountBits, 32)
            WriteUInt(self.IndexBits, 32)

            local ValueAmount = table.Count(self.t_Keys)

            WriteUInt(ValueAmount, 32)

            for Key, IndexID in pairs(self.t_Keys) do
                local Value = self.t_Values[IndexID]

                assert(Key != nil, "Server-side network `" .. tostring(self.uniqueID) .. "` don't have value for Index `" .. tostring(IndexID) .. "` in FULL_SYNC")

                WriteUInt(IndexID, self.IndexBits)
                WriteType(Key)
                WriteType(Value)
            end

        end, target)
    end
    if CLIENT then
        self:SendNetwork(function(self)
            WriteCode("FULL_SYNC")
        end)
    end
end


function META:Ping()
    self:SendNetwork(function()
        WriteCode("PING")
    end)
end

---@param Key any
---@param OldValue any?
---@param NewValue any
function META:OnVariableChanged(Key, OldValue, NewValue)

end

---@param CODE zen.meta_network.code
---@param who Player|nil|`NULL`
---@param len number
function META:OnMessage(CODE, who, len)

    if CLIENT then

        if !meta_network.bNetworkReady then return end

        if CODE == "PING" then
            self:Ping()
        elseif CODE == "UPDATE_INDEX_BETS" then
            rawset(self, "IndexBits", ReadUInt(32))
        elseif CODE == "NEW_INDEX" then
            local IndexID = self:ReadKey()
            local Key = ReadType()

            assert(Key != nil, "Key can't be nil in Client-side NEW_INDEX")

            self.t_Keys[Key] = IndexID
            self.t_KeysIndexes[IndexID] = Key
        elseif CODE == "PING_VARIBLE" then
            local IndexID = self:ReadKey()

            local Key = self.t_KeysIndexes[IndexID]
            local Value = self.t_Values[IndexID]

            -- assert(Key != nil, "Client-side network `" .. tostring(self.uniqueID) .. "` don't have key for Index `" .. tostring(IndexID) .. "`")
        elseif CODE == "UPDATE_VARIABLE" then
            local IndexID = self:ReadKey()
            local Value = ReadType()

            local Key = self.t_KeysIndexes[IndexID]
            assert(Key != nil, "Client-side network `" .. tostring(self.uniqueID) .. "` don't have key for Index `" .. tostring(IndexID) .. "`")

            self.t_Values[IndexID] = Value

            print("GetVariable ", IndexID, " ", Key, " ", Value)
        elseif CODE == "FULL_SYNC" then
            meta_network.NetworkCountBits = ReadUInt(32)

            rawset(self, "IndexBits", ReadUInt(32))

            local ValueAmount = ReadUInt(32)

            for k = 1, ValueAmount do
                local IndexID = ReadUInt(self.IndexBits)
                local Key = ReadType()
                local Value = ReadType()

                assert(IndexID != nil, "IndexID can't be nil in Client-side FULL_SYNC")
                assert(Key != nil, "Key can't be nil in Client-side FULL_SYNC")
                assert(Value != nil, "Value can't be nil in Client-side FULL_SYNC")

                self.t_Keys[Key] = IndexID
                self.t_KeysIndexes[IndexID] = Key
                self.t_Values[IndexID] = Value
            end
        end
    end

    if SERVER then

        if CODE == "FULL_SYNC" then
            self:Sync(who)
        end

    end

end

---Assign NetworkID to UniqueID
---@param uniqueID string
---@param NetworkID number? (SERVER:  Place -1 to create new NetworkID)
---@param bForceCreateNetwork boolean? (CLIENT ONLY)
function meta_network.AssignNetworkID(uniqueID, NetworkID, bForceCreateNetwork)
    assert(type(uniqueID) == "string", "uniqueID not is string")
    assert(type(NetworkID) == "number", "NetworkID not is string")

    local NETWORK_OBJECT = meta_network.mt_ListObjects[uniqueID]

    if CLIENT and bForceCreateNetwork then
        NETWORK_OBJECT = meta_network.GetNetworkObject(uniqueID)
    end

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
            t_Keys = {},
            t_KeysIndexes = {},
            t_Values = {},
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

function meta_network.InitClient()
    Start("zen.meta_network.networks")
        WriteCodeNetwork("NETWORK_LIST")
        WriteBool(false)
    SendToServer()

    Start("zen.meta_network.networks")
        WriteCodeNetwork("DATAVAR_LIST")
        WriteBool(false)
    SendToServer()
end

if CLIENT then -- Client start-up
    if IsValid(LocalPlayer()) then meta_network.InitClient() end
    hook.Add("InitPostEntity", "zen.meta_network", function()
        if CLIENT then meta_network.InitClient() end
    end)
end



/*

meta_network.GetNetworkObject("Network01")
meta_network.GetNetworkObject("Network02")
meta_network.GetNetworkObject("Network03")
meta_network.GetNetworkObject("Network04")
meta_network.GetNetworkObject("Network05")
meta_network.GetNetworkObject("Network06")
meta_network.GetNetworkObject("Network07")
meta_network.GetNetworkObject("Network08")
meta_network.GetNetworkObject("Network09")
local SOME_OBJECT = meta_network.GetNetworkObject("Network09")
if SERVER then
    SOME_OBJECT.Var01 = "10001"
    SOME_OBJECT.Var02 = "10002"
    SOME_OBJECT.Var03 = "10003"
    SOME_OBJECT.Var04 = "10004"
    SOME_OBJECT.Var05 = "10005"
    SOME_OBJECT.Var06 = "10006"
    SOME_OBJECT.Var07 = "10007"
    SOME_OBJECT.Var08 = "10008"
end
local SM2 = meta_network.GetNetworkObject("Network10")
if SERVER then
    SM2.Test = 3
end
local SM3 = meta_network.GetNetworkObject("Network11")
local SM3 = meta_network.GetNetworkObject("Network12")
if SERVER then
    SM3.Vartiable = "Fafafa"
end
local SM3 = meta_network.GetNetworkObject("Network13")
if SERVER then
    SM3.Vartiable2 = "Fafafa2"

    for k = 1, 100 do
        SM3[k] = 10

    end
end

local SM3 = meta_network.GetNetworkObject("Network14")
if SERVER then
    SM3.Vartiable3 = "Fafafa3"

    for k = 1, 1000 do
        SM3[k] = 30

    end
end

local SM3 = meta_network.GetNetworkObject("Network15")
if SERVER then
    SM3.Vartiable4 = "Fafafa4"

    for k = 1, 300 do
        SM3[k] = 500

    end
end



concommand.Add("test_network", function()
    PrintTable(meta_network)
end)

concommand.Add("test_network_sync", function()
    for k, NETWORK in pairs(meta_network.mt_ListObjectsIndex) do
        NETWORK:Sync()
    end
end)

if CLIENT then
    concommand.Add("test_network_init", function()
        meta_network.InitClient()
    end)
end

*/

