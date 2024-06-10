module("zen", package.seeall)

string = _GET("string", string)

local read_types = {
    ["ply"] = function(var) return isentity(var) and var.Nick and (var:Nick() or "NIL") or tostring(var) end,
    ["n"] = function(var) return string.Comma(tostring(var)) end,
    ["s"] = function(var) return tostring(var) end,
    ["arg"] = function(var, onlyText)
        var = tostring(var)
        return var
    end,
    ["date"] = function(var) return os.date("!%H:%M %m.%d.%y", var) end,
}

local phrase_alias = {
    ["time"] = function() return os.date("!%H:%M %m.%d.%y", os.time()) end,
}

local _concat = table.concat


function string.InterpolateConfig(message, read_types, phrase_alias, tab, onlyText)
    tab = tab or {}
    message = message:gsub('($%b{})', function(w)
        local value = w:sub(3, -2) 

        if phrase_alias[value] then
            return phrase_alias[value]()
        end

        local key, n_value = string.match(value, "(%a+):(.+)")

        do -- Check is number
            local number_value = tonumber(n_value)
            if number_value then
                n_value = number_value
            end
        end


        if read_types[key] then
            return read_types[key](tab[n_value], onlyText)
        else
            return (tab[n_value] and _concat{"${",key, ':"', tostring(tab[n_value]), '"}'} or w)
        end
    end)

    return message
end

---@param message string
---@param tab table
---@param onlyText boolean?
---@return string
function string.Interpolate(message, tab, onlyText)
    return string.InterpolateConfig(message, read_types, phrase_alias, tab, onlyText)
end