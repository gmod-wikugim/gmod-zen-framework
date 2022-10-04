local sh_hooks = zen.Init("shared_hooks")

local unpack = unpack
nt.RegisterChannel("shared.hooks", nil, {
    types = {"string_id", "array:any"},
    OnRead = function(self, ply, hook_name, hook_args)
        if CLIENT then
            ihook.Run("shared." .. hook_name, unpack(hook_args))
        end
    end,
    OnWrite = function(self, ply, hook_name, hook_args)
        if SERVER then
            ihook.Run("shared." .. hook_name, unpack(hook_args))
        end
    end
})

sh_hooks.UNIQUE_ID = "zen.shared_hooks"
function sh_hooks.Run(hook_name, ...)
    nt.SendToChannel("shared.hooks", nil, hook_name, {...})
end

function sh_hooks.StartListen(hook_name)
    ihook.Listen(hook_name, sh_hooks.UNIQUE_ID, function(...)
        sh_hooks.Run(hook_name, ...)
    end)
end

function sh_hooks.StopListen(hook_name)
    ihook.Remove(hook_name, sh_hooks.UNIQUE_ID)
end


sh_hooks.StartListen("PlayerInitialSpawn")
sh_hooks.StartListen("PlayerDisconnected")
sh_hooks.StartListen("PlayerDeath")
sh_hooks.StartListen("PlayerLoadout")
sh_hooks.StartListen("PlayerSpawn")

