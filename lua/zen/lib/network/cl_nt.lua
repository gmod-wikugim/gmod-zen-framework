module("zen", package.seeall)

local _I = table.concat
local insert = table.insert

net.Receive(nt.channels.pullChannels, function(len, ply)
    local channel_id = net.ReadUInt(32)
    local channel_name = nt.GetChannelName(channel_id)

    local bSuccess = true
    local sLastError

    if not channel_name then
        bSuccess = false
        sLastError = _I{"GET PULL: Received unknown message name ", channel_id, "\n", debug.traceback(), "\n"}
    end

    local tChannel = nt.mt_Channels[channel_name]

    if not tChannel then
        bSuccess = false
        sLastError = _I{"GET PULL: Chanell not exists ", channel_name, "\n", debug.traceback(), "\n"}
    end

    if bSuccess then
        if tChannel.ReadPull then
            local tResult = {}

            local function addResult(...) insert(tResult, {...}) end

            tChannel.ReadPull(tChannel, addResult)

            if tChannel.OnRead then
                for k, result in pairs(tResult) do
                    ihook.Run("nt.Receive", channel_name, ply, unpack(result))
                    tChannel.OnRead(tChannel, ply, unpack(result))
                end
            else
                for k, result in pairs(tResult) do
                    ihook.Run("nt.Receive", channel_name, ply, unpack(result))
                end
            end
        end
    end

    if not bSuccess then
        MsgC(COLOR.ERROR, "[NT-Predicted-Error] ", channel_name, "\n", sLastError, "\n")
        return
    end

end)

ihook.Listen("InitPostEntity", "nt.ReadyForNetwork", function()
    ihook.Run("ReadyForNetwork")
    net.Start(nt.channels.clientReady)
    net.SendToServer()
end)

ihook.Listen("nt.Receive", "zen.Channels", function(channel_name, ply, v1, v2)
    if channel_name == "channels" then
        log("NT-Channel: ", v1, " - ", v2)
    end
end)