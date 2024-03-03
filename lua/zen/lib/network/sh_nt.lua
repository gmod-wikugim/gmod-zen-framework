module("zen", package.seeall)

zen.network = zen.network or {}
nt = zen.network
nt.t_ChannelFlags = {}
nt.t_ChannelFlags.SIMPLE_NETWORK        = 0
nt.t_ChannelFlags.PUBLIC                = 2 ^ 1

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
        print("[nt.debug] Debugging started, \"zen_network_debug 0\" to stop!")
    else
        print("[nt.debug] Debugging stoped, \"zen_network_debug 1\" to start again!")
    end
end, "nt.OnChange")
nt.i_debug_lvl = GetConVar("zen_network_debug"):GetInt() or 0

nt.mt_Channels = nt.mt_Channels or {}
nt.mt_ChannelsIDS = nt.mt_ChannelsIDS or {}
nt.mt_ChannelsNames = nt.mt_ChannelsNames or {}

nt.mt_ChannelsPublic = nt.mt_ChannelsPublic or {}
nt.mt_ChannelsPublicPriority = nt.mt_ChannelsPublicPriority or {}
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

    if flags == nt.t_ChannelFlags.SIMPLE_NETWORK and !data then return channel_id, tChannel end

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

        for id, human_type in pairs(data.types) do
            if not human_type then
                bSuccess = false
                sLastError = _I{"GET: human_type is nil, id: ", id}
                break
            end


            if bSuccess then
                local fReader = nt.GetTypeReaderFunc(human_type)
                if not fReader then
                    bSuccess = false
                    sLastError = _I{"GET: Reader not exists #1: ", human_type}
                    break
                end
            end
        end

        tChannel.types = data.types
    else
        assertFunction(data.fWriter, "data.fWriter")
        assertFunction(data.fReader, "data.fReader")
        tChannel.fWriter = data.fWriter
        tChannel.fReader = data.fReader
    end

    if data.Init then
        assertFunction(data.Init, "data.Init")
        tChannel.Init = data.Init
    end

    if data.OnWrite then
        assertFunction(data.OnWrite, "data.OnWrite")
        tChannel.OnWrite = data.OnWrite
    end

    if data.OnRead then
        assertFunction(data.OnRead, "data.OnRead")
        tChannel.OnRead = data.OnRead
    end

    if FLAGS.PUBLIC then
        if SERVER then
            assertFunction(data.WritePull, "data.WritePull")
            tChannel.WritePull = data.WritePull
        end
        if CLIENT then
            assertFunction(data.ReadPull, "data.ReadPull")
            tChannel.ReadPull = data.ReadPull
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

    if tChannel.Init then
        tChannel.Init(tChannel)
    end

    return channel_id, tChannel
end

function nt.SendToChannel(channel_name, target, ...)
    local tChannel = nt.mt_Channels[channel_name]
    assert(tChannel, "channel not exists \"" .. channel_name .. "\"")
    assert(istable(tChannel.types) or isfunction(tChannel.fWriter) , "tChannel.types should be tChannel.types || tChannel.fWriter should be function")

    local data = {...}

    if tChannel.OnWrite then
        tChannel.OnWrite(tChannel, target, unpack(data))
    end

    if tChannel.types then
        nt.Send(channel_name, tChannel.types, data)
    elseif tChannel.fWriter then
        if nt.i_debug_lvl >= 2 then
            print("[nt.debug] Start \"",channel_name,"\"")
        end

        if tChannel.customNetworkString then
            net.Start(tChannel.customNetworkString)
        else
            net.Start(nt.channels.sendMessage)
            net.WriteUInt(tChannel.id, 32)
        end

        if nt.i_debug_lvl >= 2 then
            for k, v in pairs(data) do
                print("[nt.debug] Pre-Write \"",type(v),"\"", " \"",tostring(v),"\"")
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
            print("[nt.debug] End \"",channel_name,"\"")
        end

        if nt.i_debug_lvl >= 1 then
            print("[nt.debug] Sent network \"",channel_name,"\" to server/players")
        end
    else
        MsgC(COLOR.ERROR, "[NT-Predicted-Error] Channel not have send option", channel_name, "\n")
        return
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

nt.mt_listReader_SpecialCache = {}
nt.mt_listReader_Special = {}
nt.mt_listReader_Special["array"] = function(type_name, ...)
    local fReader = nt.mt_listReader[type_name]

    local count = net.ReadUInt(8)

    local tArray = {}
    for k = 1, count do
        local value = fReader()
        table.insert(tArray, value)
    end

    return tArray
end

---@param type_name string
---@return function fReader, boolean? isSpecial, ...
function nt.GetTypeReaderFunc(type_name)
    assertStringNice(type_name, "type_name")

    local defReader = nt.mt_listReader[type_name]
    if defReader then return defReader end

    if nt.mt_listReader_SpecialCache[type_name] then
        return unpack(nt.mt_listReader_SpecialCache[type_name])
    end

    do
        local specialID, type_name = string.match(type_name, "([%w]+):([%w]+)")
        if specialID and type_name then
            local specReader = nt.mt_listReader_Special[specialID]
            local defReader = nt.mt_listReader[type_name]
            if specReader and defReader then
                nt.mt_listReader_SpecialCache[type_name] = {specReader, true, type_name}
                return specReader, true, type_name
            else
                if specReader and not defReader then
                    error("GetTypReader defReader not exists #2: " .. tostring(type_name))
                elseif not specReader and defReader then
                    error("GetTypReader specReader not exists #3: " .. tostring(specialID))
                end
            end
        end
    end
