izen.network = izen.network or {}
zen.network = izen.network
nt = zen.network
nt.t_ChannelFlags = {}
nt.t_ChannelFlags.SIMPLE_NETWORK        = 0
nt.t_ChannelFlags.SAVING                = 2 ^ 3
nt.t_ChannelFlags.CLIENT_SAVING         = 2 ^ 4
nt.t_ChannelFlags.POSTREAD              = 2 ^ 5
nt.t_ChannelFlags.NEW_PLAYER_PULLS      = 2 ^ 6
nt.t_ChannelFlags.PUBLIC                = 2 ^ 7 + nt.t_ChannelFlags.POSTREAD + nt.t_ChannelFlags.NEW_PLAYER_PULLS

nt.t_ChannelFlags.ENTITY_KEY_VALUE      = nt.t_ChannelFlags.SAVING + nt.t_ChannelFlags.CLIENT_SAVING + nt.t_ChannelFlags.PUBLIC

nt.channels = nt.channels or {}
nt.channels.registerWordSingle = "nt.RegisterStringNumbersSingle"
nt.channels.registerWordMulti = "nt.RegisterStringNumbersMulti"
nt.channels.sendMessage = "nt.sendMessage"
nt.channels.clientReady = "nt.clientReady"
nt.channels.pullChannels = "nt.pullChannels"

if SERVER then
    for k, v in pairs(nt.channels) do
        util.AddNetworkString(v)
    end
end

CreateConVar("zen_network_debug", 0, FCVAR_ARCHIVE, "Enable network debugging!", 0, 3)
cvars.AddChangeCallback("zen_network_debug", function(var, old_value, new_value)
    nt.i_debug_lvl = tonumber(new_value)
    if nt.i_debug_lvl > 0 then
        zen.print("[nt.debug] Debugging started, \"zen_network_debug 0\" to stop!")
    else
        zen.print("[nt.debug] Debugging stoped, \"zen_network_debug 1\" to start again!")
    end
end, "nt.OnChange")
nt.i_debug_lvl = GetConVar("zen_network_debug"):GetInt() or 0

local bit_band = bit.band
local function isFlagSet(flags, flag) return bit_band(flags, flag) == flag end

nt.mt_Channels = nt.mt_Channels or {}
nt.mt_ChannelsIDS = nt.mt_ChannelsIDS or {}
nt.mt_ChannelsNames = nt.mt_ChannelsNames or {}

