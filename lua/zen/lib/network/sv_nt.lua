module("zen", package.seeall)

local _I = table.concat

ihook.Listen("ReadyForNetwork.Pre", "nt.SendAllNetworkChannels", function(ply)

    for _, v in ipairs(nt.mt_ChannelsPublicPriority) do
        local channel_name = v.name
        local channel_id = v.id

        local tChannel = nt.mt_Channels[channel_name]
        if not tChannel then continue end

        if nt.i_debug_lvl >= 2 then
            print("[nt.debug] Player ", ply:SteamID64(), " start pull ", channel_name)
        end

        net.Start(nt.channels.pullChannels)
            net.WriteUInt(channel_id, 32)
            if tChannel.WritePull then
                tChannel.WritePull(tChannel, ply)
            end
        net.Send(ply)

        if nt.i_debug_lvl >= 2 then
            print("[nt.debug] Player ", ply:SteamID64(), " end pull ", channel_name)
        end
    end

    if nt.i_debug_lvl >= 1 then
        print("[nt.debug] All channels sent to player ", ply:SteamID64())
    end
end)

net.Receive(nt.channels.clientReady, function(len, ply)
    ply.mbReadyForNetwork = true
    ihook.Run("ReadyForNetwork.Pre", ply)
    ihook.Run("ReadyForNetwork", ply)
end)

ihook.Listen("nt.Receive", "zen.nt.logs", function(channel_name, ply, ...)
    if nt.i_debug_lvl >= 1 then
        print("[nt.received] ", channel_name)
        print(...)
    end
end)