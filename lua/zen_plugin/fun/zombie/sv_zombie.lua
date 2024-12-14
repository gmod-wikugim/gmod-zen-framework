module("zen", package.seeall)

---@param ply Player
---@param impulse number
ihook.Listen("zen_fun.OnImpulse", "zombie", function(ply, impulse)
    if impulse != 111 then return end


    if ply:Crouching() then
        zfun_zombie.Jump(ply)
    else
        zfun_zombie.Push(ply)
    end

end)