nt.mt_ChannelsPublic = nt.mt_ChannelsPublic or {}
nt.mt_ChannelsPublicPriority = nt.mt_ChannelsPublicPriority or {}
nt.mt_ChannelsContent = nt.mt_ChannelsContent or {}
function nt.RegisterChannel(channel_name, flags, data)
    local flags = flags or nt.t_ChannelFlags.SIMPLE_NETWORK
    assertString(channel_name, "channel_name")
    assertNumber(flags, "flags")
    assert(istable(data) or data == nil, "data should be table|nil")

    local channel_id = nt.mt_ChannelsIDS[channel_name] or (data and data.id)

    if not nt.mt_ChannelsIDS[channel_name] then
        nt.mt_ChannelsIDS[channel_name] = channel_id or (SERVER and (#nt.mt_ChannelsNames + 1) or nil)

        channel_id = nt.mt_ChannelsIDS[channel_name]
        if channel_id and not nt.mt_ChannelsNames[channel_id] then
            nt.mt_ChannelsNames[channel_id] = channel_name
        end

        if SERVER and nt.mt_Channels["channels"] then
            nt.SendToChannel("channels", nil, channel_name, channel_id)
        end
    end

    nt.mt_Channels[channel_name] = nt.mt_Channels[channel_name] or {}
    local tChannel = nt.mt_Channels[channel_name]
    tChannel.id = channel_id
    tChannel.flags = flags
    tChannel.name = channel_name

    if flags <= 0 then return channel_id, tChannel end
    
    tChannel.FLAGS = util.GetFlagsTable(nt.t_ChannelFlags, flags)
    local FLAGS = tChannel.FLAGS

    if data.types and (data.fWriter or data.fReader) then
        error("You can't use \"data.types\" and (data.fWriter or data.fReader) in one time, select only one")
    end

    if data.customNetworkString then
        assertString(data.customNetworkString, "data.customNetworkString")
        assert(util.NetworkStringToID(data.customNetworkString) != 0, "data.customNetworkString not registred network: " .. tostring(data.customNetworkString))
        tChannel.customNetworkString = data.customNetworkString
    end

    if data.types then
        assertTable(data.types, "data.types not exists")
        tChannel.types = data.types
    else
        assertFunction(data.fWriter, "data.fWriter")
        assertFunction(data.fReader, "data.fReader")
        tChannel.fWriter = data.fWriter
        tChannel.fReader = data.fReader
    end

    if (SERVER and FLAGS.SAVING) or (CLIENT and FLAGS.CLIENT_SAVING) then
        local tContent
        assertFunction(data.fSaving, "data.fSaving")
        if data.fSaveInit then
            assertFunction(data.fSaveInit, "data.fSaveInit")
            tChannel.bSaveInitialized = false
            tChannel.fSaveInit = data.fSaveInit
            tContent = tChannel.fSaveInit(tChannel, nt.mt_ChannelsContent)
            assert(tContent != nil, "tChannel.fSaveInit should return not nil value! id: " .. tChannel.name)
        end

        if tContent == nil then
            if not nt.mt_ChannelsContent[channel_name] then
                nt.mt_ChannelsContent[channel_name] = {}
            end
            tContent = nt.mt_ChannelsContent[channel_name]
        end
        tChannel.tContent = tContent
        tChannel.iCounter = tChannel.iCounter or 0
        tChannel.fSaving = data.fSaving
    end

    if FLAGS.POSTREAD then
        assertFunction(data.fPostReader, "data.fPostReader")
        tChannel.fPostReader = data.fPostReader
    end

    if FLAGS.NEW_PLAYER_PULLS then
        if SERVER then
            assertFunction(data.fPullWriter, "data.fPullWriter")
            tChannel.fPullWriter = data.fPullWriter
        end
        if CLIENT then
            assertFunction(data.fPullReader, "data.fPullReader")
            tChannel.fPullReader = data.fPullReader
        end
    end

    if SERVER and FLAGS.PUBLIC then
        nt.mt_ChannelsPublic[channel_id] = tChannel

        tChannel.iPriority = isnumber(data.priority) and data.priority or 9999
        tChannel.bPublic = true

        nt.mt_ChannelsPublicPriority = {}
        for ch_id, v in pairs(nt.mt_ChannelsPublic) do
            table.insert(nt.mt_ChannelsPublicPriority, v)
        end

        table.sort(nt.mt_ChannelsPublicPriority, function(a, b) return a.iPriority < b.iPriority end)
    end

    return channel_id, tChannel, tChannel.tContent
end

function nt.SendToChannel(channel_name, target, ...)
    local tChannel = nt.mt_Channels[channel_name]
    assert(tChannel, "channel not exists \"" .. channel_name .. "\"")
    assert(istable(tChannel.types) or isfunction(tChannel.fWriter) , "tChannel.types should be tChannel.types || tChannel.fWriter should be function")

    local data = {...}

    if tChannel.fSaving then
        tChannel.fSaving(tChannel, tChannel.tContent, unpack(data))
    end


    if tChannel.bPublic then
        if tChannel.types then
            nt.Send(channel_name, tChannel.types, data)
        elseif tChannel.fWriter then
            if nt.i_debug_lvl >= 2 then
                zen.print("[nt.debug] Start \"",channel_name,"\"")
            end

            if tChannel.customNetworkString then
                net.Start(tChannel.customNetworkString)
            else
                net.Start(nt.channels.sendMessage)
                net.WriteUInt(tChannel.id, 32)
            end
                
            if nt.i_debug_lvl >= 2 then
                for k, v in pairs(data) do
                    zen.print("[nt.debug] Pre-Write \"",type(v),"\"", " \"",tostring(v),"\"")
                end
            end

            tChannel.fWriter(tChannel, unpack(data))
            
            if SERVER then
                if target then
                    net.Send(target)
                else
                    net.Broadcast()
                end
            else
                net.SendToServer()
            end

            if nt.i_debug_lvl >= 2 then
                zen.print("[nt.debug] End \"",channel_name,"\"")
            end
        
            if nt.i_debug_lvl >= 1 then
                zen.print("[nt.debug] Sent network \"",channel_name,"\" to server/players")
            end
        else
            MsgC(clr_red, "[NT-Predicted-Error] Channel not have send option", channel_name, "\n")
            return
        end
    end
end

function nt.GetChannelID(channel_name)
    if SERVER then
        if not nt.mt_ChannelsIDS[channel_name] then
            nt.RegisterChannel(channel_name)
        end
    end
    return nt.mt_ChannelsIDS[channel_name]
end

function nt.GetChannelName(channel_id)
    return nt.mt_ChannelsNames[channel_id]
end

function nt.GetChannelNetVar(list_name, key, default)
    local tChannel = nt.mt_Channels[list_name]
    if not tChannel then return end
    local tContent = nt.mt_ChannelsContent[list_name]
    if not tContent then return end

    return tContent[key]
end

local _I = table.concat
local FromSID64 = util.SteamIDFrom64
local ToSID64 = util.SteamIDTo64

nt.mt_listReader = {}
nt.mt_listReader["angle"] = function() return net.ReadAngle() end
nt.mt_listReader["bit"] = function() return net.ReadBit() end
nt.mt_listReader["boolean"] = function() return net.ReadBool() end
nt.mt_listReader["bool"] = nt.mt_listReader["boolean"]
nt.mt_listReader["color"] = function() return net.ReadColor() end
nt.mt_listReader["data"] = function() return net.ReadData() end
nt.mt_listReader["double"] = function() return net.ReadDouble() end
nt.mt_listReader["entity"] = function() return net.ReadEntity() end
nt.mt_listReader["player"] = nt.mt_listReader["entity"]
nt.mt_listReader["matrix"] = function() return net.ReadMatrix() end
nt.mt_listReader["normal"] = function() return net.ReadNormal() end
nt.mt_listReader["string"] = function() return net.ReadString() end
nt.mt_listReader["table"] = function() return net.ReadTable() end
nt.mt_listReader["vector"] = function() return net.ReadVector() end
nt.mt_listReader["any"] = function() return net.ReadType() end
nt.mt_listReader["next"] = nt.mt_listReader["boolean"]

nt.mt_listReader["int"] = function() return net.ReadInt(32) end
nt.mt_listReader["uint"] = function() return net.ReadUInt(32) end
for i = 1, 32 do
    nt.mt_listReader["int" .. i] = function() return net.ReadInt(i) end
    nt.mt_listReader["uint" .. i] = function() return net.ReadUInt(i) end
end
nt.mt_listReader["steamid"] = function()
    local x = net.ReadUInt(1)
    local y = net.ReadUInt(1)
    local z = net.ReadUInt(32)

    return _I{"STEAM_",x,":",y,":",z}
end
nt.mt_listReader["sid"] = nt.mt_listReader["steamid"]
nt.mt_listReader["steamid64"] = function()
    return ToSID64(nt.mt_listReader["steamid"]())
end
nt.mt_listReader["sid64"] = nt.mt_listReader["steamid64"]



nt.mt_listWriter = {}
nt.mt_listWriter["angle"] = function(var) return net.WriteAngle(var) end
nt.mt_listWriter["bit"] = function(var) return net.WriteBit(var) end
nt.mt_listWriter["boolean"] = function(var) return net.WriteBool(var) end
nt.mt_listWriter["bool"] = nt.mt_listWriter["boolean"]
nt.mt_listWriter["color"] = function(var) return net.WriteColor(var) end
nt.mt_listWriter["data"] = function(var) return net.WriteData(var) end
nt.mt_listWriter["double"] = function(var) return net.WriteDouble(var) end
nt.mt_listWriter["entity"] = function(var) return net.WriteEntity(var) end
nt.mt_listWriter["player"] = nt.mt_listWriter["entity"]
nt.mt_listWriter["matrix"] = function(var) return net.WriteMatrix(var) end
nt.mt_listWriter["normal"] = function(var) return net.WriteNormal(var) end
nt.mt_listWriter["string"] = function(var) return net.WriteString(var) end
nt.mt_listWriter["table"] = function(var) return net.WriteTable(var) end
nt.mt_listWriter["vector"] = function(var) return net.WriteVector(var) end
nt.mt_listWriter["any"] = function(var) return net.WriteType(var) end
nt.mt_listWriter["next"] = function(var) return net.WriteBool(var and true or false) end

nt.mt_listWriter["int"] = function(var) return net.WriteInt(var, 32) end
nt.mt_listWriter["uint"] = function(var) return net.WriteUInt(var, 32) end
for i = 1, 32 do
    nt.mt_listWriter["int" .. i] = function(var) return net.WriteInt(var, i) end
    nt.mt_listWriter["uint" .. i] = function(var) return net.WriteUInt(var, i) end
end
nt.mt_listWriter["steamid"] = function(var)
    local x = tonumber(var:sub(7,7))
    local y = tonumber(var:sub(9,9))
    local z = tonumber(var:sub(11))
    net.WriteUInt(x, 1)
    net.WriteUInt(y, 1)
    net.WriteUInt(z, 32)
end
nt.mt_listWriter["sid"] = nt.mt_listWriter["steamid"]
nt.mt_listWriter["steamid64"] = function(var)
    return nt.mt_listWriter["steamid"](FromSID64(var))
end
nt.mt_listWriter["sid64"] = nt.mt_listWriter["steamid64"]

nt.mt_listExtraTypes = {}

-- nt.Write({"player", "int32"}, Player(1), 100)
function nt.Write(types, data_values)
    for k, value in ipairs(data_values) do
        local tp_name = types[k]
        nt.mt_listWriter[tp_name](value)
    end
end

-- local player, health = nt.Read({"int8", "bool"})
function nt.Read(types)
    local args = {}
    for k, tp_name in ipairs(types) do
        local a, b, c = nt.mt_listReader[tp_name]()
        table.insert(args, a)
    end
    return unpack(args)
end