local icmd, iconsole = zen.Init("command", "console")

local floor = math.floor
local concat = table.concat

local vector_floor = function(vec)
    return '"' .. concat({floor(vec.x), floor(vec.y), floor(vec.z)}, " ") .. '"'
end

icmd.RegisterAutoCompleteTypeN(TYPE.VECTOR, function(typen, value, text_next, addSelect)
    if !value or value == "" or value == " " then
        local lp = LocalPlayer()
        addSelect {
            text = "My Pos",
            value = vector_floor(lp:GetPos()),
        }

        addSelect {
            text = "Eye Pos",
            value = vector_floor(lp:EyePos()),
        }


    end
end)