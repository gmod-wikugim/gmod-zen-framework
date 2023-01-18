local clicmd = zen.Init("client_commands")

local unpack = unpack
nt.RegisterChannel("client_commands", nil, {
    types = {"string_id"},
    OnRead = function(self, ply, command)
        if SERVER then
            clicmd.OnCommand(ply, command)
        end
    end,
})


function clicmd.StartCommand(command)
    assert(isstring(command), "command not is string")

    nt.SendToChannel("client_commands", nil, command)
end

function clicmd.OnCommand(ply, command)
    ihook.Run("zen.OnClientCommand", ply, command)
end

if CLIENT then
    ihook.Listen("PlayerButtonPress.normal", "zen.comamnd",function(ply, but, in_key, bind_name)
        if isstring(bind_name) then
            clicmd.StartCommand(bind_name)
        end
    end)
end