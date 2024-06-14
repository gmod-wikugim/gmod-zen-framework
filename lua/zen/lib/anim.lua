module("zen", package.seeall)

anim = _GET("anim")

_LISTEN("nt.RegisterChannels", "anim", function()

    nt.RegisterChannel("anim.RestartGesture", nil, {
        types = {"player", "uint32", "uint32", "boolean"},
        OnRead = function(self, _, ply, gusture_slot, act_number, auto_kill)
            if CLIENT then
                anim.RestartGesture(ply, gusture_slot, act_number, auto_kill)
            end
        end,
    })

end)



---@param ply Player
---@param gusture_slot number
---@param act_number number
---@param auto_kill boolean?
function anim.RestartGesture(ply, gusture_slot, act_number, auto_kill)
    auto_kill = auto_kill or true
    ply:AnimRestartGesture(gusture_slot, act_number, auto_kill)

    if SERVER then
        nt.SendToChannel("anim.RestartGesture", nil, ply, gusture_slot, act_number, act_number)
    end
end