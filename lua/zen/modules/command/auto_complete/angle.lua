local icmd, iconsole = zen.Init("command", "console")

local floor = math.floor
local concat = table.concat

local angle_floor = function(ang)
    return '"' .. concat({floor(ang[1]), floor(ang[2]), floor(ang[3])}, " ") .. '"'
end

icmd.RegisterAutoCompleteTypeN(TYPE.ANGLE, function(typen, value, text_next, addSelect)
    if !value or value == "" or value == " " then
        local lp = LocalPlayer()
        addSelect {
            text = "Angle(0, 0, 0)",
            value = angle_floor(Angle()),
        }

        addSelect {
            text = "My Angles",
            value = angle_floor(lp:GetAngles()),
        }

        addSelect {
            text = "Eye Angles",
            value = angle_floor(lp:EyePos()),
        }
    end
end)