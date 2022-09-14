ihook = ihook or {}

function ihook.Handler(hook_name, hook_id, func, level)
    if hook.Handler then
        hook.Handler(hook_name, hook_id, func, level)
    else
        hook.Add(hook_name, hook_id, func, level)
    end
end

function ihook.Listen(hook_name, hook_id, func, level)
    local no_return_func = function(...) func(...) end
    if hook.Listen then
        hook.Listen(hook_name, hook_id, no_return_func, level)
    else
        hook.Add(hook_name, hook_id, no_return_func, level)
    end
end

function ihook.Run(hook_name, ...)
    return hook.Run(hook_name, ...)
end

function ihook.Remove(hook_name, ...)
    return hook.Remove(hook_name, ...)
end

function ihook.Call(hook_name, gm, ...)
    return hook.Call(hook_name, gm, ...)
end

function ihook.GetTable()
    return hook.GetTable()
end