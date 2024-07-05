module("zen", package.seeall)

msg = _GET("msg")

NOTIFY_GENERIC = 0
NOTIFY_ERROR = 1
NOTIFY_UNDO = 2
NOTIFY_HINT = 3
NOTIFY_CLEANUP = 4


nt.RegisterChannel("message.debugInfo", nil, {
    types = {"string", "uint8", "color", "string"},
    OnRead = function(self, ply, text, lifetime, outline_color, font)
        if CLIENT then
            ui.DebugInfo(text, lifetime, outline_color, font)
        end
    end,
})


nt.RegisterChannel("message.chat.singleString", nil, {
    types = {"string"},
    OnRead = function(self, ply, message)
        if CLIENT then
            chat.AddText(message)
        end
    end,
})

nt.RegisterChannel("message.chat.table", nil, {
    types = {"array:any"},
    OnRead = function(self, ply, array)
        if CLIENT then
            chat.AddText(unpack(array))
        end
    end,
})

nt.RegisterChannel("message.console.singleString", nil, {
    types = {"string"},
    OnRead = function(self, ply, message)
        if CLIENT then
            print(message)
        end
    end,
})

nt.RegisterChannel("message.console.table", nil, {
    types = {"array:any"},
    OnRead = function(self, ply, array)
        if CLIENT then
            print(unpack(array))
        end
    end,
})
nt.RegisterChannel("message.notification.AddLegacy", nil, {
    types = {"string", "uint4", "uint12"},
    OnRead = function(self, ply, message, notify_type, length)
        if CLIENT then
            notification.AddLegacy(message, notify_type, length)
        end
    end,
})


do
    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param message string
    ---@param notify_type number
    ---@param length number
    function msg.Notify(target, message, notify_type, length)
        nt.SendToChannel("message.notification.AddLegacy", target, message, notify_type, length)
    end

    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param message string
    ---@param notify_type number
    ---@param length number
    ---@param tabs table<string, any>
    function msg.NotifyInterpolate(target, message, notify_type, length, tabs)
        local message_interpolated = string.Interpolate(message, tabs)

        nt.SendToChannel("message.notification.AddLegacy", target, message_interpolated, notify_type, length)
    end
end


do -- msg.ChatMessage
    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param message string
    function msg.ChatMessage(target, message)

        nt.SendToChannel("message.chat.singleString", target, message)
    end

    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param message string
    ---@param tabs table<string, any>
    function msg.ChatMessageInterpolate(target, message, tabs)
        local message_interpolated = string.Interpolate(message, tabs)

        msg.ChatMessage(target, message_interpolated)
    end

    -- Send chat message like chat.AddTextText(...)
    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param ... any
    function msg.ChatMessageArray(target, ...)
        nt.SendToChannel("message.chat.table", target, {...})
    end
end

do -- msg.Console
    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param message string
    function msg.Console(target, message)

        nt.SendToChannel("message.console.singleString", target, message)
    end

    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param message string
    ---@param tabs table<string, any>
    function msg.ConsoleInterpolate(target, message, tabs)
        local message_interpolated = string.Interpolate(message, tabs)

        msg.Console(target, message_interpolated)
    end

    -- Send chat message like chat.AddTextText(...)
    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param ... any
    function msg.ConsoleArray(target, ...)
        nt.SendToChannel("message.console.table", target, {...})
    end
end


do -- msg.Error
    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param messageError string
    function msg.Error(target, messageError)

        local text = messageError or "Unknown error"
        local lifetime = 4
        local outline_color = Color(255, 0, 0)
        local font = "6:Roboto"

        nt.SendToChannel("message.debugInfo", target, text, lifetime, outline_color, font)
    end

    ---@param target Player|"CRecipientFilter"| table<Player>
    ---@param messageError string
    ---@param tabs table<string, any>
    function msg.ErrorInterpolate(target, messageError, tabs)
        local message_interpolated = string.Interpolate(messageError, tabs)

        msg.Error(target, message_interpolated)
    end
end