end

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

nt.mt_listWriter_SpecialCache = {}
nt.mt_listWriter_Special = {}
nt.mt_listWriter_Special["array"] = function(var, type_name)
    local fWriter = nt.mt_listWriter[type_name]

    if table.IsEmpty(var) then
        net.WriteUInt(0, 8)
        return
    end

    local count = #var

    net.WriteUInt(count, 8)

    for k = 1, count do
        local value = var[k]
        fWriter(value)
    end
end

nt.mt_listSpecialCheckFunc = {}
nt.mt_listSpecialCheckFunc["array"] = function(value)
    local count = 0
    for k in pairs(value) do
        count = count + 1
        if k != count then
            return false, "array not support table with custom keys"
        end
    end
end

---@param type_name string
---@return function fReader, boolean? isSpecial, ...
function nt.GetTypeWriterFunc(type_name)
    assertStringNice(type_name, "type_name")

    local defWriter = nt.mt_listWriter[type_name]
    if defWriter then return defWriter end

    if nt.mt_listWriter_SpecialCache[type_name] then
        return unpack(nt.mt_listWriter_SpecialCache[type_name])
    end

    local specialID, type_name = string.match(type_name, "([%w]+):([%w]+)")
    if specialID and type_name then
        local specWriter = nt.mt_listWriter_Special[specialID]
        local defWriter = nt.mt_listWriter[type_name]
        if specWriter and defWriter then
            nt.mt_listWriter_SpecialCache[type_name] = {specWriter, true, type_name}
            return specWriter, true, type_name
        else
            if specWriter and not defWriter then
                error("GetTypeWriter defWriter not exists: " .. tostring(type_name))
            elseif not specWriter and defWriter then
                error("GetTypeWriter specWriter not exists: " .. tostring(specialID))
            end
        end
    end
end


nt.mt_listValidateCheck = {}
function nt.funcValidCustomType(human_type, value, type_id, id)
    local fCheck = nt.mt_listValidateCheck[human_type]
    if fCheck then return fCheck(value) end
    if nt.mt_listWriter_SpecialCache[human_type] then return true end

    local specialID, type_name = string.match(human_type, "([%w]+):([%w]+)")
    if specialID and type_name then
        local specWriter = nt.mt_listWriter_Special[specialID]
        local defWriter = nt.mt_listWriter[type_name]
        nt.mt_listWriter_SpecialCache[human_type] = {specWriter, true, type_name}
        if specWriter and defWriter then
            local funcCheck = nt.mt_listSpecialCheckFunc[specialID]
            if funcCheck then
                local res, com = funcCheck(value)
                if res == false then return false, com end
            end
            return true
        else
            if specWriter and not defWriter then
                return false, "GetTypWriter defWriter not exists: " .. tostring(type_name)
            elseif not specWriter and defWriter then
                return false, "GetTypWriter specWriter not exists: " .. tostring(specialID)
            end
        end
    end

    return false
end


-- nt.Write({"player", "int32"}, Player(1), 100)
function nt.Write(types, data_values)
    for k, value in ipairs(data_values) do
        local tp_name = types[k]
        local fWriter, isSpecial, a1, a2, a3, a4, a5 = nt.GetTypeWriterFunc(tp_name)
        fWriter(value, a1, a2, a3, a4, a5)
    end
end

-- local player, health = nt.Read({"int8", "bool"})
function nt.Read(types)
    local args = {}
    for k, tp_name in ipairs(types) do
        local fReader, isSpecial, a1, a2, a3, a4, a5 = nt.GetTypeReaderFunc(tp_name)
        table.insert(args, fReader(a1, a2, a3, a4, a5))
    end
    return unpack(args)
end

function nt.Receive(channel_name, types, callback)
    nt.RegisterChannel(channel_name, nt.t_ChannelFlags.SIMPLE_NETWORK, {
        types = types,
        OnRead = function(tChannel, ply, ...)
            return callback(ply, ...)
        end
    })
end

