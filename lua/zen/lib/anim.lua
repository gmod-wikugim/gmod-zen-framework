module("zen", package.seeall)

anim = _GET("anim")

_LISTEN("nt.RegisterChannels", "anim", function()

    nt.RegisterChannel("anim.RestartGesture", nil, {
        types = {"player", "uint32", "uint32", "bool"},
        OnRead = function(self, _, ply, gusture_slot, act_number, auto_kill)
            if CLIENT then
                anim.RestartGesture(ply, gusture_slot, act_number, auto_kill)
            end
        end,
    })


    nt.RegisterChannel("anim.ResetGestureSlot", nil, {
        types = {"player", "uint32"},
        OnRead = function(self, _, ply, gusture_slot)
            if CLIENT then
                anim.ResetGestureSlot(ply, gusture_slot)
            end
        end,
    })
end)



---@param ply Player
---@param gusture_slot number
---@param act_number number
---@param auto_kill boolean?
function anim.RestartGesture(ply, gusture_slot, act_number, auto_kill)

    if auto_kill == nil then auto_kill = true end
    ply:AnimRestartGesture(gusture_slot, act_number, auto_kill)

    if SERVER then
        nt.SendToChannel("anim.RestartGesture", nil, ply, gusture_slot, act_number, auto_kill)
    end
end


---@param ply Player
---@param gusture_slot number
function anim.ResetGestureSlot(ply, gusture_slot)

    ply:AnimResetGestureSlot(gusture_slot)

    if SERVER then
        nt.SendToChannel("anim.ResetGestureSlot", nil, ply, gusture_slot)
    end
end
