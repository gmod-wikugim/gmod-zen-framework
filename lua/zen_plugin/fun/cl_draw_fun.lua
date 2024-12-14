module("zen", package.seeall)

local color_team = Color(255,255,0)

---@param ply Player
local function DrawTeamMate(ply)
    halo.Add( {ply}, color_team, 5, 5, 2, true, true)

end
ihook.Listen("RenderScene", "zen_fun", function()
    local LP = LocalPlayer()

    if !LP:zen_GetVar("fun_mode") then return end

    for k, ply in player.Iterator() do
        if !ply:zen_GetVar("fun_mode") then continue end

        DrawTeamMate(ply)
    end
end)