function nt.Send(channel_name, types, data, target)
    assertString(channel_name, "channel_name")
    types = types or {}
    data = data or {}
    assertTable(types, "types")
    assertTable(data, "data")

    local channel_id = nt.GetChannelID(channel_name)
    local tChannel = nt.mt_Channels[channel_name]

    local bSuccess = true
    local sLastError

    if bSuccess and not channel_id then
        bSuccess = false
        sLastError = "SEND: channel_id not exists"
    end

    if bSuccess then
        if target then
            if isentity(target) and not IsValid(target) or not target:IsPlayer() then
                bSuccess = false
                sLastError = "SEND: target entity not is player or not is valid"
            end
        end
    end

    local to = target and target:SteamID64() or "server"

    local iCounter = 0
    if bSuccess then
        local res, lastID, sError = util.CheckTypeTableWithDataTable(types, data, function(net_type, value, type_id, id)
            if SERVER and net_type == "string_id" then
                nt.RegisterStringNumbers(value)
            end
            local fWriter = nt.GetTypeWriterFunc(net_type)
            if not fWriter then
                return false, "Type-Writer not exists: " .. net_type
            end
        end, nt.funcValidCustomType)
        if res then
            iCounter = lastID
        else
            bSuccess = false
            sLastError = sError
        end
    end

    if not bSuccess then
        MsgC(COLOR.ERROR, "[NT-Predicted-Error] ", channel_name, "\n", sLastError, "\n")
        return
    end

    if nt.i_debug_lvl >= 2 then
        print("[nt.debug] Start \"",channel_name,"\"")
    end

    if tChannel and tChannel.customNetworkString then
        net.Start(tChannel.customNetworkString)
    else
        net.Start(nt.channels.sendMessage)
        net.WriteUInt(channel_id, 12)
    end

        if iCounter > 0 then
            for id = 1, iCounter do
                local net_type = types[id]
                local fWriter, isSpecial, a1, a2, a3, a4, a5 = nt.GetTypeWriterFunc(net_type)
                local value = data[id]

                if nt.i_debug_lvl >= 2 then
                    print("[nt.debug] Write \"",net_type,"\"", " \"",tostring(value),"\"")
                end

                fWriter(value, a1, a2, a3, a4, a5)
            end
        end

    if SERVER then
        if target then
            net.Send(target)
        else
            net.Broadcast()
        end
    elseif CLIENT_DLL then
        net.SendToServer()
    end

    if tChannel.OnWrite then
        tChannel.OnWrite(tChannel, target, unpack(data))
    end

    if nt.i_debug_lvl >= 2 then
        print("[nt.debug] End \"",channel_name,"\"")
    end

    ihook.Run("nt.Send", {channel_name, types, data, target})

    if nt.i_debug_lvl >= 1 then
        print("[nt.debug] Sent network \"",channel_name,"\" to ", to)
    end
end

net.Receive(nt.channels.sendMessage, function(len, ply)
    local channel_id = net.ReadUInt(12)
    local channel_name = nt.GetChannelName(channel_id)

    if not IsValid(ply) then ply = nil end
    local from = ply and ply:SteamID64() or "server"

    local bSuccess = true
    local sLastError

    if not channel_name then
        bSuccess = false
        sLastError = _I{"GET: Received unknown message name ", channel_id, "\n", debug.traceback(), "\n"}
    end

    local tChannel = nt.mt_Channels[channel_name]
    local bWaitingInspect = true

    if nt.i_debug_lvl >= 2 then
        print("[nt.debug] Received \"",channel_name,"\" from ", from)
    end


    if bSuccess and bWaitingInspect and tChannel and (tChannel.fReader or tChannel.types) then
        if nt.i_debug_lvl >= 2 then
            print("[nt.debug] Start Read \"",channel_name,"\"")
        end

        if tChannel.fReader then
            local result = {tChannel.fReader(tChannel)}

            if tChannel.OnRead then
                tChannel.OnRead(tChannel, ply, unpack(result))
            end

            if nt.i_debug_lvl >= 2 then
                for k, v in pairs(result) do
                    print("[nt.debug]   Read \"",type(v),"\"", " \"",tostring(v),"\"")
                end
            end

            ihook.Run("nt.Receive", channel_name, ply, unpack(result))

            bWaitingInspect = false
        elseif tChannel.types then
            local result = {}
            for _, net_type in ipairs(tChannel.types) do
                local fReader, isSpecial, a1, a2, a3, a4, a5 = nt.GetTypeReaderFunc(net_type)

                if not fReader then
                    bSuccess = false
                    sLastError = _I{"GET: Reader not exists #4: ", net_type}
                    goto result
                end


                local read_result = fReader(a1, a2, a3, a4, a5) -- TODO: Can add multivars return
                table.insert(result, read_result)

                if nt.i_debug_lvl >= 2 then
                    print("[nt.debug]   Read \"",net_type,"\"", " \"",tostring(read_result),"\"")
                end

                if net_type == "next" and read_result == false then break end
            end

            if tChannel.OnRead then
                tChannel.OnRead(tChannel, ply, unpack(result)) -- TODO: Can add miltivars return
            end

            ihook.Run("nt.Receive", channel_name, ply, unpack(result))

            bWaitingInspect = false
        end

        if nt.i_debug_lvl >= 2 then
            print("[nt.debug] End Read \"",channel_name,"\"")
        end

        if nt.i_debug_lvl >= 1 then
            print("[nt.debug] GET: Received network \"",channel_name,"\" from ", from)
        end
    end

    if bWaitingInspect then
        bSuccess = false
        sLastError = "network not inspected"
    end

    ::result::

    if not bSuccess then
        MsgC(COLOR.ERROR, "[NT-Predicted-Error] ", channel_name, "\n", sLastError, "\n")
        return
    end
end)