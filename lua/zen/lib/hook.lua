ihook = ihook or {}

function ihook.Handler(hook_name, hook_id, func, level)
    if hook.Handler then
        hook.Handler(hook_name, hook_id, func, level)
    else
        hook.Add(hook_name, hook_id, func, level)
    end
end

function ihook.Listen(hook_name, hook_id, func, level)
    if hook.Listen then
        hook.Listen(hook_name, hook_id, func, level)
    else
        hook.Add(hook_name, hook_id, func, level)
    end
end

function ihook.Run(hook, ...)
    return hook.Run(hook, ...)
end

function ihook.Call(hook, gm, ...)
    return hook.Call(hook, gm, ...)
end

function ihook.GetTable()
    return hook.GetTable()
end