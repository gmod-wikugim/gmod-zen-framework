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

--- TODO: Add support for sub-tables

-- TODO: Rename SET_VAR to SET_VARIABLE and DEL_VARIABLE and etc. more human-readable

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
    util.AddNetworkString("zen.meta_network.sub_table")
    util.AddNetworkString("zen.meta_network.networks")
end

---@class zen.meta_network
meta_network = (_GET and _GET("meta_network") or meta_network) or {}

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
---@field t_Values table<any, any> -- <key, value>
---@field t_FreeIndexes table<number, number> -- <number, number> Free Indexes after DEL_VAR
---@field IndexCounter number
---@field IndexBits number
---@field NetworkID number
---@field uniqueID string
local META = {}
META.NAME = "[zen] Meta Network"
META.META_NETWORK = true

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
    SET_VAR                        = 4,
    DEL_VAR                        = 5,
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
CODES_BITS = countBits(#(CODES))

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

--=============---VVVVVVVVVVVVVVVV---===============--

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

--=============---VVVVVVVVVVVVVVVV---===============--

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


------------------------------------------------------
--================ CODE-SUB-TABLE ==================--

---@enum (key) zen.meta_network.code_sub_table
local CODES_SUB_TABLE = {
    SET_SUB_TABLE                  = 1,
    DEL_SUB_TABLE                  = 2,
    SET_SUB_TABLE_KEY              = 3,
    DEL_SUB_TABLE_KEY              = 4,
}

---@type table<number, zen.meta_network.code_sub_table>
local CODES_SUB_TABLE_INDEX = {}
for k, v in pairs(CODES_SUB_TABLE) do CODES_SUB_TABLE_INDEX[v] = k end

CODES_SUB_TABLE_BITS = countBits(#(CODES_SUB_TABLE))

---@param code_name zen.meta_network.code_sub_table
local function WriteCodeSubTable(code_name)
    local code = CODES_SUB_TABLE[code_name]
    WriteUInt(code, CODES_SUB_TABLE_BITS)
end

---@return zen.meta_network.code_sub_table
local function ReadCodeSubTable()
    local codeID = ReadUInt(CODES_SUB_TABLE_BITS)
    local CODE = CODES_SUB_TABLE_INDEX[codeID]

    assert(CODE != nil, "Unknown code network: " .. tostring(codeID))
    return CODE
end

--=============---VVVVVVVVVVVVVVVV---===============--


Receive("zen.meta_network.sub_table", function (len, ply)
    local NetworkID = ReadNetworkID()

    print("Receive network: ", NetworkID, " ", ply)

    local NETWORK_OBJECT = meta_network.mt_ListObjectsIndex[NetworkID]

    assert(NETWORK_OBJECT != nil, "NETWORK_OBJECT with id `" .. tostring(NetworkID) .. "` not exists")

    local code_name = ReadCodeSubTable()

    -- Your stuff here
end)


--================ CODE-SUB-TABLE ==================--
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
function META:__index(Key)
    local M = rawget(META, Key)
    if M != nil then
        return M
    end

    local VALUE = rawget(self, Key)
    if VALUE != nil then
        return VALUE
    else
        return rawget(rawget(self, "ValueVariables"), Key)
    end
end

---@param NewIndexBits number
function META:SetCurrentIndexBits(NewIndexBits)
    local OldBits = self.IndexBits
    rawset(self, "IndexBits", NewIndexBits)

    if SERVER then
        self:SendNetwork(function()
            WriteCode("UPDATE_INDEX_BETS")
            WriteUInt(NewIndexBits, 32)
        end)

        if NewIndexBits < OldBits then
            local NewIndexCounter = table.maxn(self.t_KeysIndexes)

            rawset(self, "IndexCounter", NewIndexCounter)

            for k, v in pairs(self.t_FreeIndexes) do
                if v > NewIndexCounter then
                    -- table.remove(self.t_FreeIndexes, k)
                    self.t_FreeIndexes[k] = nil
                end
            end
        end
    end
end

---@private
function META:__newindex(Key, value)
    assert(SERVER, "This is only server-side controlled")
    assert( rawget(META, Key) == nil, "You can't assing `" .. tostring(Key) .. "` this is meta-reserved")
    assert( rawget(self, Key) == nil, "You can't assing `" .. tostring(Key) .. "` this is self-reserved")

    // Check meta-table
    if type(value) == "table" then
        local MM = getmetatable(value)

        if MM then
            if rawget(MM, "META_NETWORK") != true then error("Table with key `" .. tostring(Key) .. "` already has key, and it's not meta_table") end
        end
    end

    local IndexID = self.t_Keys[Key]

    -- Ignore new key with value NIL
    if IndexID == nil then
        if value == nil then return end

        IndexID = self:GetIndexID(Key)
    end

    ---@cast IndexID number

    local OldValue = self.t_Values[Key]

    if OldValue != value then
        self.t_Values[Key] = value

        if value != nil then
            self:SendNetwork(function()
                WriteCode("SET_VAR")
                self:WriteKey(IndexID)
                WriteType(value)
            end)
        else
            self:SendNetwork(function()
                WriteCode("DEL_VAR")
                self:WriteKey(IndexID)
            end)

            self.t_Keys[Key] = nil
            self.t_KeysIndexes[IndexID] = nil

            table.insert(self.t_FreeIndexes, IndexID)

            if self.IndexCounter == IndexID then
                self:SetCurrentIndexBits( countBits( table.maxn(self.t_KeysIndexes) ) )
            end
        end

        self:OnVariableChanged(Key, OldValue, value)
    end
end

---Get numeric index from AnyKey
---@param any any
---@return number
function META:GetIndexID(any)
    local IndexID = self.t_Keys[any]

    if IndexID == nil then
        local ID_TODEL, NewIndexID = next(self.t_FreeIndexes)

        if NewIndexID == nil then

            local IndexCounter = rawget(self, "IndexCounter")
            IndexCounter = IndexCounter + 1
            rawset(self, "IndexCounter", IndexCounter)

            if IndexCounter > maxValue(self.IndexBits) then
                self:SetCurrentIndexBits( countBits(IndexCounter) )
            end

            NewIndexID = IndexCounter
        else
            table.remove(self.t_FreeIndexes, ID_TODEL)
        end

        self:SendNetwork(function()
            WriteCode("NEW_INDEX")
            self:WriteKey(NewIndexID)
            WriteType(any)
        end)

        self.t_Keys[any] = NewIndexID
        self.t_KeysIndexes[NewIndexID] = any

        return NewIndexID
    end

    assert(IndexID != nil and type(IndexID) == "number", "Cant assign / get Index for `" .. tostring(any) .. "` ")

    return IndexID
end

function META:RawSet(Key, value)
    rawset(self, Key, value)
end

function META:RawGet(Key)
    return rawget(self, Key)
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
                local Value = self.t_Values[Key]

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
            self:SetCurrentIndexBits(ReadUInt(32))
        elseif CODE == "NEW_INDEX" then
            local IndexID = self:ReadKey()
            local Key = ReadType()

            assert(Key != nil, "Key can't be nil in Client-side NEW_INDEX")

            self.t_Keys[Key] = IndexID
            self.t_KeysIndexes[IndexID] = Key
        elseif CODE == "PING_VARIBLE" then
            local IndexID = self:ReadKey()

            local Key = self.t_KeysIndexes[IndexID]
            local Value = self.t_Values[Key]

            -- assert(Key != nil, "Client-side network `" .. tostring(self.uniqueID) .. "` don't have key for Index `" .. tostring(IndexID) .. "`")
        elseif CODE == "SET_VAR" then
            local IndexID = self:ReadKey()
            local Value = ReadType()

            local Key = self.t_KeysIndexes[IndexID]
            assert(Key != nil, "Client-side network `" .. tostring(self.uniqueID) .. "` don't have key for Index `" .. tostring(IndexID) .. "`")

            self.t_Values[Key] = Value

            print("GetVariable ", IndexID, " ", Key, " ", Value)
        elseif CODE == "DEL_VAR" then
            local IndexID = self:ReadKey()

            local Key = self.t_KeysIndexes[IndexID]
            assert(Key != nil, "Client-side network `" .. tostring(self.uniqueID) .. "` don't have key for Index `" .. tostring(IndexID) .. "`")

            self.t_Values[Key] = nil
            self.t_Keys[Key] = nil
            self.t_KeysIndexes[IndexID] = nil

            print("Delete variable ", IndexID, " ", Key)
        elseif CODE == "FULL_SYNC" then
            meta_network.NetworkCountBits = ReadUInt(32)

            self:SetCurrentIndexBits(ReadUInt(32))

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
                self.t_Values[Key] = Value
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
            t_SubTables = {},
            t_FreeIndexes = {},
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
    if meta_network.bNetworkReady then return end

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



-- /*

local SM = meta_network.GetNetworkObject("Network01")
if SERVER then
    SM.Admin = "admin"
    SM.Admin5 = nil
    SM.Admin3 = true

    for k = 1, 32 do
        SM[k] = nil
        SM[k+50] = nil
    end
end



concommand.Add("test_network", function()
    PrintTable(SM)
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

-- */