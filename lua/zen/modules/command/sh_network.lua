local icmd = zen.Init("command")

nt.RegisterChannel("icmd.command", nt.t_ChannelFlags.SIMPLE_NETWORK, {
    types = {"string_id", "array:any", "array:string_id"},
    OnRead = function(self, ply, cmd_name, cmd_args, cmd_tags)
        icmd.OnCommandResult(cmd_name, cmd_args, cmd_tags, ply)
    end
})

nt.RegisterChannel("icmd.register", nt.t_ChannelFlags.PUBLIC, {
    types = {"string_id", "array:string_id", "array:string_id"},
    OnRead = function(self, target, cmd_name, cmd_types, cmd_types_name)
        if SERVER then return end

        local types = {}
        for k, v in pairs(cmd_types) do
            types[k] = {type = v, name = cmd_types_name[k]}
        end

        local function callback(who, cmd, args, tags)
            nt.SendToChannel("icmd.command", nil, cmd, args, tags)
        end

        icmd.RegisterData{
            name = cmd_name,
            IsServerCommand = true,
            callback = callback,
            types = types,
            data = {}
        }
    end,
    WritePull = function(self, target)
        local tSend = {}
        for k, tCommand in pairs(icmd.t_Commands) do
            if not tCommand.IsServerCommand then continue end
            table.insert(tSend, tCommand)
        end

        local count = #tSend

        nt.Write({"uint12"}, {count})

        if count > 0 then
            for k = 1, count do
                local tCommand = tSend[k]

                nt.Write(self.types, {tCommand.name, tCommand.types_clear, tCommand.types_names})
            end
        end
    end,
    ReadPull = function(self, addResult)
        local count = nt.Read({"uint12"})
        if count > 0 then
            for k = 1, count do
                local name, types_clear, types_names = nt.Read({"string_id", "array:string_id", "array:string_id"})
                addResult(name, types_clear, types_names)
            end
        end
    end,
})

ihook.Listen("zen.icmd.Register", "network", function(name, tCommand)
    if CLIENT then return end
    nt.SendToChannel("icmd.register", nil, tCommand.name, tCommand.types_clear, tCommand.types_names)
end)